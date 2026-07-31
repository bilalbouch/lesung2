import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Parseur PDF structurel minimal, en pur Dart.
///
/// Objectif volontairement limité et HONNÊTE :
/// - nombre et ordre des pages (arbre /Pages -> /Kids)
/// - extraction de texte simple des flux de contenu (Tj / TJ,
///   encodages standards ; les polices avec ToUnicode exotique ou les
///   scans renverront null — limitation assumée et documentée)
/// - table des matières via /Outlines quand elle existe
///
/// Le rendu graphique des pages n'est PAS du ressort de ce moteur :
/// l'application utilisera un moteur de rendu plateforme (ex. pdfx).
class PdfDocument {
  /// objNum -> contenu brut de l'objet (latin1, 1 caractère = 1 octet).
  final Map<int, String> objects;

  /// Numéros d'objets des pages, dans l'ordre de lecture.
  final List<int> pageObjects;

  PdfDocument._(this.objects, this.pageObjects);

  int get pageCount => pageObjects.length;

  static final _objectPattern =
      RegExp(r'(\d+)\s+\d+\s+obj\b', multiLine: true);

  /// Parse le fichier. Lève [FormatException] si la structure est
  /// introuvable ou sans pages.
  factory PdfDocument.parse(Uint8List bytes) {
    if (bytes.length < 8 ||
        String.fromCharCodes(bytes.sublist(0, 5)) != '%PDF-') {
      throw const FormatException('Signature %PDF- absente.');
    }
    final content = latin1.decode(bytes);

    // Découpe en objets indirects.
    final objects = <int, String>{};
    final matches = _objectPattern.allMatches(content).toList();
    for (var i = 0; i < matches.length; i++) {
      final num = int.parse(matches[i].group(1)!);
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : null;
      final objEnd = content.indexOf('endobj', start);
      if (objEnd == -1) continue;
      final realEnd = end != null && end < objEnd ? end : objEnd;
      objects[num] = content.substring(start, realEnd);
    }
    if (objects.isEmpty) {
      throw const FormatException('Aucun objet PDF trouvé.');
    }

    final pages = _resolvePageOrder(objects);
    if (pages.isEmpty) {
      throw const FormatException('Aucune page trouvée.');
    }
    return PdfDocument._(objects, pages);
  }

  // ------------------------------------------------------------------
  // Arbre des pages
  // ------------------------------------------------------------------

  static int? _refNum(String body, String key) {
    final match = RegExp('$key\\s+(\\d+)\\s+\\d+\\s+R').firstMatch(body);
    return match == null ? null : int.parse(match.group(1)!);
  }

  static List<int> _resolvePageOrder(Map<int, String> objects) {
    // Catalogue -> /Pages racine.
    int? pagesRoot;
    for (final body in objects.values) {
      if (RegExp(r'/Type\s*/Catalog\b').hasMatch(body)) {
        pagesRoot = _refNum(body, '/Pages');
        if (pagesRoot != null) break;
      }
    }
    if (pagesRoot == null) {
      // Repli : tous les objets /Type /Page dans l'ordre d'apparition.
      return [
        for (final entry in objects.entries)
          if (RegExp(r'/Type\s*/Page(?![a-zA-Z])').hasMatch(entry.value))
            entry.key
      ];
    }

    final order = <int>[];
    void walk(int objNum, Set<int> seen) {
      if (seen.contains(objNum)) return;
      seen.add(objNum);
      final body = objects[objNum];
      if (body == null) return;
      if (RegExp(r'/Type\s*/Page(?![a-zA-Z])').hasMatch(body) &&
          !RegExp(r'/Type\s*/Pages\b').hasMatch(body)) {
        order.add(objNum);
        return;
      }
      // /Kids [ a 0 R b 0 R ... ]
      final kids = RegExp(r'/Kids\s*\[([^\]]*)\]').firstMatch(body);
      if (kids != null) {
        for (final ref
            in RegExp(r'(\d+)\s+\d+\s+R').allMatches(kids.group(1)!)) {
          walk(int.parse(ref.group(1)!), seen);
        }
      }
    }
    walk(pagesRoot, {});
    return order;
  }

  // ------------------------------------------------------------------
  // Flux de contenu et extraction de texte
  // ------------------------------------------------------------------

  /// Données du flux d'un objet, décodées si FlateDecode.
  List<int>? _streamData(int objNum) {
    final body = objects[objNum];
    if (body == null) return null;
    final streamStart = body.indexOf('stream');
    if (streamStart == -1) return null;
    var dataStart = streamStart + 'stream'.length;
    if (body.startsWith('\r\n', dataStart)) {
      dataStart += 2;
    } else if (body.startsWith('\n', dataStart) ||
        body.startsWith('\r', dataStart)) {
      dataStart += 1;
    }
    final dataEnd = body.indexOf('endstream', dataStart);
    if (dataEnd == -1) return null;
    var raw = latin1.encode(body.substring(dataStart, dataEnd));
    // Retire le saut de ligne précédant endstream.
    if (raw.isNotEmpty && raw.last == 0x0A) {
      raw = raw.sublist(0, raw.length - 1);
      if (raw.isNotEmpty && raw.last == 0x0D) {
        raw = raw.sublist(0, raw.length - 1);
      }
    }
    if (body.contains('/FlateDecode')) {
      try {
        return ZLibDecoder().convert(raw);
      } catch (_) {
        return null;
      }
    }
    return raw;
  }

  /// Numéros d'objets des flux de contenu d'une page.
  List<int> _contentRefs(int pageObjNum) {
    final body = objects[pageObjNum] ?? '';
    final contents = RegExp(r'/Contents\s+(\d+)\s+\d+\s+R').firstMatch(body);
    if (contents != null) return [int.parse(contents.group(1)!)];
    final array = RegExp(r'/Contents\s*\[([^\]]*)\]').firstMatch(body);
    if (array != null) {
      return RegExp(r'(\d+)\s+\d+\s+R')
          .allMatches(array.group(1)!)
          .map((m) => int.parse(m.group(1)!))
          .toList();
    }
    return const [];
  }

  /// Texte brut d'une page (null si rien d'extractible — scan, polices
  /// non standard, etc.).
  String? pageText(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pageCount) return null;
    final buffer = StringBuffer();
    for (final ref in _contentRefs(pageObjects[pageIndex])) {
      final data = _streamData(ref);
      if (data == null) continue;
      final stream = latin1.decode(data);
      buffer.write(_extractTextFromContentStream(stream));
      buffer.write('\n');
    }
    final text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// Extraction depuis les opérateurs Tj / TJ / ' / " d'un flux de
  /// contenu. Gère les échappements PDF de base.
  static String _extractTextFromContentStream(String stream) {
    final buffer = StringBuffer();
    // Chaînes suivies de Tj, ou tableaux [ (a) 12 (b) ] TJ.
    final pattern = RegExp(
        r'\((?:\\.|[^\\()])*\)\s*(?:Tj|' "'" r'|")|\[(?:[^\[\]]|\([^)]*\))*\]\s*TJ');
    for (final match in pattern.allMatches(stream)) {
      final token = match.group(0)!;
      if (token.endsWith('TJ')) {
        for (final str in RegExp(r'\((?:\\.|[^\\()])*\)')
            .allMatches(token)) {
          buffer.write(_unescape(str.group(0)!));
        }
        buffer.write('\n');
      } else {
        final str =
            RegExp(r'\((?:\\.|[^\\()])*\)').firstMatch(token);
        if (str != null) {
          buffer.write(_unescape(str.group(0)!));
          buffer.write('\n');
        }
      }
    }
    return buffer.toString();
  }

  static String _unescape(String pdfString) {
    // Retire les parenthèses englobantes puis traite les échappements.
    var s = pdfString.substring(1, pdfString.length - 1);
    s = s
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')')
        .replaceAll(r'\\', r'\')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\t', '\t');
    return s;
  }

  // ------------------------------------------------------------------
  // Signets (/Outlines)
  // ------------------------------------------------------------------

  /// Entrées d'outline aplaties : (titre, index de page cible).
  List<(String, int?)> outlineEntries() {
    int? outlinesRoot;
    for (final body in objects.values) {
      if (RegExp(r'/Type\s*/Catalog\b').hasMatch(body)) {
        outlinesRoot = _refNum(body, '/Outlines');
        break;
      }
    }
    if (outlinesRoot == null) return const [];

    final result = <(String, int?)>[];
    void walk(int objNum, Set<int> seen) {
      if (seen.contains(objNum)) return;
      seen.add(objNum);
      final body = objects[objNum];
      if (body == null) return;
      final titleMatch =
          RegExp(r'/Title\s*\(((?:\\.|[^\\()])*)\)').firstMatch(body);
      final title =
          titleMatch == null ? null : _unescape('(${titleMatch.group(1)!})');
      int? pageIndex;
      // /Dest [ pageRef /XYZ ... ] ou /A << /D [ pageRef ... ] >>
      final dest = RegExp(r'/(?:Dest|D)\s*\[\s*(\d+)\s+\d+\s+R')
          .firstMatch(body);
      if (dest != null) {
        final target = int.parse(dest.group(1)!);
        final idx = pageObjects.indexOf(target);
        if (idx != -1) pageIndex = idx;
      }
      if (title != null && title.trim().isNotEmpty) {
        result.add((title.trim(), pageIndex));
      }
      // Descendre dans /First (enfants) puis continuer /Next (frères).
      final first = _refNum(body, '/First');
      if (first != null) walk(first, seen);
      final next = _refNum(body, '/Next');
      if (next != null) walk(next, seen);
    }

    final first = _refNum(objects[outlinesRoot] ?? '', '/First');
    if (first != null) walk(first, {});
    return result;
  }
}
