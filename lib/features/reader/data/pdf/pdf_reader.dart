import 'dart:io';

import '../../domain/reader_contract.dart';
import 'pdf_document.dart';

/// Lecteur PDF.
///
/// Implémente [ReaderContract] avec une unité = une page. La structure
/// (pages, ordre, outlines, texte simple) est extraite par [PdfDocument]
/// en pur Dart. LIMITATIONS assumées et documentées : le rendu graphique
/// des pages reste à la charge de l'application (moteur plateforme), et
/// le texte des scans/polices exotiques n'est pas extractible (unitText
/// retourne null — la recherche ignore alors ces pages).
class PdfReader implements ReaderContract {
  final Map<int, String?> _textCache = {};

  PdfDocument? _document;
  List<ReaderTocEntry> _toc = [];
  bool _open = false;

  @override
  ReaderFormat get format => ReaderFormat.pdf;

  @override
  Future<void> open(File file) async {
    if (!await file.exists()) {
      throw ReaderOpenException('Fichier introuvable : ${file.path}');
    }
    final PdfDocument document;
    try {
      document = PdfDocument.parse(await file.readAsBytes());
    } on FormatException catch (e) {
      throw ReaderOpenException(e.message);
    }
    _document = document;
    _toc = [
      for (final (title, pageIndex) in document.outlineEntries())
        ReaderTocEntry(title: title, unitIndex: pageIndex)
    ];
    _open = true;
  }

  @override
  Future<void> close() async {
    _document = null;
    _textCache.clear();
    _open = false;
  }

  PdfDocument get _doc {
    if (!_open || _document == null) {
      throw StateError('PdfReader : aucun livre ouvert.');
    }
    return _document!;
  }

  @override
  int get unitCount => _doc.pageCount;

  @override
  List<ReaderTocEntry> get tableOfContents => List.unmodifiable(_toc);

  @override
  String? get title => null; // métadonnées Info non parsées (v1)

  @override
  String? get author => null;

  void _checkUnit(int unitIndex) {
    if (unitIndex < 0 || unitIndex >= _doc.pageCount) {
      throw RangeError.range(unitIndex, 0, _doc.pageCount - 1, 'unitIndex');
    }
  }

  @override
  Future<ReaderContent> loadUnit(int unitIndex) async {
    _checkUnit(unitIndex);
    return ReaderContent.pdfPage(unitIndex);
  }

  @override
  Future<String?> unitText(int unitIndex) async {
    _checkUnit(unitIndex);
    if (_textCache.containsKey(unitIndex)) return _textCache[unitIndex];
    final text = _doc.pageText(unitIndex);
    _textCache[unitIndex] = text;
    return text;
  }

  @override
  ReaderPosition positionFor(int unitIndex, {double offsetRatio = 0}) {
    _checkUnit(unitIndex);
    final clampedOffset = offsetRatio.clamp(0.0, 1.0);
    final total = _doc.pageCount;
    final progress =
        total == 0 ? 0.0 : ((unitIndex + clampedOffset) / total).clamp(0.0, 1.0);
    return ReaderPosition(
      locator: 'pdf:p$unitIndex',
      unitIndex: unitIndex,
      offsetRatio: clampedOffset,
      progress: progress,
      chapterTitle: _outlineTitleFor(unitIndex),
    );
  }

  String? _outlineTitleFor(int unitIndex) {
    ReaderTocEntry? active;
    for (final entry in _toc) {
      final idx = entry.unitIndex;
      if (idx != null && idx <= unitIndex) {
        if (active == null || idx > (active.unitIndex ?? -1)) active = entry;
      }
    }
    return active?.title;
  }
}
