import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/cancellation/cancellation_token.dart';
import '../../search/domain/entities/download_link.dart';
import '../domain/download_link_resolver.dart';
import '../domain/entities/download_task.dart';
import 'download_storage.dart';
import 'download_verifier.dart';

/// Signal de pause : distinct de l'annulation (le partiel est conservé).
class DownloadPausedException implements Exception {
  const DownloadPausedException();
}

/// Un miroir a échoué, on tente le suivant.
class _MirrorFailedException implements Exception {
  final String reason;
  const _MirrorFailedException(this.reason);
  @override
  String toString() => 'MirrorFailed: $reason';
}

/// Worker de téléchargement — exécute RÉELLEMENT une tâche.
///
/// Reprend les meilleurs éléments d'OpenlibExtended, réécrits proprement :
/// - failover multi-miroirs (boucle sur les liens, ordre de préférence)
/// - reprise HTTP Range (les octets déjà présents ne sont jamais retéléchargés)
/// - pause / reprise / annulation
/// - progression temps réel avec vitesse et ETA
/// - vérification MD5 + signature magique via [DownloadVerifier]
/// - 416 Range = fichier déjà complet -> vérification directe
/// - 200 au lieu de 206 = serveur sans Range -> reprise à zéro propre
///
/// Le worker ne connaît AUCUNE source : les liens intermédiaires sont
/// résolus via le [DownloadLinkResolver] injecté.
class DownloadWorker {
  final http.Client _http;
  final DownloadStorage storage;
  final DownloadVerifier verifier;
  final DownloadLinkResolver? linkResolver;

  /// Timeout de connexion par miroir.
  final Duration connectTimeout;

  /// Émission de progression au plus toutes les [progressInterval].
  final Duration progressInterval;

  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

  DownloadWorker({
    http.Client? httpClient,
    required this.storage,
    DownloadVerifier? verifier,
    this.linkResolver,
    this.connectTimeout = const Duration(seconds: 30),
    this.progressInterval = const Duration(milliseconds: 200),
  })  : _http = httpClient ?? http.Client(),
        verifier = verifier ?? DownloadVerifier();

  /// Callback de progression (branché par le DownloadManager).
  void Function(DownloadProgress progress)? onProgress;

  /// Exécute [task] jusqu'à terme : complétion, échec, pause ou
  /// annulation. Le statut final est écrit dans [task].
  ///
  /// [controlToken] : annulation définitive. [pauseSignal] : consulté
  /// entre les chunks pour suspendre proprement.
  Future<DownloadTask> run(
    DownloadTask task, {
    required CancellationToken controlToken,
    required bool Function() pauseSignal,
  }) async {
    try {
      // 1. Résolution des liens intermédiaires -> URL directes.
      task.status = DownloadStatus.resolving;
      _emit(task);
      final directUrls = await _resolveAllLinks(task, controlToken);
      if (directUrls.isEmpty) {
        throw const _MirrorFailedException(
            'Aucun lien direct résolu (vérification manuelle requise)');
      }

      // 2. Boucle de failover sur les miroirs.
      Object? lastError;
      for (final url in directUrls) {
        controlToken.throwIfCancelled();
        if (pauseSignal()) throw const DownloadPausedException();

        task.activeUrl = url;
        try {
          await _downloadFromMirror(task, url, controlToken, pauseSignal);

          // 3. Vérification d'intégrité.
          task.status = DownloadStatus.verifying;
          _emit(task);
          final result =
              await verifier.verify(storage.partialFileFor(task), task);
          if (!result.passed) {
            await storage.deletePartial(task);
            task.receivedBytes = 0;
            throw _MirrorFailedException(
                result.failureReason ?? 'Vérification échouée');
          }

          // 4. Finalisation.
          final finalFile = await storage.finalize(task);
          task.status = DownloadStatus.completed;
          task.completedAt = DateTime.now();
          task.receivedBytes = await finalFile.length();
          task.totalBytes = task.receivedBytes;
          _emit(task);
          return task;
        } on DownloadPausedException {
          rethrow;
        } on RequestCancelledException {
          rethrow;
        } catch (e) {
          lastError = e;
          // Miroir suivant après une courte pause.
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }

      task.status = DownloadStatus.failed;
      task.errorMessage = 'Tous les liens ont échoué: $lastError';
      _emit(task);
      return task;
    } on DownloadPausedException {
      task.status = DownloadStatus.paused;
      _emit(task);
      return task;
    } on RequestCancelledException {
      task.status = DownloadStatus.cancelled;
      await storage.deletePartial(task);
      _emit(task);
      return task;
    }
  }

  // ------------------------------------------------------------------

  /// Résout tous les liens de la tâche en URL directes, dans l'ordre :
  /// premium d'abord, puis directs, puis pages intermédiaires.
  Future<List<Uri>> _resolveAllLinks(
      DownloadTask task, CancellationToken token) async {
    final direct = <Uri>[];
    final intermediate = <DownloadLink>[];

    for (final link in task.links) {
      switch (link.kind) {
        case DownloadLinkKind.direct:
        case DownloadLinkKind.premium:
          direct.add(link.url);
        case DownloadLinkKind.intermediatePage:
          intermediate.add(link);
      }
    }

    final resolver = linkResolver;
    if (resolver != null) {
      for (final link in intermediate) {
        token.throwIfCancelled();
        try {
          direct.addAll(await resolver.resolve(link));
        } catch (_) {
          // Lien irrésoluble : ignoré, les autres restent candidats.
        }
      }
    }
    return direct;
  }

  /// Télécharge depuis UN miroir, avec reprise Range et progression.
  Future<void> _downloadFromMirror(
    DownloadTask task,
    Uri url,
    CancellationToken token,
    bool Function() pauseSignal,
  ) async {
    final partial = storage.partialFileFor(task);
    var received = await storage.existingPartialBytes(task);

    final request = http.Request('GET', url);
    request.headers['user-agent'] = _userAgent;
    request.headers['connection'] = 'keep-alive';
    if (received > 0) {
      request.headers['range'] = 'bytes=$received-';
    }

    final http.StreamedResponse response;
    try {
      response = await _http.send(request).timeout(connectTimeout);
    } on TimeoutException {
      throw _MirrorFailedException('Timeout de connexion: $url');
    } catch (e) {
      throw _MirrorFailedException('Erreur réseau: $e');
    }

    if (response.statusCode == 416 && received > 0) {
      // Range insatisfiable : le partiel est déjà complet.
      task.totalBytes = received;
      task.receivedBytes = received;
      return;
    }
    if (response.statusCode == 403 || response.statusCode == 429) {
      throw _MirrorFailedException('HTTP ${response.statusCode} (anti-bot ou rate-limit)');
    }
    if (response.statusCode >= 400) {
      throw _MirrorFailedException('HTTP ${response.statusCode}');
    }

    // Serveur ignorant le Range (200 au lieu de 206) : reprise à zéro.
    if (received > 0 && response.statusCode == 200) {
      received = 0;
      await partial.writeAsBytes(const []);
    }

    final contentLength = response.contentLength ?? 0;
    final total = received + contentLength;
    task.totalBytes = task.expectedSizeBytes ?? total;
    task.receivedBytes = received;
    task.status = DownloadStatus.downloading;
    _emit(task);

    final sink = partial.openWrite(mode: FileMode.append);

    // Fenêtre glissante de vitesse.
    var windowBytes = 0;
    var windowStart = DateTime.now();
    var lastEmit = DateTime.now();

    final completer = Completer<void>();
    late StreamSubscription<List<int>> subscription;

    subscription = response.stream.listen(
      (chunk) {
        sink.add(chunk);
        received += chunk.length;
        windowBytes += chunk.length;
        task.receivedBytes = received;

        // Pause propre entre les chunks : l'abonnement est annulé,
        // le partiel est conservé pour la reprise Range.
        if (pauseSignal()) {
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.completeError(const DownloadPausedException());
          }
          return;
        }
        if (token.isCancelled) {
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.completeError(const RequestCancelledException());
          }
          return;
        }

        final now = DateTime.now();
        if (now.difference(lastEmit) >= progressInterval) {
          final windowSeconds =
              now.difference(windowStart).inMilliseconds / 1000;
          final speed =
              windowSeconds > 0 ? windowBytes / windowSeconds : 0.0;
          windowBytes = 0;
          windowStart = now;
          lastEmit = now;
          _emit(task, speedBytesPerSec: speed);
        }
      },
      onError: (Object e) {
        if (!completer.isCompleted) {
          completer
              .completeError(_MirrorFailedException('Flux interrompu: $e'));
        }
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    await completer.future;
    await sink.flush();
    await sink.close();
    _emit(task);
  }

  void _emit(DownloadTask task, {double speedBytesPerSec = 0}) {
    onProgress?.call(DownloadProgress(
      taskId: task.id,
      status: task.status,
      receivedBytes: task.receivedBytes,
      totalBytes: task.totalBytes,
      speedBytesPerSec: speedBytesPerSec,
      errorMessage: task.errorMessage,
    ));
  }

  void close() => _http.close();
}
