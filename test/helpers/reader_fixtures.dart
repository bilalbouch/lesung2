/// Fabrique de fichiers de test pour le Reader :
/// - EPUB réel (ZIP avec container/OPF/NCX/3 chapitres XHTML)
/// - PDF minimal mais structurellement valide (catalogue, arbre de
///   pages volontairement désordonné, flux texte, outlines)
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

/// Construit un EPUB de 3 chapitres avec TOC imbriquée.
Future<File> buildTestEpub(Directory dir, {String name = 'test.epub'}) async {
  String xhtml(String title, String body) => '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>$title</title></head>
<body><h1>$title</h1><p>$body</p></body>
</html>''';

  final files = <String, String>{
    'META-INF/container.xml': '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''',
    'OEBPS/content.opf': '''<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Die Verwandlung</dc:title>
    <dc:creator>Franz Kafka</dc:creator>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch3" href="ch3.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>
    <itemref idref="ch3"/>
  </spine>
</package>''',
    'OEBPS/toc.ncx': '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="n1" playOrder="1">
      <navLabel><text>Kapitel 1</text></navLabel>
      <content src="ch1.xhtml"/>
      <navPoint id="n1a" playOrder="2">
        <navLabel><text>Abschnitt 1.1</text></navLabel>
        <content src="ch2.xhtml"/>
      </navPoint>
    </navPoint>
    <navPoint id="n2" playOrder="3">
      <navLabel><text>Kapitel 2</text></navLabel>
      <content src="ch3.xhtml#ende"/>
    </navPoint>
  </navMap>
</ncx>''',
    'OEBPS/ch1.xhtml':
        xhtml('Kapitel 1', 'Müller ging an einem sonnigen Morgen nach Hause.'),
    'OEBPS/ch2.xhtml':
        xhtml('Abschnitt 1.1', 'Zweites Kapitel über Kafka und die Stadt.'),
    'OEBPS/ch3.xhtml':
        xhtml('Kapitel 2', 'Drittes Kapitel. Das Ende der Geschichte.'),
  };

  final archive = Archive();
  files.forEach((path, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  });
  final zipBytes = ZipEncoder().encode(archive)!;
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(zipBytes);
  return file;
}

/// Construit un PDF avec 3 pages (ordre voulu : objets 5, 3, 7),
/// texte extractible sur pages 0 et 1, page 2 sans texte, et une
/// outline à deux entrées.
Future<File> buildTestPdf(Directory dir, {String name = 'test.pdf'}) async {
  String contentStream(String textOps) => 'BT $textOps ET';

  final objects = <int, String>{
    1: '<< /Type /Catalog /Pages 2 0 R /Outlines 8 0 R >>',
    2: '<< /Type /Pages /Kids [5 0 R 3 0 R 7 0 R] /Count 3 >>',
    // Page 2 du livre (objet 3), texte Kafka.
    3: '<< /Type /Page /Parent 2 0 R /Contents 4 0 R >>',
    4: '<< /Length 0 >>\nstream\n${contentStream('(Kafka wrote Die Verwandlung) Tj')}\nendstream',
    // Page 1 du livre (objet 5), texte Hello.
    5: '<< /Type /Page /Parent 2 0 R /Contents 6 0 R >>',
    6: '<< /Length 0 >>\nstream\n${contentStream('(Hello world page one) Tj')}\nendstream',
    // Page 3 du livre (objet 7), sans texte extractible.
    7: '<< /Type /Page /Parent 2 0 R /Contents 10 0 R >>',
    10: '<< /Length 0 >>\nstream\n${contentStream('')}\nendstream',
    // Outline : Start -> page 5 (index 0), Middle -> page 3 (index 1).
    8: '<< /Type /Outlines /First 9 0 R /Last 9 0 R /Count 2 >>',
    9: '<< /Title (Start) /Parent 8 0 R /Next 11 0 R /Dest [5 0 R /XYZ 0 0 0] >>',
    11: '<< /Title (Middle) /Parent 8 0 R /Dest [3 0 R /XYZ 0 0 0] >>',
  };

  final buffer = StringBuffer('%PDF-1.4\n');
  // Ordre d'écriture volontairement non trié pour tester le parseur.
  for (final num in [1, 3, 4, 2, 5, 6, 7, 10, 8, 9, 11]) {
    buffer.write('$num 0 obj\n${objects[num]}\nendobj\n');
  }
  buffer.write('trailer\n<< /Root 1 0 R >>\n%%EOF\n');

  final file = File('${dir.path}/$name');
  await file.writeAsBytes(latin1.encode(buffer.toString()));
  return file;
}
