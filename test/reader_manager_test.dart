import 'dart:io';

import 'package:lesung/features/reader/data/json_reader_repository.dart';
import 'package:lesung/features/reader/domain/reader_contract.dart';
import 'package:lesung/features/reader/domain/reader_manager.dart';
import 'package:test/test.dart';

import 'helpers/reader_fixtures.dart';

void main() {
  late Directory dir;
  late JsonReaderRepository repo;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('lesung_rm_');
    repo = JsonReaderRepository(dir);
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  ReaderManager makeManager(
          {Duration autoSave = const Duration(milliseconds: 120)}) =>
      ReaderManager(repository: repo, autoSaveInterval: autoSave);

  test('ouverture : début du livre, session active, sous-systèmes prêts',
      () async {
    final file = await buildTestEpub(dir);
    final manager = makeManager();

    final position = await manager.open(file.path);
    expect(position.unitIndex, 0);
    expect(manager.isOpen, isTrue);
    expect(manager.bookId, file.absolute.path);
    expect(manager.statistics.sessionActive, isTrue);
    expect(manager.navigation.flatToc, isNotEmpty);
    expect(manager.reader!.title, 'Die Verwandlung');

    await manager.dispose();
  });

  test('mémorisation automatique : position restaurée à la réouverture',
      () async {
    final file = await buildTestEpub(dir);

    final first = makeManager();
    await first.open(file.path);
    first.goToUnit(2, offsetRatio: 0.5);
    await first.saveNow();
    await first.dispose();

    // Nouveau manager, MÊME repository : la position est restaurée.
    final second = makeManager();
    final restored = await second.open(file.path);
    expect(restored.unitIndex, 2);
    expect(restored.offsetRatio, 0.5);
    expect(restored.locator, 'epub:u2');
    await second.dispose();
  });

  test('auto-save périodique persiste la position sans action', () async {
    final file = await buildTestEpub(dir);
    final manager = makeManager();
    await manager.open(file.path);
    manager.goToUnit(1);

    // Aucune saveNow explicite : le minuteur doit le faire.
    final bookId = manager.bookId!;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final saved = await repo.loadPosition(bookId);
    expect(saved, isNotNull);
    expect(saved!.unitIndex, 1);

    await manager.dispose();
  });

  test('fermeture : session clôturée, statistiques cumulées', () async {
    final file = await buildTestEpub(dir);
    String? closedBookId;
    int? closedSeconds;
    double? closedProgress;

    final manager = makeManager();
    manager.onSessionClosed = (bookId, seconds, progress) {
      closedBookId = bookId;
      closedSeconds = seconds;
      closedProgress = progress;
    };
    await manager.open(file.path);
    manager.goToUnit(2);
    await Future<void>.delayed(const Duration(seconds: 1));
    final bookId = manager.bookId!;
    await manager.close();

    expect(manager.isOpen, isFalse);
    expect(closedBookId, bookId);
    expect(closedSeconds, greaterThanOrEqualTo(0));
    expect(closedProgress, closeTo(2 / 3, 1e-9));

    final stats = (await repo.loadBookStats(bookId))!;
    expect(stats.sessionsCount, 1);
    expect(stats.furthestProgress, closeTo(2 / 3, 1e-9));
    expect(stats.firstOpenedAt, isNotNull);
    expect(stats.lastOpenedAt, isNotNull);
  });

  test('navigation : chapitres, retour navigateur, dernière position',
      () async {
    final file = await buildTestEpub(dir);
    final manager = makeManager();
    await manager.open(file.path);

    manager.goToNextChapter();
    expect(manager.position!.unitIndex, 1);
    manager.goToNextChapter();
    expect(manager.position!.unitIndex, 2);
    expect(manager.goToNextChapter(), isNull); // fin du livre

    manager.goToPreviousChapter();
    expect(manager.position!.unitIndex, 1);

    // Historique : 0 -> 1 -> 2 -> 1 ; retour vers 2 puis 1.
    final back = manager.goBack();
    expect(back, isNotNull);
    expect(manager.navigation.canGoBack, isTrue);

    // returnToLastPosition après navigation non sauvegardée.
    manager.goToUnit(0);
    await manager.saveNow();
    manager.goToUnit(2); // non sauvegardé
    final returned = await manager.returnToLastPosition();
    expect(returned, isNotNull);
    expect(returned!.unitIndex, 0);

    await manager.dispose();
  });

  test('signets et annotations via le manager (persistés)', () async {
    final file = await buildTestEpub(dir);
    final manager = makeManager();
    await manager.open(file.path);
    manager.goToUnit(1);
    final bookId = manager.bookId!;

    final added = await manager.bookmarks.toggle(
        id: 'bm1',
        bookId: bookId,
        locator: manager.position!.locator,
        unitIndex: 1);
    expect(added, isTrue);
    expect(manager.bookmarks.hasBookmarkAt('epub:u1'), isTrue);

    // Re-toggle : suppression.
    final removed = await manager.bookmarks.toggle(
        id: 'bm2',
        bookId: bookId,
        locator: manager.position!.locator,
        unitIndex: 1);
    expect(removed, isFalse);
    expect(manager.bookmarks.all, isEmpty);

    await manager.annotations.add(
        id: 'a1',
        bookId: bookId,
        locator: 'epub:u1',
        unitIndex: 1,
        selectedText: 'Kafka',
        note: 'Autor');
    expect(manager.annotations.forUnit(1), hasLength(1));
    await manager.annotations.changeColor('a1', 0xFFA8C6E8);
    expect(manager.annotations.all.single.color, 0xFFA8C6E8);

    // Persistance entre deux instances.
    final second = JsonReaderRepository(dir);
    expect((await second.loadBookmarks(bookId)), isEmpty);
    expect((await second.loadAnnotations(bookId)).single.note, 'Autor');

    expect(
        () => manager.annotations.add(
            id: 'a2',
            bookId: bookId,
            locator: 'l',
            unitIndex: 0,
            selectedText: '   '),
        throwsArgumentError);

    await manager.dispose();
  });

  test('format non supporté : exception claire, extension prête CBZ/CBR...',
      () async {
    final mobi = File('${dir.path}/livre.mobi');
    await mobi.writeAsString('fake mobi');
    final manager = makeManager();
    expect(() => manager.open(mobi.path),
        throwsA(isA<ReaderUnsupportedException>()));

    // Le registre est extensible : enregistrer un lecteur CBZ suffit.
    manager.registerReader(ReaderFormat.cbz, () => _FakeCbzReader());
    final cbz = File('${dir.path}/comic.cbz');
    await cbz.writeAsBytes([0x50, 0x4B, 0x03, 0x04, 0]); // en-tête ZIP
    final position = await manager.open(cbz.path);
    expect(position.unitIndex, 0);
    expect(manager.reader!.format, ReaderFormat.cbz);
    await manager.dispose();
  });

  test('onPositionChanged notifie chaque déplacement', () async {
    final file = await buildTestEpub(dir);
    final manager = makeManager();
    final seen = <String>[];
    manager.onPositionChanged = (p) => seen.add(p.locator);
    await manager.open(file.path);
    manager.goToUnit(1);
    manager.goToUnit(2);
    expect(seen, ['epub:u0', 'epub:u1', 'epub:u2']);
    await manager.dispose();
  });
}

/// Lecteur factice prouvant l'extensibilité du registre (CBZ & co.).
class _FakeCbzReader implements ReaderContract {
  @override
  ReaderFormat get format => ReaderFormat.cbz;
  @override
  Future<void> open(File file) async {}
  @override
  Future<void> close() async {}
  @override
  int get unitCount => 1;
  @override
  List<ReaderTocEntry> get tableOfContents => const [];
  @override
  String? get title => 'Comic';
  @override
  String? get author => null;
  @override
  Future<ReaderContent> loadUnit(int unitIndex) async =>
      const ReaderContent.unsupported();
  @override
  Future<String?> unitText(int unitIndex) async => null;
  @override
  ReaderPosition positionFor(int unitIndex, {double offsetRatio = 0}) =>
      ReaderPosition(
          locator: 'cbz:u$unitIndex',
          unitIndex: unitIndex,
          progress: 0);
}
