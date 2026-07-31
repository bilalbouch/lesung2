import 'dart:async';
import 'dart:io';

import '../data/epub/epub_reader.dart';
import '../data/pdf/pdf_reader.dart';
import 'reader_annotations.dart';
import 'reader_bookmarks.dart';
import 'reader_contract.dart';
import 'reader_navigation.dart';
import 'reader_repository.dart';
import 'reader_search.dart';
import 'reader_settings.dart';
import 'reader_statistics.dart';

/// Fabrique de lecteurs par format (registre extensible).
typedef ReaderFactory = ReaderContract Function();

/// ReaderManager — chef d'orchestre du Reader.
///
/// INDÉPENDANCE TOTALE : reçoit un fichier local, ne connaît ni les
/// sources, ni le DownloadManager, ni la Library. La mémorisation
/// (position, progression, temps de lecture, date d'ouverture) est
/// automatique via l'auto-save ; la persistance passe uniquement par le
/// [ReaderRepository] ; la reconnexion avec la bibliothèque se fera
/// dans la couche application via les callbacks [onPositionChanged] /
/// [onSessionClosed] — jamais par dépendance directe.
///
/// Sous-systèmes exposés : [bookmarks], [annotations], [navigation],
/// [search], [statistics].
class ReaderManager {
  final ReaderRepository repository;

  /// Intervalle de l'auto-save (position + temps de lecture).
  final Duration autoSaveInterval;

  final Map<ReaderFormat, ReaderFactory> _registry;

  ReaderContract? _reader;
  String? _bookId;
  ReaderPosition? _position;
  Timer? _autoSaveTimer;

  late final ReaderBookmarks bookmarks = ReaderBookmarks(
    load: () => repository.loadBookmarks(_requireBookId()),
    save: (b) => repository.saveBookmark(b),
    remove: (id) => repository.removeBookmark(_requireBookId(), id),
  );
  late final ReaderAnnotations annotations = ReaderAnnotations(
    load: () => repository.loadAnnotations(_requireBookId()),
    save: (a) => repository.saveAnnotation(a),
    remove: (id) => repository.removeAnnotation(_requireBookId(), id),
  );
  late final ReaderStatistics statistics = ReaderStatistics(
    load: repository.loadBookStats,
    save: repository.saveBookStats,
    loadAll: repository.loadAllBookStats,
  );

  ReaderNavigation? _navigation;
  ReaderSearch? _search;

  /// Callbacks destinés à la couche application (reconnexion Library /
  /// UI) — optionnels, le Reader reste fonctionnel sans.
  void Function(ReaderPosition position)? onPositionChanged;
  void Function(String bookId, int durationSeconds, double progress)?
      onSessionClosed;

  ReaderManager({
    required this.repository,
    this.autoSaveInterval = const Duration(seconds: 15),
    Map<ReaderFormat, ReaderFactory>? additionalReaders,
  }) : _registry = {
          ReaderFormat.epub: () => EpubReader(),
          ReaderFormat.pdf: () => PdfReader(),
          // CBZ, CBR, MOBI, AZW3, FB2 : formats prévus par le contrat.
          // Ils s'enregistreront ici (registerReader) sans rien modifier
          // d'autre — voir le rapport d'étape.
          ...?additionalReaders,
        };

  /// Enregistre un lecteur supplémentaire (ou remplace un existant).
  /// Point d'extension pour CBZ/CBR/MOBI/AZW3/FB2.
  void registerReader(ReaderFormat format, ReaderFactory factory) {
    _registry[format] = factory;
  }

  // ------------------------------------------------------------------
  // État courant
  // ------------------------------------------------------------------

  bool get isOpen => _reader != null;

  ReaderContract? get reader => _reader;

  /// Identité du livre ouvert (chemin absolu du fichier — l'application
  /// pourra la faire correspondre à son propre identifiant).
  String? get bookId => _bookId;

  ReaderPosition? get position => _position;

  ReaderNavigation get navigation {
    final nav = _navigation;
    if (nav == null) throw StateError('ReaderManager : aucun livre ouvert.');
    return nav;
  }

  ReaderSearch get search {
    final s = _search;
    if (s == null) throw StateError('ReaderManager : aucun livre ouvert.');
    return s;
  }

  String _requireBookId() {
    final id = _bookId;
    if (id == null) {
      throw StateError('ReaderManager : aucun livre ouvert.');
    }
    return id;
  }

  // ------------------------------------------------------------------
  // Ouverture / fermeture
  // ------------------------------------------------------------------

  /// Ouvre un fichier local et restaure la dernière position connue.
  ///
  /// Le format est détecté par l'extension puis confirmé par les magic
  /// bytes (PK pour EPUB, %PDF- pour PDF) quand c'est possible.
  /// Retourne la position de reprise.
  Future<ReaderPosition> open(String filePath) async {
    await close(); // ferme proprement tout livre précédent

    final file = File(filePath);
    if (!await file.exists()) {
      throw ReaderOpenException('Fichier introuvable : $filePath');
    }
    final format = _detectFormat(file);
    final factory = _registry[format];
    if (factory == null) {
      throw ReaderUnsupportedException(format);
    }

    final reader = factory();
    await reader.open(file);

    _reader = reader;
    _bookId = file.absolute.path;

    // Historique de navigation restauré + sous-systèmes.
    final restoredHistory =
        await repository.loadNavigationHistory(_bookId!);
    _navigation = ReaderNavigation(
        tableOfContents: reader.tableOfContents,
        restoredHistory: restoredHistory);
    _search = ReaderSearch(reader);
    await bookmarks.init();
    await annotations.init();

    // Session de lecture + date d'ouverture.
    statistics.startSession();

    // Reprise à la dernière position mémorisée (sinon début du livre).
    final saved = await repository.loadPosition(_bookId!);
    final start = (saved != null && saved.unitIndex < reader.unitCount)
        ? saved
        : reader.positionFor(0);
    _applyPosition(start);

    // Auto-save périodique.
    _autoSaveTimer?.cancel();
    _autoSaveTimer =
        Timer.periodic(autoSaveInterval, (_) => saveNow());

    return _position!;
  }

  /// Ferme le livre : auto-save final, clôture de session, statistiques.
  Future<void> close() async {
    if (_reader == null) return;
    final bookId = _bookId!;
    final progress = _position?.progress ?? 0;

    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;

    await saveNow();

    // Durée capturée AVANT la clôture (endSession remet le compteur à 0).
    final sessionSeconds = statistics.currentSessionSeconds;
    await statistics.endSession(bookId, progress: progress);
    onSessionClosed?.call(bookId, sessionSeconds, progress);

    await _reader!.close();
    _reader = null;
    _bookId = null;
    _position = null;
    _navigation = null;
    _search = null;
  }

  // ------------------------------------------------------------------
  // Position et navigation
  // ------------------------------------------------------------------

  /// Déplace la position courante (enregistre la visite, notifie).
  void goTo(ReaderPosition position) {
    _applyPosition(position);
  }

  /// Déplacement par index d'unité (chapitre/page).
  void goToUnit(int unitIndex, {double offsetRatio = 0}) {
    final reader = _reader;
    if (reader == null) throw StateError('Aucun livre ouvert.');
    _applyPosition(reader.positionFor(unitIndex, offsetRatio: offsetRatio));
  }

  /// Chapitre suivant (null en fin de livre).
  ReaderPosition? goToNextChapter() {
    final current = _position;
    if (current == null) return null;
    final next = navigation.nextChapter(current.unitIndex);
    final index = next?.unitIndex;
    if (index == null) return null;
    goToUnit(index);
    return _position;
  }

  /// Chapitre précédent (null en début de livre).
  ReaderPosition? goToPreviousChapter() {
    final current = _position;
    if (current == null) return null;
    final previous = navigation.previousChapter(current.unitIndex);
    final index = previous?.unitIndex;
    if (index == null) return null;
    goToUnit(index);
    return _position;
  }

  /// Retour navigateur dans l'historique (null si rien à quoi revenir).
  ReaderPosition? goBack() {
    final locator = navigation.goBack();
    if (locator == null) return null;
    return _positionFromLocator(locator);
  }

  /// Retourne à la dernière position persistée (ex. après une réouverture
  /// volontaire au début).
  Future<ReaderPosition?> returnToLastPosition() async {
    final saved = await repository.loadPosition(_requireBookId());
    if (saved == null || saved.unitIndex >= (_reader?.unitCount ?? 0)) {
      return null;
    }
    _applyPosition(saved);
    return saved;
  }

  ReaderPosition? _positionFromLocator(String locator) {
    final reader = _reader;
    if (reader == null) return null;
    // Format des locators produits par positionFor : « epub:uN » / « pdf:pN ».
    final match = RegExp(r'^[a-z]+:[a-z](\d+)$').firstMatch(locator);
    if (match == null) return null;
    final index = int.parse(match.group(1)!);
    if (index >= reader.unitCount) return null;
    _applyPosition(reader.positionFor(index));
    return _position;
  }

  void _applyPosition(ReaderPosition position) {
    _position = position;
    _navigation?.recordVisit(position.locator);
    onPositionChanged?.call(position);
  }

  // ------------------------------------------------------------------
  // Auto-save
  // ------------------------------------------------------------------

  /// Sauvegarde immédiate : position, progression, historique de
  /// navigation. Appelée par le minuteur, par [close], et disponible
  /// pour l'UI (pause de l'application, changement de page...).
  Future<void> saveNow() async {
    final bookId = _bookId;
    final position = _position;
    if (bookId == null || position == null) return;
    await repository.savePosition(bookId, position);
    await statistics.recordProgress(bookId, position.progress);
    final history = _navigation?.history;
    if (history != null) {
      await repository.saveNavigationHistory(bookId, history);
    }
  }

  // ------------------------------------------------------------------
  // Réglages
  // ------------------------------------------------------------------

  Future<ReaderSettings> loadSettings() => repository.loadSettings();

  Future<void> saveSettings(ReaderSettings settings) =>
      repository.saveSettings(settings);

  // ------------------------------------------------------------------
  // Contenu (délégation au lecteur actif)
  // ------------------------------------------------------------------

  Future<ReaderContent> loadUnit(int unitIndex) {
    final reader = _reader;
    if (reader == null) throw StateError('Aucun livre ouvert.');
    return reader.loadUnit(unitIndex);
  }

  // ------------------------------------------------------------------
  // Détection de format
  // ------------------------------------------------------------------

  ReaderFormat _detectFormat(File file) {
    final byExtension = readerFormatFromPath(file.path);
    // Confirmation par magic bytes quand le fichier est lisible.
    try {
      final raf = file.openSync();
      final header = raf.readSync(5);
      raf.closeSync();
      if (header.length >= 5 &&
          String.fromCharCodes(header) == '%PDF-') {
        return ReaderFormat.pdf;
      }
      if (header.length >= 2 && header[0] == 0x50 && header[1] == 0x4B) {
        // ZIP : EPUB ou CBZ — l'extension départage.
        if (byExtension == ReaderFormat.cbz) return ReaderFormat.cbz;
        return ReaderFormat.epub;
      }
    } catch (_) {
      // En cas d'échec de lecture d'en-tête, l'extension décide.
    }
    return byExtension;
  }

  Future<void> dispose() async {
    await close();
  }
}
