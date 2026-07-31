import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:lesung/features/downloads/data/download_verifier.dart';
import 'package:lesung/features/downloads/domain/entities/download_task.dart';
import 'package:lesung/features/search/domain/entities/download_link.dart';

void main() {
  late Directory dir;
  final verifier = DownloadVerifier();

  setUp(() async => dir = await Directory.systemTemp.createTemp('verifier'));
  tearDown(() async => dir.delete(recursive: true));

  Future<File> write(List<int> bytes) async {
    final f = File('${dir.path}/book.bin');
    await f.writeAsBytes(bytes);
    return f;
  }

  DownloadTask task({String? md5, int? size}) => DownloadTask(
        id: 't1',
        title: 'T',
        links: [DownloadLink(url: Uri.parse('https://x/f'), kind: DownloadLinkKind.direct)],
        expectedMd5: md5,
        expectedSizeBytes: size,
      );

  test('epub valide (PK) + md5 correct -> passed', () async {
    final content = [0x50, 0x4B, 0x03, 0x04, ...utf8.encode('epub content')];
    final file = await write(content);
    final result = await verifier.verify(
        file, task(md5: md5.convert(content).toString()));
    expect(result.passed, isTrue);
    expect(result.detectedSignature, 'zip/epub');
  });

  test('pdf valide (%PDF) -> passed', () async {
    final file = await write(utf8.encode('%PDF-1.7 ...'));
    final result = await verifier.verify(file, task());
    expect(result.passed, isTrue);
    expect(result.detectedSignature, 'pdf');
  });

  test('md5 incorrect -> échec explicite', () async {
    final file = await write([0x50, 0x4B, 0x03, 0x04, 1, 2, 3]);
    final result = await verifier.verify(file, task(md5: 'deadbeef' * 4));
    expect(result.passed, isFalse);
    expect(result.failureReason, contains('MD5'));
  });

  test('page HTML au lieu d\'un livre -> mismatch', () async {
    final file = await write(utf8.encode('<html>403</html>'));
    final result = await verifier.verify(file, task());
    expect(result.passed, isFalse);
    expect(result.failureReason, contains('Signature'));
  });

  test('taille annoncée non respectée -> échec', () async {
    final file = await write([0x50, 0x4B, 0x03, 0x04, 1]);
    final result = await verifier.verify(file, task(size: 999));
    expect(result.passed, isFalse);
    expect(result.failureReason, contains('Taille'));
  });

  test('fichier vide -> échec', () async {
    final file = await write([]);
    expect((await verifier.verify(file, task())).passed, isFalse);
  });
}
