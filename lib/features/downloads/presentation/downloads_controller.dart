import 'dart:async';

import '../data/download_manager.dart';
import '../domain/entities/download_task.dart';

/// Contrôleur de présentation des téléchargements — SANS Flutter.
///
/// Expose un état consolidé (tâches + dernière progression connue) et
/// les actions utilisateur. Sera branché sur Riverpod côté app.
class DownloadsController {
  final DownloadManager manager;

  /// Dernière progression connue par tâche.
  final Map<String, DownloadProgress> progressById = {};

  /// Snapshot courant des tâches.
  List<DownloadTask> tasks = [];

  void Function()? onChanged;

  StreamSubscription<DownloadProgress>? _progressSub;
  StreamSubscription<List<DownloadTask>>? _tasksSub;

  DownloadsController(this.manager);

  /// Branche les streams du manager. À appeler une fois.
  void listen() {
    tasks = manager.tasks;
    _tasksSub ??= manager.tasksStream.listen((updated) {
      tasks = updated;
      onChanged?.call();
    });
    _progressSub ??= manager.progressStream.listen((progress) {
      progressById[progress.taskId] = progress;
      onChanged?.call();
    });
  }

  DownloadProgress? progressFor(String taskId) => progressById[taskId];

  List<DownloadTask> get active =>
      tasks.where((t) => t.isActive || t.status == DownloadStatus.queued || t.status == DownloadStatus.paused).toList();

  List<DownloadTask> get completed =>
      tasks.where((t) => t.status == DownloadStatus.completed).toList();

  List<DownloadTask> get failed =>
      tasks.where((t) => t.status == DownloadStatus.failed).toList();

  // -- Actions utilisateur --

  Future<void> enqueue(DownloadTask task) => manager.enqueue(task);
  void pause(String taskId) => manager.pause(taskId);
  Future<void> resume(String taskId) => manager.resume(taskId);
  Future<void> cancel(String taskId) => manager.cancel(taskId);
  Future<void> retry(String taskId) => manager.retry(taskId);
  Future<void> remove(String taskId) => manager.remove(taskId);

  Future<void> dispose() async {
    await _progressSub?.cancel();
    await _tasksSub?.cancel();
  }
}
