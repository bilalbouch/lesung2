import 'dart:io';

import 'package:lesung/features/library/data/json_library_repository.dart';
import 'package:lesung/features/library/domain/entities/collection.dart';
import 'package:lesung/features/library/domain/entities/favorite.dart';
import 'package:lesung/features/library/domain/entities/library_book.dart';
import 'package:lesung/features/library/domain/entities/reading_history.dart';
import 'package:lesung/features/library/domain/entities/reading_progress.dart';
import 'package:lesung/features/library/domain/entities/reading_stats.dart';
import 'package:test/test.dart';

LibraryBook book(String id,
        {String? title,
        bool downloaded = false,
        String? filePath,
        DateTime? addedAt}) =>
    LibraryBook(
      id: id,
      title: title ?? 'Titre $id',
      author: 'Auteur $id',
      language: 'de',
      format: 'epub',
      downloaded: downloaded,
      filePath: filePath,
      addedAt: addedAt ?? DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );

void main() {
  late Directory dir;
  late JsonLibraryRepository repo;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('lesung_lib_repo_');
    repo = JsonLibraryRepository(dir);
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('books', () {
    test('upsert + lecture + tri par updatedAt décroissant', () async {
      await repo.saveBook(book('a'));
      await repo.saveBook(book('b'));
      final b = book('b').copyWith(title: 'B v2', updatedAt: DateTime(2026, 3));
      await repo.saveBook(b);

      final all = await repo.allBooks();
      expect(all, hasLength(2));
      expect(all.first.id, 'b');
      expect(all.first.title, 'B v2');
      expect((await repo.bookById('a'))!.author, 'Auteur a');
    });

    test('persistance sur disque entre deux instances', () async {
      await repo.saveBook(book('persist'));
      final second = JsonLibraryRepository(dir);
      expect((await second.bookById('persist'))!.title, 'Titre persist');
    });

    test('fichier corrompu supprimé, repart à zéro', () async {
      await File('${dir.path}/books.json').writeAsString('{pas du json');
      expect(await repo.allBooks(), isEmpty);
      expect(File('${dir.path}/books.json').existsSync(), isFalse);
    });
  });

  group('cascade deleteBook', () {
    test('supprime favori, liens collections, progression, historique, download',
        () async {
      await repo.saveBook(book('x'));
      await repo
          .addFavorite(Favorite(bookId: 'x', addedAt: DateTime(2026, 2)));
      await repo.saveCollection(Collection(
          id: 'c1',
          name: 'C',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026)));
      await repo.addBookToCollection(CollectionBook(
          collectionId: 'c1',
          bookId: 'x',
          addedAt: DateTime(2026),
          position: 0));
      await repo.saveReadingProgress(ReadingProgress(
          bookId: 'x',
          locator: 'epubcfi(/6/2)',
          progress: 0.5,
          updatedAt: DateTime(2026)));
      await repo.addHistoryEntry(
          ReadingHistoryEntry(bookId: 'x', openedAt: DateTime(2026)));
      await repo.saveDownloadRecord(DownloadRecord(
          bookId: 'x',
          filePath: '/tmp/x.epub',
          fileSizeBytes: 10,
          md5Verified: true,
          completedAt: DateTime(2026)));

      await repo.deleteBook('x');

      expect(await repo.bookById('x'), isNull);
      expect(await repo.isFavorite('x'), isFalse);
      expect(await repo.collectionBooks('c1'), isEmpty);
      expect(await repo.readingProgressFor('x'), isNull);
      expect(await repo.history(), isEmpty);
      expect(await repo.downloadRecordFor('x'), isNull);
    });
  });

  group('favorites', () {
    test('tri ajout récent d\'abord, add idempotent', () async {
      await repo.addFavorite(
          Favorite(bookId: 'old', addedAt: DateTime(2026, 1)));
      await repo.addFavorite(
          Favorite(bookId: 'new', addedAt: DateTime(2026, 6)));
      await repo.addFavorite(
          Favorite(bookId: 'new', addedAt: DateTime(2026, 7)));
      expect(await repo.favoriteBookIds(), ['new', 'old']);
    });
  });

  group('collections', () {
    test('tri par sortOrder puis nom ; liens ordonnés par position',
        () async {
      await repo.saveCollection(Collection(
          id: 'b',
          name: 'Beta',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          sortOrder: 1));
      await repo.saveCollection(Collection(
          id: 'a',
          name: 'Alpha',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          sortOrder: 0));
      expect((await repo.allCollections()).map((c) => c.id), ['a', 'b']);

      await repo.addBookToCollection(CollectionBook(
          collectionId: 'a',
          bookId: 'k2',
          addedAt: DateTime(2026),
          position: 1));
      await repo.addBookToCollection(CollectionBook(
          collectionId: 'a',
          bookId: 'k1',
          addedAt: DateTime(2026),
          position: 0));
      expect(
          (await repo.collectionBooks('a')).map((l) => l.bookId), ['k1', 'k2']);
      expect(await repo.collectionIdsForBook('k1'), ['a']);

      await repo.deleteCollection('a');
      expect(await repo.collectionById('a'), isNull);
      expect(await repo.collectionBooks('a'), isEmpty);
    });
  });

  group('reading_progress', () {
    test('upsert, tri récent, suppression', () async {
      await repo.saveReadingProgress(ReadingProgress(
          bookId: 'p1',
          locator: 'l1',
          progress: 0.3,
          updatedAt: DateTime(2026, 1)));
      await repo.saveReadingProgress(ReadingProgress(
          bookId: 'p2',
          locator: 'l2',
          progress: 0.9,
          updatedAt: DateTime(2026, 5)));
      final all = await repo.allReadingProgress();
      expect(all.first.bookId, 'p2');
      await repo.deleteReadingProgress('p1');
      expect(await repo.readingProgressFor('p1'), isNull);
    });
  });

  group('history', () {
    test('id auto-incrémenté, session ouverte détectée, tri récent',
        () async {
      final e1 = await repo.addHistoryEntry(
          ReadingHistoryEntry(bookId: 'h', openedAt: DateTime(2026, 1)));
      final e2 = await repo.addHistoryEntry(
          ReadingHistoryEntry(bookId: 'h', openedAt: DateTime(2026, 2)));
      expect(e1.id, isNotNull);
      expect(e2.id, greaterThan(e1.id!));

      expect((await repo.openSessionFor('h'))!.id, e2.id);

      await repo.updateHistoryEntry(e2.close(DateTime(2026, 2, 1), 60));
      // e1 est encore ouverte : openSessionFor la trouve.
      expect((await repo.openSessionFor('h'))!.id, e1.id);
      await repo.updateHistoryEntry(e1.close(DateTime(2026, 2, 0 + 1), 30));
      expect(await repo.openSessionFor('h'), isNull);

      final all = await repo.history();
      expect(all.first.id, e2.id);
      expect(all.first.durationSeconds, 60);

      // Persistance : l'id continue de s'incrémenter après rechargement.
      final second = JsonLibraryRepository(dir);
      final e3 = await second.addHistoryEntry(
          ReadingHistoryEntry(bookId: 'h', openedAt: DateTime(2026, 3)));
      expect(e3.id, greaterThan(e2.id!));
    });
  });

  group('statistics', () {
    test('compteurs à zéro puis persistés', () async {
      expect((await repo.statisticsCounters()).totalReadingSeconds, 0);
      await repo.saveStatisticsCounters(
          const StatisticsCounters(totalReadingSeconds: 120, sessionsCount: 2));
      final second = JsonLibraryRepository(dir);
      final counters = await second.statisticsCounters();
      expect(counters.totalReadingSeconds, 120);
      expect(counters.sessionsCount, 2);
    });
  });
}
