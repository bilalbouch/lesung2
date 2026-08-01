import '../../../core/events/app_events.dart';
import '../../../core/events/event_bus.dart';
import 'entities/collection.dart';
import 'entities/library_book.dart';
import 'library_repository.dart';

/// Gestion des collections personnalisées de l'utilisateur.
///
/// Une collection est un regroupement libre : elle ne dépend ni du
/// téléchargement, ni de la lecture, ni des favoris. Les suppressions
/// sont en cascade (liens collection_books) sans toucher aux livres.
class CollectionsManager {
  final LibraryRepository repository;
  final EventBus eventBus;
  final String Function() idGenerator;

  CollectionsManager({
    required this.repository,
    required this.eventBus,
    String Function()? idGenerator,
  }) : idGenerator = idGenerator ?? _defaultId;

  static String _defaultId() =>
      'col_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Future<List<Collection>> collections() => repository.allCollections();

  Future<Collection> create(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Nom de collection vide.');
    }
    final now = DateTime.now();
    final collection = Collection(
      id: idGenerator(),
      name: trimmed,
      createdAt: now,
      updatedAt: now,
      sortOrder: (await repository.allCollections()).length,
    );
    await repository.saveCollection(collection);
    eventBus.emit(CollectionCreatedEvent(collection.id, collection.name));
    return collection;
  }

  Future<Collection> rename(String collectionId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(newName, 'newName', 'Nom de collection vide.');
    }
    final existing = await repository.collectionById(collectionId);
    if (existing == null) {
      throw StateError('Collection inconnue : $collectionId');
    }
    final updated = existing.copyWith(name: trimmed, updatedAt: DateTime.now());
    await repository.saveCollection(updated);
    eventBus.emit(CollectionUpdatedEvent(collectionId));
    return updated;
  }

  Future<void> delete(String collectionId) async {
    await repository.deleteCollection(collectionId);
    eventBus.emit(CollectionDeletedEvent(collectionId));
  }

  /// Ajoute un livre à une collection (idempotent). Retourne `false`
  /// si le livre y était déjà.
  Future<bool> addBook(String collectionId, String bookId) async {
    if (await repository.collectionById(collectionId) == null) {
      throw StateError('Collection inconnue : $collectionId');
    }
    if (await repository.bookById(bookId) == null) {
      throw StateError('Livre inconnu de la bibliothèque : $bookId');
    }
    final existing = await repository.collectionBooks(collectionId);
    if (existing.any((l) => l.bookId == bookId)) return false;
    await repository.addBookToCollection(CollectionBook(
      collectionId: collectionId,
      bookId: bookId,
      addedAt: DateTime.now(),
      position: existing.length,
    ));
    eventBus.emit(CollectionBookAddedEvent(collectionId, bookId));
    return true;
  }

  Future<void> removeBook(String collectionId, String bookId) async {
    await repository.removeBookFromCollection(collectionId, bookId);
    eventBus.emit(CollectionBookRemovedEvent(collectionId, bookId));
  }

  /// Livres d'une collection, dans l'ordre défini (position).
  Future<List<LibraryBook>> booksIn(String collectionId) async {
    final links = await repository.collectionBooks(collectionId);
    final books = <LibraryBook>[];
    for (final link in links) {
      final book = await repository.bookById(link.bookId);
      if (book != null) books.add(book);
    }
    return books;
  }

  /// Collections contenant un livre donné.
  Future<List<Collection>> collectionsFor(String bookId) async {
    final ids = await repository.collectionIdsForBook(bookId);
    final result = <Collection>[];
    for (final id in ids) {
      final collection = await repository.collectionById(id);
      if (collection != null) result.add(collection);
    }
    return result;
  }
}
