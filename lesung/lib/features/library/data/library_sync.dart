import 'dart:io';

import '../domain/library_repository.dart';

/// Résultat d'un scan de synchronisation bibliothèque <-> disque.
class LibrarySyncReport {
  /// Livres dont le fichier référencé a disparu du disque.
  final List<String> missingBookIds;

  /// Livres dont le fichier est réapparu (marque fileMissing levée).
  final List<String> restoredBookIds;

  /// Fichiers présents dans le dossier des livres mais inconnus de la base.
  ///
  /// Jamais supprimés automatiquement : rapportés à l'utilisateur.
  final List<String> orphanFilePaths;

  /// Nombre total de corrections appliquées à la base.
  final int correctionsApplied;

  const LibrarySyncReport({
    required this.missingBookIds,
    required this.restoredBookIds,
    required this.orphanFilePaths,
    required this.correctionsApplied,
  });

  bool get hasChanges => correctionsApplied > 0 || orphanFilePaths.isNotEmpty;
}

/// Synchronisation bibliothèque <-> système de fichiers.
///
/// Lancée au démarrage : vérifie que les fichiers référencés existent,
/// détecte les fichiers supprimés hors de l'application, lève la marque
/// quand un fichier réapparaît (SD card réinsérée, restauration...),
/// et repère les fichiers orphelins. La base est corrigée
/// automatiquement ; les fichiers eux-mêmes ne sont jamais effacés.
class LibrarySync {
  final LibraryRepository repository;

  /// Dossier racine des livres téléchargés.
  final Directory booksDirectory;

  /// Extensions reconnues comme fichiers de livres.
  static const bookExtensions = {
    '.epub', '.pdf', '.cbr', '.cbz', '.azw3', '.mobi', '.fb2', '.djvu',
  };

  LibrarySync({required this.repository, required this.booksDirectory});

  Future<LibrarySyncReport> synchronize() async {
    final books = await repository.allBooks();
    final missing = <String>[];
    final restored = <String>[];
    var corrections = 0;

    final referencedPaths = <String>{};

    for (final book in books) {
      final path = book.filePath;
      if (!book.downloaded || path == null) continue;

      final normalized = File(path).absolute.path;
      referencedPaths.add(normalized);

      final exists = await File(path).exists();
      if (!exists && !book.fileMissing) {
        await repository.saveBook(book.copyWith(
            fileMissing: true, updatedAt: DateTime.now()));
        missing.add(book.id);
        corrections += 1;
      } else if (exists && book.fileMissing) {
        await repository.saveBook(book.copyWith(
            fileMissing: false, updatedAt: DateTime.now()));
        restored.add(book.id);
        corrections += 1;
      }
    }

    final orphans = await _findOrphanFiles(referencedPaths);

    return LibrarySyncReport(
      missingBookIds: missing,
      restoredBookIds: restored,
      orphanFilePaths: orphans,
      correctionsApplied: corrections,
    );
  }

  /// Fichiers de livres présents sur le disque mais non référencés.
  Future<List<String>> _findOrphanFiles(Set<String> referencedPaths) async {
    final orphans = <String>[];
    if (!await booksDirectory.exists()) return orphans;
    await for (final entity
        in booksDirectory.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final path = entity.absolute.path;
      final lower = path.toLowerCase();
      final isBook = bookExtensions.any(lower.endsWith);
      if (isBook && !referencedPaths.contains(path)) {
        orphans.add(path);
      }
    }
    orphans.sort();
    return orphans;
  }
}
