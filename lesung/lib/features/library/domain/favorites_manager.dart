import '../../../core/events/app_events.dart';
import '../../../core/events/event_bus.dart';
import 'entities/favorite.dart';
import 'entities/library_book.dart';
import 'library_repository.dart';

/// Gestion des favoris : un état totalement indépendant du téléchargement.
///
/// Un livre peut être favori sans être téléchargé, dans une collection,
/// commencé ou terminé. Chaque action est persistée puis publiée sur le
/// bus d'événements afin que les autres composants (statistiques, UI)
/// réagissent sans dépendance directe.
class FavoritesManager {
  final LibraryRepository repository;
  final EventBus eventBus;

  FavoritesManager({required this.repository, required this.eventBus});

  Future<bool> isFavorite(String bookId) => repository.isFavorite(bookId);

  /// Livres favoris, ajout récent d'abord.
  Future<List<LibraryBook>> favorites() async {
    final ids = await repository.favoriteBookIds();
    final books = <LibraryBook>[];
    for (final id in ids) {
      final book = await repository.bookById(id);
      if (book != null) books.add(book);
    }
    return books;
  }

  Future<void> add(String bookId) async {
    final book = await repository.bookById(bookId);
    if (book == null) {
      throw StateError('Livre inconnu de la bibliothèque : $bookId');
    }
    await repository
        .addFavorite(Favorite(bookId: bookId, addedAt: DateTime.now()));
    eventBus.emit(FavoriteAddedEvent(
      book.id,
      title: book.title,
      author: book.author,
      coverUrl: book.coverUrl,
      language: book.language,
      format: book.format,
    ));
  }

  Future<void> remove(String bookId) async {
    if (await repository.isFavorite(bookId)) {
      await repository.removeFavorite(bookId);
      eventBus.emit(FavoriteRemovedEvent(bookId));
    }
  }

  /// Bascule l'état favori. Retourne le nouvel état.
  Future<bool> toggle(String bookId) async {
    if (await repository.isFavorite(bookId)) {
      await remove(bookId);
      return false;
    }
    await add(bookId);
    return true;
  }
}
