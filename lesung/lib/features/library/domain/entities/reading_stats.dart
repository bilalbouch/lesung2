/// Statistiques agrégées de la bibliothèque (vue calculée).
class ReadingStats {
  final int totalBooks;
  final int downloadedBooks;
  final int notDownloadedBooks;
  final int finishedBooks;
  final int inProgressBooks;
  final int favoritesCount;
  final int collectionsCount;

  /// Temps de lecture cumulé, toutes sessions confondues.
  final int totalReadingSeconds;

  /// Espace occupé par les fichiers téléchargés (octets).
  final int totalSizeBytes;

  /// Répartition par langue ISO ('de': 12, 'fr': 5...).
  final Map<String, int> booksByLanguage;

  /// Répartition par format ('epub': 20, 'pdf': 8...).
  final Map<String, int> booksByFormat;

  const ReadingStats({
    required this.totalBooks,
    required this.downloadedBooks,
    required this.notDownloadedBooks,
    required this.finishedBooks,
    required this.inProgressBooks,
    required this.favoritesCount,
    required this.collectionsCount,
    required this.totalReadingSeconds,
    required this.totalSizeBytes,
    required this.booksByLanguage,
    required this.booksByFormat,
  });

  Duration get totalReadingTime => Duration(seconds: totalReadingSeconds);
}

/// Compteurs persistants (table statistics) — alimentés
/// incrémentalement par les événements, sans recalcul complet.
class StatisticsCounters {
  final int totalReadingSeconds;
  final int sessionsCount;

  const StatisticsCounters({
    this.totalReadingSeconds = 0,
    this.sessionsCount = 0,
  });

  StatisticsCounters addSession(int durationSeconds) => StatisticsCounters(
      totalReadingSeconds: totalReadingSeconds + durationSeconds,
      sessionsCount: sessionsCount + 1);

  Map<String, dynamic> toJson() => {
        'totalReadingSeconds': totalReadingSeconds,
        'sessionsCount': sessionsCount,
      };

  factory StatisticsCounters.fromJson(Map<String, dynamic> json) =>
      StatisticsCounters(
        totalReadingSeconds: json['totalReadingSeconds'] as int? ?? 0,
        sessionsCount: json['sessionsCount'] as int? ?? 0,
      );
}
