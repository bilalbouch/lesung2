import 'book.dart';
import 'search_query.dart';

/// Rapport d'exécution d'une source pour une recherche donnée.
class SourceReport {
  final String sourceId;

  /// Nombre de résultats bruts retournés par la source.
  final int rawCount;

  /// Durée de la requête.
  final Duration elapsed;

  /// Erreur éventuelle (la source est alors ignorée sans casser le reste).
  final Object? error;

  /// La source indique qu'une page suivante existe.
  final bool hasMore;

  const SourceReport({
    required this.sourceId,
    required this.rawCount,
    required this.elapsed,
    this.error,
    this.hasMore = false,
  });

  bool get isOk => error == null;
}

/// Un livre avec son score final et le détail de son calcul.
class SearchResultItem {
  final Book book;

  /// Score final 0..100.
  final double score;

  /// Détail par critère (ex. {'language': 35, 'relevance': 18.5}).
  /// Conservé pour la transparence et les tests.
  final Map<String, double> scoreBreakdown;

  const SearchResultItem({
    required this.book,
    required this.score,
    required this.scoreBreakdown,
  });
}

/// Résultat complet d'une recherche après pipeline.
class SearchResult {
  final SearchQuery query;

  /// Livres dédupliqués, triés par score décroissant.
  final List<SearchResultItem> items;

  /// Rapport par source interrogée (succès et échecs).
  final List<SourceReport> sourceReports;

  /// Au moins une source signale une page suivante disponible.
  final bool hasMore;

  const SearchResult({
    required this.query,
    required this.items,
    required this.sourceReports,
    required this.hasMore,
  });

  int get totalCount => items.length;

  /// Sources ayant répondu sans erreur.
  List<SourceReport> get okReports =>
      sourceReports.where((r) => r.isOk).toList();

  /// True si toutes les sources ont échoué.
  bool get allSourcesFailed =>
      sourceReports.isNotEmpty && okReports.isEmpty;
}
