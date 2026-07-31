import 'dart:io';

import 'package:lesung/features/reader/data/epub/epub_reader.dart';
import 'package:lesung/features/reader/domain/reader_contract.dart';
import 'package:test/test.dart';

import 'helpers/reader_fixtures.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('lesung_epub_'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('ouvre un EPUB : métadonnées, spine, toc imbriquée', () async {
    final file = await buildTestEpub(dir);
    final reader = EpubReader();
    await reader.open(file);

    expect(reader.format, ReaderFormat.epub);
    expect(reader.title, 'Die Verwandlung');
    expect(reader.author, 'Franz Kafka');
    expect(reader.unitCount, 3);

    final toc = reader.tableOfContents;
    expect(toc, hasLength(2));
    expect(toc[0].title, 'Kapitel 1');
    expect(toc[0].unitIndex, 0);
    expect(toc[0].children.single.title, 'Abschnitt 1.1');
    expect(toc[0].children.single.unitIndex, 1);
    expect(toc[1].title, 'Kapitel 2');
    expect(toc[1].unitIndex, 2);
    expect(toc[1].fragment, 'ende');
  });

  test('loadUnit retourne le HTML, unitText le texte brut (avec cache)',
      () async {
    final file = await buildTestEpub(dir);
    final reader = EpubReader();
    await reader.open(file);

    final content = await reader.loadUnit(0);
    expect(content.type, ReaderContentType.html);
    expect(content.html, contains('<h1>Kapitel 1</h1>'));

    final text = await reader.unitText(0);
    expect(text, contains('Müller ging'));
    expect(text, isNot(contains('<h1>'))); // balises retirées

    // Deuxième appel : même référence (cache).
    final cached = await reader.unitText(0);
    expect(identical(text, cached), isTrue);
  });

  test('positionFor : locator, progression, titre de chapitre', () async {
    final file = await buildTestEpub(dir);
    final reader = EpubReader();
    await reader.open(file);

    final p0 = reader.positionFor(0);
    expect(p0.locator, 'epub:u0');
    expect(p0.progress, 0);
    expect(p0.chapterTitle, 'Kapitel 1');

    final p1 = reader.positionFor(1, offsetRatio: 0.5);
    expect(p1.progress, closeTo((1 + 0.5) / 3, 1e-9));

    final p2 = reader.positionFor(2);
    expect(p2.chapterTitle, 'Kapitel 2');
    expect(() => reader.positionFor(3), throwsRangeError);
  });

  test('erreurs explicites sur fichiers invalides', () async {
    final missing = EpubReader();
    expect(() => missing.open(File('${dir.path}/nope.epub')),
        throwsA(isA<ReaderOpenException>()));

    final notZip = File('${dir.path}/fake.epub');
    await notZip.writeAsString('pas un zip');
    expect(() => EpubReader().open(notZip),
        throwsA(isA<ReaderOpenException>()));

    // ZIP valide mais sans container.xml.
    final empty = File('${dir.path}/empty.epub');
    await empty.writeAsBytes(
        ZipEncoderShim.emptyZip());
    expect(() => EpubReader().open(empty),
        throwsA(isA<ReaderOpenException>()));
  });
}

/// Petit utilitaire pour produire un ZIP vide.
class ZipEncoderShim {
  static List<int> emptyZip() {
    // ZIP minimal : fin de central directory uniquement.
    return [0x50, 0x4B, 0x05, 0x06, ...List.filled(18, 0)];
  }
}
