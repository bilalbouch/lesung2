import '../../../core/events/app_events.dart';
import '../../../core/events/event_bus.dart';
import 'entities/reading_progress.dart';
import 'library_repository.dart';

/// Progression de lecture : un localisateur opaque (CFI epub, page pdf)
/// plus un ratio 0..1, indépendant du Reader qui les produira.
///
/// Atteindre 100 % marque le livre comme terminé (finishedAt) et publie
/// [BookFinishedEvent]. Revenir en arrière sous 100 % retire la marque.
class ReadingProgressManager {
  final LibraryRepository repository;
  final EventBus eventBus;

  static const double finishedThreshold = 1.0;

  ReadingProgressManager({required this.repository, required this.eventBus});

  Future<ReadingProgress?> progressFor(String bookId) =>
      repository.readingProgressFor(bookId);

  Future<List<ReadingProgress>> allProgress() =>
      repository.allReadingProgress();

  /// Enregistre une avancée. [progress] est borné à [0, 1].
  Future<ReadingProgress> updateProgress(
      String bookId, String locator, double progress) async {
    if (locator.isEmpty) {
      throw ArgumentError.value(locator, 'locator', 'Localisateur vide.');
    }
    if (await repository.bookById(bookId) == null) {
      throw StateError('Livre inconnu de la bibliothèque : $bookId');
    }
    final clamped = progress.clamp(0.0, 1.0);
    final entry = ReadingProgress(
      bookId: bookId,
      locator: locator,
      progress: clamped,
      updatedAt: DateTime.now(),
    );
    await repository.saveReadingProgress(entry);

    final book = (await repository.bookById(bookId))!;
    final nowFinished = clamped >= finishedThreshold;
    final wasFinished = book.finishedAt != null;
    if (nowFinished && !wasFinished) {
      await repository
          .saveBook(book.copyWith(finishedAt: DateTime.now()));
      eventBus.emit(BookFinishedEvent(bookId));
    } else if (!nowFinished && wasFinished) {
      await repository.saveBook(book.copyWith(clearFinishedAt: true));
    }

    eventBus.emit(ReadingProgressChangedEvent(bookId, locator, clamped));
    return entry;
  }

  Future<void> clearProgress(String bookId) async {
    await repository.deleteReadingProgress(bookId);
    final book = await repository.bookById(bookId);
    if (book != null && book.finishedAt != null) {
      await repository.saveBook(book.copyWith(clearFinishedAt: true));
    }
  }
}
