import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/cloudflare_guard.dart';
import '../../../search/domain/entities/book.dart';
import '../../../search/domain/entities/book_details.dart';
import '../../../search/domain/entities/download_link.dart';
import '../../../search/domain/entities/search_query.dart';
import '../../domain/book_source.dart';
import 'annas_archive_cache.dart';
import 'annas_archive_client.dart';
import 'annas_archive_dto.dart';
import 'annas_archive_health_check.dart';
import 'annas_archive_instance_store.dart';
import 'annas_archive_instances.dart';
import 'annas_archive_mapper.dart';
import 'annas_archive_parser.dart';

/// Provider Anna's Archive — première source du moteur.
///
/// ORCHESTRATEUR UNIQUEMENT : il compose client (transport), parser
/// (HTML), mapper (modèle), cache, health-check et CloudflareGuard.
/// Aucune logique réseau bas niveau, aucun parsing ici.
///
/// Endpoints utilisés (constatés dans l'audit, rien d'inventé) :
/// - recherche : GET {base}/search?q=&sort=&lang=&ext=&year=&page=
/// - détail    : GET {base}/md5/{md5}
/// - liens     : ancres /slow_download/ de la page de détail
/// - fast dl   : GET {base}/dyn/api/fast_download.json?md5=&key= (clé)
class AnnaArchiveSource implements BookSource {
  final AnnaArchiveClient client;
  final AnnaArchiveParser parser;
  final AnnaArchiveMapper mapper;
  final AnnaArchiveCache cache;
  final CloudflareGuard cloudflareGuard;
  final AnnaArchiveHealthCheck healthChecker;
  final AnnaArchiveInstanceStore? instanceStore;
  final String? donationKey;

  /// Âge maximal du classement avant un retest automatique.
  final Duration healthMaxAge;

  /// Horodatage de la dernière mesure complète des instances.
  DateTime? _lastRankingAt;

  static const _meta = SourceMeta(
    id: AnnaArchiveMapper.sourceId,
    displayName: "Anna's Archive",
    supportsPagination: true,
  );

  /// Jeton de la requête en cours : toute nouvelle recherche annule
  /// l'ancienne (annulation des requêtes obsolètes).
  CancellationToken? _activeToken;

  AnnaArchiveSource({
    AnnaArchiveClient? client,
    AnnaArchiveParser? parser,
    AnnaArchiveMapper? mapper,
    AnnaArchiveCache? cache,
    CloudflareGuard? cloudflareGuard,
    AnnaArchiveHealthCheck? healthCheck,
    this.instanceStore,
    this.healthMaxAge = const Duration(hours: 6),
    this.donationKey,
  })  : parser = parser ?? AnnaArchiveParser(),
        client = client ?? AnnaArchiveClient(),
        mapper = mapper ?? AnnaArchiveMapper(),
        cache = cache ?? AnnaArchiveCache(),
        cloudflareGuard = cloudflareGuard ?? CloudflareGuard(),
        healthChecker = healthCheck ?? AnnaArchiveHealthCheck();

  /// Construction groupée pour l'app : transport injectable (tests).
  factory AnnaArchiveSource.custom({
    http.Client? httpClient,
    List<ArchiveInstance>? instances,
    AnnaArchiveCache? cache,
    CloudflareGuard? guard,
    AnnaArchiveInstanceStore? instanceStore,
    Duration healthMaxAge = const Duration(hours: 6),
    String? donationKey,
  }) {
    final shared = httpClient ?? http.Client();
    return AnnaArchiveSource(
      client: AnnaArchiveClient(httpClient: shared, instances: instances),
      healthCheck: AnnaArchiveHealthCheck(httpClient: shared),
      cache: cache,
      cloudflareGuard: guard,
      instanceStore: instanceStore,
      healthMaxAge: healthMaxAge,
      donationKey: donationKey,
    );
  }

  @override
  SourceMeta get meta => _meta;

  /// À appeler au démarrage : initialise le cache disque et restaure
  /// le classement des instances sauvegardé à la session précédente.
  Future<void> initialize() async {
    await cache.initialize();
    final store = instanceStore;
    if (store != null) {
      _lastRankingAt = await store.restore(client.instances);
    }
  }

  /// RETEST RÉGULIER DES INSTANCES.
  ///
  /// Ne refait une mesure complète que si le classement est plus vieux
  /// que [healthMaxAge] (ou jamais mesuré) — ou si [force] est vrai.
  /// Après chaque mesure, le classement est persisté via [instanceStore].
  /// Retourne les rapports, ou une liste vide si rien n'était à faire.
  Future<List<InstanceHealthReport>> maintainInstances(
      {bool force = false}) async {
    final stale = _lastRankingAt == null ||
        DateTime.now().difference(_lastRankingAt!) > healthMaxAge;
    if (!force && !stale) return const [];
    final reports = await healthChecker.checkAll(client.instances);
    _lastRankingAt = DateTime.now();
    await instanceStore?.persist(client.instances);
    return reports;
  }

  // ------------------------------------------------------------------
  // Recherche
  // ------------------------------------------------------------------

  @override
  Future<PagedResult<Book>> search(SearchQuery query) async {
    // Annulation de la requête précédente : une seule recherche active.
    final token = _newToken();

    // Retest régulier en arrière-plan : ne bloque JAMAIS la recherche.
    // Actif uniquement si un store est configuré (le classement a alors
    // vocation à être persisté et maintenu à jour entre les sessions).
    if (instanceStore != null) unawaited(maintainInstances());

    final cacheKey = 'search|${_canonicalQuery(query)}';
    final cached = await cache.get(cacheKey);
    token.throwIfCancelled();
    if (cached != null) {
      final page = RawSearchPage.fromJson(
          jsonDecode(cached) as Map<String, dynamic>);
      // La base URL du cache est inconnue : on reconstruit sur la
      // meilleure instance courante.
      return PagedResult(
        items: mapper.mapSearchHits(page.hits, _bestInstanceUrl()),
        hasMore: page.hasNextPage,
      );
    }

    final path = _buildSearchPath(query);
    final response = await _fetchWithGuard(path, token);
    token.throwIfCancelled();

    final page = parser.parseSearchPage(response.body, currentPage: query.page);

    // Mise en cache du DTO brut (indépendant du modèle).
    await cache.set(cacheKey, jsonEncode(page.toJson()));

    return PagedResult(
      items: mapper.mapSearchHits(page.hits, response.instanceBaseUrl),
      hasMore: page.hasNextPage,
    );
  }

  /// Construit la query string (endpoint /search réel).
  String _buildSearchPath(SearchQuery query) {
    final params = <String, String>{
      'index': '',
      'q': query.text,
      'display': '',
      'page': query.page.toString(),
      'sort': switch (query.sort) {
        SearchSort.newest => 'newest',
        SearchSort.oldest => 'oldest',
        SearchSort.largest => 'largest',
        SearchSort.smallest => 'smallest',
        SearchSort.relevance => '',
      },
      'lang': query.language ?? '',
      'ext': query.format == null || query.format == BookFormat.unknown
          ? ''
          : query.format!.name,
      'year': query.year?.toString() ?? '',
      'content': '',
    };
    return Uri(path: '/search', queryParameters: params).toString();
  }

  String _canonicalQuery(SearchQuery query) =>
      '${query.text.trim().toLowerCase()}|${query.language ?? ''}|'
      '${query.format?.name ?? ''}|${query.year ?? ''}|'
      '${query.sort.name}|${query.page}';

  // ------------------------------------------------------------------
  // Détail
  // ------------------------------------------------------------------

  @override
  Future<BookDetails> details(String sourceBookId) async {
    final token = _newToken();
    final response = await _fetchWithGuard('/md5/$sourceBookId', token);
    final raw = parser.parseDetailPage(response.body);
    return mapper.mapDetail(raw, sourceBookId, response.instanceBaseUrl);
  }

  // ------------------------------------------------------------------
  // Liens de téléchargement
  // ------------------------------------------------------------------

  @override
  Future<List<DownloadLink>> resolveDownloadLinks(String sourceBookId) async {
    final token = _newToken();
    final response = await _fetchWithGuard('/md5/$sourceBookId', token);
    final raw = parser.parseDetailPage(response.body);
    final links =
        mapper.mapDownloadLinks(raw, sourceBookId, response.instanceBaseUrl);

    // Fast download si une clé de don est configurée.
    final key = donationKey;
    if (key != null && key.isNotEmpty) {
      final fastUrl = await _resolveFastDownload(sourceBookId, key, token);
      if (fastUrl != null) {
        links.insert(
            0,
            DownloadLink(
                url: fastUrl, kind: DownloadLinkKind.premium, md5: sourceBookId));
      }
    }
    return links;
  }

  /// Interroge /dyn/api/fast_download.json (endpoint réel, clé requise).
  Future<Uri?> _resolveFastDownload(
      String md5, String key, CancellationToken token) async {
    try {
      final result = await _fetchWithGuard(
          Uri(path: '/dyn/api/fast_download.json', queryParameters: {
            'md5': md5,
            'key': key,
          }).toString(),
          token);
      final match =
          RegExp(r'"download_url"\s*:\s*"([^"]+)"').firstMatch(result.body);
      final url = match?.group(1)?.replaceAll(r'\/', '/');
      return (url == null || url.isEmpty) ? null : Uri.tryParse(url);
    } catch (_) {
      return null; // Clé invalide ou indisponible : fallback slow_download.
    }
  }

  // ------------------------------------------------------------------
  // Santé + ranking
  // ------------------------------------------------------------------

  @override
  Future<SourceHealth> healthCheck() async {
    final reports = await maintainInstances(force: true);
    if (reports.isEmpty) return const SourceHealth(reachable: false);
    final best = reports.first;
    return SourceHealth(
      reachable: best.available,
      latency: best.latency,
      challengeDetected: best.challengeDetected,
    );
  }

  /// Relance un health-check complet et retourne les rapports détaillés
  /// (disponibilité, latence, qualité, challenge, erreurs) par instance.
  Future<List<InstanceHealthReport>> rankInstances() =>
      maintainInstances(force: true);

  // ------------------------------------------------------------------
  // Annulation
  // ------------------------------------------------------------------

  /// Annule la requête réseau en cours (changement de recherche,
  /// fermeture d'écran...).
  void cancelActiveRequests() => _activeToken?.cancel();

  CancellationToken _newToken() {
    _activeToken?.cancel();
    final token = CancellationToken();
    _activeToken = token;
    return token;
  }

  // ------------------------------------------------------------------
  // Transport + CloudflareGuard
  // ------------------------------------------------------------------

  /// Exécute un GET avec gestion Cloudflare déléguée au guard :
  /// 1. tentative normale (le client bascule déjà entre instances)
  /// 2. si tous les miroirs sont challengés, le guard tente une
  ///    résolution (session cachée d'abord, solver/WebView en dernier)
  /// 3. si une session est obtenue, elle est injectée et on retente
  Future<RawHttpResponse> _fetchWithGuard(
      String path, CancellationToken token) async {
    // Session fraîche éventuelle : injectée avant même la 1re tentative.
    client.sessionHeaders = cloudflareGuard.sessionHeaders;

    try {
      return await client.get(path, token: token);
    } on AllInstancesFailedException catch (e) {
      if (!e.cloudflareOnAll && !e.errors.any((x) => x is InstanceChallengedException)) {
        rethrow; // Panne classique : le guard n'y peut rien.
      }
      token.throwIfCancelled();

      // Cloudflare : on demande au guard de résoudre. Le provider ne
      // sait pas COMMENT (WebView ou cache) — c'est le rôle du guard.
      final session =
          await cloudflareGuard.resolve(Uri.parse('${_bestInstanceUrl()}/'));
      if (session == null) rethrow;

      token.throwIfCancelled();
      client.sessionHeaders = cloudflareGuard.sessionHeaders;
      return client.get(path, token: token);
    }
  }

  String _bestInstanceUrl() {
    final active = client.instances.where((i) => i.enabled).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return active.isEmpty
        ? client.instances.first.baseUrl
        : active.first.baseUrl;
  }

  void close() {
    cancelActiveRequests();
    client.close();
  }
}
