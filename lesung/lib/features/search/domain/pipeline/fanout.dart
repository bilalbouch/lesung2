import '../../../sources/domain/book_source.dart';
import '../entities/book.dart';
import '../entities/search_query.dart';
import '../entities/search_result.dart';

/// Résultat brut d'une source après fan-out.
class SourceFanoutResult {
  final BookSource source;
  final List<Book> books;
  final SourceReport report;

  const SourceFanoutResult({
    required this.source,
    required this.books,
    required this.report,
  });
}

/// ÉTAPE 1 DU PIPELINE — FAN-OUT.
///
/// Interroge TOUTES les sources en parallèle. Chaque source dispose d'un
/// timeout individuel : une source lente ou en panne n'affecte jamais
/// les autres. Les erreurs sont capturées dans le [SourceReport] et ne
/// se propagent pas.
Future<List<SourceFanoutResult>> fanOutToSources(
  List<BookSource> sources,
  SearchQuery query, {
  Duration perSourceTimeout = const Duration(seconds: 20),
}) {
  return Future.wait(sources.map((source) async {
    final sw = Stopwatch()..start();
    try {
      final page = await source.search(query).timeout(perSourceTimeout);
      sw.stop();
      return SourceFanoutResult(
        source: source,
        books: page.items,
        report: SourceReport(
          sourceId: source.meta.id,
          rawCount: page.items.length,
          elapsed: sw.elapsed,
          hasMore: page.hasMore,
        ),
      );
    } catch (e) {
      sw.stop();
      return SourceFanoutResult(
        source: source,
        books: const [],
        report: SourceReport(
          sourceId: source.meta.id,
          rawCount: 0,
          elapsed: sw.elapsed,
          error: e,
        ),
      );
    }
  }));
}
