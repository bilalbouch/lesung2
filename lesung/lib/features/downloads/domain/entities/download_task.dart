import '../../../search/domain/entities/download_link.dart';
import '../../../search/domain/entities/search_query.dart';

/// Statuts du cycle de vie d'un téléchargement.
enum DownloadStatus {
  /// En file d'attente, pas encore démarré.
  queued,

  /// Résolution des liens intermédiaires en cours.
  resolving,

  /// Téléchargement actif.
  downloading,

  /// Suspendu par l'utilisateur (reprise possible via HTTP Range).
  paused,

  /// Vérification d'intégrité en cours.
  verifying,

  /// Terminé et vérifié.
  completed,

  /// Échoué définitivement (tous les liens épuisés).
  failed,

  /// Annulé par l'utilisateur (fichier partiel supprimé).
  cancelled,
}

/// Tâche de téléchargement — construite UNIQUEMENT à partir de
/// [DownloadLink] normalisés. Le moteur ne connaît aucune source.
class DownloadTask {
  /// Identifiant unique de la tâche.
  final String id;

  final String title;
  final String? author;
  final String? coverUrl;
  final BookFormat format;

  /// Liens candidats, ordonnés par préférence : directs (http),
  /// premium (clé) ou intermédiaires (à résoudre via le
  /// DownloadLinkResolver injecté — jamais via une source concrète).
  final List<DownloadLink> links;

  /// Empreinte MD5 annoncée (vérification post-téléchargement).
  final String? expectedMd5;

  /// Taille annoncée en octets, si connue.
  final int? expectedSizeBytes;

  // -- État mutable piloté par le moteur --

  DownloadStatus status;
  int receivedBytes;
  int totalBytes;
  String? errorMessage;

  /// URL effectivement utilisée (miroir en cours ou ayant abouti).
  Uri? activeUrl;

  final DateTime createdAt;
  DateTime? completedAt;

  DownloadTask({
    required this.id,
    required this.title,
    this.author,
    this.coverUrl,
    this.format = BookFormat.unknown,
    required this.links,
    this.expectedMd5,
    this.expectedSizeBytes,
    this.status = DownloadStatus.queued,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.activeUrl,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0, 1) : 0;

  bool get isActive =>
      status == DownloadStatus.downloading ||
      status == DownloadStatus.resolving ||
      status == DownloadStatus.verifying;

  bool get isTerminal =>
      status == DownloadStatus.completed ||
      status == DownloadStatus.failed ||
      status == DownloadStatus.cancelled;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'coverUrl': coverUrl,
        'format': format.name,
        'links': links
            .map((l) => {
                  'url': l.url.toString(),
                  'kind': l.kind.name,
                  'format': l.format.name,
                  'md5': l.md5,
                  'fileSizeBytes': l.fileSizeBytes,
                })
            .toList(),
        'expectedMd5': expectedMd5,
        'expectedSizeBytes': expectedSizeBytes,
        'status': status.name,
        'receivedBytes': receivedBytes,
        'totalBytes': totalBytes,
        'errorMessage': errorMessage,
        'activeUrl': activeUrl?.toString(),
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory DownloadTask.fromJson(Map<String, dynamic> json) => DownloadTask(
        id: json['id'] as String,
        title: json['title'] as String,
        author: json['author'] as String?,
        coverUrl: json['coverUrl'] as String?,
        format: bookFormatFromString(json['format'] as String?),
        links: (json['links'] as List)
            .map((l) => DownloadLink(
                  url: Uri.parse(l['url'] as String),
                  kind: DownloadLinkKind.values.byName(l['kind'] as String),
                  format: bookFormatFromString(l['format'] as String?),
                  md5: l['md5'] as String?,
                  fileSizeBytes: l['fileSizeBytes'] as int?,
                ))
            .toList(),
        expectedMd5: json['expectedMd5'] as String?,
        expectedSizeBytes: json['expectedSizeBytes'] as int?,
        status: DownloadStatus.values.byName(json['status'] as String),
        receivedBytes: json['receivedBytes'] as int? ?? 0,
        totalBytes: json['totalBytes'] as int? ?? 0,
        errorMessage: json['errorMessage'] as String?,
        activeUrl:
            json['activeUrl'] == null ? null : Uri.parse(json['activeUrl']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
      );
}

/// Progression temps réel émise par le worker.
class DownloadProgress {
  final String taskId;
  final DownloadStatus status;

  final int receivedBytes;
  final int totalBytes;

  /// Vitesse instantanée (fenêtre glissante) en octets/s.
  final double speedBytesPerSec;

  final String? errorMessage;

  const DownloadProgress({
    required this.taskId,
    required this.status,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.speedBytesPerSec = 0,
    this.errorMessage,
  });

  double get progress =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0, 1) : 0;

  /// Estimation du temps restant. Null si indéterminable.
  Duration? get eta {
    if (speedBytesPerSec <= 0 || totalBytes <= receivedBytes) return null;
    return Duration(
        seconds: ((totalBytes - receivedBytes) / speedBytesPerSec).round());
  }
}
