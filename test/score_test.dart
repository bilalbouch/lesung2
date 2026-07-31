import 'package:test/test.dart';
import 'package:lesung/features/search/domain/entities/book.dart';
import 'package:lesung/features/search/domain/entities/search_query.dart';
import 'package:lesung/features/search/domain/pipeline/normalize.dart';
import 'package:lesung/features/search/domain/pipeline/score.dart';

Book book({
  required String title,
  String? author,
  String? language,
  BookFormat format = BookFormat.unknown,
  int? year,
  String? coverUrl,
  String? publisher,
  int? fileSizeBytes,
}) =>
    normalizeBook(Book(
      title: title,
      author: author,
      language: language,
      format: format,
      year: year,
      coverUrl: coverUrl,
      publisher: publisher,
      fileSizeBytes: fileSizeBytes,
      refs: const [SourceBookRef(sourceId: 's1', sourceBookId: 'x')],
    ));

void main() {
  const query = SearchQuery(text: 'die verwandlung');

  group('priorité des langues (charte : DE > FR > autres)', () {
    test('allemand bat français bat anglais', () {
      final items = scoreAndSortBooks([
        book(title: 'Die Verwandlung', language: 'en'),
        book(title: 'Die Verwandlung', language: 'fr'),
        book(title: 'Die Verwandlung', language: 'de'),
      ], query);

      expect(items[0].book.language, 'de');
      expect(items[1].book.language, 'fr');
      expect(items[2].book.language, 'en');
      expect(items[0].scoreBreakdown['language'], 35);
      expect(items[1].scoreBreakdown['language'], 30);
      expect(items[2].scoreBreakdown['language'], 10);
    });
  });

  group('pertinence', () {
    test('match exact du titre > match partiel > aucun', () {
      final exact = scoreAndSortBooks(
          [book(title: 'Die Verwandlung')], query).single;
      final partial = scoreAndSortBooks(
          [book(title: 'Etwas ganz anderes')], query).single;

      expect(exact.scoreBreakdown['relevance'], 25);
      expect(partial.scoreBreakdown['relevance'], 0);
      expect(exact.score, greaterThan(partial.score));
    });

    test('match auteur partiel reconnu', () {
      final item = scoreAndSortBooks(
          [book(title: 'Unbekannt', author: 'Die Verwandlung')],
          query).single;
      expect(item.scoreBreakdown['relevance'], greaterThan(0));
    });
  });

  group('format', () {
    test('epub > pdf > inconnu', () {
      final epub = scoreAndSortBooks(
          [book(title: 'T', format: BookFormat.epub)], query).single;
      final pdf = scoreAndSortBooks(
          [book(title: 'T', format: BookFormat.pdf)], query).single;
      final none = scoreAndSortBooks([book(title: 'T')], query).single;

      expect(epub.scoreBreakdown['format'], 15);
      expect(pdf.scoreBreakdown['format'], closeTo(10, 0.01));
      expect(none.scoreBreakdown['format'], 0);
    });
  });

  group('métadonnées et fraîcheur', () {
    test('métadonnées complètes = score plein', () {
      final full = scoreAndSortBooks([
        book(
            title: 'T',
            coverUrl: 'https://x',
            year: 2023,
            publisher: 'Suhrkamp',
            fileSizeBytes: 1024)
      ], query).single;
      expect(full.scoreBreakdown['metadata'], 10);
      expect(full.scoreBreakdown['recency'], 5);
    });

    test('score total borné entre 0 et 100', () {
      final items = scoreAndSortBooks([
        book(
            title: 'Die Verwandlung',
            language: 'de',
            format: BookFormat.epub,
            year: 2023,
            coverUrl: 'https://x',
            publisher: 'P',
            fileSizeBytes: 1),
      ], query);
      expect(items.single.score, lessThanOrEqualTo(100));
      expect(items.single.score, greaterThan(90),
          reason: 'un livre parfait frôle le maximum');
    });
  });

  group('tri', () {
    test('ordre décroissant par score', () {
      final items = scoreAndSortBooks([
        book(title: 'Nimporte quoi', language: 'en'),
        book(title: 'Die Verwandlung', language: 'de', format: BookFormat.epub),
        book(title: 'Die Verwandlung heute', language: 'fr'),
      ], query);
      for (var i = 0; i + 1 < items.length; i++) {
        expect(items[i].score, greaterThanOrEqualTo(items[i + 1].score));
      }
    });
  });
}
