import 'dart:async';

import '../domain/reader_annotations.dart';
import '../domain/reader_bookmarks.dart';
import '../domain/reader_contract.dart';
import '../domain/reader_manager.dart';
import '../domain/reader_search.dart';
import '../domain/reader_settings.dart';

/// État de la vue Reader.
enum ReaderStatus { idle, loading, ready, error }

/// État immuable exposé à l'UI (converti en providers Riverpod dans
/// l'application — ici pur Dart, testable).
class ReaderViewState {
  final ReaderStatus status;
  final String? errorMessage;
  final String? bookId;
  final String? title;
  final String? author;
  final ReaderPosition? position;
  final List<ReaderTocEntry> tableOfContents;
  final ReaderSettings settings;
  final List<ReaderBookmark> bookmarks;
  final List<ReaderAnnotation> annotations;
  final List<ReaderSearchHit> searchResults;
  final bool searching;
  final int searchDoneUnits;
  final int searchTotalUnits;
  final bool canGoBack;

  const ReaderViewState({
    this.status = ReaderStatus.idle,
    this.errorMessage,
    this.bookId,
    this.title,
    this.author,
    this.position,
    this.tableOfContents = const [],
    this.settings = const ReaderSettings(),
    this.bookmarks = const [],
    this.annotations = const [],
    this.searchResults = const [],
    this.searching = false,
    this.searchDoneUnits = 0,
    this.searchTotalUnits = 0,
    this.canGoBack = false,
  });

  ReaderViewState copyWith({
    ReaderStatus? status,
    String? errorMessage,
    bool clearError = false,
    String? bookId,
    String? title,
    String? author,
    ReaderPosition? position,
    List<ReaderTocEntry>? tableOfContents,
    ReaderSettings? settings,
    List<ReaderBookmark>? bookmarks,
    List<ReaderAnnotation>? annotations,
    List<ReaderSearchHit>? searchResults,
    bool? searching,
    int? searchDoneUnits,
    int? searchTotalUnits,
    bool? canGoBack,
  }) =>
      ReaderViewState(
        status: status ?? this.status,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        bookId: bookId ?? this.bookId,
        title: title ?? this.title,
        author: author ?? this.author,
        position: position ?? this.position,
        tableOfContents: tableOfContents ?? this.tableOfContents,
        settings: settings ?? this.settings,
        bookmarks: bookmarks ?? this.bookmarks,
        annotations: annotations ?? this.annotations,
        searchResults: searchResults ?? this.searchResults,
        searching: searching ?? this.searching,
        searchDoneUnits: searchDoneUnits ?? this.searchDoneUnits,
        searchTotalUnits: searchTotalUnits ?? this.searchTotalUnits,
        canGoBack: canGoBack ?? this.canGoBack,
      );
}

/// Contrôleur de présentation du Reader (pur Dart).
///
/// Délègue tout au [ReaderManager] ; maintient un [ReaderViewState]
/// immuable diffusé sur [stream]. Annule les recherches périmées quand
/// une nouvelle est lancée.
class ReaderController {
  final ReaderManager manager;
  final String Function() idGenerator;

  final _stateController = StreamController<ReaderViewState>.broadcast();
  ReaderViewState _state = const ReaderViewState();

  int _searchSeq = 0;
  bool _searchCancelled = false;

  ReaderController({
    required this.manager,
    String Function()? idGenerator,
  }) : idGenerator = idGenerator ?? _defaultId {
    manager.onPositionChanged = (position) {
      _state = _state.copyWith(
          position: position, canGoBack: manager.navigation.canGoBack);
      _emit();
    };
  }

  static String _defaultId() =>
      'r_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Stream<ReaderViewState> get stream => _stateController.stream;
  ReaderViewState get state => _state;

  void _emit() {
    if (!_stateController.isClosed) _stateController.add(_state);
  }

  Future<void> dispose() async {
    await manager.dispose();
    await _stateController.close();
  }

  // ------------------------------------------------------------------
  // Cycle de vie du livre
  // ------------------------------------------------------------------

  Future<void> init() async {
    final settings = await manager.loadSettings();
    _state = _state.copyWith(settings: settings);
    _emit();
  }

  /// Ouvre un fichier local. L'état passe par loading -> ready/error.
  Future<void> openBook(String filePath) async {
    _state = _state.copyWith(
        status: ReaderStatus.loading, clearError: true, searchResults: []);
    _emit();
    try {
      await manager.open(filePath);
      final reader = manager.reader!;
      _state = _state.copyWith(
        status: ReaderStatus.ready,
        bookId: manager.bookId,
        title: reader.title,
        author: reader.author,
        position: manager.position,
        tableOfContents: reader.tableOfContents,
        bookmarks: manager.bookmarks.all,
        annotations: manager.annotations.all,
        canGoBack: manager.navigation.canGoBack,
      );
    } catch (e) {
      _state = _state.copyWith(
          status: ReaderStatus.error, errorMessage: e.toString());
    }
    _emit();
  }

  Future<void> closeBook() async {
    await manager.close();
    _state = ReaderViewState(settings: _state.settings);
    _emit();
  }

  // ------------------------------------------------------------------
  // Navigation
  // ------------------------------------------------------------------

  Future<ReaderContent> loadUnit(int unitIndex) => manager.loadUnit(unitIndex);

  void goToUnit(int unitIndex, {double offsetRatio = 0}) =>
      manager.goToUnit(unitIndex, offsetRatio: offsetRatio);

  void goToTocEntry(ReaderTocEntry entry) {
    final index = entry.unitIndex;
    if (index != null) manager.goToUnit(index);
  }

  void nextChapter() => manager.goToNextChapter();

  void previousChapter() => manager.goToPreviousChapter();

  void goBack() => manager.goBack();

  Future<void> returnToLastPosition() => manager.returnToLastPosition();

  /// Sauvegarde explicite (pause de l'app, changement de page...).
  Future<void> saveNow() => manager.saveNow();

  // ------------------------------------------------------------------
  // Recherche dans le livre
  // ------------------------------------------------------------------

  Future<void> searchInBook(String query) async {
    final mySeq = ++_searchSeq;
    _searchCancelled = false;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _state = _state.copyWith(searchResults: [], searching: false);
      _emit();
      return;
    }
    _state = _state.copyWith(
        searching: true, searchResults: [], searchDoneUnits: 0);
    _emit();

    final results = await manager.search.search(
      trimmed,
      isCancelled: () => _searchCancelled || mySeq != _searchSeq,
      onProgress: (done, total) {
        if (mySeq != _searchSeq) return;
        _state = _state.copyWith(
            searchDoneUnits: done, searchTotalUnits: total);
        _emit();
      },
    );
    if (mySeq != _searchSeq) return; // une recherche plus récente a gagné
    _state = _state.copyWith(searchResults: results, searching: false);
    _emit();
  }

  void cancelSearch() {
    _searchCancelled = true;
    _state = _state.copyWith(searching: false);
    _emit();
  }

  void goToSearchHit(ReaderSearchHit hit) =>
      manager.goToUnit(hit.unitIndex);

  // ------------------------------------------------------------------
  // Signets et annotations
  // ------------------------------------------------------------------

  Future<void> toggleBookmarkAtCurrentPosition() async {
    final position = manager.position;
    final bookId = manager.bookId;
    if (position == null || bookId == null) return;
    await manager.bookmarks.toggle(
      id: idGenerator(),
      bookId: bookId,
      locator: position.locator,
      unitIndex: position.unitIndex,
      chapterTitle: position.chapterTitle,
    );
    _state = _state.copyWith(bookmarks: manager.bookmarks.all);
    _emit();
  }

  Future<void> removeBookmark(String bookmarkId) async {
    await manager.bookmarks.remove(bookmarkId);
    _state = _state.copyWith(bookmarks: manager.bookmarks.all);
    _emit();
  }

  Future<void> addAnnotation({
    required String selectedText,
    String note = '',
    int color = 0xFFFFD966,
  }) async {
    final position = manager.position;
    final bookId = manager.bookId;
    if (position == null || bookId == null) return;
    await manager.annotations.add(
      id: idGenerator(),
      bookId: bookId,
      locator: position.locator,
      unitIndex: position.unitIndex,
      selectedText: selectedText,
      note: note,
      color: color,
    );
    _state = _state.copyWith(annotations: manager.annotations.all);
    _emit();
  }

  Future<void> updateAnnotationNote(String annotationId, String note) async {
    await manager.annotations.updateNote(annotationId, note);
    _state = _state.copyWith(annotations: manager.annotations.all);
    _emit();
  }

  Future<void> removeAnnotation(String annotationId) async {
    await manager.annotations.remove(annotationId);
    _state = _state.copyWith(annotations: manager.annotations.all);
    _emit();
  }

  // ------------------------------------------------------------------
  // Réglages
  // ------------------------------------------------------------------

  Future<void> updateSettings(
      ReaderSettings Function(ReaderSettings) update) async {
    final updated = update(_state.settings);
    await manager.saveSettings(updated);
    _state = _state.copyWith(settings: updated);
    _emit();
  }
}
