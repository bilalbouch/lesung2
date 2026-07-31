import 'entities/download_history.dart';
import 'entities/download_task.dart';

/// Contrat du repository de téléchargements — DONNÉES UNIQUEMENT.
///
/// Aucune logique réseau ici : persistance des tâches (reprise après
/// redémarrage) et de l'historique.
abstract class DownloadRepository {
  Future<void> saveTask(DownloadTask task);
  Future<DownloadTask?> loadTask(String taskId);
  Future<List<DownloadTask>> loadAllTasks();
  Future<void> deleteTask(String taskId);

  Future<void> addHistoryEntry(DownloadHistoryEntry entry);
  Future<List<DownloadHistoryEntry>> loadHistory();
  Future<void> clearHistory();
}
