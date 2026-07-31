import '../../search/domain/entities/book.dart';
import '../../search/domain/entities/book_details.dart';
import '../../search/domain/entities/download_link.dart';
import '../../search/domain/entities/search_query.dart';

/// Page de résultats retournée par une source.
class PagedResult<T> {
  final List<T> items;

  /// La source signale qu'une page suivante existe.
  final bool hasMore;

  const PagedResult({required this.items, required this.hasMore});
}

/// Métadonnées descriptives d'une source.
class SourceMeta {
  /// Identifiant stable unique (ex. 'annas_archive', 'open_library').
  final String id;

  /// Nom affichable.
  final String displayName;

  /// La source supporte la pagination native.
  final bool supportsPagination;

  const SourceMeta({
    required this.id,
    required this.displayName,
    this.supportsPagination = false,
  });
}

/// État de santé d'une source, mesuré par une requête fonctionnelle réelle.
class SourceHealth {
  final bool reachable;
  final Duration? latency;

  /// La source répond mais présente un challenge anti-bot (Cloudflare...).
  final bool challengeDetected;

  const SourceHealth({
    required this.reachable,
    this.latency,
    this.challengeDetected = false,
  });

  /// Note de fiabilité 0..1 injectée dans le scoring.
  double get reliabilityScore {
    if (!reachable) return 0;
    if (challengeDetected) return 0.3;
    final ms = latency?.inMilliseconds ?? 9999;
    if (ms < 1500) return 1;
    if (ms < 4000) return 0.7;
    return 0.4;
  }
}

/// Contrat unique que toute source de livres doit implémenter.
///
/// Le moteur (SearchService/SearchRepository) ne connaît QUE cette
/// interface : ajouter WeLib, Open Library ou Gutenberg ne modifie
/// aucune ligne du moteur.
abstract class BookSource {
  SourceMeta get meta;

  /// Recherche paginée. Les filtres non supportés par la source sont
  /// ignorés côté source et appliqués côté moteur.
  Future<PagedResult<Book>> search(SearchQuery query);

  /// Détails complets d'un livre identifié chez cette source.
  Future<BookDetails> details(String sourceBookId);

  /// Résout les liens de téléchargement d'un livre.
  Future<List<DownloadLink>> resolveDownloadLinks(String sourceBookId);

  /// Vérification de santé FONCTIONNELLE (vraie requête de recherche),
  /// pas un simple ping HTTP.
  Future<SourceHealth> healthCheck();
}
