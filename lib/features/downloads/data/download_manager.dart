import 'dart:async';

import '../../../../core/cancellation/cancellation_token.dart';
import '../../../../core/events/app_events.dart';
import '../../../../core/events/event_bus.dart';
import '../domain/download_notification_service.dart';
import '../domain/download_repository.dart';
import '../domain/entities/download_history.dart';
import '../domain/entities/download_task.dart';
import 'download_queue.dart';
import 'download_storage.dart';
import 'download_worker.dart';

/// DownloadManager — CHEF D'ORCHESTRE du moteur de téléchargement.
///
/// Ne contient AUCUNE logique réseau et AUCUNE référence à une source :
/// - il reçoit des [DownloadTask] construites sur des DownloadLink normalisés
/// - la file décide QUAND démarrer (concurrence bornée)
/// - le worker exécute (réseau, Range, failover miroirs)
/// - le repository persiste
/// - le service de notifications informe l'utilisateur
///
/// API publique : enqueue / pause / resume / cancel / retry / remove +
/// streams de progression et d'état pour la présentation.
class DownloadManager {
  final DownloadQueue queue;
  final DownloadWorker worker;
  final DownloadRepository repository;
  final DownloadStorage storage;
  final DownloadNotificationService? notifications;

  /// Bus d'événements applicatif (optionnel).
  ///
  /// Le DownloadManager N'ÉCRIT JAMAIS dans la bibliothèque : il publie
  /// [DownloadFinishedEvent] / [DownloadRemovedEvent], et la bibliothèque
  /// (ou tout autre abonné) réagit sans dépendance directe.
  final EventBus? eventBus;

  /// Tâches connues (actives ou récentes), indexées par id.
  final Map<String, DownloadTask> _tasks = {};

  /// Contrôles par tâche : annulation + signal de pause.
  final Map<String, CancellationToken> _tokens = {};
  final Map<String, bool> _pauseSignals = {};

  final _progressController =
      StreamController<DownloadProgress>.broadcast();
  final _tasksController =
      StreamController<List<DownloadTask>>.broadcast();

  /// Progression temps réel (toutes tâches).
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  /// Snapshot des tâches à chaque changement.
  Stream<List<DownloadTask>> get tasksStream => _tasksController.stream;

  DownloadManager({
    required this.worker,
    required this.repository,
    required this.storage,
    this.notifications,
    this.eventBus,
    int maxConcurrent = 2,
  }) : queue = DownloadQueue(maxConcurrent: maxConcurrent) {
    queue.runner = _runTask;
    worker.onProgress = _onWorkerProgress;
  }

  /// Tâches actuellement connues, triées par date de création.
  List<DownloadTask> get tasks =>
      _tasks.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  DownloadTask? taskById(String id) => _tasks[id];

  bool _storageReady = false;

  /// Garantit que les répertoires de stockage existent (une fois).
  Future<void> _ensureStorageReady() async {
    if (_storageReady) return;
    await storage.initialize();
    _storageReady = true;
  }

  /// Restaure les tâches persistées (appel au démarrage) : les tâches
  /// interrompues sont remises en pause, reprises manuellement ou
  /// automatiquement selon [autoResume].
  Future<void> restore({bool autoResume = false}) async {
    await _ensureStorageReady();
    final persisted = await repository.loadAllTasks();
    for (final task in persisted) {
      if (task.status == DownloadStatus.completed ||
          task.status == DownloadStatus.cancelled) {
        continue;
      }
      // Une tâche « downloading » au moment de l'arrêt devient paused.
      if (task.isActive) task.status = DownloadStatus.paused;
      _tasks[task.id] = task;
      if (autoResume && task.status == DownloadStatus.paused) {
        resume(task.id);
      }
    }
    _emitTasks();
  }

  /// Ajoute une tâche à la file et la persiste.
  Future<void> enqueue(DownloadTask task) async {
    if (_tasks.containsKey(task.id)) return;
    await _ensureStorageReady();
    _tasks[task.id] = task;
    _tokens[task.id] = CancellationToken();
    _pauseSignals[task.id] = false;
    await repository.saveTask(task);
    _emitTasks();
    await notifications?.showProgress(task);
    queue.enqueue(task);
  }

  /// Suspend une tâche active (partiel conservé, reprise Range).
  void pause(String taskId) {
    final task = _tasks[taskId];
    if (task == null || !task.isActive) return;
    _pauseSignals[taskId] = true;
    // Le worker observe le signal entre les chunks.
  }

  /// Reprend une tâche en pause.
  Future<void> resume(String taskId) async {
    final task = _tasks[taskId];
    if (task == null || task.status != DownloadStatus.paused) return;
    task.status = DownloadStatus.queued;
    task.errorMessage = null;
    _tokens[taskId] = CancellationToken();
    _pauseSignals[taskId] = false;
    await repository.saveTask(task);
    _emitTasks();
    queue.requeue(task);
  }

  /// Annule définitivement : fichier partiel supprimé.
  Future<void> cancel(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) return;
    if (queue.remove(taskId)) {
      // Encore en attente : annulation immédiate.
      task.status = DownloadStatus.cancelled;
      await repository.saveTask(task);
      _emitTasks();
      return;
    }
    _tokens[taskId]?.cancel();
    _pauseSignals[taskId] = false;
  }

  /// Relance une tâche échouée depuis zéro.
  Future<void> retry(String taskId) async {
    final task = _tasks[taskId];
    if (task == null || task.status != DownloadStatus.failed) return;
    await storage.deletePartial(task);
    task
      ..status = DownloadStatus.queued
      ..receivedBytes = 0
      ..totalBytes = 0
      ..errorMessage = null
      ..activeUrl = null;
    _tokens[taskId] = CancellationToken();
    _pauseSignals[taskId] = false;
    await repository.saveTask(task);
    _emitTasks();
    queue.requeue(task);
  }

  /// Retire une tâche de la liste (historique conservé).
  Future<void> remove(String taskId) async {
    if (_tasks[taskId]?.isActive ?? false) await cancel(taskId);
    final removed = _tasks.remove(taskId);
    if (removed != null && removed.status == DownloadStatus.completed) {
      eventBus?.emit(DownloadRemovedEvent(
        bookId: taskId,
        filePath: storage.finalFileFor(removed).path,
      ));
    }
    _tokens.remove(taskId);
    _pauseSignals.remove(taskId);
    await repository.deleteTask(taskId);
    await notifications?.cancelFor(taskId);
    _emitTasks();
  }

  // ------------------------------------------------------------------

  Future<void> _runTask(DownloadTask task) async {
    final token = _tokens[task.id]!;
    try {
      await worker.run(task,
          controlToken: token,
          pauseSignal: () => _pauseSignals[task.id] ?? false);
    } finally {
      queue.complete(task.id);
    }

    await repository.saveTask(task);

    switch (task.status) {
      case DownloadStatus.completed:
        // Si un MD5 était attendu, la complétion garantit qu'il a été
        // vérifié (le worker échoue sinon). Sans MD5 annoncé, la
        // vérification n'a porté que sur taille/signature.
        final verified =
            task.expectedMd5 != null && task.expectedMd5!.isNotEmpty;
        await repository.addHistoryEntry(DownloadHistoryEntry(
          taskId: task.id,
          title: task.title,
          author: task.author,
          format: task.format,
          filePath: storage.finalFileFor(task).path,
          fileSizeBytes: task.receivedBytes,
          md5Verified: verified,
          completedAt: task.completedAt ?? DateTime.now(),
        ));
        await notifications?.showCompleted(task, verified: verified);
        // Événement vers la bibliothèque (et tout autre abonné).
        // L'id de la tâche EST l'identité du livre côté bibliothèque.
        eventBus?.emit(DownloadFinishedEvent(
          bookId: task.id,
          title: task.title,
          author: task.author,
          coverUrl: task.coverUrl,
          format: task.format.name,
          filePath: storage.finalFileFor(task).path,
          fileSizeBytes: task.receivedBytes,
          md5Verified: verified,
        ));
      case DownloadStatus.failed:
        await notifications?.showFailed(task);
      case DownloadStatus.paused:
        await notifications?.showProgress(task);
      default:
        break;
    }
    _emitTasks();
  }

  void _onWorkerProgress(DownloadProgress progress) {
    final task = _tasks[progress.taskId];
    if (task == null) return;
    _progressController.add(progress);
    if (progress.status == DownloadStatus.downloading) {
      notifications?.showProgress(task);
    }
  }

  void _emitTasks() {
    if (!_tasksController.isClosed) _tasksController.add(tasks);
  }

  Future<void> dispose() async {
    for (final token in _tokens.values) {
      token.cancel();
    }
    await _progressController.close();
    await _tasksController.close();
    worker.close();
  }
}
