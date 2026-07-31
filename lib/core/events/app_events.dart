/// Vocabulaire d'événements partagé de l'application.
///
/// NOYAU PARTAGÉ : ces événements n'appartiennent à aucune feature.
/// Le DownloadManager publie [DownloadFinishedEvent] sans connaître
/// la bibliothèque ; la bibliothèque l'écoute sans connaître le
/// DownloadManager. Un futur Reader publiera les événements de lecture
/// sur le même principe.
library;

/// Classe mère scellée de tous les événements applicatifs.
sealed class AppEvent {
  final DateTime occurredAt;
  AppEvent() : occurredAt = DateTime.now();
}

// --------------------------------------------------------------------
// Téléchargements (publiés par le moteur de téléchargement)
// --------------------------------------------------------------------

/// Un téléchargement est terminé et vérifié.
class DownloadFinishedEvent extends AppEvent {
  final String bookId;
  final String title;
  final String? author;
  final String? coverUrl;
  final String? language;
  final String format;
  final String filePath;
  final int fileSizeBytes;

  /// L'empreinte MD5 annoncée a été vérifiée avec succès.
  final bool md5Verified;

  DownloadFinishedEvent({
    required this.bookId,
    required this.title,
    this.author,
    this.coverUrl,
    this.language,
    required this.format,
    required this.filePath,
    required this.fileSizeBytes,
    required this.md5Verified,
  });
}

/// Un fichier téléchargé a été supprimé du disque (par l'utilisateur
/// ou par détection de la synchronisation).
class DownloadRemovedEvent extends AppEvent {
  final String bookId;
  final String? filePath;
  DownloadRemovedEvent({required this.bookId, this.filePath});
}

// --------------------------------------------------------------------
// Bibliothèque (publiés via le LibraryManager)
// --------------------------------------------------------------------

/// Un livre entre dans la bibliothèque (favori, collection, import...).
class BookAddedEvent extends AppEvent {
  final String bookId;
  BookAddedEvent(this.bookId);
}

/// Un livre est retiré de la bibliothèque.
class BookRemovedEvent extends AppEvent {
  final String bookId;
  final bool deleteFile;
  BookRemovedEvent(this.bookId, {this.deleteFile = false});
}

class FavoriteAddedEvent extends AppEvent {
  final String bookId;
  final String? title;
  final String? author;
  final String? coverUrl;
  final String? language;
  final String? format;
  FavoriteAddedEvent(this.bookId,
      {this.title, this.author, this.coverUrl, this.language, this.format});
}

class FavoriteRemovedEvent extends AppEvent {
  final String bookId;
  FavoriteRemovedEvent(this.bookId);
}

class CollectionCreatedEvent extends AppEvent {
  final String collectionId;
  final String name;
  CollectionCreatedEvent(this.collectionId, this.name);
}

class CollectionUpdatedEvent extends AppEvent {
  final String collectionId;
  CollectionUpdatedEvent(this.collectionId);
}

class CollectionDeletedEvent extends AppEvent {
  final String collectionId;
  CollectionDeletedEvent(this.collectionId);
}

class CollectionBookAddedEvent extends AppEvent {
  final String collectionId;
  final String bookId;
  CollectionBookAddedEvent(this.collectionId, this.bookId);
}

class CollectionBookRemovedEvent extends AppEvent {
  final String collectionId;
  final String bookId;
  CollectionBookRemovedEvent(this.collectionId, this.bookId);
}

// --------------------------------------------------------------------
// Lecture (publiés par le futur Reader via ces mêmes contrats)
// --------------------------------------------------------------------

class ReadingSessionOpenedEvent extends AppEvent {
  final String bookId;
  ReadingSessionOpenedEvent(this.bookId);
}

class ReadingSessionClosedEvent extends AppEvent {
  final String bookId;

  /// Durée effective de la session en secondes.
  final int durationSeconds;
  ReadingSessionClosedEvent(this.bookId, {required this.durationSeconds});
}

class ReadingProgressChangedEvent extends AppEvent {
  final String bookId;

  /// Localisateur opaque (CFI epub, numéro de page pdf...).
  final String locator;

  /// Progression 0..1.
  final double progress;
  ReadingProgressChangedEvent(this.bookId, this.locator, this.progress);
}

class BookFinishedEvent extends AppEvent {
  final String bookId;
  BookFinishedEvent(this.bookId);
}

// --------------------------------------------------------------------
// Synchronisation
// --------------------------------------------------------------------

/// Résultat d'un scan de synchronisation bibliothèque <-> disque.
class LibraryFilesScannedEvent extends AppEvent {
  final List<String> missingBookIds;
  final List<String> orphanFilePaths;
  final int correctionsApplied;
  LibraryFilesScannedEvent({
    required this.missingBookIds,
    required this.orphanFilePaths,
    required this.correctionsApplied,
  });
}
