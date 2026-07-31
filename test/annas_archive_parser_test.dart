import 'dart:io';
import 'package:test/test.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_parser.dart';

String fixture(String name) =>
    File('test/fixtures/$name').readAsStringSync();

void main() {
  final parser = AnnaArchiveParser();

  group('parseSearchPage', () {
    test('extrait titre, auteur, éditeur, md5, infos brutes', () {
      final page = parser.parseSearchPage(fixture('aa_search.html'));

      expect(page.hits, hasLength(3));

      final kafka = page.hits[0];
      expect(kafka.title, 'Die Verwandlung');
      expect(kafka.author, 'Franz Kafka');
      expect(kafka.publisher, 'Suhrkamp Verlag');
      expect(kafka.md5, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
      expect(kafka.detailPath, '/md5/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
      expect(kafka.infoLine, contains('epub'));
      expect(kafka.languageHint, 'de');
      expect(kafka.yearHint, 1915);

      final hugo = page.hits[1];
      expect(hugo.languageHint, 'fr');
      expect(hugo.yearHint, 1862);
      expect(hugo.infoLine, contains('pdf'));
    });

    test('détecte la page suivante', () {
      final page1 = parser.parseSearchPage(fixture('aa_search.html'),
          currentPage: 1);
      expect(page1.hasNextPage, isTrue);
      final page2 = parser.parseSearchPage(fixture('aa_search.html'),
          currentPage: 2);
      expect(page2.hasNextPage, isFalse);
    });

    test('ne dépend pas des classes CSS Tailwind (structurel)', () {
      // Même contenu, classes différentes : le parsing doit survivre.
      const html = '''
      <div class="xyz">
        <a href="/md5/dddddddddddddddddddddddddddddddd">Titre Test</a>
        <div>Auteur Test</div>
        <div>German [de] · epub · 2 MB · 2001</div>
      </div>''';
      final page = parser.parseSearchPage(html);
      expect(page.hits, hasLength(1));
      expect(page.hits.single.title, 'Titre Test');
      expect(page.hits.single.md5, 'dddddddddddddddddddddddddddddddd');
    });

    test('page vide -> aucun hit', () {
      expect(parser.parseSearchPage('<html><body></body></html>').hits,
          isEmpty);
    });
  });

  group('parseDetailPage', () {
    test('extrait synopsis, isbn et liens slow_download', () {
      final raw = parser.parseDetailPage(fixture('aa_detail.html'));

      expect(raw.synopsis, contains('Franz Kafka'));
      expect(raw.isbn, '9783150098148');
      expect(raw.slowDownloadPaths, hasLength(2));
      expect(raw.slowDownloadPaths.first,
          '/slow_download/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/0/0');
    });
  });

  group('isCloudflareChallenge', () {
    test('détecte un vrai challenge (statut + corps + en-tête)', () {
      expect(
          parser.isCloudflareChallenge(403, {}, fixture('aa_cloudflare.html')),
          isTrue);
      expect(
          parser.isCloudflareChallenge(
              200, {'cf-mitigated': 'challenge'}, '<html></html>'),
          isTrue);
    });

    test('ne confond pas une page normale', () {
      expect(parser.isCloudflareChallenge(200, {}, fixture('aa_search.html')),
          isFalse);
      expect(parser.isCloudflareChallenge(403, {}, '<html>Forbidden</html>'),
          isFalse);
    });
  });
}
