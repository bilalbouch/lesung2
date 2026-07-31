import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';

import '../../domain/reader_contract.dart';

/// Lecteur EPUB (EPUB 2 et 3).
///
/// Un EPUB est un ZIP : container.xml désigne le fichier OPF, qui donne
/// les métadonnées (titre/auteur), le manifeste et le spine (ordre de
/// lecture). La table des matières vient du NCX (EPUB 2) ou du document
/// NAV (EPUB 3). Implémente [ReaderContract] ; aucune dépendance UI :
/// [loadUnit] retourne le HTML brut du chapitre, c'est l'application
/// qui le rendra.
class EpubReader implements ReaderContract {
  final Map<int, String?> _textCache = {};

  Map<String, ArchiveFile> _files = {};
  String _opfDir = '';
  List<String> _spine = [];
  List<ReaderTocEntry> _toc = [];
  String? _title;
  String? _author;
  bool _open = false;

  @override
  ReaderFormat get format => ReaderFormat.epub;

  @override
  Future<void> open(File file) async {
    if (!await file.exists()) {
      throw ReaderOpenException('Fichier introuvable : ${file.path}');
    }
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    } catch (e) {
      throw ReaderOpenException('ZIP illisible : $e');
    }
    _files = {for (final f in archive.files) f.name: f};

    final container = _readXml('META-INF/container.xml');
    if (container == null) {
      throw const ReaderOpenException('META-INF/container.xml absent.');
    }
    final opfPath = container
        .findAllElements('rootfile')
        .firstOrNullAttr('full-path');
    if (opfPath == null || !_files.containsKey(opfPath)) {
      throw const ReaderOpenException('Fichier OPF introuvable.');
    }
    _opfDir = _dirOf(opfPath);

    final opf = _readXml(opfPath);
    if (opf == null) {
      throw const ReaderOpenException('OPF illisible.');
    }

    // Métadonnées (espaces de noms ignorés volontairement).
    _title = _textOfFirst(opf, 'title');
    _author = _textOfFirst(opf, 'creator');

    // Manifeste : id -> (href, media-type, properties).
    final manifest = <String, _ManifestItem>{};
    for (final item in opf.findAllElements('item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      if (id == null || href == null) continue;
      manifest[id] = _ManifestItem(
        href: _resolve(_opfDir, Uri.decodeFull(href)),
        mediaType: item.getAttribute('media-type') ?? '',
        properties: item.getAttribute('properties') ?? '',
      );
    }

    // Spine : ordre de lecture.
    _spine = [
      for (final ref in opf.findAllElements('itemref'))
        if (manifest[ref.getAttribute('idref')] != null)
          manifest[ref.getAttribute('idref')]!.href
    ];
    if (_spine.isEmpty) {
      throw const ReaderOpenException('Spine vide : pas de contenu lisible.');
    }

    // Table des matières : NCX (EPUB 2) ou NAV (EPUB 3).
    String? ncxPath;
    final tocId = opf
        .findAllElements('spine')
        .firstOrNullAttr('toc');
    if (tocId != null && manifest.containsKey(tocId)) {
      ncxPath = manifest[tocId]!.href;
    } else {
      for (final item in manifest.values) {
        if (item.mediaType == 'application/x-dtbncx+xml') {
          ncxPath = item.href;
          break;
        }
      }
    }
    _toc = ncxPath != null
        ? _parseNcx(ncxPath)
        : _parseNav(manifest.values
            .where((i) => i.properties.split(' ').contains('nav'))
            .firstOrNull
            ?.href);

    _open = true;
  }

  @override
  Future<void> close() async {
    _files = {};
    _textCache.clear();
    _open = false;
  }

  @override
  int get unitCount => _spine.length;

  @override
  List<ReaderTocEntry> get tableOfContents => List.unmodifiable(_toc);

  @override
  String? get title => _title;

  @override
  String? get author => _author;

  void _ensureOpen() {
    if (!_open) {
      throw StateError('EpubReader : aucun livre ouvert.');
    }
  }

  @override
  Future<ReaderContent> loadUnit(int unitIndex) async {
    _ensureOpen();
    _checkUnit(unitIndex);
    final raw = _readText(_spine[unitIndex]);
    if (raw == null) return const ReaderContent.unsupported();
    return ReaderContent.html(raw);
  }

  @override
  Future<String?> unitText(int unitIndex) async {
    _ensureOpen();
    _checkUnit(unitIndex);
    if (_textCache.containsKey(unitIndex)) return _textCache[unitIndex];
    final raw = _readText(_spine[unitIndex]);
    String? text;
    if (raw != null) {
      text = html_parser.parse(raw).documentElement?.text.trim();
    }
    _textCache[unitIndex] = text;
    return text;
  }

  @override
  ReaderPosition positionFor(int unitIndex, {double offsetRatio = 0}) {
    _checkUnit(unitIndex);
    final clampedOffset = offsetRatio.clamp(0.0, 1.0);
    final progress = _spine.isEmpty
        ? 0.0
        : ((unitIndex + clampedOffset) / _spine.length).clamp(0.0, 1.0);
    return ReaderPosition(
      locator: 'epub:u$unitIndex',
      unitIndex: unitIndex,
      offsetRatio: clampedOffset,
      progress: progress,
      chapterTitle: _chapterTitleFor(unitIndex),
    );
  }

  String? _chapterTitleFor(int unitIndex) {
    ReaderTocEntry? active;
    void walk(List<ReaderTocEntry> entries) {
      for (final e in entries) {
        final idx = e.unitIndex;
        if (idx != null && idx <= unitIndex) {
          if (active == null || idx > (active!.unitIndex ?? -1)) active = e;
        }
        walk(e.children);
      }
    }
    walk(_toc);
    return active?.title;
  }

  // ------------------------------------------------------------------
  // Parsing interne
  // ------------------------------------------------------------------

  void _checkUnit(int unitIndex) {
    if (unitIndex < 0 || unitIndex >= _spine.length) {
      throw RangeError.range(unitIndex, 0, _spine.length - 1, 'unitIndex');
    }
  }

  XmlDocument? _readXml(String path) {
    final text = _readText(path);
    if (text == null) return null;
    try {
      return XmlDocument.parse(text);
    } catch (_) {
      return null;
    }
  }

  String? _readText(String path) {
    final file = _files[path];
    if (file == null || file.content == null) return null;
    final bytes = file.content as List<int>;
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  static String _dirOf(String path) {
    final slash = path.lastIndexOf('/');
    return slash == -1 ? '' : path.substring(0, slash + 1);
  }

  static String _resolve(String baseDir, String relative) {
    // Normalise les « ../ » sans dépendre de package:path.
    final segments = '$baseDir$relative'.split('/');
    final stack = <String>[];
    for (final segment in segments) {
      if (segment == '.' || segment.isEmpty && stack.isNotEmpty) continue;
      if (segment == '..') {
        if (stack.isNotEmpty) stack.removeLast();
      } else {
        stack.add(segment);
      }
    }
    return stack.join('/');
  }

  String? _textOfFirst(XmlDocument doc, String localName) {
    // findAllElements compare le nom QUALIFIÉ : les métadonnées Dublin
    // Core (dc:title, dc:creator...) exigent la comparaison locale.
    for (final element in doc.descendantElements) {
      if (element.name.local == localName) {
        final text = element.innerText.trim();
        if (text.isNotEmpty) return text;
      }
    }
    return null;
  }

  /// Convertit un href (chemin + fragment) en index de spine.
  int? _spineIndexFor(String baseDir, String hrefWithFragment) {
    final href = Uri.decodeFull(hrefWithFragment.split('#').first);
    final resolved = _resolve(baseDir, href);
    final index = _spine.indexOf(resolved);
    return index == -1 ? null : index;
  }

  List<ReaderTocEntry> _parseNcx(String ncxPath) {
    final doc = _readXml(ncxPath);
    if (doc == null) return const [];
    final baseDir = _dirOf(ncxPath);

    ReaderTocEntry? build(XmlElement navPoint) {
      String label = '';
      String src = '';
      // Enfants directs uniquement : descendantElements capturerait les
      // navPoint imbriqués et fausserait label/src des parents.
      for (final child in navPoint.childElements) {
        if (child.localName == 'navLabel' && label.isEmpty) {
          for (final textEl in child.childElements) {
            if (textEl.localName == 'text') {
              label = textEl.innerText.trim();
              break;
            }
          }
        } else if (child.localName == 'content' && src.isEmpty) {
          src = child.getAttribute('src') ?? '';
        }
      }
      if (label.isEmpty) return null;
      return ReaderTocEntry(
        title: label,
        unitIndex: src.isEmpty ? null : _spineIndexFor(baseDir, src),
        fragment: src.contains('#') ? src.split('#').last : null,
        children: navPoint.childElements
            .where((e) => e.localName == 'navPoint')
            .map(build)
            .whereType<ReaderTocEntry>()
            .toList(),
      );
    }

    for (final navMap in doc.findAllElements('navMap')) {
      return navMap.childElements
          .where((e) => e.localName == 'navPoint')
          .map(build)
          .whereType<ReaderTocEntry>()
          .toList();
    }
    return const [];
  }

  List<ReaderTocEntry> _parseNav(String? navPath) {
    if (navPath == null) return const [];
    final doc = _readXml(navPath);
    if (doc == null) return const [];
    final baseDir = _dirOf(navPath);

    // Trouve <nav epub:type="toc"> (ou le premier <nav>).
    XmlElement? nav;
    for (final candidate in doc.findAllElements('nav')) {
      var type = '';
      for (final attribute in candidate.attributes) {
        if (attribute.name.local == 'type') {
          type = attribute.value;
          break;
        }
      }
      if (type.contains('toc')) {
        nav = candidate;
        break;
      }
      nav ??= candidate;
    }
    final rootList = nav?.descendantElements
        .where((e) => e.localName == 'ol')
        .firstOrNull;
    if (rootList == null) return const [];

    ReaderTocEntry? build(XmlElement li) {
      String label = '';
      String href = '';
      XmlElement? childOl;
      for (final child in li.childElements) {
        if ((child.localName == 'a' || child.localName == 'span') &&
            label.isEmpty) {
          label = child.innerText.trim();
          href = child.getAttribute('href') ?? '';
        } else if (child.localName == 'ol') {
          childOl = child;
        }
      }
      if (label.isEmpty) return null;
      return ReaderTocEntry(
        title: label,
        unitIndex: href.isEmpty ? null : _spineIndexFor(baseDir, href),
        fragment: href.contains('#') ? href.split('#').last : null,
        children: childOl == null
            ? const []
            : childOl.childElements
                .where((e) => e.localName == 'li')
                .map(build)
                .whereType<ReaderTocEntry>()
                .toList(),
      );
    }

    return rootList.childElements
        .where((e) => e.localName == 'li')
        .map(build)
        .whereType<ReaderTocEntry>()
        .toList();
  }
}

class _ManifestItem {
  final String href;
  final String mediaType;
  final String properties;
  const _ManifestItem(
      {required this.href, required this.mediaType, required this.properties});
}

/// Petit accesseur null-safe sur Iterable<XmlElement>.
extension _FirstAttr on Iterable<XmlElement> {
  String? firstOrNullAttr(String name) {
    for (final element in this) {
      final value = element.getAttribute(name);
      if (value != null) return value;
    }
    return null;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
