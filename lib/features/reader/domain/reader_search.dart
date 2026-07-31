import 'dart:async';

import 'reader_contract.dart';

/// Un résultat de recherche dans le livre.
class ReaderSearchHit {
  /// Unité (chapitre/page) contenant l'occurrence.
  final int unitIndex;

  /// Position de l'occurrence dans le texte brut de l'unité.
  final int offsetInUnit;

  /// Extrait autour de l'occurrence (pour la liste de résultats).
  final String snippet;

  /// Titre de chapitre si résoluble.
  final String? chapterTitle;

  const ReaderSearchHit({
    required this.unitIndex,
    required this.offsetInUnit,
    required this.snippet,
    this.chapterTitle,
  });
}

/// Recherche plein texte dans un livre ouvert.
///
/// Insensible à la casse et aux diacritiques (« Müller » trouve
/// « muller »). Parcourt les unités une à une, annulable à tout moment,
/// et peut émettre les résultats au fil de l'eau.
class ReaderSearch {
  /// Taille de l'extrait de part et d'autre de l'occurrence.
  static const snippetRadius = 60;

  final ReaderContract reader;

  ReaderSearch(this.reader);

  /// Recherche complète. [onProgress] reçoit (unités traitées / total).
  /// [isCancelled] est consulté entre chaque unité.
  Future<List<ReaderSearchHit>> search(
    String query, {
    void Function(int done, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final normalizedQuery = _normalize(query.trim());
    if (normalizedQuery.isEmpty) return const [];

    final hits = <ReaderSearchHit>[];
    final total = reader.unitCount;
    for (var unit = 0; unit < total; unit++) {
      if (isCancelled?.call() ?? false) break;
      final text = await reader.unitText(unit);
      if (text != null && text.isNotEmpty) {
        final normalizedText = _normalize(text);
        var from = 0;
        while (true) {
          final at = normalizedText.indexOf(normalizedQuery, from);
          if (at == -1) break;
          hits.add(ReaderSearchHit(
            unitIndex: unit,
            offsetInUnit: at,
            snippet: _snippet(text, at, query.trim().length),
            chapterTitle: null,
          ));
          from = at + normalizedQuery.length;
        }
      }
      onProgress?.call(unit + 1, total);
      // Laisse respirer l'isolate entre les unités.
      await Future<void>.delayed(Duration.zero);
    }
    return hits;
  }

  /// Recherche en flux : émet chaque unité de résultats dès qu'elle
  /// est terminée (utile pour une UI réactive sur gros livres).
  Stream<List<ReaderSearchHit>> searchStreaming(String query) async* {
    final normalizedQuery = _normalize(query.trim());
    if (normalizedQuery.isEmpty) return;
    for (var unit = 0; unit < reader.unitCount; unit++) {
      final text = await reader.unitText(unit);
      if (text == null || text.isEmpty) continue;
      final normalizedText = _normalize(text);
      final unitHits = <ReaderSearchHit>[];
      var from = 0;
      while (true) {
        final at = normalizedText.indexOf(normalizedQuery, from);
        if (at == -1) break;
        unitHits.add(ReaderSearchHit(
          unitIndex: unit,
          offsetInUnit: at,
          snippet: _snippet(text, at, query.trim().length),
        ));
        from = at + normalizedQuery.length;
      }
      if (unitHits.isNotEmpty) yield unitHits;
    }
  }

  String _snippet(String text, int at, int queryLength) {
    final start = at - snippetRadius < 0 ? 0 : at - snippetRadius;
    final end = at + queryLength + snippetRadius > text.length
        ? text.length
        : at + queryLength + snippetRadius;
    final prefix = start > 0 ? '…' : '';
    final suffix = end < text.length ? '…' : '';
    return '$prefix${text.substring(start, end).trim()}$suffix';
  }

  /// Normalisation locale (le Reader ne dépend d'aucune autre feature) :
  /// minuscules + suppression des diacritiques courants.
  static String _normalize(String input) {
    final buffer = StringBuffer();
    for (final codeUnit in input.toLowerCase().split('')) {
      buffer.write(_diacritics[codeUnit] ?? codeUnit);
    }
    return buffer.toString();
  }

  static const _diacritics = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'å': 'a',
    'ç': 'c',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ñ': 'n',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ý': 'y', 'ÿ': 'y',
    'ß': 'ss', 'œ': 'oe', 'æ': 'ae',
  };
}
