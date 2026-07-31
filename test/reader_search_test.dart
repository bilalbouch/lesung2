import 'dart:io';

import 'package:lesung/features/reader/domain/reader_search.dart';
import 'package:test/test.dart';

import 'helpers/reader_fixtures.dart';
import 'package:lesung/features/reader/data/epub/epub_reader.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('lesung_rs_'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<ReaderSearch> openSearch() async {
    final file = await buildTestEpub(dir);
    final reader = EpubReader();
    await reader.open(file);
    return ReaderSearch(reader);
  }

  test('recherche insensible à la casse et aux diacritiques', () async {
    final search = await openSearch();
    final hits = await search.search('muller'); // trouve « Müller »
    expect(hits, hasLength(1));
    expect(hits.single.unitIndex, 0);
    expect(hits.single.snippet, contains('Müller'));

    final kafka = await search.search('KAFKA');
    expect(kafka.single.unitIndex, 1);

    expect(await search.search('inexistant'), isEmpty);
    expect(await search.search('   '), isEmpty);
  });

  test('occurrences multiples + rapport de progression', () async {
    final search = await openSearch();
    final progress = <String>[];
    final hits = await search.search('Kapitel',
        onProgress: (done, total) => progress.add('$done/$total'));
    // « Kapitel » apparaît dans les titres h1 ET les paragraphes.
    expect(hits.length, greaterThanOrEqualTo(3));
    expect(progress.last, '3/3');
  });

  test('annulation entre les unités', () async {
    final search = await openSearch();
    var calls = 0;
    final hits = await search.search('Kapitel',
        isCancelled: () => ++calls > 1); // annule après la 1re unité
    expect(hits.every((h) => h.unitIndex == 0), isTrue);
  });

  test('recherche en flux : unités émises au fil de l\'eau', () async {
    final search = await openSearch();
    final batches = await search.searchStreaming('Kapitel').toList();
    expect(batches.length, greaterThanOrEqualTo(2));
    expect(batches.expand((b) => b).length, greaterThanOrEqualTo(3));
  });
}
