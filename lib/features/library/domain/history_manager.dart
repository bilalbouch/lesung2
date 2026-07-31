import '../../../core/events/app_events.dart';
import '../../../core/events/event_bus.dart';
import 'entities/reading_history.dart';
import 'library_repository.dart';

/// Historique de lecture sous forme de sessions (ouverture / fermeture).
///
/// Les sessions fermées alimentent incrémentalement les compteurs de
/// statistiques : pas de recalcul complet de l'historique pour connaître
/// le temps de lecture total.
class HistoryManager {
  final LibraryRepository repository;
  final EventBus eventBus;

  HistoryManager({required this.repository, required this.eventBus});

  /// Historique des sessions, la plus récente d'abord.
  Future<List<ReadingHistoryEntry>> history() => repository.history();

  /// Ouvre une session de lecture pour un livre.
  ///
  /// Si une session est déjà ouverte pour ce livre (Reader interrompu),
  /// elle est d'abord clôturée avec la durée connue jusqu'à maintenant.
  Future<ReadingHistoryEntry> openSession(String bookId) async {
    final dangling = await repository.openSessionFor(bookId);
    if (dangling != null) {
      await _closeEntry(dangling, DateTime.now());
    }
    final entry = await repository.addHistoryEntry(
        ReadingHistoryEntry(bookId: bookId, openedAt: DateTime.now()));
    eventBus.emit(ReadingSessionOpenedEvent(bookId));
    return entry;
  }

  /// Clôture la session ouverte d'un livre, s'il y en a une.
  /// Retourne la durée en secondes, ou null s'il n'y avait rien à fermer.
  Future<int?> closeSession(String bookId) async {
    final open = await repository.openSessionFor(bookId);
    if (open == null) return null;
    final closedAt = DateTime.now();
    final closed = await _closeEntry(open, closedAt);
    return closed.durationSeconds;
  }

  Future<ReadingHistoryEntry> _closeEntry(
      ReadingHistoryEntry entry, DateTime closedAt) async {
    final seconds = closedAt.difference(entry.openedAt).inSeconds;
    final closed = entry.close(closedAt, seconds);
    await repository.updateHistoryEntry(closed);
    // Compteurs globaux : mise à jour incrémentale.
    final counters = await repository.statisticsCounters();
    await repository.saveStatisticsCounters(counters.addSession(seconds));
    eventBus.emit(
        ReadingSessionClosedEvent(entry.bookId, durationSeconds: seconds));
    return closed;
  }

  /// Sessions récentes d'un livre précis.
  Future<List<ReadingHistoryEntry>> historyFor(String bookId) async {
    final all = await repository.history();
    return all.where((e) => e.bookId == bookId).toList();
  }
}
