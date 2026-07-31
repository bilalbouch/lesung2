import 'dart:io';

import 'package:lesung/features/reader/data/pdf/pdf_reader.dart';
import 'package:lesung/features/reader/domain/reader_contract.dart';
import 'package:lesung/features/reader/domain/reader_search.dart';
import 'package:test/test.dart';

import 'helpers/reader_fixtures.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('lesung_pdf_'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('ouvre un PDF : nombre de pages dans le bon ordre', () async {
    final file = await buildTestPdf(dir);
    final reader = PdfReader();
    await reader.open(file);

    expect(reader.format, ReaderFormat.pdf);
    expect(reader.unitCount, 3);
    // L'ordre de lecture vient de /Kids [5 3 7], pas des numéros d'objets.
    expect(await reader.unitText(0), contains('Hello world'));
    expect(await reader.unitText(1), contains('Kafka wrote'));
    expect(await reader.unitText(2), isNull); // pas de texte extractible
  });

  test('table des matières depuis les outlines', () async {
    final file = await buildTestPdf(dir);
    final reader = PdfReader();
    await reader.open(file);

    final toc = reader.tableOfContents;
    expect(toc, hasLength(2));
    expect(toc[0].title, 'Start');
    expect(toc[0].unitIndex, 0);
    expect(toc[1].title, 'Middle');
    expect(toc[1].unitIndex, 1);
  });

  test('loadUnit décrit une page, positionFor calcule la progression',
      () async {
    final file = await buildTestPdf(dir);
    final reader = PdfReader();
    await reader.open(file);

    final content = await reader.loadUnit(1);
    expect(content.type, ReaderContentType.pdfPage);
    expect(content.pageNumber, 1);

    final pos = reader.positionFor(1, offsetRatio: 0.5);
    expect(pos.locator, 'pdf:p1');
    expect(pos.progress, closeTo(1.5 / 3, 1e-9));
    expect(pos.chapterTitle, 'Middle');

    expect(() => reader.loadUnit(3), throwsRangeError);
  });

  test('recherche dans le livre ignore les pages sans texte', () async {
    final file = await buildTestPdf(dir);
    final reader = PdfReader();
    await reader.open(file);

    final hits = await ReaderSearch(reader).search('verwandlung');
    expect(hits, hasLength(1));
    expect(hits.single.unitIndex, 1);
    expect(hits.single.snippet, contains('Verwandlung'));
  });

  test('fichier non-PDF refusé explicitement', () async {
    final bad = File('${dir.path}/bad.pdf');
    await bad.writeAsString('definitively not a pdf');
    expect(() => PdfReader().open(bad),
        throwsA(isA<ReaderOpenException>()));
  });
}
