import 'reader_annotations.dart';
import 'reader_bookmarks.dart';
import 'reader_contract.dart';
import 'reader_settings.dart';
import 'reader_statistics.dart';

/// Contrat de persistance du Reader.
///
/// Le domaine ne connaît que cette interface. L'implémentation JSON
/// (pur Dart, testable) et une future implémentation sqflite sont
/// interchangeables. Le Reader y persiste : réglages, positions,
/// signets, annotations, statistiques et historique de navigation.
abstract class ReaderRepository {
  // ---------- réglages (globaux) ----------

  Future<ReaderSettings> loadSettings();

  Future<void> saveSettings(ReaderSettings settings);

  // ---------- position mémorisée (par livre) ----------

  /// Dernière position connue du livre, ou null si jamais ouvert.
  Future<ReaderPosition?> loadPosition(String bookId);

  /// Auto-save : appelé périodiquement ET à la fermeture.
  Future<void> savePosition(String bookId, ReaderPosition position);

  Future<void> clearPosition(String bookId);

  // ---------- signets ----------

  Future<List<ReaderBookmark>> loadBookmarks(String bookId);

  Future<void> saveBookmark(ReaderBookmark bookmark);

  Future<void> removeBookmark(String bookId, String bookmarkId);

  // ---------- annotations ----------

  Future<List<ReaderAnnotation>> loadAnnotations(String bookId);

  Future<void> saveAnnotation(ReaderAnnotation annotation);

  Future<void> removeAnnotation(String bookId, String annotationId);

  // ---------- statistiques de lecture ----------

  Future<ReaderBookStats?> loadBookStats(String bookId);

  Future<void> saveBookStats(ReaderBookStats stats);

  Future<List<ReaderBookStats>> loadAllBookStats();

  // ---------- historique de navigation (par livre) ----------

  /// Pile de locators visités, le plus récent en fin de liste.
  Future<List<String>> loadNavigationHistory(String bookId);

  Future<void> saveNavigationHistory(String bookId, List<String> history);
}
