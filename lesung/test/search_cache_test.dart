import 'package:test/test.dart';
import 'package:lesung/features/search/data/search_cache.dart';
import 'package:lesung/features/search/data/search_repository_impl.dart';
import 'package:lesung/features/search/data/search_service.dart';
import 'package:lesung/features/search/domain/entities/book.dart';
import 'package:lesung/features/search/domain/entities/search_query.dart';
import 'package:lesung/features/search/domain/entities/search_result.dart';
import 'package:lesung/features/sources/domain/book_source.dart';
import 'package:lesung/features/sources/domain/source_registry.dart';

import 'pipeline_test.dart' show FakeSource, book;

SearchResult _result(SearchQuery query, int count) => SearchResult(
      query: query,
      items: [
        for (var i = 0; i < count; i++)
          SearchResultItem(
            book: book('Livre $i', 'Auteur', 'test'),
            score: 50,
            scoreBreakdown: const {},
          ),
      ],
      sourceReports: const [],
      hasMore: false,
    );

void main() {
  group('SearchCache', () {
    test('get retourne null hors cache, puis le résultat après put', () {
      final cache = SearchCache();
      const query = SearchQuery(text: 'kafka');
      expect(cache.get(query), isNull);

      final result = _result(query, 3);
      cache.put(query, result);
      expect(cache.get(query), same(result));
    });

    test('la clé distingue texte, langue, format, page et tri', () {
      final cache = SearchCache();
      const base = SearchQuery(text: 'kafka');
      cache.put(base, _result(base, 1));

      // Chaque variante est une entrée DISTINCTE (miss).
      expect(cache.get(const SearchQuery(text: 'kafka')), isNotNull,
          reason:
              'même requête (égalité structurelle de SearchQuery)');
      expect(
          cache.get(const SearchQuery(text: 'kafka', language: 'de')),
          isNull,
          reason: 'langue différente');
      expect(
          cache.get(
              const SearchQuery(text: 'kafka', format: BookFormat.epub)),
          isNull,
          reason: 'format différent');
      expect(cache.get(const SearchQuery(text: 'kafka', page: 2)), isNull,
          reason: 'page différente');
      expect(
          cache.get(const SearchQuery(
              text: 'kafka', sort: SearchSort.newest)),
          isNull,
          reason: 'tri différent');
    });

    test('expiration automatique après le ttl', () {
      var now = DateTime(2026, 1, 1, 12);
      final cache = SearchCache(
          ttl: const Duration(minutes: 5), clock: () => now);
      const query = SearchQuery(text: 'kafka');
      cache.put(query, _result(query, 1));
      expect(cache.get(query), isNotNull);

      now = now.add(const Duration(minutes: 6));
      expect(cache.get(query), isNull,
          reason: 'entrée expirée => invalidée');
      expect(cache.size, 0, reason: 'entrée expirée supprimée à la lecture');
    });

    test('put balaye les entrées expirées', () {
      var now = DateTime(2026, 1, 1, 12);
      final cache = SearchCache(
          ttl: const Duration(minutes: 1), clock: () => now);
      cache.put(const SearchQuery(text: 'a'), _result(const SearchQuery(text: 'a'), 1));
      now = now.add(const Duration(minutes: 2));
      cache.put(const SearchQuery(text: 'b'), _result(const SearchQuery(text: 'b'), 1));
      expect(cache.size, 1, reason: 'l’entrée expirée a été balayée');
      expect(cache.get(const SearchQuery(text: 'b')), isNotNull);
    });

    test('éviction des plus anciennes au-delà de maxEntries', () {
      final cache = SearchCache(maxEntries: 3);
      for (var i = 1; i <= 4; i++) {
        final q = SearchQuery(text: 'q$i');
        cache.put(q, _result(q, 1));
      }
      expect(cache.size, 3);
      expect(cache.get(const SearchQuery(text: 'q1')), isNull,
          reason: 'la plus ancienne est évincée');
      expect(cache.get(const SearchQuery(text: 'q4')), isNotNull);
    });

    test('invalidate vide tout le cache', () {
      final cache = SearchCache();
      const query = SearchQuery(text: 'kafka');
      cache.put(query, _result(query, 1));
      cache.invalidate();
      expect(cache.size, 0);
      expect(cache.get(query), isNull);
    });
  });

  group('SearchRepositoryImpl + SearchCache', () {
    test('deuxième recherche identique servie sans interroger la source',
        () async {
      var calls = 0;
      final countingSource = _CountingSource(
          onSearch: () => calls++,
          books: [book('Die Verwandlung', 'Franz Kafka', 'counting', lang: 'de')]);
      final registry = SourceRegistry()..register(countingSource);
      final repo = SearchRepositoryImpl(SearchService(registry),
          cache: SearchCache());

      const query = SearchQuery(text: 'kafka');
      final first = await repo.search(query);
      final second = await repo.search(query);

      expect(calls, 1, reason: 'la deuxième requête vient du cache');
      expect(second.items, hasLength(first.items.length));
    });

    test('pages différentes interrogent réellement la source', () async {
      var calls = 0;
      final countingSource = _CountingSource(
          onSearch: () => calls++, books: const []);
      final registry = SourceRegistry()..register(countingSource);
      final repo = SearchRepositoryImpl(SearchService(registry),
          cache: SearchCache());

      await repo.search(const SearchQuery(text: 'kafka'));
      await repo.search(const SearchQuery(text: 'kafka', page: 2));
      expect(calls, 2);
    });
  });
}

/// Source factice qui compte ses appels de recherche.
class _CountingSource extends FakeSource {
  final void Function() onSearch;

  _CountingSource({required this.onSearch, required List<Book> books})
      : super('counting', books);

  @override
  Future<PagedResult<Book>> search(SearchQuery query) {
    onSearch();
    return super.search(query);
  }
}
