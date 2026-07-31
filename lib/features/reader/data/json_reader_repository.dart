import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/reader_annotations.dart';
import '../domain/reader_bookmarks.dart';
import '../domain/reader_contract.dart';
import '../domain/reader_repository.dart';
import '../domain/reader_settings.dart';
import '../domain/reader_statistics.dart';

/// Implémentation JSON du [ReaderRepository], en pur Dart.
///
/// Un fichier par agrégat sous [directory] ; écritures atomiques
/// (tmp + renommage) et sérialisées (l'auto-save peut se chevaucher
/// avec une action utilisateur). Sert le moteur et les tests ;
/// l'application pourra fournir une implémentation sqflite.
class JsonReaderRepository implements ReaderRepository {
  final Directory directory;

  Map<String, ReaderPosition>? _positions;
  Map<String, List<ReaderBookmark>>? _bookmarks;
  Map<String, List<ReaderAnnotation>>? _annotations;
  Map<String, ReaderBookStats>? _stats;
  Map<String, List<String>>? _navHistory;

  Future<void> _writeChain = Future<void>.value();

  JsonReaderRepository(this.directory);

  Future<T> _enqueueWrite<T>(Future<T> Function() operation) {
    final result = _writeChain.then((_) => operation());
    _writeChain = result.then((_) {}, onError: (_) {});
    return result;
  }

  File _file(String name) => File('${directory.path}/$name.json');

  Future<void> _ensureDirectory() async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  Map<String, dynamic> _readMap(File file) {
    if (!file.existsSync()) return const {};
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is Map<String, dynamic>) return decoded;
      file.deleteSync();
    } catch (_) {
      try {
        file.deleteSync();
      } catch (_) {}
    }
    return const {};
  }

  Future<void> _writeJson(String name, Object payload) {
    return _enqueueWrite(() async {
      await _ensureDirectory();
      final target = _file(name);
      final tmp = File('${target.path}.tmp');
      await tmp.writeAsString(jsonEncode(payload));
      await tmp.rename(target.path);
    });
  }

  // ---------- réglages ----------

  @override
  Future<ReaderSettings> loadSettings() async {
    final map = _readMap(_file('settings'));
    if (map.isEmpty) return const ReaderSettings();
    return ReaderSettings.fromJson(map);
  }

  @override
  Future<void> saveSettings(ReaderSettings settings) =>
      _writeJson('settings', settings.toJson());

  // ---------- positions ----------

  Map<String, ReaderPosition> get _positionsMap {
    if (_positions == null) {
      _positions = {
        for (final entry in _readMap(_file('positions')).entries)
          if (entry.value is Map<String, dynamic>)
            entry.key:
                ReaderPosition.fromJson(entry.value as Map<String, dynamic>)
      };
    }
    return _positions!;
  }

  @override
  Future<ReaderPosition?> loadPosition(String bookId) async =>
      _positionsMap[bookId];

  @override
  Future<void> savePosition(String bookId, ReaderPosition position) {
    _positionsMap[bookId] = position;
    return _writeJson('positions', {
      for (final e in _positionsMap.entries) e.key: e.value.toJson()
    });
  }

  @override
  Future<void> clearPosition(String bookId) {
    if (_positionsMap.remove(bookId) == null) {
      return Future<void>.value();
    }
    return _writeJson('positions', {
      for (final e in _positionsMap.entries) e.key: e.value.toJson()
    });
  }

  // ---------- signets ----------

  Map<String, List<ReaderBookmark>> get _bookmarksMap {
    if (_bookmarks == null) {
      _bookmarks = {};
      for (final entry in _readMap(_file('bookmarks')).entries) {
        if (entry.value is! List) continue;
        _bookmarks![entry.key] = (entry.value as List)
            .whereType<Map<String, dynamic>>()
            .map(ReaderBookmark.fromJson)
            .toList();
      }
    }
    return _bookmarks!;
  }

  Future<void> _writeBookmarks() => _writeJson('bookmarks', {
        for (final e in _bookmarksMap.entries)
          e.key: e.value.map((b) => b.toJson()).toList()
      });

  @override
  Future<List<ReaderBookmark>> loadBookmarks(String bookId) async =>
      List.unmodifiable(_bookmarksMap[bookId] ?? const []);

  @override
  Future<void> saveBookmark(ReaderBookmark bookmark) {
    final list = _bookmarksMap.putIfAbsent(bookmark.bookId, () => []);
    list.removeWhere((b) => b.id == bookmark.id);
    list.add(bookmark);
    list.sort((a, b) => a.unitIndex.compareTo(b.unitIndex));
    return _writeBookmarks();
  }

  @override
  Future<void> removeBookmark(String bookId, String bookmarkId) {
    final list = _bookmarksMap[bookId];
    if (list == null) return Future<void>.value();
    list.removeWhere((b) => b.id == bookmarkId);
    return _writeBookmarks();
  }

  // ---------- annotations ----------

  Map<String, List<ReaderAnnotation>> get _annotationsMap {
    if (_annotations == null) {
      _annotations = {};
      for (final entry in _readMap(_file('annotations')).entries) {
        if (entry.value is! List) continue;
        _annotations![entry.key] = (entry.value as List)
            .whereType<Map<String, dynamic>>()
            .map(ReaderAnnotation.fromJson)
            .toList();
      }
    }
    return _annotations!;
  }

  Future<void> _writeAnnotations() => _writeJson('annotations', {
        for (final e in _annotationsMap.entries)
          e.key: e.value.map((a) => a.toJson()).toList()
      });

  @override
  Future<List<ReaderAnnotation>> loadAnnotations(String bookId) async =>
      List.unmodifiable(_annotationsMap[bookId] ?? const []);

  @override
  Future<void> saveAnnotation(ReaderAnnotation annotation) {
    final list = _annotationsMap.putIfAbsent(annotation.bookId, () => []);
    list.removeWhere((a) => a.id == annotation.id);
    list.add(annotation);
    list.sort((a, b) => a.unitIndex.compareTo(b.unitIndex));
    return _writeAnnotations();
  }

  @override
  Future<void> removeAnnotation(String bookId, String annotationId) {
    final list = _annotationsMap[bookId];
    if (list == null) return Future<void>.value();
    list.removeWhere((a) => a.id == annotationId);
    return _writeAnnotations();
  }

  // ---------- statistiques ----------

  Map<String, ReaderBookStats> get _statsMap {
    if (_stats == null) {
      _stats = {
        for (final entry in _readMap(_file('reader_stats')).entries)
          if (entry.value is Map<String, dynamic>)
            entry.key:
                ReaderBookStats.fromJson(entry.value as Map<String, dynamic>)
      };
    }
    return _stats!;
  }

  @override
  Future<ReaderBookStats?> loadBookStats(String bookId) async =>
      _statsMap[bookId];

  @override
  Future<void> saveBookStats(ReaderBookStats stats) {
    _statsMap[stats.bookId] = stats;
    return _writeJson('reader_stats', {
      for (final e in _statsMap.entries) e.key: e.value.toJson()
    });
  }

  @override
  Future<List<ReaderBookStats>> loadAllBookStats() async =>
      _statsMap.values.toList();

  // ---------- historique de navigation ----------

  Map<String, List<String>> get _navMap {
    if (_navHistory == null) {
      _navHistory = {
        for (final entry in _readMap(_file('nav_history')).entries)
          if (entry.value is List)
            entry.key: (entry.value as List).whereType<String>().toList()
      };
    }
    return _navHistory!;
  }

  @override
  Future<List<String>> loadNavigationHistory(String bookId) async =>
      List.unmodifiable(_navMap[bookId] ?? const []);

  @override
  Future<void> saveNavigationHistory(String bookId, List<String> history) {
    _navMap[bookId] = [...history];
    return _writeJson('nav_history', _navMap);
  }
}
