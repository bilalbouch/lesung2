import 'dart:io';

import 'package:lesung/core/events/app_events.dart';
import 'package:lesung/core/events/event_bus.dart';
import 'package:lesung/features/library/data/json_library_repository.dart';
import 'package:lesung/features/library/data/library_sync.dart';
import 'package:lesung/features/library/domain/entities/library_book.dart';
import 'package:lesung/features/library/domain/library_manager.dart';
import 'package:lesung/features/library/presentation/library_controller.dart';
import 'package:test/test.dart';

LibraryBook book(String id,
        {bool downloaded = false,
        String? filePath,
        bool fileMissing = false,
        DateTime? addedAt,
        DateTime? finishedAt}) =>
    LibraryBook(
      id: id,
      title: 'Titre $id',
      language: 'de',
      format: 'epub',
      downloaded: downloaded,
      filePath: filePath,
      fileSizeBytes: 100,
      fileMissing: fileMissing,
      addedAt: addedAt ?? DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
      finishedAt: finishedAt,
    );

void main() {
  late Directory dir;
  late JsonLibraryRepository repo;
  late EventBus bus;
  late LibraryManager manager;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('lesung_lib_lm_');
    repo = JsonLibraryRepository(dir);
    bus = EventBus();
    manager = LibraryManager(repository: repo, eventBus: bus)..listen();
  });

  tearDown(() async {
    await manager.dispose();
    await bus.dispose();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  /// Laisse le temps aux listeners broadcast (micro-tâches).
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  /// Attente active asynchrone (les handlers d'événements font de l'I/O).
  Future<void> waitForAsync(Future<bool> Function() condition,
      {Duration timeout = const Duration(seconds: 3)}) async {
    final sw = Stopwatch()..start();
    while (!await condition() && sw.elapsed < timeout) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  group('réaction aux événements de téléchargement', () {
    test('DownloadFinishedEvent crée un livre téléchargé + trace', () async {
      bus.emit(DownloadFinishedEvent(
        bookId: 'dl1',
        title: 'Die Verwandlung',
        author: 'Kafka',
        coverUrl: 'https://x/cover.jpg',
        language: 'de',
        format: 'epub',
        filePath: '/books/dl1.epub',
        fileSizeBytes: 4242,
        md5Verified: true,
      ));
      await waitForAsync(() async => await repo.bookById('dl1') != null);

      final b = (await repo.bookById('dl1'))!;
      expect(b.title, 'Die Verwandlung');
      expect(b.downloaded, isTrue);
      expect(b.filePath, '/books/dl1.epub');
      expect(b.fileSizeBytes, 4242);

      final record = (await repo.downloadRecordFor('dl1'))!;
      expect(record.md5Verified, isTrue);
      expect(record.fileSizeBytes, 4242);
    });

    test('DownloadFinishedEvent complète un livre existant (favori gardé)',
        () async {
      await manager.addBook(book('fav1'));
      await manager.favorites.add('fav1');

      bus.emit(DownloadFinishedEvent(
        bookId: 'fav1',
        title: 'Titre fav1',
        format: 'pdf',
        filePath: '/books/fav1.pdf',
        fileSizeBytes: 10,
        md5Verified: false,
      ));
      await waitForAsync(
          () async => (await repo.bookById('fav1'))?.downloaded ?? false);

      final b = (await repo.bookById('fav1'))!;
      expect(b.downloaded, isTrue);
      expect(b.fileMissing, isFalse);
      // Le favori survit au téléchargement.
      expect(await repo.isFavorite('fav1'), isTrue);
    });

    test('DownloadRemovedEvent : livre conservé, plus téléchargé', () async {
      bus.emit(DownloadFinishedEvent(
        bookId: 'rm1',
        title: 'T',
        format: 'epub',
        filePath: '/books/rm1.epub',
        fileSizeBytes: 5,
        md5Verified: true,
      ));
      await waitForAsync(() async => await repo.bookById('rm1') != null);
      bus.emit(const _Removed('rm1', '/books/rm1.epub').event);
      await waitForAsync(
          () async => !(await repo.bookById('rm1'))!.downloaded);

      final b = (await repo.bookById('rm1'))!;
      expect(b, isNotNull); // le livre reste en bibliothèque
      expect(b.downloaded, isFalse);
      expect(b.filePath, isNull);
      expect(await repo.downloadRecordFor('rm1'), isNull);
    });
  });

  group('écritures UI et vues', () {
    test('addBook idempotent, removeBook cascade + événement', () async {
      await manager.addBook(book('u1'));
      final again = await manager.addBook(book('u1').copyWith(title: 'Autre'));
      expect(again.title, 'Titre u1'); // l'existant est conservé

      await manager.favorites.add('u1');
      final removedEvents = <BookRemovedEvent>[];
      bus.on<BookRemovedEvent>().listen(removedEvents.add);
      await manager.removeBook('u1');
      await pump();

      expect(await repo.bookById('u1'), isNull);
      expect(await repo.isFavorite('u1'), isFalse);
      expect(removedEvents.single.bookId, 'u1');
    });

    test('vues : récents, continuer, terminés, téléchargés, non téléchargés',
        () async {
      await manager.addBook(
          book('old', addedAt: DateTime(2026, 1), downloaded: true));
      await manager
          .addBook(book('new', addedAt: DateTime(2026, 6)));
      await manager
          .addBook(book('done', finishedAt: DateTime(2026, 5)));
      await manager.progress.updateProgress('old', 'l1', 0.5);
      await manager.progress.updateProgress('new', 'l2', 0.2);

      final recent = await manager.recentBooks();
      expect(recent.first.id, 'new');

      final cont = await manager.continueReading();
      expect(cont.map((b) => b.id).toSet(), {'old', 'new'});

      expect((await manager.finishedBooks()).single.id, 'done');
      expect((await manager.downloadedBooks()).map((b) => b.id),
          contains('old'));
      expect((await manager.notDownloadedBooks()).map((b) => b.id).toSet(),
          {'new', 'done'});
    });

    test('openReading/closeReading : lastOpenedAt + session + stats',
        () async {
      await manager.addBook(book('r1'));
      await manager.openReading('r1');

      expect((await repo.bookById('r1'))!.lastOpenedAt, isNotNull);

      final seconds = await manager.closeReading('r1');
      expect(seconds, isNotNull);
      expect((await repo.statisticsCounters()).sessionsCount, 1);

      expect(() => manager.openReading('inconnu'), throwsStateError);
    });
  });

  group('LibrarySync', () {
    test('détecte fichier disparu, fichier revenu, fichiers orphelins',
        () async {
      final booksDir = Directory('${dir.path}/books')..createSync();
      final present = File('${booksDir.path}/present.epub')
        ..writeAsBytesSync([1, 2, 3]);
      final orphan = File('${booksDir.path}/orphelin.epub')
        ..writeAsBytesSync([4, 5]);
      File('${booksDir.path}/notes.txt').writeAsStringSync('pas un livre');

      await manager.addBook(book('lost',
          downloaded: true, filePath: '${booksDir.path}/perdu.epub'));
      await manager.addBook(book('ok',
          downloaded: true, filePath: present.path));
      await manager.addBook(book('back',
          downloaded: true,
          filePath: '${booksDir.path}/revenu.epub',
          fileMissing: true));
      // Le fichier « revenu » réapparaît sur le disque.
      File('${booksDir.path}/revenu.epub').writeAsBytesSync([9]);

      final sync = LibrarySync(repository: repo, booksDirectory: booksDir);
      final report = await sync.synchronize();

      expect(report.missingBookIds, ['lost']);
      expect(report.restoredBookIds, ['back']);
      expect(report.orphanFilePaths, [orphan.absolute.path]);
      expect(report.correctionsApplied, 2);
      // L'orphelin n'est JAMAIS supprimé automatiquement.
      expect(orphan.existsSync(), isTrue);

      expect((await repo.bookById('lost'))!.fileMissing, isTrue);
      expect((await repo.bookById('back'))!.fileMissing, isFalse);

      // Deuxième passage : plus rien à corriger.
      final second = await sync.synchronize();
      expect(second.correctionsApplied, 0);
      expect(second.orphanFilePaths, hasLength(1));
    });
  });

  group('LibraryController', () {
    test('init charge l\'état, événement déclenche un rafraîchissement',
        () async {
      await manager.addBook(book('ctl1'));
      final controller = LibraryController(manager: manager, eventBus: bus);
      final states = <int>[];
      final sub = controller.stream.listen((s) => states.add(s.recentBooks.length));

      await controller.init();
      expect(controller.state.loaded, isTrue);
      expect(controller.state.recentBooks, hasLength(1));
      expect(controller.state.stats, isNotNull);

      await controller.toggleFavorite('ctl1');
      await waitFor(() => controller.state.favorites.isNotEmpty);

      expect(controller.state.favorites, hasLength(1));
      expect(states, isNotEmpty);

      await controller.createCollection('Lecture du moment');
      await waitFor(() => controller.state.collections.isNotEmpty);
      expect(controller.state.collections.single.name, 'Lecture du moment');

      await sub.cancel();
      await controller.dispose();
    });
  });
}

/// Attente active sur une condition (rafraîchissements asynchrones).
Future<void> waitFor(bool Function() condition,
    {Duration timeout = const Duration(seconds: 3)}) async {
  final sw = Stopwatch()..start();
  while (!condition() && sw.elapsed < timeout) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// Petit helper pour émettre un DownloadRemovedEvent de façon lisible.
class _Removed {
  final String bookId;
  final String? filePath;
  const _Removed(this.bookId, this.filePath);
  DownloadRemovedEvent get event =>
      DownloadRemovedEvent(bookId: bookId, filePath: filePath);
}
