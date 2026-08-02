import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesung/core/events/event_bus.dart';
import 'package:lesung/features/downloads/data/download_manager.dart';
import 'package:lesung/features/downloads/presentation/downloads_controller.dart';
import 'package:lesung/features/library/domain/library_manager.dart';
import 'package:lesung/features/library/presentation/library_controller.dart';
import 'package:lesung/features/reader/domain/reader_manager.dart';
import 'package:lesung/features/reader/domain/reader_repository.dart';
import 'package:lesung/features/search/presentation/search_controller.dart';
import 'package:lesung/features/sources/domain/source_registry.dart';

import 'engine_factory.dart';

/// Moteur applicatif assemblé selon les capacités de la plateforme.
class Engine {
  final EventBus eventBus;
  final SearchController search;
  final LibraryManager libraryManager;
  final LibraryController library;
  final DownloadManager? downloadManager;
  final DownloadsController? downloads;
  final ReaderRepository readerRepository;
  final SourceRegistry registry;

  const Engine({
    required this.eventBus,
    required this.search,
    required this.libraryManager,
    required this.library,
    required this.downloadManager,
    required this.downloads,
    required this.readerRepository,
    required this.registry,
  });

  bool get supportsManagedDownloads => downloadManager != null;

  ReaderManager createReaderManager() =>
      ReaderManager(repository: readerRepository);

  static Future<Engine> create() => createEngine();
}

/// Fourni au démarrage via override (voir main.dart).
final engineProvider = Provider<Engine>(
  (ref) => throw StateError('Engine non initialisé (splash requis).'),
);
