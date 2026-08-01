import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:lesung/features/reader/domain/reader_manager.dart';
import 'package:lesung/features/search/data/search_cache.dart';
import 'package:lesung/features/search/data/search_repository_impl.dart';
import 'package:lesung/features/search/data/search_service.dart';
import 'package:lesung/features/search/presentation/search_controller.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_instance_store.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_source.dart';
import 'package:lesung/features/sources/domain/source_registry.dart';
import 'package:path_provider/path_provider.dart';

/// Moteur applicatif — assemble les features pur-Dart derrière des
/// contrôleurs prêts pour l'UI. Créé une fois au démarrage (splash).
class Engine {
  final EventBus eventBus;
  final SearchController search;
  final LibraryManager libraryManager;
  final LibraryController library;
  final DownloadManager downloadManager;
  final DownloadsController downloads;
  final JsonReaderRepository readerRepository;
  final SourceRegistry registry;

  Engine._({
    required this.eventBus,
    required this.search,
    required this.libraryManager,
    required this.library,
    required this.downloadManager,
    required this.downloads,
    required this.readerRepository,
    required this.registry,
  });

  ReaderManager createReaderManager() =>
      ReaderManager(repository: readerRepository);

  static Future<Engine> create() async {
    final support = await getApplicationSupportDirectory();
    final documents = await getApplicationDocumentsDirectory();

    final eventBus = EventBus();

    // --- Recherche : registre de sources (Anna's Archive actif) ----
    final registry = SourceRegistry();
    final annasArchive = AnnaArchiveSource.custom(
      cache: null, // cache mémoire par défaut ; disque après choix dir
      // Classement des miroirs persisté entre sessions + retest régulier.
      instanceStore: AnnaArchiveInstanceStore(
          Directory('${support.path}/annas_archive')),
    );
    await annasArchive.initialize();
    registry.register(annasArchive);
    // Cache mémoire : ttl 5 min, invalidation automatique.
    final search = SearchController(
        SearchRepositoryImpl(SearchService(registry),
            cache: SearchCache()));

    // --- Bibliothèque ------------------------------------------------
    final booksDir = Directory('${documents.path}/books');
    final libraryManager = LibraryManager(
      repository: JsonLibraryRepository(
          Directory('${support.path}/library')),
      eventBus: eventBus,
    )..listen();
    final library =
        LibraryController(manager: libraryManager, eventBus: eventBus);
    await library.init();

    // Synchronisation bibliothèque <-> disque au démarrage.
    await LibrarySync(
            repository: libraryManager.repository,
            booksDirectory: booksDir)
        .synchronize();

    // --- Téléchargements ---------------------------------------------
    final storage = DownloadStorage(booksDirectory: booksDir);
    final downloadRepository = DownloadRepositoryImpl(
        directory: Directory('${support.path}/downloads'));
    await downloadRepository.initialize();
    final downloadManager = DownloadManager(
      worker: DownloadWorker(storage: storage),
      repository: downloadRepository,
      storage: storage,
      eventBus: eventBus,
    );
    await downloadManager.restore();
    final downloads = DownloadsController(downloadManager)..listen();

    // --- Reader --------------------------------------------------------
    final readerRepository =
        JsonReaderRepository(Directory('${support.path}/reader'));

    return Engine._(
      eventBus: eventBus,
      search: search,
      libraryManager: libraryManager,
      library: library,
      downloadManager: downloadManager,
      downloads: downloads,
      readerRepository: readerRepository,
      registry: registry,
    );
  }
}

/// Fourni au démarrage via override (voir main.dart).
final engineProvider = Provider<Engine>(
  (ref) => throw StateError('Engine non initialisé (splash requis).'),
);
