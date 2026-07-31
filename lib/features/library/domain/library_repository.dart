import 'entities/collection.dart';
import 'entities/favorite.dart';
import 'entities/library_book.dart';
import 'entities/reading_history.dart';
import 'entities/reading_progress.dart';
import 'entities/reading_stats.dart';

/// Contrat de persistance de la bibliothèque.
///
/// Le domaine ne connaît que cette interface : l'implémentation JSON
/// (moteur pur Dart, testable) et la future implémentation sqflite
/// (application Flutter) sont interchangeables. Le schéma SQL de référence
/// est défini dans `data/schema/library_schema.dart`.
abstract class LibraryRepository {
  // ---------- books ----------

  /// Insère ou met à jour un livre (upsert sur [LibraryBook.id]).
  Future<void> saveBook(LibraryBook book);

  Future<LibraryBook?> bookById(String bookId);

  /// Tous les livres, triés par [LibraryBook.updatedAt] décroissant.
  Future<List<LibraryBook>> allBooks();

  /// Supprime le livre et toutes ses données liées (favori, collections,
  /// progression, historique, trace de téléchargement).
  Future<void> deleteBook(String bookId);

  // ---------- favorites ----------

  Future<void> addFavorite(Favorite favorite);

  Future<void> removeFavorite(String bookId);

  /// Identifiants des livres favoris (triés par ajout récent d'abord).
  Future<List<String>> favoriteBookIds();

  Future<bool> isFavorite(String bookId);

  // ---------- collections ----------

  Future<void> saveCollection(Collection collection);

  Future<void> deleteCollection(String collectionId);

  Future<Collection?> collectionById(String collectionId);

  /// Toutes les collections, triées par [Collection.sortOrder] puis nom.
  Future<List<Collection>> allCollections();

  /// Ajoute un livre à une collection (idempotent).
  Future<void> addBookToCollection(CollectionBook link);

  Future<void> removeBookFromCollection(String collectionId, String bookId);

  /// Livres d'une collection, triés par [CollectionBook.position].
  Future<List<CollectionBook>> collectionBooks(String collectionId);

  /// Collections contenant un livre donné.
  Future<List<String>> collectionIdsForBook(String bookId);

  // ---------- reading_progress ----------

  Future<void> saveReadingProgress(ReadingProgress progress);

  Future<ReadingProgress?> readingProgressFor(String bookId);

  /// Toutes les progressions, triées par mise à jour récente d'abord.
  Future<List<ReadingProgress>> allReadingProgress();

  Future<void> deleteReadingProgress(String bookId);

  // ---------- history ----------

  /// Ajoute une entrée d'historique. Retourne l'entrée avec son id.
  Future<ReadingHistoryEntry> addHistoryEntry(ReadingHistoryEntry entry);

  Future<void> updateHistoryEntry(ReadingHistoryEntry entry);

  /// Historique complet, le plus récent d'abord.
  Future<List<ReadingHistoryEntry>> history();

  /// Dernière session ouverte (non fermée) d'un livre, s'il y en a une.
  Future<ReadingHistoryEntry?> openSessionFor(String bookId);

  // ---------- downloads (trace bibliothèque) ----------

  Future<void> saveDownloadRecord(DownloadRecord record);

  Future<DownloadRecord?> downloadRecordFor(String bookId);

  Future<void> deleteDownloadRecord(String bookId);

  // ---------- statistics ----------

  /// Lit les compteurs globaux (zéros si jamais initialisés).
  Future<StatisticsCounters> statisticsCounters();

  Future<void> saveStatisticsCounters(StatisticsCounters counters);
}
