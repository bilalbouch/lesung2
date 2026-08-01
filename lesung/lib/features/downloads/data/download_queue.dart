import 'dart:async';

import '../domain/entities/download_task.dart';

/// File d'attente des téléchargements avec concurrence bornée.
///
/// FIFO stricte : les tâches sont démarrées dans l'ordre d'arrivée dès
/// qu'un slot se libère. La file ne connaît pas le réseau : elle invoque
/// un [runner] fourni par le DownloadManager.
class DownloadQueue {
  /// Téléchargements simultanés maximum.
  final int maxConcurrent;

  final List<DownloadTask> _pending = [];
  final Set<String> _running = {};

  /// Exécuteur fourni par le manager (qui détient les workers).
  Future<void> Function(DownloadTask task)? runner;

  /// Notification de changement d'état de la file.
  void Function()? onChanged;

  DownloadQueue({this.maxConcurrent = 2});

  List<DownloadTask> get pending => List.unmodifiable(_pending);
  Set<String> get running => Set.unmodifiable(_running);

  bool get hasCapacity => _running.length < maxConcurrent;

  /// Ajoute une tâche et tente de la démarrer immédiatement.
  void enqueue(DownloadTask task) {
    _pending.add(task);
    _notify();
    _pump();
  }

  /// Retire une tâche en attente (avant démarrage).
  bool remove(String taskId) {
    final before = _pending.length;
    _pending.removeWhere((t) => t.id == taskId);
    final removed = _pending.length != before;
    if (removed) _notify();
    return removed;
  }

  /// Remet une tâche en file (reprise après pause).
  void requeue(DownloadTask task) {
    if (_pending.any((t) => t.id == task.id) || _running.contains(task.id)) {
      return;
    }
    enqueue(task);
  }

  /// Libère le slot d'une tâche terminée et démarre la suivante.
  void complete(String taskId) {
    _running.remove(taskId);
    _notify();
    _pump();
  }

  bool isRunning(String taskId) => _running.contains(taskId);

  /// Tâche en attente identifiée.
  DownloadTask? pendingTask(String taskId) {
    for (final t in _pending) {
      if (t.id == taskId) return t;
    }
    return null;
  }

  void _pump() {
    final run = runner;
    if (run == null) return;
    while (hasCapacity && _pending.isNotEmpty) {
      final task = _pending.removeAt(0);
      _running.add(task.id);
      _notify();
      // Fire-and-forget : le runner appelle complete() en fin d'exécution.
      unawaited(run(task));
    }
  }

  void _notify() => onChanged?.call();
}
