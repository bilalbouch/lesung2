import 'dart:io';
import 'package:test/test.dart';
import 'package:lesung/features/downloads/data/download_queue.dart';
import 'package:lesung/features/downloads/data/download_storage.dart';
import 'package:lesung/features/downloads/data/download_repository_impl.dart';
import 'package:lesung/features/downloads/domain/entities/download_history.dart';
import 'package:lesung/features/downloads/domain/entities/download_task.dart';
import 'package:lesung/features/search/domain/entities/download_link.dart';
import 'package:lesung/features/search/domain/entities/search_query.dart';

DownloadTask task(String id, {String title = 'Titre', String? author}) =>
    DownloadTask(
      id: id,
      title: title,
      author: author,
      format: BookFormat.epub,
      links: [
        DownloadLink(
            url: Uri.parse('https://x/$id'), kind: DownloadLinkKind.direct)
      ],
    );

void main() {
  group('DownloadQueue', () {
    test('FIFO stricte et concurrence bornée', () async {
      final started = <String>[];
      final queue = DownloadQueue(maxConcurrent: 2);
      queue.runner = (t) async {
        started.add(t.id);
        await Future.delayed(const Duration(milliseconds: 50));
        queue.complete(t.id);
      };

      queue.enqueue(task('a'));
      queue.enqueue(task('b'));
      queue.enqueue(task('c'));

      expect(started, ['a', 'b'], reason: '2 slots seulement');
      await Future.delayed(const Duration(milliseconds: 200));
      expect(started, containsAll(['a', 'b', 'c']));
    });

    test('remove retire une tâche en attente', () async {
      final queue = DownloadQueue(maxConcurrent: 0)..runner = null;
      queue.enqueue(task('x'));
      expect(queue.remove('x'), isTrue);
      expect(queue.pending, isEmpty);
    });

    test('requeue ignore les doublons', () async {
      final queue = DownloadQueue(maxConcurrent: 0)..runner = null;
      final t = task('x');
      queue.enqueue(t);
      queue.requeue(t);
      expect(queue.pending, hasLength(1));
    });
  });

  group('DownloadStorage', () {
    late Directory dir;
    late DownloadStorage storage;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('storage');
      storage = DownloadStorage(booksDirectory: dir);
      await storage.initialize();
    });
    tearDown(() async => dir.delete(recursive: true));

    test('nommage sûr : caractères dangereux retirés', () {
      final t = task('abc123def456',
          title: 'Un / titre: <dangereux> *?', author: 'Auteur "X"');
      final name = storage.fileNameFor(t);
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('<')));
      expect(name, isNot(contains('"')));
      expect(name.endsWith('.epub'), isTrue);
    });

    test('cycle partiel -> finalize -> delete', () async {
      final t = task('cycle1');
      await storage.partialFileFor(t).writeAsBytes([1, 2, 3]);
      expect(await storage.existingPartialBytes(t), 3);

      final finalFile = await storage.finalize(t);
      expect(await finalFile.exists(), isTrue);
      expect(await storage.partialFileFor(t).exists(), isFalse);

      await storage.deleteFinal(t);
      expect(await finalFile.exists(), isFalse);
    });
  });

  group('DownloadRepositoryImpl', () {
    late Directory dir;
    late DownloadRepositoryImpl repo;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('repo');
      repo = DownloadRepositoryImpl(directory: dir);
      await repo.initialize();
    });
    tearDown(() async => dir.delete(recursive: true));

    test('save/load/delete tâche avec état complet', () async {
      final t = task('save-me')
        ..receivedBytes = 123
        ..totalBytes = 456
        ..status = DownloadStatus.paused;
      await repo.saveTask(t);

      final loaded = await repo.loadTask('save-me');
      expect(loaded, isNotNull);
      expect(loaded!.receivedBytes, 123);
      expect(loaded.status, DownloadStatus.paused);
      expect(loaded.links.single.url.toString(), 'https://x/save-me');

      await repo.deleteTask('save-me');
      expect(await repo.loadTask('save-me'), isNull);
    });

    test('historique : plus récent en tête', () async {
      await repo.addHistoryEntry(DownloadHistoryEntry(
          taskId: 'old',
          title: 'Ancien',
          format: BookFormat.epub,
          filePath: '/x',
          fileSizeBytes: 1,
          md5Verified: true,
          completedAt: DateTime(2024)));
      await repo.addHistoryEntry(DownloadHistoryEntry(
          taskId: 'new',
          title: 'Récent',
          format: BookFormat.pdf,
          filePath: '/y',
          fileSizeBytes: 2,
          md5Verified: false,
          completedAt: DateTime(2025)));

      final history = await repo.loadHistory();
      expect(history.first.taskId, 'new');
      expect(history.last.taskId, 'old');
    });
  });
}
