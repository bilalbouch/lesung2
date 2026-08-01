import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesung/features/search/domain/entities/search_query.dart';
import 'package:lesung/features/search/domain/entities/search_result.dart';
import 'package:lesung/features/search/presentation/search_controller.dart'
    as engine;

import '../../app/engine.dart';

/// États de la recherche côté UI (charte : Idle / Loading / Success /
/// Error — « empty » distingue un succès sans résultat).
enum SearchUiStatus { idle, loading, success, empty, error }

/// Instantané immuable de la recherche pour les widgets.
class SearchUiState {
  final SearchUiStatus status;
  final List<SearchResultItem> items;
  final bool hasMore;
  final String? errorMessage;

  const SearchUiState({
    required this.status,
    this.items = const [],
    this.hasMore = false,
    this.errorMessage,
  });

  /// Traduit l'état du contrôleur moteur (pur Dart, testé) en état UI.
  factory SearchUiState.from(engine.SearchController controller) {
    return SearchUiState(
      status: switch (controller.status) {
        engine.SearchStatus.idle => SearchUiStatus.idle,
        engine.SearchStatus.loading => SearchUiStatus.loading,
        engine.SearchStatus.success => SearchUiStatus.success,
        engine.SearchStatus.empty => SearchUiStatus.empty,
        engine.SearchStatus.error => SearchUiStatus.error,
      },
      items: controller.items,
      hasMore: controller.hasMore,
      errorMessage: controller.error?.toString(),
    );
  }
}

/// SearchController Riverpod (AsyncNotifier).
///
/// PONT D'ÉTAT UNIQUEMENT : toute la logique métier (debounce 300 ms,
/// annulation des requêtes obsolètes, pagination, fan-out) reste dans
/// le contrôleur pur Dart du moteur — testé à 100 %. Ce notifier se
/// contente de re-publier chaque changement comme [AsyncValue].
class SearchController extends AsyncNotifier<SearchUiState> {
  @override
  Future<SearchUiState> build() async {
    final controller = ref.watch(engineProvider).search;
    controller.onChanged = () {
      state = AsyncData(SearchUiState.from(controller));
    };
    ref.onDispose(() => controller.onChanged = null);
    return SearchUiState.from(controller);
  }

  engine.SearchController get _engine => ref.read(engineProvider).search;

  /// Frappe clavier — debounce 300 ms assuré par le moteur.
  void onQueryChanged(String text) => _engine.onQueryChanged(text);

  /// Recherche immédiate (soumission, changement de filtre).
  Future<void> search(String text, {BookFormat? format}) =>
      _engine.search(text, format: format);

  /// Page suivante (agrégée par le moteur).
  Future<void> loadMore() => _engine.loadMore();
}

/// Provider du contrôleur de recherche de l'application.
final searchControllerProvider =
    AsyncNotifierProvider<SearchController, SearchUiState>(
        SearchController.new);
