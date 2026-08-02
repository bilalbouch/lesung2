import 'dart:convert';

import 'package:lesung/features/reader/domain/reader_annotations.dart';
import 'package:lesung/features/reader/domain/reader_bookmarks.dart';
import 'package:lesung/features/reader/domain/reader_contract.dart';
import 'package:lesung/features/reader/domain/reader_repository.dart';
import 'package:lesung/features/reader/domain/reader_settings.dart';
import 'package:lesung/features/reader/domain/reader_statistics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistance des préférences et métadonnées de lecture dans le navigateur.
class PreferencesReaderRepository implements ReaderRepository {
  static const _prefix = 'lesung.reader.';
  final SharedPreferences _preferences;

  PreferencesReaderRepository(this._preferences);

  Map<String, dynamic> _map(String name) {
    final raw = _preferences.getString('$_prefix$name');
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _save(String name, Object value) async {
    await _preferences.setString('$_prefix$name', jsonEncode(value));
  }

  @override
  Future<ReaderSettings> loadSettings() async {

    final value = _map('settings');
    return value.isEmpty ? const ReaderSettings() : ReaderSettings.fromJson(value);
  }

  @override
  Future<void> saveSettings(ReaderSettings settings) =>
      _save('settings', settings.toJson());

  @override
  Future<ReaderPosition?> loadPosition(String bookId) async {
    final value = _map('positions')[bookId];
    return value is Map
        ? ReaderPosition.fromJson(Map<String, dynamic>.from(value))
        : null;
  }

  @override
  Future<void> savePosition(String bookId, ReaderPosition position) async {
    final values = _map('positions')..[bookId] = position.toJson();
    await _save('positions', values);
  }

  @override
  Future<void> clearPosition(String bookId) async {
    final values = _map('positions')..remove(bookId);
    await _save('positions', values);
  }

  @override
  Future<List<ReaderBookmark>> loadBookmarks(String bookId) async {
    final value = _map('bookmarks')[bookId];
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((row) => ReaderBookmark.fromJson(Map<String, dynamic>.from(row)))
        .toList()
      ..sort((a, b) => a.unitIndex.compareTo(b.unitIndex));
  }

  @override
  Future<void> saveBookmark(ReaderBookmark bookmark) async {
    final values = _map('bookmarks');
    final items = (await loadBookmarks(bookmark.bookId))
      ..removeWhere((value) => value.id == bookmark.id)
      ..add(bookmark)
      ..sort((a, b) => a.unitIndex.compareTo(b.unitIndex));
    values[bookmark.bookId] = items.map((value) => value.toJson()).toList();

    await _save('bookmarks', values);
  }

  @override
  Future<void> removeBookmark(String bookId, String bookmarkId) async {
    final values = _map('bookmarks');
    final items = (await loadBookmarks(bookId))
      ..removeWhere((value) => value.id == bookmarkId);
    values[bookId] = items.map((value) => value.toJson()).toList();
    await _save('bookmarks', values);
  }

  @override
  Future<List<ReaderAnnotation>> loadAnnotations(String bookId) async {
    final value = _map('annotations')[bookId];
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((row) => ReaderAnnotation.fromJson(Map<String, dynamic>.from(row)))
        .toList()
      ..sort((a, b) => a.unitIndex.compareTo(b.unitIndex));
  }

  @override
  Future<void> saveAnnotation(ReaderAnnotation annotation) async {
    final values = _map('annotations');
    final items = (await loadAnnotations(annotation.bookId))
      ..removeWhere((value) => value.id == annotation.id)
      ..add(annotation)
      ..sort((a, b) => a.unitIndex.compareTo(b.unitIndex));
    values[annotation.bookId] =

        items.map((value) => value.toJson()).toList();
    await _save('annotations', values);
  }

  @override
  Future<void> removeAnnotation(String bookId, String annotationId) async {
    final values = _map('annotations');
    final items = (await loadAnnotations(bookId))
      ..removeWhere((value) => value.id == annotationId);
    values[bookId] = items.map((value) => value.toJson()).toList();
    await _save('annotations', values);
  }

  @override
  Future<ReaderBookStats?> loadBookStats(String bookId) async {
    final value = _map('statistics')[bookId];
    return value is Map
        ? ReaderBookStats.fromJson(Map<String, dynamic>.from(value))
        : null;
  }

  @override
  Future<void> saveBookStats(ReaderBookStats stats) async {
    final values = _map('statistics')..[stats.bookId] = stats.toJson();
    await _save('statistics', values);
  }

  @override
  Future<List<ReaderBookStats>> loadAllBookStats() async => _map('statistics')
      .values
      .whereType<Map>()
      .map((row) => ReaderBookStats.fromJson(Map<String, dynamic>.from(row)))
      .toList();

  @override
  Future<List<String>> loadNavigationHistory(String bookId) async {
    final value = _map('navigation')[bookId];
    return value is List ? value.whereType<String>().toList() : [];
  }

  @override
  Future<void> saveNavigationHistory(
    String bookId,
    List<String> history,
  ) async {
    final values = _map('navigation')..[bookId] = history;
    await _save('navigation', values);
  }
}
