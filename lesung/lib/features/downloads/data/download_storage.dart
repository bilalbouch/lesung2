import 'dart:io';

import '../../search/domain/entities/search_query.dart';
import '../domain/entities/download_task.dart';

/// Gestion du stockage disque — UNIQUEMENT les fichiers.
///
/// - répertoires injectés (testables en temporaire)
/// - fichiers partiels dans un sous-dossier `.partial`
/// - nommage sûr et déterministe
/// - finalisation = déplacement atomique du partiel vers le final
class DownloadStorage {
  /// Répertoire racine des livres terminés.
  final Directory booksDirectory;

  Directory get partialDirectory =>
      Directory('${booksDirectory.path}/.partial');

  DownloadStorage({required this.booksDirectory});

  Future<void> initialize() async {
    if (!await booksDirectory.exists()) {
      await booksDirectory.create(recursive: true);
    }
    if (!await partialDirectory.exists()) {
      await partialDirectory.create(recursive: true);
    }
  }

  /// Nom de fichier sûr pour une tâche : Titre_(Auteur)_id.ext
  String fileNameFor(DownloadTask task) {
    final ext = task.format == BookFormat.unknown ? 'bin' : task.format.name;
    final base = _sanitize(task.title);
    final author =
        task.author == null ? '' : '_${_sanitize(task.author!)}';
    final shortId =
        task.id.length > 12 ? task.id.substring(task.id.length - 12) : task.id;
    return '$base$author _$shortId.$ext'
        .replaceAll(RegExp(r'\s+_'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  File partialFileFor(DownloadTask task) =>
      File('${partialDirectory.path}/${fileNameFor(task)}');

  File finalFileFor(DownloadTask task) =>
      File('${booksDirectory.path}/${fileNameFor(task)}');

  /// Octets déjà téléchargés (fichier partiel existant) — base de la
  /// reprise HTTP Range.
  Future<int> existingPartialBytes(DownloadTask task) async {
    final file = partialFileFor(task);
    return await file.exists() ? await file.length() : 0;
  }

  /// Finalise : déplace le partiel vers le fichier définitif.
  Future<File> finalize(DownloadTask task) async {
    final partial = partialFileFor(task);
    final target = finalFileFor(task);
    if (await target.exists()) await target.delete();
    return partial.rename(target.path);
  }

  /// Supprime le fichier partiel (annulation, retry propre).
  Future<void> deletePartial(DownloadTask task) async {
    final file = partialFileFor(task);
    if (await file.exists()) await file.delete();
  }

  /// Supprime le fichier final (suppression d'un livre).
  Future<void> deleteFinal(DownloadTask task) async {
    final file = finalFileFor(task);
    if (await file.exists()) await file.delete();
  }

  /// Espace libre approximatif en octets (null si indéterminable).
  Future<int?> freeSpaceBytes() async {
    try {
      final stat = await Process.run('df', ['-k', booksDirectory.path]);
      final lines = (stat.stdout as String).trim().split('\n');
      if (lines.length < 2) return null;
      final parts = lines.last.split(RegExp(r'\s+'));
      return int.parse(parts[3]) * 1024;
    } catch (_) {
      return null;
    }
  }

  String _sanitize(String input) {
    var s = input.trim();
    s = s.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.length > 80) s = s.substring(0, 80).trim();
    return s.isEmpty ? 'livre' : s;
  }
}
