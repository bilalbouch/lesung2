import 'package:lesung/core/events/event_bus.dart';
import 'package:lesung/features/library/domain/library_manager.dart';
import 'package:lesung/features/library/presentation/library_controller.dart';
import 'package:lesung/features/search/data/search_cache.dart';
import 'package:lesung/features/search/data/search_repository_impl.dart';
import 'package:lesung/features/search/data/search_service.dart';
import 'package:lesung/features/search/presentation/search_controller.dart';
import 'package:lesung/features/sources/data/google_books/google_books_source.dart';
import 'package:lesung/features/sources/data/gutendex/gutendex_source.dart';
import 'package:lesung/features/sources/data/open_library/open_library_source.dart';
import 'package:lesung/features/sources/domain/source_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/preferences_library_repository.dart';
import '../storage/preferences_reader_repository.dart';
import 'engine.dart';

Future<Engine> createEngine() async {
  final preferences = await SharedPreferences.getInstance();
  final eventBus = EventBus();

  // Les sources HTTP compatibles CORS restent disponibles dans le navigateur.
  final registry = SourceRegistry()
    ..register(OpenLibrarySource())
    ..register(GutendexSource())
    ..register(GoogleBooksSource());
  final search = SearchController(
    SearchRepositoryImpl(SearchService(registry), cache: SearchCache()),
  );

  final libraryManager = LibraryManager(
    repository: PreferencesLibraryRepository(preferences),
    eventBus: eventBus,
  )..listen();
  final library = LibraryController(
    manager: libraryManager,
    eventBus: eventBus,
  );
  await library.init();

  return Engine(
    eventBus: eventBus,
    search: search,
    libraryManager: libraryManager,
    library: library,
    downloadManager: null,
    downloads: null,
    readerRepository: PreferencesReaderRepository(preferences),
    registry: registry,
  );
}
