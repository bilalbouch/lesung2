import 'dart:io';

import 'package:crypto/crypto.dart';

import '../domain/entities/download_task.dart';

/// Résultat détaillé d'une vérification.
class VerificationResult {
  final bool passed;

  /// MD5 calculé (si demandé).
  final String? computedMd5;

  /// Signature magique détectée ('zip/epub', 'pdf', null si inconnue).
  final String? detectedSignature;

  /// Raison de l'échec, le cas échéant.
  final String? failureReason;

  const VerificationResult({
    required this.passed,
    this.computedMd5,
    this.detectedSignature,
    this.failureReason,
  });
}

/// Vérificateur d'intégrité des fichiers téléchargés.
///
/// Trois contrôles indépendants, composés :
/// 1. taille annoncée (si connue)
/// 2. empreinte MD5 en streaming (si annoncée)
/// 3. signature magique cohérente avec le format attendu
///    (PK\x03\x04 pour epub/zip, %PDF pour pdf)
class DownloadVerifier {
  /// Vérifie [file] selon les attentes de [task].
  Future<VerificationResult> verify(File file, DownloadTask task) async {
    if (!await file.exists()) {
      return const VerificationResult(
          passed: false, failureReason: 'Fichier absent');
    }

    final length = await file.length();
    if (length == 0) {
      return const VerificationResult(
          passed: false, failureReason: 'Fichier vide');
    }

    // 1. Taille annoncée (tolérance : égalité stricte).
    final expected = task.expectedSizeBytes;
    if (expected != null && expected > 0 && length != expected) {
      return VerificationResult(
          passed: false,
          failureReason: 'Taille $length != attendue $expected');
    }

    // 2. Signature magique.
    final signature = await _detectSignature(file, task);
    if (signature == 'mismatch') {
      return VerificationResult(
          passed: false,
          failureReason:
              'Signature inattendue (ni epub/zip ni pdf) — probable page HTML');
    }

    // 3. MD5 en streaming.
    String? computed;
    final expectedMd5 = task.expectedMd5;
    if (expectedMd5 != null && expectedMd5.isNotEmpty) {
      computed = await _md5Of(file);
      if (computed.toLowerCase() != expectedMd5.toLowerCase()) {
        return VerificationResult(
          passed: false,
          computedMd5: computed,
          detectedSignature: signature,
          failureReason: 'Checksum MD5 $computed != $expectedMd5',
        );
      }
    }

    return VerificationResult(
        passed: true, computedMd5: computed, detectedSignature: signature);
  }

  /// MD5 d'un fichier en streaming (faible empreinte mémoire).
  Future<String> _md5Of(File file) async {
    final digest = await md5.bind(file.openRead()).first;
    return digest.toString();
  }

  /// Lit les 5 premiers octets et compare au format attendu.
  /// Retourne 'pdf', 'zip/epub', 'unknown' ou 'mismatch'.
  Future<String> _detectSignature(File file, DownloadTask task) async {
    final raf = await file.open();
    List<int> head;
    try {
      head = await raf.read(5);
    } finally {
      await raf.close();
    }
    if (head.length < 4) return 'mismatch';

    final isZip = head[0] == 0x50 && head[1] == 0x4B; // PK
    final isPdf = head[0] == 0x25 &&
        head[1] == 0x50 &&
        head[2] == 0x44 &&
        head[3] == 0x46; // %PDF

    if (isPdf) return 'pdf';
    if (isZip) return 'zip/epub';

    // Format inconnu : on ne pénalise pas les formats sans signature
    // stable (mobi, fb2...), sauf si le contenu ressemble à du HTML.
    final asText = String.fromCharCodes(head.take(5)).toLowerCase();
    if (asText.startsWith('<') || asText.contains('html')) return 'mismatch';
    return 'unknown';
  }
}
