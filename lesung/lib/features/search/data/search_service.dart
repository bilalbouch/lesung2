import '../domain/entities/search_result.dart';
import '../domain/entities/search_query.dart';
import '../domain/pipeline/fanout.dart';
import '../domain/pipeline/normalize.dart';
import '../domain/pipeline/deduplicate.dart';
import '../domain/pipeline/score.dart';
import '../../sources/domain/source_registry.dart';

/// Orchestrateur du pipeline de recherche.
///
/// Enchaîne les 4 étages (fan-out -> normalisation -> déduplication ->
/// scoring) en appelant des fonctions pures, chacune testable isolément.
/// Ne contient AUCUNE logique spécifique à une source.
class SearchService {
  final SourceRegistry registry;
  final ScoringConfig scoringConfig;
  final Duration perSourceTimeout;

  const SearchService(
    this.registry, {
    this.scoringConfig = const ScoringConfig(),
    this.perSourceTimeout = const Duration(seconds: 20),
  });

  /// Exécute le pipeline complet pour la page de [query].
  Future<SearchResult> run(SearchQuery query) async {
    final sources = registry.activeSources;
    if (sources.isEmpty) {
      return SearchResult(
        query: query,
        items: const [],
        sourceReports: const [],
        hasMore: false,
      );
    }

    // 1. FAN-OUT — toutes les sources en parallèle, erreurs isolées.
    final fanoutResults =
        await fanOutToSources(sources, query, perSourceTimeout: perSourceTimeout);

    // 2. NORMALISATION — livres bruts -> entités comparables.
    final rawBooks =
        fanoutResults.expand((r) => r.books).toList(growable: false);
    final normalized = normalizeBooks(rawBooks);

    // 3. DÉDUPLICATION — fusion ISBN + clé floue titre/auteur.
    final deduplicated = deduplicateBooks(normalized);

    // 4. SCORING — note 0..100, tri DE > FR > autres, puis pertinence.
    final scored = scoreAndSortBooks(
      deduplicated,
      query,
      config: scoringConfig,
    );

    return SearchResult(
      query: query,
      items: scored,
      sourceReports: fanoutResults.map((r) => r.report).toList(),
      hasMore: fanoutResults.any((r) => r.report.hasMore),
    );
  }
}
