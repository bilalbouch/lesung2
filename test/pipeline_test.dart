import 'package:test/test.dart';
import 'package:lesung/features/search/domain/entities/book.dart';
import 'package:lesung/features/search/domain/entities/book_details.dart';
import 'package:lesung/features/search/domain/entities/download_link.dart';
import 'package:lesung/features/search/domain/entities/search_query.dart';
import 'package:lesung/features/search/data/search_repository_impl.dart';
import 'package:lesung/features/search/data/search_service.dart';
import 'package:lesung/features/sources/domain/book_source.dart';
import 'package:lesung/features/sources/domain/source_registry.dart';

/// Source factice configurable pour tester le pipeline sans réseau.
class FakeSource implements BookSource {
  @override
  final SourceMeta meta;
  final List<Book> books;
  final Object? failure;
  final Duration delay;
  final bool more;

  FakeSource(String id, this.books,
      {this.failure, this.delay = Duration.zero, this.more = false})
      : meta = SourceMeta(id: id, displayName: id);

  @override
  Future<PagedResult<Book>> search(SearchQuery query) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    if (failure != null) throw failure!;
    return PagedResult(items: books, hasMore: more);
  }

  @override
  Future<BookDetails> details(String id) => throw UnimplementedError();
  @override
  Future<List<DownloadLink>> resolveDownloadLinks(String id) =>
      throw UnimplementedError();
  @override
  Future<SourceHealth> healthCheck() =>
      Future.value(const SourceHealth(reachable: true));
}

Book book(String title, String author, String sourceId, {String? lang}) =>
    Book(
      title: title,
      author: author,
      language: lang,
      refs: [SourceBookRef(sourceId: sourceId, sourceBookId: 'id-$title')],
    );

SearchRepositoryImpl makeRepo(SourceRegistry registry) =>
    SearchRepositoryImpl(SearchService(registry));

void main() {
  group('SourceRegistry', () {
    test('activation/désactivation dynamique', () {
      final registry = SourceRegistry();
      registry.register(FakeSource('a', const []));
      registry.register(FakeSource('b', const []));
      expect(registry.activeCount, 2);

      registry.disable('a');
      expect(registry.activeCount, 1);
      expect(registry.activeSources.single.meta.id, 'b');

      registry.enable('a');
      expect(registry.activeCount, 2);
    });
  });

  group('pipeline complet via SearchRepository', () {
    test('fan-out multi-sources + fusion + dédup + tri DE>FR', () async {
      final registry = SourceRegistry()
        ..register(FakeSource('sourceA', [
          book('Les Misérables', 'Victor Hugo', 'sourceA', lang: 'fr'),
          book('Faust', 'Goethe', 'sourceA', lang: 'de'),
        ]))
        ..register(FakeSource('sourceB', [
          book('les miserables', 'VICTOR HUGO', 'sourceB', lang: 'fr'),
          book('The Trial', 'Kafka', 'sourceB', lang: 'en'),
        ]));

      final result =
          await makeRepo(registry).search(const SearchQuery(text: 'hugo'));

      expect(result.sourceReports, hasLength(2));
      expect(result.allSourcesFailed, isFalse);
      // 4 livres bruts -> 3 après fusion des Misérables.
      expect(result.items, hasLength(3));
      final merged = result.items
          .firstWhere((i) => i.book.normalizedTitle == 'les miserables');
      expect(merged.book.refs, hasLength(2));
    });

    test('une source en panne ne bloque pas les autres', () async {
      final registry = SourceRegistry()
        ..register(FakeSource('down', const [], failure: Exception('boom')))
        ..register(FakeSource('up', [book('Faust', 'Goethe', 'up', lang: 'de')]));

      final result =
          await makeRepo(registry).search(const SearchQuery(text: 'faust'));

      expect(result.items, hasLength(1));
      expect(result.items.single.book.title, 'Faust');
      final down = result.sourceReports.firstWhere((r) => r.sourceId == 'down');
      expect(down.isOk, isFalse);
      expect(down.error, isNotNull);
    });

    test('une source lente est isolée par le timeout individuel', () async {
      final registry = SourceRegistry()
        ..register(FakeSource('slow', const [],
            delay: const Duration(seconds: 30)))
        ..register(FakeSource('fast', [book('Faust', 'Goethe', 'fast')]));

      final service = SearchService(registry,
          perSourceTimeout: const Duration(milliseconds: 300));
      final result = await SearchRepositoryImpl(service)
          .search(const SearchQuery(text: 'faust'));

      expect(result.items, hasLength(1));
      final slow =
          result.sourceReports.firstWhere((r) => r.sourceId == 'slow');
      expect(slow.isOk, isFalse, reason: 'timeout capturé comme erreur');
    });

    test('hasMore agrégé : une source avec suite suffit', () async {
      final registry = SourceRegistry()
        ..register(FakeSource('a', [book('A', 'x', 'a')], more: true))
        ..register(FakeSource('b', [book('B', 'y', 'b')], more: false));

      final result =
          await makeRepo(registry).search(const SearchQuery(text: 'x'));
      expect(result.hasMore, isTrue);
    });

    test('requête vide -> résultat vide sans toucher aux sources', () async {
      final registry = SourceRegistry()
        ..register(FakeSource('a', [book('A', 'x', 'a')]));
      final result =
          await makeRepo(registry).search(const SearchQuery(text: '   '));
      expect(result.items, isEmpty);
      expect(result.sourceReports, isEmpty);
    });

    test('aucune source active -> résultat vide propre', () async {
      final registry = SourceRegistry()
        ..register(FakeSource('a', [book('A', 'x', 'a')]))
        ..disable('a');
      final result =
          await makeRepo(registry).search(const SearchQuery(text: 'x'));
      expect(result.items, isEmpty);
    });
  });
}
