import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:lesung/core/cancellation/cancellation_token.dart';
import 'package:lesung/features/downloads/data/download_storage.dart';
import 'package:lesung/features/downloads/data/download_worker.dart';
import 'package:lesung/features/downloads/domain/entities/download_task.dart';
import 'package:lesung/features/search/domain/entities/download_link.dart';
import 'package:lesung/features/search/domain/entities/search_query.dart';

/// Contenu simulant un epub (signature PK).
List<int> fakeBook([int size = 10000]) =>
    [0x50, 0x4B, 0x03, 0x04, ...List.filled(size - 4, 7)];

void main() {
  late Directory dir;
  late DownloadStorage storage;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('worker_test');
    storage = DownloadStorage(booksDirectory: dir);
    await storage.initialize();
  });
  tearDown(() async => dir.delete(recursive: true));

  DownloadTask task(List<DownloadLink> links, {String? md5, int? size}) =>
      DownloadTask(
        id: 'task-${DateTime.now().microsecondsSinceEpoch}',
        title: 'Livre Test',
        format: BookFormat.epub,
        links: links,
        expectedMd5: md5,
        expectedSizeBytes: size,
      );

  DownloadLink direct(String host) => DownloadLink(
      url: Uri.parse('https://$host/book.epub'),
      kind: DownloadLinkKind.direct);

  group('téléchargement nominal', () {
    test('complète, vérifie MD5 et finalise le fichier', () async {
      final content = fakeBook();
      final mock = MockClient.streaming((request, _) async =>
          http.StreamedResponse(Stream.value(content), 200,
              contentLength: content.length));

      final worker = DownloadWorker(httpClient: mock, storage: storage);
      final t = task([direct('mirror.test')],
          md5: md5.convert(content).toString());

      final result =
          await worker.run(t, controlToken: CancellationToken(), pauseSignal: () => false);

      expect(result.status, DownloadStatus.completed);
      expect(result.activeUrl.toString(), 'https://mirror.test/book.epub');
      final finalFile = storage.finalFileFor(t);
      expect(await finalFile.exists(), isTrue);
      expect(await finalFile.length(), content.length);
    });

    test('émet la progression avec le statut downloading', () async {
      final content = fakeBook(3000);
      final mock = MockClient.streaming((request, _) async {
        // 3 chunks pour observer plusieurs émissions.
        return http.StreamedResponse(
            Stream.fromIterable([
              content.sublist(0, 1000),
              content.sublist(1000, 2000),
              content.sublist(2000),
            ]),
            200,
            contentLength: content.length);
      });

      final worker = DownloadWorker(
          httpClient: mock,
          storage: storage,
          progressInterval: Duration.zero);
      final events = <DownloadProgress>[];
      worker.onProgress = events.add;

      await worker.run(task([direct('m.test')]),
          controlToken: CancellationToken(), pauseSignal: () => false);

      expect(events.any((e) => e.status == DownloadStatus.downloading),
          isTrue);
      final last = events.lastWhere((e) => e.status == DownloadStatus.completed);
      expect(last.progress, 1.0);
    });
  });

  group('reprise HTTP Range', () {
    test('reprend là où le partiel s\'est arrêté (206)', () async {
      final content = fakeBook();
      const alreadyHave = 4000;
      String? seenRange;

      final mock = MockClient.streaming((request, _) async {
        seenRange = request.headers['range'];
        final rest = content.sublist(alreadyHave);
        return http.StreamedResponse(Stream.value(rest), 206,
            contentLength: rest.length);
      });

      // Partiel pré-existant.
      final worker = DownloadWorker(httpClient: mock, storage: storage);
      final t = task([direct('m.test')], md5: md5.convert(content).toString());
      await storage
          .partialFileFor(t)
          .writeAsBytes(content.sublist(0, alreadyHave));

      final result = await worker.run(t,
          controlToken: CancellationToken(), pauseSignal: () => false);

      expect(seenRange, 'bytes=$alreadyHave-');
      expect(result.status, DownloadStatus.completed);
      expect(await storage.finalFileFor(t).length(), content.length);
    });

    test('416 Range -> partiel considéré complet, vérification directe',
        () async {
      final content = fakeBook();
      final mock = MockClient.streaming((request, _) async =>
          http.StreamedResponse(const Stream.empty(), 416));

      final worker = DownloadWorker(httpClient: mock, storage: storage);
      final t = task([direct('m.test')], md5: md5.convert(content).toString());
      await storage.partialFileFor(t).writeAsBytes(content);

      final result = await worker.run(t,
          controlToken: CancellationToken(), pauseSignal: () => false);
      expect(result.status, DownloadStatus.completed);
    });

    test('serveur sans Range (200) -> reprise à zéro propre', () async {
      final content = fakeBook();
      final mock = MockClient.streaming((request, _) async =>
          http.StreamedResponse(Stream.value(content), 200,
              contentLength: content.length));

      final worker = DownloadWorker(httpClient: mock, storage: storage);
      final t = task([direct('m.test')], md5: md5.convert(content).toString());
      // Partiel obsolète de 2000 octets : doit être écrasé.
      await storage.partialFileFor(t).writeAsBytes(List.filled(2000, 0));

      final result = await worker.run(t,
          controlToken: CancellationToken(), pauseSignal: () => false);
      expect(result.status, DownloadStatus.completed);
      expect(await storage.finalFileFor(t).length(), content.length);
    });
  });

  group('failover multi-miroirs', () {
    test('miroir 1 en panne -> miroir 2 utilisé', () async {
      final content = fakeBook();
      final mock = MockClient.streaming((request, _) async {
        if (request.url.host == 'dead.test') {
          return http.StreamedResponse(const Stream.empty(), 500);
        }
        return http.StreamedResponse(Stream.value(content), 200,
            contentLength: content.length);
      });

      final worker = DownloadWorker(httpClient: mock, storage: storage);
      final result = await worker.run(
          task([direct('dead.test'), direct('alive.test')]),
          controlToken: CancellationToken(),
          pauseSignal: () => false);

      expect(result.status, DownloadStatus.completed);
      expect(result.activeUrl!.host, 'alive.test');
    });

    test('checksum invalide sur tous les miroirs -> failed', () async {
      final mock = MockClient.streaming((request, _) async =>
          http.StreamedResponse(Stream.value(fakeBook()), 200));

      final worker = DownloadWorker(httpClient: mock, storage: storage);
      final result = await worker.run(
          task([direct('a.test'), direct('b.test')], md5: 'f' * 32),
          controlToken: CancellationToken(),
          pauseSignal: () => false);

      expect(result.status, DownloadStatus.failed);
      expect(result.errorMessage, contains('MD5'));
    });
  });

  group('pause / annulation', () {
    test('pause en cours de flux -> paused, partiel conservé', () async {
      var chunksSent = 0;
      final mock = MockClient.streaming((request, _) async {
        final controller = StreamController<List<int>>();
        () async {
          for (var i = 0; i < 10; i++) {
            chunksSent++;
            controller.add(fakeBook(1000));
            await Future.delayed(const Duration(milliseconds: 20));
          }
          await controller.close();
        }();
        return http.StreamedResponse(controller.stream, 200,
            contentLength: 10000);
      });

      var paused = false;
      final worker = DownloadWorker(httpClient: mock, storage: storage);
      final t = task([direct('m.test')]);

      final future = worker.run(t,
          controlToken: CancellationToken(), pauseSignal: () => paused);
      await Future.delayed(const Duration(milliseconds: 60));
      paused = true;

      final result = await future;
      expect(result.status, DownloadStatus.paused);
      expect(await storage.partialFileFor(t).length(), greaterThan(0));
      expect(chunksSent, lessThan(10));
    });

    test('annulation -> cancelled, partiel supprimé', () async {
      final mock = MockClient.streaming((request, _) async {
        final controller = StreamController<List<int>>();
        () async {
          for (var i = 0; i < 10; i++) {
            controller.add(fakeBook(1000));
            await Future.delayed(const Duration(milliseconds: 20));
          }
          await controller.close();
        }();
        return http.StreamedResponse(controller.stream, 200,
            contentLength: 10000);
      });

      final token = CancellationToken();
      final worker = DownloadWorker(httpClient: mock, storage: storage);
      final t = task([direct('m.test')]);

      final future = worker.run(t,
          controlToken: token, pauseSignal: () => false);
      await Future.delayed(const Duration(milliseconds: 60));
      token.cancel();

      final result = await future;
      expect(result.status, DownloadStatus.cancelled);
      expect(await storage.partialFileFor(t).exists(), isFalse);
    });
  });
}
