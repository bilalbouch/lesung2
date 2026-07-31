import 'dart:convert';
import 'dart:io';

import '../domain/download_repository.dart';
import '../domain/entities/download_history.dart';
import '../domain/entities/download_task.dart';

/// Persistance JSON des tâches et de l'historique.
///
/// - tâches : une par fichier dans `tasks/` (reprise après redémarrage)
/// - historique : un fichier JSON unique `history.json`
/// Répertoire injecté : testable en temporaire.
class DownloadRepositoryImpl implements DownloadRepository {
  final Directory directory;

  DownloadRepositoryImpl({required this.directory});

  Directory get _tasksDir => Directory('${directory.path}/tasks');
  File get _historyFile => File('${directory.path}/history.json');

  Future<void> initialize() async {
    if (!await _tasksDir.exists()) await _tasksDir.create(recursive: true);
  }

  // ------------------------------------------------------------------
  // Tâches
  // ------------------------------------------------------------------

  @override
  Future<void> saveTask(DownloadTask task) async {
    await initialize();
    await _taskFile(task.id)
        .writeAsString(jsonEncode(task.toJson()));
  }

  @override
  Future<DownloadTask?> loadTask(String taskId) async {
    try {
      final file = _taskFile(taskId);
      if (!await file.exists()) return null;
      return DownloadTask.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DownloadTask>> loadAllTasks() async {
    await initialize();
    final tasks = <DownloadTask>[];
    await for (final entity in _tasksDir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        tasks.add(DownloadTask.fromJson(jsonDecode(
                await entity.readAsString())
            as Map<String, dynamic>));
      } catch (_) {
        // Fichier corrompu : supprimé préventivement.
        await entity.delete();
      }
    }
    tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return tasks;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final file = _taskFile(taskId);
    if (await file.exists()) await file.delete();
  }

  File _taskFile(String taskId) => File(
      '${_tasksDir.path}/${taskId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.json');

  // ------------------------------------------------------------------
  // Historique
  // ------------------------------------------------------------------

  @override
  Future<void> addHistoryEntry(DownloadHistoryEntry entry) async {
    final history = await loadHistory();
    history.insert(0, entry); // plus récent en tête
    await _historyFile.writeAsString(
        jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  @override
  Future<List<DownloadHistoryEntry>> loadHistory() async {
    try {
      if (!await _historyFile.exists()) return [];
      final list = jsonDecode(await _historyFile.readAsString()) as List;
      return list
          .map((e) =>
              DownloadHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> clearHistory() async {
    if (await _historyFile.exists()) await _historyFile.delete();
  }
}
