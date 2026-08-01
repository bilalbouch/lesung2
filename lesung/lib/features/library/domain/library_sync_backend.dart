import 'entities/collection.dart';
import 'entities/favorite.dart';
import 'entities/library_book.dart';
import 'entities/reading_progress.dart';

/// Instantané synchronisable de la bibliothèque.
///
/// Volontairement limité aux données de bibliothèque (jamais les fichiers
/// eux-mêmes : un futur chiffrement/transfert de fichiers sera un contrat
/// séparé). Les dates permettent une résolution de conflits « dernier
/// auteur gagne » sans changer les composants.
class LibrarySnapshot {
  final List<LibraryBook> books;
  final List<Favorite> favorites;
  final List<Collection> collections;
  final List<CollectionBook> collectionBooks;
  final List<ReadingProgress> readingProgress;

  /// Horodatage de la capture (côté producteur).
  final DateTime capturedAt;

  const LibrarySnapshot({
    required this.books,
    required this.favorites,
    required this.collections,
    required this.collectionBooks,
    required this.readingProgress,
    required this.capturedAt,
  });
}

/// CONTRAT pour une future synchronisation Cloud.
///
/// PRÉPARATION UNIQUEMENT — aucune implémentation n'existe encore, et
/// aucun composant actuel ne dépend d'un backend concret. Le jour où une
/// synchro est ajoutée, elle implémentera cette interface (ex.
/// WebDAV, serveur auto-hébergé...) sans modifier ni LibraryManager,
/// ni les managers, ni le repository :
///
/// - [push] envoie l'état local sous forme de [LibrarySnapshot]
/// - [pull] récupère l'état distant ; la fusion (last-write-wins sur
///   updatedAt) sera appliquée via le [LibraryRepository] existant
///
/// Contraintes imposées aux futures implémentations :
/// - les fichiers de livres ne transitent JAMAIS par ce contrat
/// - aucune donnée n'est envoyée sans action explicite de l'utilisateur
///   (application privée, pas de télémétrie)
abstract class LibrarySyncBackend {
  /// Identifiant stable du backend (ex. 'webdav', 'lesung_server').
  String get backendId;

  /// Le backend est-il configuré et joignable ?
  Future<bool> isAvailable();

  /// Envoie un instantané complet de la bibliothèque locale.
  Future<void> push(LibrarySnapshot snapshot);

  /// Récupère l'instantané distant, ou null si aucun n'existe encore.
  Future<LibrarySnapshot?> pull();
}
