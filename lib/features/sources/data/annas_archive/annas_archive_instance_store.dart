import 'dart:convert';
import 'dart:io';

import 'annas_archive_instances.dart';

/// Persistance du classement des instances (score + dernière mesure).
///
/// Le HealthCheck mesure les miroirs ; ce store SAUVEGARDE le classement
/// résultant sur disque afin qu'une nouvelle session démarre avec la
/// meilleure instance connue, sans attendre une nouvelle mesure.
///
/// Format : un seul fichier JSON { id: {score, lastCheckedAt} }.
/// Écriture atomique (fichier temporaire + renommage), répertoire
/// injecté — même discipline que les repositories du projet.
class AnnaArchiveInstanceStore {
  final Directory directory;

  static const _fileName = 'instance_ranking.json';

  AnnaArchiveInstanceStore(this.directory);

  File get _file => File('${directory.path}/$_fileName');

  /// Restaure les scores sauvegardés sur les [instances] (par id).
  ///
  /// Les ids inconnus sont ignorés ; les instances sans sauvegarde
  /// gardent leur score par défaut. Fichier absent ou illisible :
  /// no-op silencieux (le HealthCheck refera une mesure).
  Future<DateTime?> restore(List<ArchiveInstance> instances) async {
    try {
      if (!await _file.exists()) return null;
      final raw = jsonDecode(await _file.readAsString())
          as Map<String, dynamic>;
      DateTime? newest;
      for (final instance in instances) {
        final saved = raw[instance.id];
        if (saved is! Map<String, dynamic>) continue;
        final score = saved['score'];
        final checked = saved['lastCheckedAt'];
        if (score is num) instance.score = score.toDouble();
        if (checked is String) {
          final at = DateTime.tryParse(checked);
          if (at != null) {
            instance.lastCheckedAt = at;
            if (newest == null || at.isAfter(newest)) newest = at;
          }
        }
      }
      return newest; // mesure la plus récente restaurée (fraîcheur)
    } catch (_) {
      return null; // sauvegarde corrompue : repartir des défauts
    }
  }

  /// Sauvegarde le classement courant (appelée après chaque mesure).
  Future<void> persist(List<ArchiveInstance> instances) async {
    await directory.create(recursive: true);
    final payload = {
      for (final i in instances)
        i.id: {
          'score': i.score,
          'lastCheckedAt': i.lastCheckedAt?.toIso8601String(),
        },
    };
    // Écriture atomique : jamais de fichier à moitié écrit.
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(payload));
    await tmp.rename(_file.path);
  }
}
