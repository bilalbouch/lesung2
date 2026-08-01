import 'entities/library_book.dart';
import 'entities/reading_stats.dart';
import 'library_repository.dart';

/// Statistiques de lecture et de la bibliothèque.
///
/// Le temps de lecture provient des compteurs incrémentaux persistés
/// (table statistics) ; les répartitions (livres, langues, formats,
/// espace disque) sont agrégées à la demande sur l'état courant.
class StatisticsManager {
  final LibraryRepository repository;

  StatisticsManager({required this.repository});

  /// Vue statistique complète, calculée sur l'état actuel.
  Future<ReadingStats> compute() async {
    final books = await repository.allBooks();
    final favorites = await repository.favoriteBookIds();
    final collections = await repository.allCollections();
    final progress = await repository.allReadingProgress();
    final counters = await repository.statisticsCounters();

    final byLanguage = <String, int>{};
    final byFormat = <String, int>{};
    var downloaded = 0;
    var finished = 0;
    var totalSize = 0;

    for (final book in books) {
      byLanguage.update(book.language ?? 'inconnu', (v) => v + 1,
          ifAbsent: () => 1);
      byFormat.update(book.format ?? 'inconnu', (v) => v + 1,
          ifAbsent: () => 1);
      if (book.downloaded) {
        downloaded += 1;
        totalSize += book.fileSizeBytes ?? 0;
      }
      if (book.finishedAt != null) finished += 1;
    }

    // En cours = progression connue entre 0 % et 100 % exclus.
    final inProgress = progress
        .where((p) => p.progress > 0 && p.progress < 1)
        .length;

    return ReadingStats(
      totalBooks: books.length,
      downloadedBooks: downloaded,
      notDownloadedBooks: books.length - downloaded,
      finishedBooks: finished,
      inProgressBooks: inProgress,
      favoritesCount: favorites.length,
      collectionsCount: collections.length,
      totalReadingSeconds: counters.totalReadingSeconds,
      totalSizeBytes: totalSize,
      booksByLanguage: byLanguage,
      booksByFormat: byFormat,
    );
  }

  /// Temps de lecture total sans recalcul complet (compteur persisté).
  Future<Duration> totalReadingTime() async {
    final counters = await repository.statisticsCounters();
    return Duration(seconds: counters.totalReadingSeconds);
  }
}

/// Petit utilitaire de regroupement utilisé par les vues statistiques.
extension LibraryBookGrouping on Iterable<LibraryBook> {
  Map<String, int> countBy(String? Function(LibraryBook) keyOf) {
    final result = <String, int>{};
    for (final book in this) {
      result.update(keyOf(book) ?? 'inconnu', (v) => v + 1, ifAbsent: () => 1);
    }
    return result;
  }
}
