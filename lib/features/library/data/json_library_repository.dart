import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/entities/collection.dart';
import '../domain/entities/favorite.dart';
import '../domain/entities/library_book.dart';
import '../domain/entities/reading_history.dart';
import '../domain/entities/reading_progress.dart';
import '../domain/entities/reading_stats.dart';
import '../domain/library_repository.dart';

/// Implémentation JSON du [LibraryRepository], en pur Dart.
///
/// Chaque agrégat est persisté dans un fichier `<name>.json` sous
/// [directory]. Les écritures sont atomiques (fichier temporaire + renommage)
/// et les données sont gardées en mémoire après le premier chargement.
///
/// Cette implémentation sert le moteur et les tests ; l'application Flutter
/// utilisera une implémentation sqflite suivant `schema/library_schema.dart`,
/// sans qu'aucun composant du domaine ne change.
class JsonLibraryRepository implements LibraryRepository {
  final Directory directory;

  Map<String, LibraryBook>? _books;
  List<Favorite>? _favorites;
  Map<String, Collection>? _collections;
  List<CollectionBook>? _collectionBooks;
  Map<String, ReadingProgress>? _progress;
  List<ReadingHistoryEntry>? _history;
  Map<String, DownloadRecord>? _downloads;
  StatisticsCounters? _counters;
  int _nextHistoryId = 1;

  /// Sérialise toutes les écritures disque : les handlers d'événements
  /// peuvent s'exécuter en parallèle, deux fichiers .tmp simultanés ne
  /// doivent jamais entrer en conflit.
  Future<void> _writeChain = Future<void>.value();

  Future<T> _enqueueWrite<T>(Future<T> Function() operation) {
    final result = _writeChain.then((_) => operation());
    _writeChain = result.then((_) {}, onError: (_) {});
    return result;
  }

  JsonLibraryRepository(this.directory);

  // ---------- helpers génériques ----------

  File _file(String name) => File('${directory.path}/$name.json');

  Future<void> _ensureDirectory() async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  List<Map<String, dynamic>> _readList(File file) {
    if (!file.existsSync()) return const [];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
      // Fichier corrompu : on le supprime pour repartir proprement.
      file.deleteSync();
    } catch (_) {
      try {
        file.deleteSync();
      } catch (_) {}
    }
    return const [];
  }

  Future<void> _writeList(String name, List<Map<String, dynamic>> rows) {
    return _enqueueWrite(() async {
      await _ensureDirectory();
      final target = _file(name);
      final tmp = File('${target.path}.tmp');
      await tmp.writeAsString(jsonEncode(rows));
      await tmp.rename(target.path);
    });
  }

  Map<String, T> _loadMap<T>(
    String name,
    T Function(Map<String, dynamic>) decode,
    String Function(T) keyOf,
  ) {
    final result = <String, T>{};
    for (final row in _readList(_file(name))) {
      final value = decode(row);
      result[keyOf(value)] = value;
    }
    return result;
  }

  // ---------- books ----------

  Map<String, LibraryBook> get _booksMap =>
      _books ??= _loadMap('books', LibraryBook.fromJson, (b) => b.id);

  @override
  Future<void> saveBook(LibraryBook book) async {
    _booksMap[book.id] = book;
    await _writeList(
        'books', _booksMap.values.map((b) => b.toJson()).toList());
  }

  @override
  Future<LibraryBook?> bookById(String bookId) async => _booksMap[bookId];

  @override
  Future<List<LibraryBook>> allBooks() async {
    final list = _booksMap.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<void> deleteBook(String bookId) async {
    _booksMap.remove(bookId);
    await _writeList(
        'books', _booksMap.values.map((b) => b.toJson()).toList());
    // Données liées : suppression en cascade, comme le schéma SQL.
    await removeFavorite(bookId);
    _collectionBooksList.removeWhere((l) => l.bookId == bookId);
    await _writeCollectionBooks();
    if (_progressMap.containsKey(bookId)) {
      _progressMap.remove(bookId);
      await _writeProgress();
    }
    if (_historyList.any((e) => e.bookId == bookId)) {
      _historyList.removeWhere((e) => e.bookId == bookId);
      await _writeHistory();
    }
    await deleteDownloadRecord(bookId);
  }

  // ---------- favorites ----------

  List<Favorite> get _favoritesList =>
      _favorites ??= _readList(_file('favorites'))
          .map(Favorite.fromJson)
          .toList();

  Future<void> _writeFavorites() => _writeList(
      'favorites', _favoritesList.map((f) => f.toJson()).toList());

  @override
  Future<void> addFavorite(Favorite favorite) async {
    _favoritesList.removeWhere((f) => f.bookId == favorite.bookId);
    _favoritesList.add(favorite);
    await _writeFavorites();
  }

  @override
  Future<void> removeFavorite(String bookId) async {
    final before = _favoritesList.length;
    _favoritesList.removeWhere((f) => f.bookId == bookId);
    if (_favoritesList.length != before) await _writeFavorites();
  }

  @override
  Future<List<String>> favoriteBookIds() async {
    final sorted = [..._favoritesList]
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sorted.map((f) => f.bookId).toList();
  }

  @override
  Future<bool> isFavorite(String bookId) async =>
      _favoritesList.any((f) => f.bookId == bookId);

  // ---------- collections ----------

  Map<String, Collection> get _collectionsMap =>
      _collections ??= _loadMap('collections', Collection.fromJson, (c) => c.id);

  List<CollectionBook> get _collectionBooksList =>
      _collectionBooks ??= _readList(_file('collection_books'))
          .map(CollectionBook.fromJson)
          .toList();

  Future<void> _writeCollectionBooks() => _writeList('collection_books',
      _collectionBooksList.map((l) => l.toJson()).toList());

  @override
  Future<void> saveCollection(Collection collection) async {
    _collectionsMap[collection.id] = collection;
    await _writeList('collections',
        _collectionsMap.values.map((c) => c.toJson()).toList());
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    _collectionsMap.remove(collectionId);
    await _writeList('collections',
        _collectionsMap.values.map((c) => c.toJson()).toList());
    _collectionBooksList.removeWhere((l) => l.collectionId == collectionId);
    await _writeCollectionBooks();
  }

  @override
  Future<Collection?> collectionById(String collectionId) async =>
      _collectionsMap[collectionId];

  @override
  Future<List<Collection>> allCollections() async {
    final list = _collectionsMap.values.toList()
      ..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });
    return list;
  }

  @override
  Future<void> addBookToCollection(CollectionBook link) async {
    _collectionBooksList.removeWhere((l) =>
        l.collectionId == link.collectionId && l.bookId == link.bookId);
    _collectionBooksList.add(link);
    await _writeCollectionBooks();
  }

  @override
  Future<void> removeBookFromCollection(
      String collectionId, String bookId) async {
    final before = _collectionBooksList.length;
    _collectionBooksList.removeWhere(
        (l) => l.collectionId == collectionId && l.bookId == bookId);
    if (_collectionBooksList.length != before) await _writeCollectionBooks();
  }

  @override
  Future<List<CollectionBook>> collectionBooks(String collectionId) async {
    final list = _collectionBooksList
        .where((l) => l.collectionId == collectionId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return list;
  }

  @override
  Future<List<String>> collectionIdsForBook(String bookId) async =>
      _collectionBooksList
          .where((l) => l.bookId == bookId)
          .map((l) => l.collectionId)
          .toList();

  // ---------- reading_progress ----------

  Map<String, ReadingProgress> get _progressMap => _progress ??=
      _loadMap('reading_progress', ReadingProgress.fromJson, (p) => p.bookId);

  Future<void> _writeProgress() => _writeList('reading_progress',
      _progressMap.values.map((p) => p.toJson()).toList());

  @override
  Future<void> saveReadingProgress(ReadingProgress progress) async {
    _progressMap[progress.bookId] = progress;
    await _writeProgress();
  }

  @override
  Future<ReadingProgress?> readingProgressFor(String bookId) async =>
      _progressMap[bookId];

  @override
  Future<List<ReadingProgress>> allReadingProgress() async {
    final list = _progressMap.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<void> deleteReadingProgress(String bookId) async {
    if (_progressMap.remove(bookId) != null) await _writeProgress();
  }

  // ---------- history ----------

  List<ReadingHistoryEntry> get _historyList {
    if (_history == null) {
      _history = _readList(_file('history'))
          .map(ReadingHistoryEntry.fromJson)
          .toList();
      for (final e in _history!) {
        final id = e.id ?? 0;
        if (id >= _nextHistoryId) _nextHistoryId = id + 1;
      }
    }
    return _history!;
  }

  Future<void> _writeHistory() => _writeList(
      'history', _historyList.map((e) => e.toJson()).toList());

  @override
  Future<ReadingHistoryEntry> addHistoryEntry(
      ReadingHistoryEntry entry) async {
    // Force le chargement paresseux AVANT d'attribuer l'id : c'est le
    // getter qui calcule _nextHistoryId d'après les entrées existantes.
    final list = _historyList;
    final withId = ReadingHistoryEntry(
      id: _nextHistoryId++,
      bookId: entry.bookId,
      openedAt: entry.openedAt,
      closedAt: entry.closedAt,
      durationSeconds: entry.durationSeconds,
    );
    list.add(withId);
    await _writeHistory();
    return withId;
  }

  @override
  Future<void> updateHistoryEntry(ReadingHistoryEntry entry) async {
    final index = _historyList.indexWhere((e) => e.id == entry.id);
    if (index == -1) {
      _historyList.add(entry);
    } else {
      _historyList[index] = entry;
    }
    await _writeHistory();
  }

  @override
  Future<List<ReadingHistoryEntry>> history() async {
    final list = [..._historyList]
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return list;
  }

  @override
  Future<ReadingHistoryEntry?> openSessionFor(String bookId) async {
    ReadingHistoryEntry? latest;
    for (final e in _historyList) {
      if (e.bookId == bookId && e.closedAt == null) {
        if (latest == null || e.openedAt.isAfter(latest.openedAt)) {
          latest = e;
        }
      }
    }
    return latest;
  }

  // ---------- downloads ----------

  Map<String, DownloadRecord> get _downloadsMap => _downloads ??=
      _loadMap('downloads', DownloadRecord.fromJson, (d) => d.bookId);

  @override
  Future<void> saveDownloadRecord(DownloadRecord record) async {
    _downloadsMap[record.bookId] = record;
    await _writeList('downloads',
        _downloadsMap.values.map((d) => d.toJson()).toList());
  }

  @override
  Future<DownloadRecord?> downloadRecordFor(String bookId) async =>
      _downloadsMap[bookId];

  @override
  Future<void> deleteDownloadRecord(String bookId) async {
    if (_downloadsMap.remove(bookId) != null) {
      await _writeList('downloads',
          _downloadsMap.values.map((d) => d.toJson()).toList());
    }
  }

  // ---------- statistics ----------

  @override
  Future<StatisticsCounters> statisticsCounters() async {
    if (_counters != null) return _counters!;
    final file = _file('statistics');
    if (file.existsSync()) {
      try {
        final decoded = jsonDecode(file.readAsStringSync());
        if (decoded is Map<String, dynamic>) {
          _counters = StatisticsCounters.fromJson(decoded);
          return _counters!;
        }
      } catch (_) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }
    _counters = const StatisticsCounters();
    return _counters!;
  }

  @override
  Future<void> saveStatisticsCounters(StatisticsCounters counters) {
    _counters = counters;
    return _enqueueWrite(() async {
      await _ensureDirectory();
      final target = _file('statistics');
      final tmp = File('${target.path}.tmp');
      await tmp.writeAsString(jsonEncode(counters.toJson()));
      await tmp.rename(target.path);
    });
  }
}
