import 'dart:io';

import 'package:lesung/features/reader/data/json_reader_repository.dart';
import 'package:lesung/features/reader/presentation/reader_controller.dart';
import 'package:lesung/features/reader/domain/reader_manager.dart';
import 'package:test/test.dart';

import 'helpers/reader_fixtures.dart';

void main() {
  late Directory dir;
  late JsonReaderRepository repo;
  late ReaderController controller;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('lesung_rc_');
    repo = JsonReaderRepository(dir);
    controller =
        ReaderController(manager: ReaderManager(repository: repo));
    await controller.init();
  });

  tearDown(() async {
    await controller.dispose();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('cycle complet : ouvrir, naviguer, rechercher, bookmark, réglages',
      () async {
    final file = await buildTestEpub(dir);

    await controller.openBook(file.path);
    expect(controller.state.status, ReaderStatus.ready);
    expect(controller.state.title, 'Die Verwandlung');
    expect(controller.state.position!.unitIndex, 0);
    expect(controller.state.tableOfContents, hasLength(2));

    // Navigation via toc + callback de position.
    controller.goToTocEntry(controller.state.tableOfContents[1]);
    expect(controller.state.position!.unitIndex, 2);
    expect(controller.state.canGoBack, isTrue);
    controller.previousChapter();
    expect(controller.state.position!.unitIndex, 1);

    // Recherche.
    await controller.searchInBook('kafka');
    expect(controller.state.searching, isFalse);
    expect(controller.state.searchResults, hasLength(1));
    controller.goToSearchHit(controller.state.searchResults.single);
    expect(controller.state.position!.unitIndex, 1);

    // Bookmark.
    await controller.toggleBookmarkAtCurrentPosition();
    expect(controller.state.bookmarks, hasLength(1));
    await controller.toggleBookmarkAtCurrentPosition(); // retire
    expect(controller.state.bookmarks, isEmpty);

    // Annotation.
    await controller.addAnnotation(selectedText: 'Stadt', note: 'N1');
    expect(controller.state.annotations.single.note, 'N1');
    await controller.updateAnnotationNote(
        controller.state.annotations.single.id, 'N2');
    expect(controller.state.annotations.single.note, 'N2');

    // Réglages.
    await controller
        .updateSettings((s) => s.copyWith(themeId: 'night', fontSize: 20));
    expect(controller.state.settings.themeId, 'night');
    expect((await repo.loadSettings()).fontSize, 20);

    // Fermeture.
    await controller.closeBook();
    expect(controller.state.status, ReaderStatus.idle);
    expect(controller.state.position, isNull);
  });

  test('erreur d\'ouverture exposée proprement', () async {
    await controller.openBook('${dir.path}/rien.epub');
    expect(controller.state.status, ReaderStatus.error);
    expect(controller.state.errorMessage, contains('ReaderOpenException'));
  });

  test('recherche périmée ignorée quand une nouvelle démarre', () async {
    final file = await buildTestEpub(dir);
    await controller.openBook(file.path);

    final first = controller.searchInBook('Kapitel');
    final second = controller.searchInBook('kafka'); // prend le relais
    await Future.wait([first, second]);

    expect(controller.state.searchResults, hasLength(1));
    expect(controller.state.searchResults.single.snippet, contains('Kafka'));
  });
}
