/// Test d'intégration : DownloadManager --événement--> LibraryManager.
///
/// Vérifie le découplage par événements : le moteur de téléchargement ne
/// connaît pas la bibliothèque ; pourtant, un téléchargement terminé y
/// apparaît, et sa suppression la met à jour — via le bus uniquement.
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:lesung/core/events/event_bus.dart';
import 'package:lesung/features/downloads/data/download_manager.dart';
import 'package:lesung/features/downloads/data/download_repository_impl.dart';
import 'package:lesung/features/downloads/data/download_storage.dart';
import 'package:lesung/features/downloads/data/download_worker.dart';
import 'package:lesung/features/downloads/domain/entities/download_task.dart';
import 'package:lesung/features/library/data/json_library_repository.dart';
import 'package:lesung/features/library/domain/library_manager.dart';
import 'package:lesung/features/search/domain/entities/download_link.dart';
import 'package:lesung/features/search/domain/entities/search_query.dart';

void main() {
  late Directory booksDir;
  late Directory dataDir;
  late Directory libDir;
  late EventBus bus;
  late DownloadManager downloads;
  late LibraryManager library;

  setUp(() async {
    booksDir = await Directory.systemTemp.createTemp('books');
    dataDir = await Directory.systemTemp.createTemp('dl_data');
    libDir = await Directory.systemTemp.createTemp('lib_data');
    bus = EventBus();

    final storage = DownloadStorage(booksDirectory: booksDir);
    final dlRepo = DownloadRepositoryImpl(directory: dataDir);
    await dlRepo.initialize();

    final mock = MockClient.streaming((request, _) async {
      final body = [0x50, 0x4B, 0x03, 0x04, ...List.filled(996, 7)];
      return http.StreamedResponse(Stream.value(body), 200, headers: {
        'content-length': body.length.toString(),
      });
    });

    downloads = DownloadManager(
      worker: DownloadWorker(
          httpClient: mock, storage: storage, progressInterval: Duration.zero),
      repository: dlRepo,
      storage: storage,
      eventBus: bus,
    );

    library = LibraryManager(
        repository: JsonLibraryRepository(libDir), eventBus: bus)
      ..listen();
  });

  tearDown(() async {
    await library.dispose();
    await downloads.dispose();
    await bus.dispose();
    await booksDir.delete(recursive: true);
    await dataDir.delete(recursive: true);
    await libDir.delete(recursive: true);
  });

  test('téléchargement terminé => livre en bibliothèque, suppression => retrait',
      () async {
    final task = DownloadTask(
      id: 'int1',
      title: 'Die Verwandlung',
      author: 'Franz Kafka',
      format: BookFormat.epub,
      links: [
        DownloadLink(
            url: Uri.parse('https://m.test/int1.epub'),
            kind: DownloadLinkKind.direct)
      ],
    );
    await downloads.enqueue(task);

    // Attendre la complétion côté bibliothèque (preuve du passage par le bus).
    final sw = Stopwatch()..start();
    while (sw.elapsed < const Duration(seconds: 5)) {
      final b = await library.bookById('int1');
      if (b != null && b.downloaded) break;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }

    final book = (await library.bookById('int1'))!;
    expect(book.title, 'Die Verwandlung');
    expect(book.author, 'Franz Kafka');
    expect(book.downloaded, isTrue);
    expect(book.filePath, isNotNull);
    expect(File(book.filePath!).existsSync(), isTrue);
    expect((await library.downloadedBooks()).single.id, 'int1');

    // Suppression de la tâche => événement => bibliothèque mise à jour.
    await downloads.remove('int1');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final after = (await library.bookById('int1'))!;
    expect(after.downloaded, isFalse);
    expect(after.filePath, isNull);
  });
}
