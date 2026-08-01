/// CONTRAT READER — tout lecteur de l'application l'implémente.
///
/// Le Reader est une fonctionnalité indépendante : il ne connaît ni les
/// sources, ni le DownloadManager, ni la Library. Il reçoit UNIQUEMENT
/// un fichier local. Un nouveau format (CBZ, CBR, MOBI, AZW3, FB2...)
/// s'ajoute en implémentant ce contrat puis en l'enregistrant dans le
/// [ReaderRegistry] du ReaderManager — sans toucher au reste.
library;

import 'dart:io';

/// Formats de livres reconnus par le Reader.
enum ReaderFormat { epub, pdf, cbz, cbr, mobi, azw3, fb2, unknown }

/// Détection par extension (la confirmation par magic bytes est faite
/// par le ReaderManager à l'ouverture).
ReaderFormat readerFormatFromPath(String path) {
  final lower = path.toLowerCase();
  for (final format in ReaderFormat.values) {
    if (format == ReaderFormat.unknown) continue;
    if (lower.endsWith('.${format.name}')) return format;
  }
  return ReaderFormat.unknown;
}

/// Levée quand aucun lecteur n'est enregistré pour un format.
class ReaderUnsupportedException implements Exception {
  final ReaderFormat format;
  const ReaderUnsupportedException(this.format);
  @override
  String toString() =>
      'ReaderUnsupportedException: aucun lecteur enregistré pour .$format';
}

/// Levée quand le fichier est illisible ou corrompu pour son format.
class ReaderOpenException implements Exception {
  final String message;
  const ReaderOpenException(this.message);
  @override
  String toString() => 'ReaderOpenException: $message';
}

/// Position précise dans un livre ouvert.
///
/// [unitIndex] = chapitre (EPUB) ou page (PDF), base 0.
/// [offsetRatio] = avancement dans l'unité, 0..1 (défilement, fragment).
/// [locator] = identifiant textuel stable, persisté tel quel.
/// [progress] = progression globale du livre, 0..1 (calculée par le
/// lecteur à partir de sa structure).
class ReaderPosition {
  final String locator;
  final int unitIndex;
  final double offsetRatio;
  final double progress;
  final String? chapterTitle;

  const ReaderPosition({
    required this.locator,
    required this.unitIndex,
    this.offsetRatio = 0,
    required this.progress,
    this.chapterTitle,
  });

  ReaderPosition copyWith({
    String? locator,
    int? unitIndex,
    double? offsetRatio,
    double? progress,
    String? chapterTitle,
  }) =>
      ReaderPosition(
        locator: locator ?? this.locator,
        unitIndex: unitIndex ?? this.unitIndex,
        offsetRatio: offsetRatio ?? this.offsetRatio,
        progress: progress ?? this.progress,
        chapterTitle: chapterTitle ?? this.chapterTitle,
      );

  Map<String, dynamic> toJson() => {
        'locator': locator,
        'unitIndex': unitIndex,
        'offsetRatio': offsetRatio,
        'progress': progress,
        'chapterTitle': chapterTitle,
      };

  factory ReaderPosition.fromJson(Map<String, dynamic> json) =>
      ReaderPosition(
        locator: json['locator'] as String? ?? '',
        unitIndex: (json['unitIndex'] as num?)?.toInt() ?? 0,
        offsetRatio: (json['offsetRatio'] as num?)?.toDouble() ?? 0,
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        chapterTitle: json['chapterTitle'] as String?,
      );
}

/// Entrée de table des matières (arborescente).
class ReaderTocEntry {
  final String title;

  /// Unité cible (chapitre/page, base 0), si résoluble.
  final int? unitIndex;

  /// Fragment interne éventuel (ancre HTML), conservé dans le locator.
  final String? fragment;

  final List<ReaderTocEntry> children;

  const ReaderTocEntry({
    required this.title,
    this.unitIndex,
    this.fragment,
    this.children = const [],
  });

  /// Aplatit l'arbre (parcours préfixe) pour la navigation par chapitre.
  List<ReaderTocEntry> flatten() {
    final result = <ReaderTocEntry>[];
    void walk(ReaderTocEntry e) {
      result.add(e);
      e.children.forEach(walk);
    }
    walk(this);
    return result;
  }
}

/// Type de contenu d'une unité de lecture.
enum ReaderContentType { html, pdfPage, text, unsupported }

/// Contenu d'une unité (chapitre/page) prêt pour le rendu par l'UI.
class ReaderContent {
  final ReaderContentType type;

  /// HTML du chapitre (EPUB) ou null.
  final String? html;

  /// Numéro de page (PDF, base 0) ou null.
  final int? pageNumber;

  const ReaderContent.html(this.html)
      : type = ReaderContentType.html,
        pageNumber = null;

  const ReaderContent.pdfPage(this.pageNumber)
      : type = ReaderContentType.pdfPage,
        html = null;

  const ReaderContent.unsupported()
      : type = ReaderContentType.unsupported,
        html = null,
        pageNumber = null;
}

/// Le contrat que tout lecteur implémente.
///
/// Modèle d'« unités » : un livre est une suite ordonnée d'unités
/// (chapitres EPUB, pages PDF). La progression globale est dérivée de
/// l'index d'unité, ce qui rend le contrat indépendant du format.
abstract class ReaderContract {
  /// Format géré par ce lecteur.
  ReaderFormat get format;

  /// Ouvre le fichier et charge sa structure (spine, toc, pages...).
  /// Lève [ReaderOpenException] si le fichier est illisible.
  Future<void> open(File file);

  /// Libère les ressources. Doit être idempotent.
  Future<void> close();

  /// Nombre total d'unités (chapitres/pages).
  int get unitCount;

  /// Table des matières (vide si le livre n'en a pas).
  List<ReaderTocEntry> get tableOfContents;

  /// Titre du livre si les métadonnées en fournissent un.
  String? get title;

  /// Auteur si disponible.
  String? get author;

  /// Charge le contenu d'une unité pour le rendu.
  Future<ReaderContent> loadUnit(int unitIndex);

  /// Texte brut d'une unité (recherche dans le livre).
  /// Null si l'unité n'a pas de texte extractible (page scannée...).
  Future<String?> unitText(int unitIndex);

  /// Construit la position correspondant à une unité + décalage.
  ReaderPosition positionFor(int unitIndex, {double offsetRatio = 0});
}
