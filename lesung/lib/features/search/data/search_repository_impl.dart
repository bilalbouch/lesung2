import '../domain/entities/search_query.dart';
import '../domain/entities/search_result.dart';
import '../domain/search_repository.dart';
import 'search_cache.dart';
import 'search_service.dart';

/// Implémentation du repository : simple façade sur [SearchService].
///
/// Point d'entrée unique du moteur pour le reste de l'application.
/// Ne connaît aucune source concrète.
class SearchRepositoryImpl implements SearchRepository {
  final SearchService _service;
  final SearchCache? _cache;

  const SearchRepositoryImpl(this._service, {SearchCache? cache})
      : _cache = cache;

  @override
  Future<SearchResult> search(SearchQuery query) async {
    if (query.text.trim().isEmpty) {
      return SearchResult(
        query: query,
        items: const [],
        sourceReports: const [],
        hasMore: false,
      );
    }
    final cache = _cache;
    if (cache != null) {
      final cached = cache.get(query);
      if (cached != null) return cached; // hit : aucun accès réseau
    }
    final result = await _service.run(query);
    cache?.put(query, result);
    return result;
  }
}
