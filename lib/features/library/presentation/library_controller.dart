import 'dart:async';

import '../../../core/events/app_events.dart';
import '../../../core/events/event_bus.dart';
import '../domain/entities/collection.dart';
import '../domain/entities/library_book.dart';
import '../domain/entities/reading_history.dart';
import '../domain/entities/reading_stats.dart';
import '../domain/library_manager.dart';

/// Contrôleur de présentation de la bibliothèque (pur Dart, sans
/// dépendance Flutter — le binding Riverpod viendra avec l'application).
///
/// Expose un [state] immuable rafraîchi à chaque événement pertinent du
/// bus, et des actions fines qui délèguent au [LibraryManager].
class LibraryController {
  final LibraryManager manager;
  final EventBus eventBus;

  final _stateController = StreamController<LibraryState>.broadcast();
  final List<StreamSubscription<Object>> _subscriptions = [];

  LibraryState _state = const LibraryState();

  LibraryController({required this.manager, required this.eventBus});

  Stream<LibraryState> get stream => _stateController.stream;
  LibraryState get state => _state;

  /// Abonne le contrôleur aux événements et charge l'état initial.
  Future<void> init() async {
    _subscriptions.add(eventBus.on<AppEvent>().listen((_) => refresh()));
    await refresh();
  }

  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _stateController.close();
  }

  /// Recharge l'état complet depuis le domaine.
  Future<void> refresh() async {
    final results = await Future.wait([
      manager.recentBooks(),
      manager.continueReading(),
      manager.downloadedBooks(),
      manager.notDownloadedBooks(),
      manager.finishedBooks(),
      manager.favorites.favorites(),
      manager.collections.collections(),
      manager.history.history(),
      manager.stats(),
    ]);
    _state = LibraryState(
      recentBooks: results[0] as List<LibraryBook>,
      continueReading: results[1] as List<LibraryBook>,
      downloadedBooks: results[2] as List<LibraryBook>,
      notDownloadedBooks: results[3] as List<LibraryBook>,
      finishedBooks: results[4] as List<LibraryBook>,
      favorites: results[5] as List<LibraryBook>,
      collections: results[6] as List<Collection>,
      history: results[7] as List<ReadingHistoryEntry>,
      stats: results[8] as ReadingStats,
      loaded: true,
    );
    if (!_stateController.isClosed) _stateController.add(_state);
  }

  // ---------- actions déléguées ----------

  Future<void> toggleFavorite(String bookId) =>
      manager.favorites.toggle(bookId);

  Future<Collection> createCollection(String name) =>
      manager.collections.create(name);

  Future<void> addToCollection(String collectionId, String bookId) =>
      manager.collections.addBook(collectionId, bookId);

  Future<void> removeFromCollection(String collectionId, String bookId) =>
      manager.collections.removeBook(collectionId, bookId);

  Future<void> removeBook(String bookId, {bool deleteFile = false}) =>
      manager.removeBook(bookId, deleteFile: deleteFile);

  Future<void> openReading(String bookId) => manager.openReading(bookId);

  Future<void> closeReading(String bookId) => manager.closeReading(bookId);

  Future<void> updateProgress(
          String bookId, String locator, double progress) =>
      manager.progress.updateProgress(bookId, locator, progress);
}

/// État immuable de la vue bibliothèque.
class LibraryState {
  final List<LibraryBook> recentBooks;
  final List<LibraryBook> continueReading;
  final List<LibraryBook> downloadedBooks;
  final List<LibraryBook> notDownloadedBooks;
  final List<LibraryBook> finishedBooks;
  final List<LibraryBook> favorites;
  final List<Collection> collections;
  final List<ReadingHistoryEntry> history;
  final ReadingStats? stats;
  final bool loaded;

  const LibraryState({
    this.recentBooks = const [],
    this.continueReading = const [],
    this.downloadedBooks = const [],
    this.notDownloadedBooks = const [],
    this.finishedBooks = const [],
    this.favorites = const [],
    this.collections = const [],
    this.history = const [],
    this.stats,
    this.loaded = false,
  });
}
