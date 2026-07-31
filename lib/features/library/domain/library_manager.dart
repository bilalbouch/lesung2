import 'dart:async';
import 'dart:io';

import '../../../core/events/app_events.dart';
import '../../../core/events/event_bus.dart';
import 'collections_manager.dart';
import 'entities/library_book.dart';
import 'entities/reading_history.dart';
import 'entities/reading_stats.dart';
import 'favorites_manager.dart';
import 'history_manager.dart';
import 'library_repository.dart';
import 'reading_progress_manager.dart';
import 'statistics_manager.dart';

/// Orchestrateur de la bibliothèque — point d'entrée unique du domaine.
///
/// DÉCOUPLAGE TOTAL : la bibliothèque ne connaît ni Anna's Archive, ni
/// le DownloadManager, ni le Reader. Tout ce qui vient de l'extérieur
/// arrive par le [EventBus] (voir [listen]) ; tout ce qui est déclenché
/// depuis l'UI passe par les managers exposés ici, qui publient ensuite
/// leurs propres événements pour les observateurs (stats, UI...).
///
/// Sous-systèmes exposés : [favorites], [collections], [history],
/// [progress], [statistics].
class LibraryManager {
  final LibraryRepository repository;
  final EventBus eventBus;

  late final FavoritesManager favorites =
      FavoritesManager(repository: repository, eventBus: eventBus);
  late final CollectionsManager collections =
      CollectionsManager(repository: repository, eventBus: eventBus);
  late final HistoryManager history =
      HistoryManager(repository: repository, eventBus: eventBus);
  late final ReadingProgressManager progress =
      ReadingProgressManager(repository: repository, eventBus: eventBus);
  late final StatisticsManager statistics =
      StatisticsManager(repository: repository);

  final List<StreamSubscription<Object>> _subscriptions = [];

  LibraryManager({required this.repository, required this.eventBus});

  // ------------------------------------------------------------------
  // Écoute des événements externes (seule voie d'entrée des autres
  // moteurs dans la bibliothèque).
  // ------------------------------------------------------------------

  /// Abonne la bibliothèque au bus. À appeler une fois au démarrage.
  void listen() {
    _subscriptions
      ..add(eventBus.on<DownloadFinishedEvent>().listen(_onDownloadFinished))
      ..add(eventBus.on<DownloadRemovedEvent>().listen(_onDownloadRemoved));
  }

  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }

  /// Un téléchargement vérifié entre dans la bibliothèque.
  Future<void> _onDownloadFinished(DownloadFinishedEvent event) async {
    final existing = await repository.bookById(event.bookId);
    final now = DateTime.now();
    final book = existing == null
        ? LibraryBook(
            id: event.bookId,
            title: event.title,
            author: event.author,
            coverUrl: event.coverUrl,
            language: event.language,
            format: event.format,
            downloaded: true,
            filePath: event.filePath,
            fileSizeBytes: event.fileSizeBytes,
            addedAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            downloaded: true,
            filePath: event.filePath,
            fileSizeBytes: event.fileSizeBytes,
            fileMissing: false,
            updatedAt: now,
          );
    await repository.saveBook(book);
    await repository.saveDownloadRecord(DownloadRecord(
      bookId: event.bookId,
      filePath: event.filePath,
      fileSizeBytes: event.fileSizeBytes,
      md5Verified: event.md5Verified,
      completedAt: now,
    ));
  }

  /// Un fichier téléchargé a été retiré : le livre reste en bibliothèque
  /// (favori, collections, progression), mais n'est plus « téléchargé ».
  Future<void> _onDownloadRemoved(DownloadRemovedEvent event) async {
    final book = await repository.bookById(event.bookId);
    if (book == null) return;
    await repository.saveBook(book.copyWith(
      downloaded: false,
      clearFilePath: true,
      fileMissing: false,
      updatedAt: DateTime.now(),
    ));
    await repository.deleteDownloadRecord(event.bookId);
  }

  // ------------------------------------------------------------------
  // Écritures déclenchées depuis l'UI
  // ------------------------------------------------------------------

  /// Ajoute un livre à la bibliothèque sans fichier (ex. avant de le
  /// marquer favori depuis la recherche). Idempotent : un livre existant
  /// est complété avec les métadonnées non nulles fournies.
  Future<LibraryBook> addBook(LibraryBook book) async {
    final existing = await repository.bookById(book.id);
    if (existing != null) return existing;
    await repository.saveBook(book);
    eventBus.emit(BookAddedEvent(book.id));
    return book;
  }

  /// Retire un livre de la bibliothèque (cascade sur favoris,
  /// collections, progression, historique, trace de téléchargement).
  /// [deleteFile] supprime aussi le fichier du disque.
  Future<void> removeBook(String bookId, {bool deleteFile = false}) async {
    final book = await repository.bookById(bookId);
    if (book == null) return;
    if (deleteFile && book.filePath != null) {
      try {
        await File(book.filePath!).delete();
      } catch (_) {
        // Fichier déjà absent : la synchronisation le gèrera sinon.
      }
    }
    await repository.deleteBook(bookId);
    eventBus.emit(BookRemovedEvent(bookId, deleteFile: deleteFile));
  }

  /// Marque l'ouverture d'un livre (met à jour lastOpenedAt) et démarre
  /// une session de lecture.
  Future<void> openReading(String bookId) async {
    final book = await repository.bookById(bookId);
    if (book == null) {
      throw StateError('Livre inconnu de la bibliothèque : $bookId');
    }
    await repository
        .saveBook(book.copyWith(lastOpenedAt: DateTime.now()));
    await history.openSession(bookId);
  }

  /// Clôture la session de lecture en cours d'un livre.
  Future<int?> closeReading(String bookId) => history.closeSession(bookId);

  // ------------------------------------------------------------------
  // Requêtes de lecture (vues de la bibliothèque)
  // ------------------------------------------------------------------

  Future<LibraryBook?> bookById(String bookId) => repository.bookById(bookId);

  Future<List<LibraryBook>> allBooks() => repository.allBooks();

  /// Livres récemment ajoutés (ajout décroissant).
  Future<List<LibraryBook>> recentBooks({int limit = 20}) async {
    final books = await repository.allBooks();
    books.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return books.take(limit).toList();
  }

  /// Continuer la lecture : progression 0 % < p < 100 %, récent d'abord.
  Future<List<LibraryBook>> continueReading({int limit = 20}) async {
    final progresses = await repository.allReadingProgress();
    final result = <LibraryBook>[];
    for (final p in progresses) {
      if (p.progress <= 0 || p.progress >= 1) continue;
      final book = await repository.bookById(p.bookId);
      if (book != null) result.add(book);
      if (result.length >= limit) break;
    }
    return result;
  }

  /// Livres en cours (identique à continueReading, sans limite).
  Future<List<LibraryBook>> inProgressBooks() => continueReading(limit: 1 << 30);

  Future<List<LibraryBook>> finishedBooks() async =>
      (await repository.allBooks())
          .where((b) => b.finishedAt != null)
          .toList()
        ..sort((a, b) => b.finishedAt!.compareTo(a.finishedAt!));

  Future<List<LibraryBook>> downloadedBooks() async =>
      (await repository.allBooks()).where((b) => b.downloaded).toList();

  /// Livres en bibliothèque sans fichier (favoris/collections non
  /// téléchargés, ou fichiers détectés manquants).
  Future<List<LibraryBook>> notDownloadedBooks() async =>
      (await repository.allBooks()).where((b) => !b.downloaded).toList();

  /// Statistiques complètes (délégué au StatisticsManager).
  Future<ReadingStats> stats() => statistics.compute();
}
