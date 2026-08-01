import '../../../search/domain/entities/search_query.dart';

/// Entrée d'historique : trace d'un téléchargement terminé.
class DownloadHistoryEntry {
  final String taskId;
  final String title;
  final String? author;
  final BookFormat format;
  final String filePath;
  final int fileSizeBytes;

  /// Résultat de la vérification d'intégrité.
  final bool md5Verified;

  final DateTime completedAt;

  const DownloadHistoryEntry({
    required this.taskId,
    required this.title,
    this.author,
    required this.format,
    required this.filePath,
    required this.fileSizeBytes,
    required this.md5Verified,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'title': title,
        'author': author,
        'format': format.name,
        'filePath': filePath,
        'fileSizeBytes': fileSizeBytes,
        'md5Verified': md5Verified,
        'completedAt': completedAt.toIso8601String(),
      };

  factory DownloadHistoryEntry.fromJson(Map<String, dynamic> json) =>
      DownloadHistoryEntry(
        taskId: json['taskId'] as String,
        title: json['title'] as String,
        author: json['author'] as String?,
        format: bookFormatFromString(json['format'] as String?),
        filePath: json['filePath'] as String,
        fileSizeBytes: json['fileSizeBytes'] as int,
        md5Verified: json['md5Verified'] as bool,
        completedAt: DateTime.parse(json['completedAt'] as String),
      );
}
