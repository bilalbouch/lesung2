/// Session de lecture (table history).
class ReadingHistoryEntry {
  final int? id;
  final String bookId;
  final DateTime openedAt;
  final DateTime? closedAt;

  /// Durée effective en secondes (calculée à la fermeture).
  final int? durationSeconds;

  const ReadingHistoryEntry({
    this.id,
    required this.bookId,
    required this.openedAt,
    this.closedAt,
    this.durationSeconds,
  });

  ReadingHistoryEntry close(DateTime at, int durationSeconds) =>
      ReadingHistoryEntry(
          id: id,
          bookId: bookId,
          openedAt: openedAt,
          closedAt: at,
          durationSeconds: durationSeconds);

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'openedAt': openedAt.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
        'durationSeconds': durationSeconds,
      };

  factory ReadingHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ReadingHistoryEntry(
        id: json['id'] as int?,
        bookId: json['bookId'] as String,
        openedAt: DateTime.parse(json['openedAt'] as String),
        closedAt: json['closedAt'] == null
            ? null
            : DateTime.parse(json['closedAt'] as String),
        durationSeconds: json['durationSeconds'] as int?,
      );
}

/// Enregistrement de téléchargement (table downloads).
class DownloadRecord {
  final String bookId;
  final String filePath;
  final int fileSizeBytes;
  final bool md5Verified;
  final DateTime completedAt;

  const DownloadRecord({
    required this.bookId,
    required this.filePath,
    required this.fileSizeBytes,
    required this.md5Verified,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'filePath': filePath,
        'fileSizeBytes': fileSizeBytes,
        'md5Verified': md5Verified ? 1 : 0,
        'completedAt': completedAt.toIso8601String(),
      };

  factory DownloadRecord.fromJson(Map<String, dynamic> json) =>
      DownloadRecord(
        bookId: json['bookId'] as String,
        filePath: json['filePath'] as String,
        fileSizeBytes: json['fileSizeBytes'] as int,
        md5Verified: (json['md5Verified'] as int? ?? 0) == 1,
        completedAt: DateTime.parse(json['completedAt'] as String),
      );
}
