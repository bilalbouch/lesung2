import 'dart:io';

import 'package:lesung/core/events/app_events.dart';
import 'package:lesung/core/events/event_bus.dart';
import 'package:lesung/features/library/data/json_library_repository.dart';
import 'package:lesung/features/library/domain/collections_manager.dart';
import 'package:lesung/features/library/domain/entities/favorite.dart';
import 'package:lesung/features/library/domain/entities/library_book.dart';
import 'package:lesung/features/library/domain/entities/reading_progress.dart';
import 'package:lesung/features/library/domain/entities/reading_stats.dart';
import 'package:lesung/features/library/domain/favorites_manager.dart';
import 'package:lesung/features/library/domain/history_manager.dart';
import 'package:lesung/features/library/domain/reading_progress_manager.dart';
import 'package:lesung/features/library/domain/statistics_manager.dart';
import 'package:test/test.dart';

LibraryBook book(String id,
        {bool downloaded = false,
        String? language,
        String? format,
        int? fileSizeBytes}) =>
    LibraryBook(
      id: id,
      title: 'Titre $id',
      language: language,
      format: format,
      downloaded: downloaded,
      filePath: downloaded ? '/tmp/$id.epub' : null,
      fileSizeBytes: fileSizeBytes,
      addedAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );

void main() {
  late Directory dir;
  late JsonLibraryRepository repo;
  late EventBus bus;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('lesung_lib_mgr_');
    repo = JsonLibraryRepository(dir);
    bus = EventBus();
  });

  tearDown(() async {
    await bus.dispose();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  /// Les événements broadcast sont livrés en micro-tâche : on purge
  /// avant toute assertion sur les listes d'événements.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  Future<void> seed(List<LibraryBook> books) async {
    for (final b in books) {
      await repo.saveBook(b);
    }
  }

  group('EventBus', () {
    test('dispatch par type exact + type de base AppEvent', () async {
      final exact = <String>[];
      final all = <String>[];
      bus.on<FavoriteAddedEvent>().listen((e) => exact.add(e.bookId));
      bus.on<AppEvent>().listen((e) => all.add(e.runtimeType.toString()));
      bus.emit(FavoriteAddedEvent('b1'));
      bus.emit(BookFinishedEvent('b2'));
      await Future<void>.delayed(Duration.zero);
      expect(exact, ['b1']);
      expect(all, ['FavoriteAddedEvent', 'BookFinishedEvent']);
    });
  });

  group('FavoritesManager', () {
    test('toggle on/off avec événements, favori sur livre inconnu refusé',
        () async {
      await seed([book('f1')]);
      final manager = FavoritesManager(repository: repo, eventBus: bus);
      final events = <AppEvent>[];
      bus.on<AppEvent>().listen(events.add);

      expect(await manager.toggle('f1'), isTrue);
      expect(await manager.isFavorite('f1'), isTrue);
      expect(await manager.toggle('f1'), isFalse);
      await pump();
      expect(events.whereType<FavoriteAddedEvent>(), hasLength(1));
      expect(events.whereType<FavoriteRemovedEvent>(), hasLength(1));

      expect(() => manager.add('inconnu'), throwsStateError);
    });

    test('favori indépendant du téléchargement', () async {
      await seed([book('nf')]); // non téléchargé
      final manager = FavoritesManager(repository: repo, eventBus: bus);
      await manager.add('nf');
      final favs = await manager.favorites();
      expect(favs.single.downloaded, isFalse);
    });
  });

  group('CollectionsManager', () {
    test('créer, renommer, ajouter/retirer un livre, supprimer', () async {
      await seed([book('c1'), book('c2')]);
      var seq = 0;
      final manager = CollectionsManager(
          repository: repo, eventBus: bus, idGenerator: () => 'col_${seq++}');
      final events = <AppEvent>[];
      bus.on<AppEvent>().listen(events.add);

      final col = await manager.create('  À lire  ');
      expect(col.name, 'À lire');
      expect(await manager.addBook(col.id, 'c1'), isTrue);
      expect(await manager.addBook(col.id, 'c1'), isFalse); // idempotent
      await manager.addBook(col.id, 'c2');

      final renamed = await manager.rename(col.id, 'Priorité');
      expect(renamed.name, 'Priorité');

      final books = await manager.booksIn(col.id);
      expect(books.map((b) => b.id), ['c1', 'c2']);
      expect((await manager.collectionsFor('c1')).single.id, col.id);

      await manager.removeBook(col.id, 'c1');
      expect(await manager.booksIn(col.id), hasLength(1));

      await manager.delete(col.id);
      expect(await manager.collections(), isEmpty);
      // Les livres eux-mêmes survivent à la suppression.
      expect(await repo.bookById('c2'), isNotNull);

      await pump();
      expect(events.whereType<CollectionCreatedEvent>(), hasLength(1));
      expect(events.whereType<CollectionUpdatedEvent>(), hasLength(1));
      expect(events.whereType<CollectionBookAddedEvent>(), hasLength(2));
      expect(events.whereType<CollectionBookRemovedEvent>(), hasLength(1));
      expect(events.whereType<CollectionDeletedEvent>(), hasLength(1));
    });

    test('nom vide refusé, collection inconnue refusée', () async {
      final manager = CollectionsManager(repository: repo, eventBus: bus);
      expect(() => manager.create('   '), throwsArgumentError);
      expect(() => manager.addBook('nope', 'x'), throwsStateError);
    });
  });

  group('HistoryManager', () {
    test('sessions ouverture/fermeture alimentent les compteurs', () async {
      final manager = HistoryManager(repository: repo, eventBus: bus);
      final events = <AppEvent>[];
      bus.on<AppEvent>().listen(events.add);

      await manager.openSession('h1');
      // Simule une session déjà ouverte : réouvrir clôture l'ancienne.
      await manager.openSession('h1');
      final duration = await manager.closeSession('h1');
      expect(duration, isNotNull);
      expect(await manager.closeSession('h1'), isNull); // plus rien à fermer

      final counters = await repo.statisticsCounters();
      expect(counters.sessionsCount, 2); // la dangling + la finale
      await pump();
      expect(events.whereType<ReadingSessionOpenedEvent>(), hasLength(2));
      expect(events.whereType<ReadingSessionClosedEvent>(), hasLength(2));

      final history = await manager.historyFor('h1');
      expect(history, hasLength(2));
      expect(history.where((e) => e.closedAt != null), hasLength(2));
    });
  });

  group('ReadingProgressManager', () {
    test('progression bornée, 100 % marque terminé + événement', () async {
      await seed([book('r1')]);
      final manager =
          ReadingProgressManager(repository: repo, eventBus: bus);
      final finished = <String>[];
      bus.on<BookFinishedEvent>().listen((e) => finished.add(e.bookId));

      await manager.updateProgress('r1', 'epubcfi(/6/4)', 0.5);
      expect((await manager.progressFor('r1'))!.progress, 0.5);
      expect((await repo.bookById('r1'))!.finishedAt, isNull);

      await manager.updateProgress('r1', 'epubcfi(/6/99)', 1.4); // borné à 1
      expect((await manager.progressFor('r1'))!.progress, 1.0);
      expect((await repo.bookById('r1'))!.finishedAt, isNotNull);
      expect(finished, ['r1']);

      // Revenir en arrière retire la marque « terminé ».
      await manager.updateProgress('r1', 'epubcfi(/6/4)', 0.4);
      expect((await repo.bookById('r1'))!.finishedAt, isNull);
      expect(finished, hasLength(1)); // pas de second événement

      await pump();
      expect(finished, hasLength(1));

      await manager.clearProgress('r1');
      expect(await manager.progressFor('r1'), isNull);

      expect(() => manager.updateProgress('inconnu', 'l', 0.5),
          throwsStateError);
    });
  });

  group('StatisticsManager', () {
    test('agrégats : livres, langues, formats, taille, en cours', () async {
      await seed([
        book('s1', downloaded: true, language: 'de', format: 'epub',
            fileSizeBytes: 100),
        book('s2', downloaded: true, language: 'fr', format: 'pdf',
            fileSizeBytes: 250),
        book('s3', language: 'de', format: 'epub'),
      ]);
      final manager = StatisticsManager(repository: repo);
      await repo.saveReadingProgress(progress('s1', 0.4));
      await repo.saveReadingProgress(progress('s2', 1.0));
      await repo.saveBook(
          (await repo.bookById('s2'))!.copyWith(finishedAt: DateTime(2026, 4)));
      await repo.addFavorite(fav('s3'));
      await repo.saveStatisticsCounters(
          const StatisticsCounters(totalReadingSeconds: 3600, sessionsCount: 5));

      final stats = await manager.compute();
      expect(stats.totalBooks, 3);
      expect(stats.downloadedBooks, 2);
      expect(stats.notDownloadedBooks, 1);
      expect(stats.finishedBooks, 1);
      expect(stats.inProgressBooks, 1);
      expect(stats.favoritesCount, 1);
      expect(stats.totalReadingSeconds, 3600);
      expect(stats.totalSizeBytes, 350);
      expect(stats.booksByLanguage, {'de': 2, 'fr': 1});
      expect(stats.booksByFormat, {'epub': 2, 'pdf': 1});
      expect(await manager.totalReadingTime(),
          const Duration(seconds: 3600));
    });
  });
}

ReadingProgress progress(String bookId, double value) => ReadingProgress(
      bookId: bookId,
      locator: 'epubcfi(/6/2)',
      progress: value,
      updatedAt: DateTime(2026, 2),
    );

Favorite fav(String bookId) =>
    Favorite(bookId: bookId, addedAt: DateTime(2026, 3));
