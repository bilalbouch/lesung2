import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../../core/cancellation/cancellation_token.dart';
import 'annas_archive_instances.dart';
import 'annas_archive_parser.dart';

export '../../../../core/cancellation/cancellation_token.dart';

/// Un miroir présente un challenge Cloudflare.
class InstanceChallengedException implements Exception {
  final String instanceBaseUrl;
  const InstanceChallengedException(this.instanceBaseUrl);
  @override
  String toString() =>
      'InstanceChallengedException: challenge sur $instanceBaseUrl';
}

/// Tous les miroirs ont échoué.
class AllInstancesFailedException implements Exception {
  final List<Object> errors;
  final bool cloudflareOnAll;
  const AllInstancesFailedException(this.errors,
      {this.cloudflareOnAll = false});
  @override
  String toString() =>
      'AllInstancesFailedException(${errors.length} miroirs, '
      'cloudflareOnAll: $cloudflareOnAll)';
}

/// Réponse HTTP brute d'un miroir (corps + méta de transport).
class RawHttpResponse {
  final String body;
  final int statusCode;
  final Map<String, String> headers;
  final String instanceBaseUrl;
  final Duration elapsed;

  const RawHttpResponse({
    required this.body,
    required this.statusCode,
    required this.headers,
    required this.instanceBaseUrl,
    required this.elapsed,
  });
}

/// Client HTTP d'Anna's Archive — TRANSPORT UNIQUEMENT.
///
/// Aucune logique métier, aucun parsing : il récupère des pages HTML.
/// - failover multi-instances ordonné par score décroissant
/// - retry avec backoff sur les erreurs réseau transitoires
/// - timeout par tentative
/// - annulation via [CancellationToken]
/// - détection Cloudflare déléguée au parser (seul fichier couplé au
///   markup), remontée comme [InstanceChallengedException]
class AnnaArchiveClient {
  final http.Client _http;
  final AnnaArchiveParser _parser;
  final List<ArchiveInstance> instances;

  /// Timeout par tentative HTTP.
  final Duration attemptTimeout;

  /// Tentatives max par instance (1 initiale + retries).
  final int maxAttemptsPerInstance;

  /// Cookies de session injectés après résolution d'un challenge
  /// (fournis par le CloudflareGuard, jamais gérés ici).
  Map<String, String> sessionHeaders = {};

  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

  AnnaArchiveClient({
    http.Client? httpClient,
    AnnaArchiveParser? parser,
    List<ArchiveInstance>? instances,
    this.attemptTimeout = const Duration(seconds: 12),
    this.maxAttemptsPerInstance = 2,
  })  : _http = httpClient ?? http.Client(),
        _parser = parser ?? AnnaArchiveParser(),
        instances = instances ?? defaultArchiveInstances();

  /// Récupère [path] sur le meilleur miroir disponible.
  ///
  /// Les instances sont essayées dans l'ordre de leur [ArchiveInstance.score]
  /// décroissant (meilleure d'abord). Une erreur réseau transitoire est
  /// retentée avec backoff ; un challenge Cloudflare ou une erreur 5xx
  /// fait basculer sur l'instance suivante ; une erreur 4xx est définitive.
  Future<RawHttpResponse> get(String path, {CancellationToken? token}) async {
    token?.throwIfCancelled();

    final candidates = instances
        .where((i) => i.enabled)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    if (candidates.isEmpty) {
      throw StateError("Aucune instance Anna's Archive activée.");
    }

    final errors = <Object>[];
    var challenges = 0;

    for (final instance in candidates) {
      for (var attempt = 0; attempt < maxAttemptsPerInstance; attempt++) {
        token?.throwIfCancelled();
        final sw = Stopwatch()..start();
        try {
          final response = await _http
              .get(Uri.parse('${instance.baseUrl}$path'), headers: {
            'user-agent': _userAgent,
            ...sessionHeaders,
          }).timeout(attemptTimeout);
          sw.stop();

          if (_parser.isCloudflareChallenge(
              response.statusCode, response.headers, response.body)) {
            challenges++;
            errors.add(InstanceChallengedException(instance.baseUrl));
            break; // Instance suivante (retry inutile sur un challenge).
          }
          if (response.statusCode >= 500) {
            errors.add(http.ClientException(
                'HTTP ${response.statusCode}', Uri.parse(instance.baseUrl)));
            break; // 5xx : instance suivante.
          }
          if (response.statusCode >= 400) {
            // 4xx (hors challenge) : erreur définitive de la requête.
            throw http.ClientException(
                'HTTP ${response.statusCode}', Uri.parse(instance.baseUrl));
          }
          return RawHttpResponse(
            body: response.body,
            statusCode: response.statusCode,
            headers: response.headers,
            instanceBaseUrl: instance.baseUrl,
            elapsed: sw.elapsed,
          );
        } on TimeoutException catch (e) {
          errors.add(e);
          if (attempt + 1 < maxAttemptsPerInstance) {
            await _backoff(attempt, token);
          }
        } on http.ClientException catch (e) {
          // Erreur socket/DNS : retry backoff, puis instance suivante.
          errors.add(e);
          if (attempt + 1 < maxAttemptsPerInstance) {
            await _backoff(attempt, token);
          }
        }
      }
    }

    throw AllInstancesFailedException(errors,
        cloudflareOnAll: challenges == candidates.length);
  }

  /// Backoff exponentiel borné : 400 ms, 800 ms...
  Future<void> _backoff(int attempt, CancellationToken? token) async {
    final delay = Duration(milliseconds: 400 * (attempt + 1));
    await Future.delayed(delay);
    token?.throwIfCancelled();
  }

  void close() => _http.close();
}
