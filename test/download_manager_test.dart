import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:lesung/features/downloads/data/download_manager.dart';
import 'package:lesung/features/downloads/data/download_repository_impl.dart';
import 'package:lesung/features/downloads/data/download_storage.dart';
import 'package:lesung/features/downloads/data/download_worker.dart';
import 'package:lesung/features/downloads/domain/download_notification_service.dart';
import 'package:lesung/features/downloads/domain/entities/download_task.dart';
import 'package:lesung/features/search/domain/entities/download_link.dart';
import 'package:lesung/features/search/domain/entities/search_query.dart';

List<int> fakeBook([int size = 5000]) =>
    [0x50, 0x4B, 0x03, 0x04, ...List.filled(size - 4, 9)];

class RecordingNotifications implements DownloadNotificationService {
  final List<String> calls = [];
  @override
  Future<void> showProgress(DownloadTask task) async =>
      calls.add('progress:${task.id}');
  @override
  Future<void> showCompleted(DownloadTask task,
          {required bool verified}) async =>
      calls.add('completed:${task.id}:verified=$verified');
  @override
  Future<void> showFailed(DownloadTask task) async =>
      calls.add('failed:${task.id}');
  @override
  Future<void> cancelFor(String taskId) async => calls.add('cancel:$taskId');
  @override
  Future<void> cancelAll() async => calls.add('cancelAll');
}

void main() {
  late Directory booksDir;
  late Directory dataDir;
  late DownloadStorage storage;
  late DownloadRepositoryImpl repository;

  setUp(() async {
    booksDir = await Directory.systemTemp.createTemp('books');
    dataDir = await Directory.systemTemp.createTemp('data');
    storage = DownloadStorage(booksDirectory: booksDir);
    repository = DownloadRepositoryImpl(directory: dataDir);
    await repository.initialize();
  });
  tearDown(() async {
    await booksDir.delete(recursive: true);
    await dataDir.delete(recursive: true);
  });

  DownloadManager makeManager(http.Client httpClient,
      {RecordingNotifications? notifications, int maxConcurrent = 2}) {
    return DownloadManager(
      worker: DownloadWorker(
          httpClient: httpClient,
          storage: storage,
          progressInterval: Duration.zero),
      repository: repository,
      storage: storage,
      notifications: notifications,
      maxConcurrent: maxConcurrent,
    );
  }

  DownloadTask task(String id, {String host = 'm.test', String? md5}) =>
      DownloadTask(
        id: id,
        title: 'Livre $id',
        format: BookFormat.epub,
        links: [
          DownloadLink(
              url: Uri.parse('https://$host/$id.epub'),
              kind: DownloadLinkKind.direct)
        ],
        expectedMd5: md5,
      );

  Future<void> _waitFor(bool Function() condition,
      {Duration timeout = const Duration(seconds: 3)}) async {
    final sw = Stopwatch()..start();
    while (!condition() && sw.elapsed < timeout) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  Future<DownloadTask> awaitStatus(
      DownloadManager m, String id, DownloadStatus wanted,
      {Duration timeout = const Duration(seconds: 5)}) async {
    final sw = Stopwatch()..start();
    while (sw.elapsed < timeout) {
      final t = m.taskById(id);
      if (t != null && t.status == wanted) return t;
      await Future.delayed(const Duration(milliseconds: 25));
    }
    throw StateError('$id jamais passé en $wanted (${m.taskById(id)?.status})');
  }

  group('orchestration de bout en bout', () {
    test('enqueue -> completed + historique + notification', () async {
      final content = fakeBook();
      final mock = MockClient.streaming((_, __) async =>
          http.StreamedResponse(Stream.value(content), 200,
              contentLength: content.length));
      final notifs = RecordingNotifications();
      final manager = makeManager(mock, notifications: notifs);

      await manager
          .enqueue(task('t1', md5: md5.convert(content).toString()));
      final done = await awaitStatus(manager, 't1', DownloadStatus.completed);

      expect(done.receivedBytes, content.length);
      expect(await storage.finalFileFor(done).exists(), isTrue);

      final history = await repository.loadHistory();
      expect(history, hasLength(1));
      expect(history.single.md5Verified, isTrue);
      expect(notifs.calls.any((c) => c.startsWith('completed:t1')), isTrue);
      await manager.dispose();
    });

    test('persistance : la tâche est sauvegardée pendant le cycle', () async {
      final mock = MockClient.streaming((_, __) async =>
          http.StreamedResponse(Stream.value(fakeBook()), 200));
      final manager = makeManager(mock);
      await manager.enqueue(task('persisted'));
      // Même avant complétion, la tâche existe sur disque.
      expect(await repository.loadTask('persisted'), isNotNull);
      await awaitStatus(manager, 'persisted', DownloadStatus.completed);
      await manager.dispose();
    });

    test('échec de tous les miroirs -> failed + notification', () async {
      final mock = MockClient.streaming(
          (_, __) async => http.StreamedResponse(const Stream.empty(), 500));
      final notifs = RecordingNotifications();
      final manager = makeManager(mock, notifications: notifs);

      await manager.enqueue(task('doomed'));
      final failed = await awaitStatus(manager, 'doomed', DownloadStatus.failed);
      expect(failed.errorMessage, isNotNull);
      // La notification suit l'écriture du statut : attente active.
      await _waitFor(() =>
          notifs.calls.any((c) => c.startsWith('failed:doomed')));
      expect(notifs.calls.any((c) => c.startsWith('failed:doomed')), isTrue);
      await manager.dispose();
    });
  });

  group('file et concurrence', () {
    test('maxConcurrent borné : jamais plus de N téléchargements actifs',
        () async {
      var activeNow = 0;
      var maxSeen = 0;
      final mock = MockClient.streaming((_, __) async {
        activeNow++;
        if (activeNow > maxSeen) maxSeen = activeNow;
        final controller = StreamController<List<int>>();
        () async {
          await Future.delayed(const Duration(milliseconds: 120));
          controller.add(fakeBook());
          await controller.close();
          activeNow--;
        }();
        return http.StreamedResponse(controller.stream, 200);
      });

      final manager = makeManager(mock, maxConcurrent: 2);
      for (var i = 0; i < 5; i++) {
        await manager.enqueue(task('t$i'));
      }
      for (var i = 0; i < 5; i++) {
        await awaitStatus(manager, 't$i', DownloadStatus.completed);
      }
      expect(maxSeen, lessThanOrEqualTo(2));
      await manager.dispose();
    });

    test('retry d\'une tâche échouée repart et réussit', () async {
      var failFirst = true;
      final mock = MockClient.streaming((_, __) async {
        if (failFirst) {
          return http.StreamedResponse(const Stream.empty(), 500);
        }
        return http.StreamedResponse(Stream.value(fakeBook()), 200);
      });
      final manager = makeManager(mock);

      await manager.enqueue(task('retry-me'));
      await awaitStatus(manager, 'retry-me', DownloadStatus.failed);

      failFirst = false;
      await manager.retry('retry-me');
      final done =
          await awaitStatus(manager, 'retry-me', DownloadStatus.completed);
      expect(done.errorMessage, isNull);
      await manager.dispose();
    });

    test('annulation d\'une tâche en attente -> cancelled immédiat', () async {
      // Un slot unique + une tâche qui traîne : la seconde reste en file.
      final mock = MockClient.streaming((_, __) async {
        final controller = StreamController<List<int>>();
        () async {
          await Future.delayed(const Duration(milliseconds: 300));
          controller.add(fakeBook());
          await controller.close();
        }();
        return http.StreamedResponse(controller.stream, 200);
      });
      final manager = makeManager(mock, maxConcurrent: 1);
      await manager.enqueue(task('long'));
      await manager.enqueue(task('waiting'));

      await manager.cancel('waiting');
      expect(manager.taskById('waiting')!.status, DownloadStatus.cancelled);

      await awaitStatus(manager, 'long', DownloadStatus.completed);
      await manager.dispose();
    });
  });

  group('restauration après redémarrage', () {
    test('une tâche downloading persistée repasse en paused', () async {
      // Simule une tâche interrompue par l'arrêt de l'app.
      final interrupted = task('interrupted')
        ..status = DownloadStatus.downloading
        ..receivedBytes = 500;
      await repository.saveTask(interrupted);

      final mock = MockClient.streaming((_, __) async =>
          http.StreamedResponse(Stream.value(fakeBook()), 200));
      final manager = makeManager(mock);
      await manager.restore();

      expect(manager.taskById('interrupted')!.status,
          DownloadStatus.paused);
      await manager.dispose();
    });
  });
}
