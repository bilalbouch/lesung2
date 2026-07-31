/// Miroirs (instances) d'Anna's Archive.
///
/// Reprise nettoyée de la liste auditée, enrichie d'un [score] issu du
/// HealthCheck : le client trie les instances par score décroissant.
library;

class ArchiveInstance {
  final String id;
  final String name;
  final String baseUrl;
  bool enabled;

  /// Score 0..1 mesuré par le HealthCheck fonctionnel (1 = meilleur).
  /// 0.5 par défaut (instance jamais mesurée).
  double score;

  /// Horodatage de la dernière mesure.
  DateTime? lastCheckedAt;

  ArchiveInstance({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.enabled = true,
    this.score = 0.5,
    this.lastCheckedAt,
  });
}

/// Miroirs par défaut (même liste que l'audit OpenlibExtended).
List<ArchiveInstance> defaultArchiveInstances() => [
      ArchiveInstance(
        id: 'annas_archive_gl',
        name: "Anna's Archive (.gl)",
        baseUrl: 'https://annas-archive.gl',
      ),
      ArchiveInstance(
        id: 'annas_archive_pk',
        name: "Anna's Archive (.pk)",
        baseUrl: 'https://annas-archive.pk',
      ),
      ArchiveInstance(
        id: 'annas_archive_vg',
        name: "Anna's Archive (.vg)",
        baseUrl: 'https://annas-archive.vg',
      ),
      ArchiveInstance(
        id: 'annas_archive_gd',
        name: "Anna's Archive (.gd)",
        baseUrl: 'https://annas-archive.gd',
      ),
    ];
