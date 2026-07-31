import 'entities/download_task.dart';

/// Contrat des notifications de téléchargement.
///
/// Implémenté PAR L'APPLICATION (flutter_local_notifications sur
/// mobile). Le moteur ne connaît que cette interface.
abstract class DownloadNotificationService {
  /// Progression d'une tâche active.
  Future<void> showProgress(DownloadTask task);

  /// Tâche terminée (vérifiée ou non).
  Future<void> showCompleted(DownloadTask task, {required bool verified});

  /// Tâche échouée.
  Future<void> showFailed(DownloadTask task);

  /// Supprime la notification d'une tâche.
  Future<void> cancelFor(String taskId);

  /// Supprime toutes les notifications.
  Future<void> cancelAll();
}
