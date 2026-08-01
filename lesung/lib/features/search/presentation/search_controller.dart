export '../domain/entities/search_query.dart' show BookFormat, SearchSort;

import 'dart:async';

import '../domain/entities/search_query.dart';
import '../domain/entities/search_result.dart';
import '../domain/search_repository.dart';

/// État de la recherche côté présentation.
enum SearchStatus { idle, loading, success, empty, error }

/// Contrôleur de recherche SANS dépendance Flutter.
///
/// Gère l'état (requête courante, résultats, pagination, debounce) et
/// sera branché sur Riverpod dans l'application. Testable en Dart pur.
class SearchController {
  final SearchRepository _repository;
  final Duration debounceDuration;

  SearchStatus status = SearchStatus.idle;
  SearchResult? result;
  Object? error;

  SearchQuery _query = const SearchQuery(text: '');
  Timer? _debounce;

  /// Séquence de requête : une réponse arrivant après une nouvelle
  /// recherche est ignorée (annulation logique des requêtes obsolètes).
  int _requestSeq = 0;

  /// Callback de notification (branché sur setState/Riverpod côté app).
  void Function()? onChanged;

  SearchController(this._repository,
      {this.debounceDuration = const Duration(milliseconds: 300)});

  SearchQuery get query => _query;
  List<SearchResultItem> get items => result?.items ?? const [];
  bool get hasMore => result?.hasMore ?? false;

  /// Lance une recherche avec debounce (frappe clavier).
  void onQueryChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(debounceDuration, () => search(text));
  }

  /// Lance une recherche immédiate (nouvelle requête -> page 1).
  Future<void> search(
    String text, {
    String? language,
    BookFormat? format,
    int? year,
    SearchSort sort = SearchSort.relevance,
  }) async {
    _query = SearchQuery(
      text: text.trim(),
      language: language,
      format: format,
      year: year,
      sort: sort,
    );
    if (_query.text.isEmpty) {
      status = SearchStatus.idle;
      result = null;
      _notify();
      return;
    }
    await _execute(_query);
  }

  /// Charge la page suivante et l'agrège aux résultats courants.
  Future<void> loadMore() async {
    if (result == null || !hasMore || status == SearchStatus.loading) return;
    final mySeq = ++_requestSeq;
    final previous = result!;
    final nextQuery = _query.copyWith(page: _query.page + 1);

    status = SearchStatus.loading;
    _notify();

    try {
      final next = await _repository.search(nextQuery);
      if (mySeq != _requestSeq) return; // nouvelle recherche entre-temps
      _query = nextQuery;
      // Agrégation : items précédents + nouveaux (dédupliqués par le
      // moteur page par page ; l'agrégation conserve l'ordre des scores).
      final mergedItems = [...previous.items, ...next.items];
      result = SearchResult(
        query: nextQuery,
        items: mergedItems,
        sourceReports: next.sourceReports,
        hasMore: next.hasMore,
      );
      status = mergedItems.isEmpty ? SearchStatus.empty : SearchStatus.success;
    } catch (e) {
      if (mySeq != _requestSeq) return;
      error = e;
      status = SearchStatus.error;
    }
    _notify();
  }

  Future<void> _execute(SearchQuery query) async {
    final mySeq = ++_requestSeq;
    status = SearchStatus.loading;
    error = null;
    _notify();
    try {
      final fresh = await _repository.search(query);
      if (mySeq != _requestSeq) return; // réponse obsolète : ignorée
      result = fresh;
      status = fresh.items.isEmpty ? SearchStatus.empty : SearchStatus.success;
    } catch (e) {
      if (mySeq != _requestSeq) return;
      error = e;
      status = SearchStatus.error;
    }
    _notify();
  }

  void _notify() => onChanged?.call();

  void dispose() => _debounce?.cancel();
}
