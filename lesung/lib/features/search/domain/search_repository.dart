import 'entities/search_query.dart';
import 'entities/search_result.dart';

/// Contrat du repository de recherche (port côté domain).
///
/// L'implémentation vit dans data/. Elle communique avec les sources
/// EXCLUSIVEMENT via l'interface BookSource : elle ne connaît jamais
/// Anna's Archive, WeLib ou toute autre source concrète.
abstract class SearchRepository {
  /// Exécute le pipeline complet : fan-out -> normalisation ->
  /// déduplication -> scoring, pour la page demandée dans [query].
  Future<SearchResult> search(SearchQuery query);
}
