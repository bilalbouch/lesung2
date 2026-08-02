import 'dart:io';

import 'package:lesung/core/events/event_bus.dart';
import 'package:lesung/features/downloads/data/download_manager.dart';
import 'package:lesung/features/downloads/data/download_repository_impl.dart';
import 'package:lesung/features/downloads/data/download_storage.dart';
import 'package:lesung/features/downloads/data/download_worker.dart';
import 'package:lesung/features/downloads/presentation/downloads_controller.dart';
import 'package:lesung/features/library/data/json_library_repository.dart';
import 'package:lesung/features/library/data/library_sync.dart';
import 'package:lesung/features/library/domain/library_manager.dart';
import 'package:lesung/features/library/presentation/library_controller.dart';
import 'package:lesung/features/reader/data/json_reader_repository.dart';
import 'package:lesung/features/search/data/search_cache.dart';
import 'package:lesung/features/search/data/search_repository_impl.dart';
import 'package:lesung/features/search/data/search_service.dart';
import 'package:lesung/features/search/presentation/search_controller.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_instance_store.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_source.dart';
import 'package:lesung/features/sources/data/google_books/google_books_source.dart';
import 'package:lesung/features/sources/data/gutendex/gutendex_source.dart';
import 'package:lesung/features/sources/data/open_library/open_library_source.dart';
import 'package:lesung/features/sources/domain/source_registry.dart';
import 'package:path_provider/path_provider.dart';

import 'engine.dart';

Future<Engine> createEngine() async {
  final support = await getApplicationSupportDirectory();
  final documents = await getApplicationDocumentsDirectory();
  final eventBus = EventBus();

  final registry = SourceRegistry();
  final annasArchive = AnnaArchiveSource.custom(
    cache: null,
    instanceStore: AnnaArchiveInstanceStore(
      Directory('${support.path}/annas_archive'),
    ),
  );
  annasArchive.initialize().catchError((_) {});
  registry.register(annasArchive);
  registry.register(OpenLibrarySource());
  registry.register(GutendexSource());
  registry.register(GoogleBooksSource());
  final search = SearchController(
    SearchRepositoryImpl(SearchService(registry), cache: SearchCache()),
  );

  final booksDirectory = Directory('${documents.path}/books');
  final libraryManager = LibraryManager(
    repository: JsonLibraryRepository(
      Directory('${support.path}/library'),
    ),
    eventBus: eventBus,
  )..listen();
  final library = LibraryController(
    manager: libraryManager,
    eventBus: eventBus,
  );
  await library.init();
  await LibrarySync(
    repository: libraryManager.repository,
    booksDirectory: booksDirectory,
  ).synchronize();

  final storage = DownloadStorage(booksDirectory: booksDirectory);
  final downloadRepository = DownloadRepositoryImpl(
    directory: Directory('${support.path}/downloads'),
  );
  await downloadRepository.initialize();
  final downloadManager = DownloadManager(
    worker: DownloadWorker(storage: storage),
    repository: downloadRepository,
    storage: storage,
    eventBus: eventBus,
  );
  await downloadManager.restore();
  final downloads = DownloadsController(downloadManager)..listen();

  return Engine(
    eventBus: eventBus,
    search: search,
    libraryManager: libraryManager,
    library: library,
    downloadManager: downloadManager,
    downloads: downloads,
    readerRepository: JsonReaderRepository(
      Directory('${support.path}/reader'),
    ),
    registry: registry,
  );
}
