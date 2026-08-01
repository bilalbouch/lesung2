import 'dart:async';

import 'package:http/http.dart' as http;

import 'annas_archive_instances.dart';
import 'annas_archive_parser.dart';

/// Rapport de santé d'une instance, mesuré par une VRAIE petite
/// recherche (jamais un simple HEAD).
class InstanceHealthReport {
  final String instanceId;

  /// L'instance a répondu.
  final bool available;

  /// Temps de réponse de la requête fonctionnelle.
  final Duration? latency;

  /// Qualité 0..1 : la page retournée contient-elle de vrais résultats
  /// exploitables (hits parsés avec titres) ?
  final double quality;

  /// Challenge Cloudflare rencontré.
  final bool challengeDetected;

  /// Erreur éventuelle.
  final Object? error;

  /// Score composite 0..1 injecté dans l'instance pour le failover.
  final double score;

  const InstanceHealthReport({
    required this.instanceId,
    required this.available,
    this.latency,
    this.quality = 0,
    this.challengeDetected = false,
    this.error,
    required this.score,
  });
}

/// HealthCheck fonctionnel d'Anna's Archive.
///
/// Pour chaque instance : exécute une petite recherche réelle, parse le
/// résultat, mesure disponibilité + latence + qualité + challenge, puis
/// calcule un score et met à jour [ArchiveInstance.score] — le client
/// de transport utilisera automatiquement la meilleure instance en
/// premier.
class AnnaArchiveHealthCheck {
  final http.Client _http;
  final AnnaArchiveParser _parser;
  final Duration timeout;

  /// Requête de sonde : courte, en allemand (langue principale de l'app).
  static const probeQuery = 'kafka';
  static const probePath = '/search?q=$probeQuery&page=1';

  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

  AnnaArchiveHealthCheck({
    http.Client? httpClient,
    AnnaArchiveParser? parser,
    this.timeout = const Duration(seconds: 10),
  })  : _http = httpClient ?? http.Client(),
        _parser = parser ?? AnnaArchiveParser();

  /// Mesure toutes les instances en PARALLÈLE, met à jour leurs scores
  /// et retourne les rapports triés du meilleur au pire.
  Future<List<InstanceHealthReport>> checkAll(
      List<ArchiveInstance> instances) async {
    final reports = await Future.wait(
      instances.where((i) => i.enabled).map(checkInstance),
    );

    for (final report in reports) {
      final instance = instances.firstWhere((i) => i.id == report.instanceId);
      instance.score = report.score;
      instance.lastCheckedAt = DateTime.now();
    }

    reports.sort((a, b) => b.score.compareTo(a.score));
    return reports;
  }

  /// Mesure une seule instance via une recherche fonctionnelle.
  Future<InstanceHealthReport> checkInstance(ArchiveInstance instance) async {
    final sw = Stopwatch()..start();
    try {
      final response = await _http
          .get(Uri.parse('${instance.baseUrl}$probePath'),
              headers: {'user-agent': _userAgent})
          .timeout(timeout);
      sw.stop();

      final challenged = _parser.isCloudflareChallenge(
          response.statusCode, response.headers, response.body);
      if (challenged) {
        return InstanceHealthReport(
          instanceId: instance.id,
          available: true,
          latency: sw.elapsed,
          challengeDetected: true,
          score: 0.2, // disponible mais bloquée : dernier recours
        );
      }
      if (response.statusCode >= 400) {
        return InstanceHealthReport(
          instanceId: instance.id,
          available: false,
          latency: sw.elapsed,
          error: 'HTTP ${response.statusCode}',
          score: 0,
        );
      }

      // Qualité : la page contient-elle de vrais résultats exploitables ?
      final page = _parser.parseSearchPage(response.body);
      final quality = _measureQuality(page.hits.length);

      final score = _computeScore(
        available: true,
        latency: sw.elapsed,
        quality: quality,
      );

      return InstanceHealthReport(
        instanceId: instance.id,
        available: true,
        latency: sw.elapsed,
        quality: quality,
        score: score,
      );
    } catch (e) {
      sw.stop();
      return InstanceHealthReport(
        instanceId: instance.id,
        available: false,
        latency: sw.elapsed,
        error: e,
        score: 0,
      );
    }
  }

  /// 10+ résultats = qualité pleine ; dégradé en dessous.
  double _measureQuality(int hitCount) {
    if (hitCount >= 10) return 1;
    if (hitCount >= 5) return 0.8;
    if (hitCount >= 1) return 0.5;
    return 0;
  }

  /// Score composite : qualité 50 %, latence 35 %, disponibilité 15 %.
  double _computeScore({
    required bool available,
    required Duration latency,
    required double quality,
  }) {
    if (!available) return 0;
    final ms = latency.inMilliseconds;
    final latencyScore = ms < 800
        ? 1.0
        : ms < 1500
            ? 0.85
            : ms < 3000
                ? 0.6
                : ms < 5000
                    ? 0.35
                    : 0.15;
    return quality * 0.5 + latencyScore * 0.35 + 0.15;
  }
}

/// Instance indisponible après health check.
class NoHealthyInstanceException implements Exception {
  final List<InstanceHealthReport> reports;
  const NoHealthyInstanceException(this.reports);
}
