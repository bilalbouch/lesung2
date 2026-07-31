import 'dart:io';

import 'package:lesung/features/reader/data/json_reader_repository.dart';
import 'package:lesung/features/reader/domain/reader_annotations.dart';
import 'package:lesung/features/reader/domain/reader_bookmarks.dart';
import 'package:lesung/features/reader/domain/reader_contract.dart';
import 'package:lesung/features/reader/domain/reader_settings.dart';
import 'package:lesung/features/reader/domain/reader_statistics.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late JsonReaderRepository repo;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('lesung_reader_repo_');
    repo = JsonReaderRepository(dir);
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  const pos = ReaderPosition(
      locator: 'epub:u2', unitIndex: 2, progress: 0.5, chapterTitle: 'Ch2');

  test('réglages : défaut puis persistés entre deux instances', () async {
    expect((await repo.loadSettings()).fontSize, 18);
    await repo
        .saveSettings(const ReaderSettings().copyWith(themeId: 'night'));
    final second = JsonReaderRepository(dir);
    expect((await second.loadSettings()).themeId, 'night');
  });

  test('position mémorisée : sauvegarde, lecture, effacement', () async {
    expect(await repo.loadPosition('b1'), isNull);
    await repo.savePosition('b1', pos);
    final second = JsonReaderRepository(dir);
    final restored = (await second.loadPosition('b1'))!;
    expect(restored.locator, 'epub:u2');
    expect(restored.progress, 0.5);
    expect(restored.chapterTitle, 'Ch2');
    await second.clearPosition('b1');
    expect(await second.loadPosition('b1'), isNull);
  });

  test('signets : triés par unité, upsert, suppression', () async {
    ReaderBookmark bm(String id, int unit) => ReaderBookmark(
        id: id,
        bookId: 'b1',
        locator: 'epub:u$unit',
        unitIndex: unit,
        createdAt: DateTime(2026));
    await repo.saveBookmark(bm('x', 5));
    await repo.saveBookmark(bm('y', 1));
    await repo.saveBookmark(bm('x', 3)); // upsert : même id

    final list = await repo.loadBookmarks('b1');
    expect(list.map((b) => b.id), ['y', 'x']);
    expect(list.last.unitIndex, 3);

    final second = JsonReaderRepository(dir);
    expect((await second.loadBookmarks('b1')), hasLength(2));

    await repo.removeBookmark('b1', 'x');
    expect((await repo.loadBookmarks('b1')).single.id, 'y');
    expect(await repo.loadBookmarks('inconnu'), isEmpty);
  });

  test('annotations : couleur/note persistées, suppression', () async {
    final annotation = ReaderAnnotation(
      id: 'a1',
      bookId: 'b1',
      locator: 'epub:u1',
      unitIndex: 1,
      selectedText: 'Müller ging',
      note: 'Wichtig!',
      color: 0xFFA8C6E8,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await repo.saveAnnotation(annotation);
    final second = JsonReaderRepository(dir);
    final restored = (await second.loadAnnotations('b1')).single;
    expect(restored.note, 'Wichtig!');
    expect(restored.color, 0xFFA8C6E8);

    await second.removeAnnotation('b1', 'a1');
    expect(await second.loadAnnotations('b1'), isEmpty);
  });

  test('statistiques par livre : cumul sessions + progression max', () async {
    var stats = ReaderBookStats(
        bookId: 'b1',
        firstOpenedAt: DateTime(2026, 1),
        lastOpenedAt: DateTime(2026, 1));
    stats = stats.recordSession(
        durationSeconds: 120, at: DateTime(2026, 1, 2), progress: 0.3);
    stats = stats.recordSession(
        durationSeconds: 60, at: DateTime(2026, 1, 3), progress: 0.2);
    stats = stats.updateProgress(0.7, DateTime(2026, 1, 4));
    await repo.saveBookStats(stats);

    final second = JsonReaderRepository(dir);
    final restored = (await second.loadBookStats('b1'))!;
    expect(restored.totalSeconds, 180);
    expect(restored.sessionsCount, 2);
    expect(restored.furthestProgress, 0.7);
    expect(restored.firstOpenedAt, DateTime(2026, 1));
    expect((await second.loadAllBookStats()), hasLength(1));
  });

  test('historique de navigation persisté', () async {
    await repo.saveNavigationHistory('b1', ['epub:u0', 'epub:u2']);
    final second = JsonReaderRepository(dir);
    expect(await second.loadNavigationHistory('b1'), ['epub:u0', 'epub:u2']);
    expect(await second.loadNavigationHistory('inconnu'), isEmpty);
  });

  test('fichier corrompu supprimé, repart à zéro', () async {
    await File('${dir.path}/positions.json').writeAsString('{nope');
    expect(await repo.loadPosition('b1'), isNull);
    expect(File('${dir.path}/positions.json').existsSync(), isFalse);
  });
}
