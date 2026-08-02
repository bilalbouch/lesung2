import 'dart:convert';

import 'package:lesung/features/library/domain/entities/collection.dart';
import 'package:lesung/features/library/domain/entities/favorite.dart';
import 'package:lesung/features/library/domain/entities/library_book.dart';
import 'package:lesung/features/library/domain/entities/reading_history.dart';
import 'package:lesung/features/library/domain/entities/reading_progress.dart';
import 'package:lesung/features/library/domain/entities/reading_stats.dart';
import 'package:lesung/features/library/domain/library_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistance de la bibliothèque dans le stockage local du navigateur.
class PreferencesLibraryRepository implements LibraryRepository {
  static const _prefix = 'lesung.library.';

  final SharedPreferences _preferences;
  late final Map<String, LibraryBook> _books;
  late final List<Favorite> _favorites;
  late final Map<String, Collection> _collections;
  late final List<CollectionBook> _collectionBooks;
  late final Map<String, ReadingProgress> _progress;
  late final List<ReadingHistoryEntry> _history;
  late final Map<String, DownloadRecord> _downloads;
  late StatisticsCounters _counters;
  int _nextHistoryId = 1;

  PreferencesLibraryRepository(this._preferences) {
    _books = _map('books', LibraryBook.fromJson, (value) => value.id);
    _favorites = _list('favorites', Favorite.fromJson);
    _collections =
        _map('collections', Collection.fromJson, (value) => value.id);
    _collectionBooks = _list('collectionBooks', CollectionBook.fromJson);
    _progress = _map(
      'progress',
      ReadingProgress.fromJson,
      (value) => value.bookId,
    );
    _history = _list('history', ReadingHistoryEntry.fromJson);
    _downloads = _map(
      'downloads',
      DownloadRecord.fromJson,
      (value) => value.bookId,
    );
    final counters = _object('statistics');
    _counters = counters == null
        ? const StatisticsCounters()
        : StatisticsCounters.fromJson(counters);
    for (final entry in _history) {
      final id = entry.id ?? 0;
      if (id >= _nextHistoryId) _nextHistoryId = id + 1;
    }
  }

  List<Map<String, dynamic>> _rows(String name) {
    final raw = _preferences.getString('$_prefix$name');
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic>? _object(String name) {
    final raw = _preferences.getString('$_prefix$name');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  List<T> _list<T>(
    String name,
    T Function(Map<String, dynamic>) decode,
  ) =>
      _rows(name).map(decode).toList();

  Map<String, T> _map<T>(
    String name,
    T Function(Map<String, dynamic>) decode,
    String Function(T) keyOf,
  ) =>
      {
        for (final value in _list(name, decode)) keyOf(value): value,
      };

  Future<void> _saveRows(
    String name,
    Iterable<Map<String, dynamic>> rows,
  ) async {
    await _preferences.setString('$_prefix$name', jsonEncode(rows.toList()));
  }

  Future<void> _saveBooks() =>

      _saveRows('books', _books.values.map((value) => value.toJson()));
  Future<void> _saveFavorites() =>
      _saveRows('favorites', _favorites.map((value) => value.toJson()));
  Future<void> _saveCollections() => _saveRows(
      'collections', _collections.values.map((value) => value.toJson()));
  Future<void> _saveCollectionBooks() => _saveRows(
      'collectionBooks', _collectionBooks.map((value) => value.toJson()));
  Future<void> _saveProgress() =>
      _saveRows('progress', _progress.values.map((value) => value.toJson()));
  Future<void> _saveHistory() =>
      _saveRows('history', _history.map((value) => value.toJson()));
  Future<void> _saveDownloads() => _saveRows(
      'downloads', _downloads.values.map((value) => value.toJson()));

  @override
  Future<void> saveBook(LibraryBook book) async {
    _books[book.id] = book;
    await _saveBooks();
  }

  @override
  Future<LibraryBook?> bookById(String bookId) async => _books[bookId];

  @override
  Future<List<LibraryBook>> allBooks() async => _books.values.toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Future<void> deleteBook(String bookId) async {
    _books.remove(bookId);
    _favorites.removeWhere((value) => value.bookId == bookId);
    _collectionBooks.removeWhere((value) => value.bookId == bookId);
    _progress.remove(bookId);
    _history.removeWhere((value) => value.bookId == bookId);
    _downloads.remove(bookId);
    await Future.wait([
      _saveBooks(),
      _saveFavorites(),
      _saveCollectionBooks(),
      _saveProgress(),
      _saveHistory(),
      _saveDownloads(),
    ]);
  }

  @override
  Future<void> addFavorite(Favorite favorite) async {
    _favorites.removeWhere((value) => value.bookId == favorite.bookId);
    _favorites.add(favorite);
    await _saveFavorites();
  }

  @override
  Future<void> removeFavorite(String bookId) async {
    _favorites.removeWhere((value) => value.bookId == bookId);
    await _saveFavorites();
  }

  @override
  Future<List<String>> favoriteBookIds() async {
    final sorted = [..._favorites]
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sorted.map((value) => value.bookId).toList();
  }

  @override
  Future<bool> isFavorite(String bookId) async =>
      _favorites.any((value) => value.bookId == bookId);

  @override
  Future<void> saveCollection(Collection collection) async {
    _collections[collection.id] = collection;
    await _saveCollections();
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    _collections.remove(collectionId);
    _collectionBooks
        .removeWhere((value) => value.collectionId == collectionId);
    await Future.wait([_saveCollections(), _saveCollectionBooks()]);
  }

  @override
  Future<Collection?> collectionById(String collectionId) async =>
      _collections[collectionId];

  @override
  Future<List<Collection>> allCollections() async =>
      _collections.values.toList()
        ..sort((a, b) {
          final order = a.sortOrder.compareTo(b.sortOrder);
          return order == 0 ? a.name.compareTo(b.name) : order;
        });

  @override
  Future<void> addBookToCollection(CollectionBook link) async {
    _collectionBooks.removeWhere((value) =>
        value.collectionId == link.collectionId &&
        value.bookId == link.bookId);
    _collectionBooks.add(link);
    await _saveCollectionBooks();
  }

  @override
  Future<void> removeBookFromCollection(
    String collectionId,
    String bookId,
  ) async {
    _collectionBooks.removeWhere((value) =>
        value.collectionId == collectionId && value.bookId == bookId);
    await _saveCollectionBooks();
  }

  @override
  Future<List<CollectionBook>> collectionBooks(String collectionId) async =>
      _collectionBooks
          .where((value) => value.collectionId == collectionId)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));

  @override
  Future<List<String>> collectionIdsForBook(String bookId) async =>
      _collectionBooks
          .where((value) => value.bookId == bookId)
          .map((value) => value.collectionId)
          .toList();

  @override
  Future<void> saveReadingProgress(ReadingProgress progress) async {
    _progress[progress.bookId] = progress;
    await _saveProgress();
  }

  @override
  Future<ReadingProgress?> readingProgressFor(String bookId) async =>
      _progress[bookId];

  @override
  Future<List<ReadingProgress>> allReadingProgress() async =>
      _progress.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Future<void> deleteReadingProgress(String bookId) async {
    _progress.remove(bookId);
    await _saveProgress();
  }

  @override
  Future<ReadingHistoryEntry> addHistoryEntry(
    ReadingHistoryEntry entry,
  ) async {
    final saved = ReadingHistoryEntry(
      id: _nextHistoryId++,
      bookId: entry.bookId,
      openedAt: entry.openedAt,
      closedAt: entry.closedAt,
      durationSeconds: entry.durationSeconds,
    );
    _history.add(saved);
    await _saveHistory();
    return saved;
  }

  @override
  Future<void> updateHistoryEntry(ReadingHistoryEntry entry) async {
    final index = _history.indexWhere((value) => value.id == entry.id);
    if (index < 0) {
      _history.add(entry);
    } else {
      _history[index] = entry;
    }
    await _saveHistory();
  }

  @override
  Future<List<ReadingHistoryEntry>> history() async => [..._history]
    ..sort((a, b) => b.openedAt.compareTo(a.openedAt));

  @override
  Future<ReadingHistoryEntry?> openSessionFor(String bookId) async {
    final sessions = _history
        .where((value) => value.bookId == bookId && value.closedAt == null)
        .toList()
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return sessions.isEmpty ? null : sessions.first;
  }

  @override
  Future<void> saveDownloadRecord(DownloadRecord record) async {
    _downloads[record.bookId] = record;
    await _saveDownloads();
  }

  @override
  Future<DownloadRecord?> downloadRecordFor(String bookId) async =>
      _downloads[bookId];

  @override
  Future<void> deleteDownloadRecord(String bookId) async {
    _downloads.remove(bookId);
    await _saveDownloads();
  }

  @override
  Future<StatisticsCounters> statisticsCounters() async => _counters;

  @override
  Future<void> saveStatisticsCounters(StatisticsCounters counters) async {
    _counters = counters;
    await _preferences.setString(
      '${_prefix}statistics',
      jsonEncode(counters.toJson()),
    );
  }
}
