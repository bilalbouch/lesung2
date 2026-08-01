/// Statistiques de lecture propres au Reader (par livre).
///
/// Indépendant des statistiques de la bibliothèque : ici on mesure ce
/// que le Reader voit (sessions, temps, progression maximale atteinte).
library;

/// Statistiques agrégées d'un livre.
class ReaderBookStats {
  final String bookId;
  final int totalSeconds;
  final int sessionsCount;
  final DateTime firstOpenedAt;
  final DateTime lastOpenedAt;

  /// Progression maximale jamais atteinte (0..1).
  final double furthestProgress;

  const ReaderBookStats({
    required this.bookId,
    this.totalSeconds = 0,
    this.sessionsCount = 0,
    required this.firstOpenedAt,
    required this.lastOpenedAt,
    this.furthestProgress = 0,
  });

  ReaderBookStats recordSession({
    required int durationSeconds,
    required DateTime at,
    double progress = 0,
  }) =>
      ReaderBookStats(
        bookId: bookId,
        totalSeconds: totalSeconds + durationSeconds,
        sessionsCount: sessionsCount + 1,
        firstOpenedAt: firstOpenedAt,
        lastOpenedAt: at,
        furthestProgress:
            progress > furthestProgress ? progress : furthestProgress,
      );

  ReaderBookStats updateProgress(double progress, DateTime at) =>
      ReaderBookStats(
        bookId: bookId,
        totalSeconds: totalSeconds,
        sessionsCount: sessionsCount,
        firstOpenedAt: firstOpenedAt,
        lastOpenedAt: at,
        furthestProgress:
            progress > furthestProgress ? progress : furthestProgress,
      );

  Duration get totalReadingTime => Duration(seconds: totalSeconds);

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'totalSeconds': totalSeconds,
        'sessionsCount': sessionsCount,
        'firstOpenedAt': firstOpenedAt.toIso8601String(),
        'lastOpenedAt': lastOpenedAt.toIso8601String(),
        'furthestProgress': furthestProgress,
      };

  factory ReaderBookStats.fromJson(Map<String, dynamic> json) =>
      ReaderBookStats(
        bookId: json['bookId'] as String,
        totalSeconds: (json['totalSeconds'] as num?)?.toInt() ?? 0,
        sessionsCount: (json['sessionsCount'] as num?)?.toInt() ?? 0,
        firstOpenedAt:
            DateTime.tryParse(json['firstOpenedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
        lastOpenedAt:
            DateTime.tryParse(json['lastOpenedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
        furthestProgress:
            (json['furthestProgress'] as num?)?.toDouble() ?? 0,
      );
}

/// Gestion des statistiques de lecture du Reader.
///
/// Le ReaderManager ouvre une session à l'ouverture d'un livre et la
/// clôture à la fermeture (ou à l'auto-save) ; les durées sont cumulées
/// ici et persistées via le repository.
class ReaderStatistics {
  final Future<ReaderBookStats?> Function(String bookId) _load;
  final Future<void> Function(ReaderBookStats) _save;
  final Future<List<ReaderBookStats>> Function() _loadAll;

  /// Début de la session courante (null si aucun livre ouvert).
  DateTime? _sessionStartedAt;

  ReaderStatistics({
    required Future<ReaderBookStats?> Function(String bookId) load,
    required Future<void> Function(ReaderBookStats) save,
    required Future<List<ReaderBookStats>> Function() loadAll,
  })  : _load = load,
        _save = save,
        _loadAll = loadAll;

  bool get sessionActive => _sessionStartedAt != null;

  /// Démarre la mesure. Réinitialise si une session était déjà ouverte.
  void startSession() {
    _sessionStartedAt = DateTime.now();
  }

  /// Durée de la session en cours (0 si aucune).
  int get currentSessionSeconds => _sessionStartedAt == null
      ? 0
      : DateTime.now().difference(_sessionStartedAt!).inSeconds;

  /// Clôture la session et cumule ses secondes dans les statistiques
  /// persistées du livre. Sans effet si aucune session n'est ouverte.
  Future<ReaderBookStats> endSession(String bookId,
      {double progress = 0}) async {
    final startedAt = _sessionStartedAt;
    _sessionStartedAt = null;
    final now = DateTime.now();
    final seconds = startedAt == null
        ? 0
        : now.difference(startedAt).inSeconds.clamp(0, 1 << 31);

    final existing = await _load(bookId);
    final stats = (existing ??
            ReaderBookStats(
                bookId: bookId,
                firstOpenedAt: startedAt ?? now,
                lastOpenedAt: now))
        .recordSession(
            durationSeconds: seconds, at: now, progress: progress);
    await _save(stats);
    return stats;
  }

  /// Met à jour la progression maximale atteinte sans clôturer la
  /// session (appelé par l'auto-save).
  Future<void> recordProgress(String bookId, double progress) async {
    final existing = await _load(bookId);
    if (existing == null) return; // la première session créera l'entrée
    await _save(existing.updateProgress(progress, DateTime.now()));
  }

  Future<ReaderBookStats?> statsFor(String bookId) => _load(bookId);

  /// Statistiques de tous les livres (temps total, etc.).
  Future<List<ReaderBookStats>> allStats() => _loadAll();

  /// Temps de lecture cumulé tous livres confondus.
  Future<Duration> totalReadingTime() async {
    final all = await _loadAll();
    var seconds = 0;
    for (final stats in all) {
      seconds += stats.totalSeconds;
    }
    return Duration(seconds: seconds);
  }
}
