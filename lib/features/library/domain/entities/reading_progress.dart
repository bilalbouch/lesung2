/// Progression de lecture d'un livre.
class ReadingProgress {
  final String bookId;

  /// Localisateur opaque : CFI (epub) ou numéro de page (pdf).
  final String locator;

  /// Progression 0..1.
  final double progress;

  final DateTime updatedAt;

  const ReadingProgress({
    required this.bookId,
    required this.locator,
    required this.progress,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'locator': locator,
        'progress': progress,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ReadingProgress.fromJson(Map<String, dynamic> json) =>
      ReadingProgress(
        bookId: json['bookId'] as String,
        locator: json['locator'] as String,
        progress: (json['progress'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
