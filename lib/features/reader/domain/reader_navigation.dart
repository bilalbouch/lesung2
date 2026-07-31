import 'reader_contract.dart';

/// Navigation dans un livre ouvert : chapitres, historique, retour.
///
/// Maintient la pile des positions visitées (persistée via le
/// repository), la navigation par chapitre via la table des matières
/// aplatie, et le « retour » façon navigateur.
class ReaderNavigation {
  /// Profondeur maximale de l'historique (les plus anciennes entrées
  /// sont évincées).
  static const maxHistoryLength = 50;

  final List<ReaderTocEntry> _flatToc;
  final List<String> _history;

  ReaderNavigation({
    required List<ReaderTocEntry> tableOfContents,
    List<String> restoredHistory = const [],
  })  : _flatToc = _flatten(tableOfContents),
        _history = [...restoredHistory];

  static List<ReaderTocEntry> _flatten(List<ReaderTocEntry> toc) {
    final result = <ReaderTocEntry>[];
    for (final entry in toc) {
      result.addAll(entry.flatten());
    }
    return result;
  }

  /// Table des matières aplatie (parcours préfixe).
  List<ReaderTocEntry> get flatToc => List.unmodifiable(_flatToc);

  /// Historique des locators visités (le plus récent en fin).
  List<String> get history => List.unmodifiable(_history);

  bool get canGoBack => _history.length >= 2;

  /// Enregistre une visite (ignorée si identique au sommet de pile).
  void recordVisit(String locator) {
    if (locator.isEmpty) return;
    if (_history.isNotEmpty && _history.last == locator) return;
    _history.add(locator);
    if (_history.length > maxHistoryLength) {
      _history.removeRange(0, _history.length - maxHistoryLength);
    }
  }

  /// Retourne le locator précédent et le retire de la pile.
  /// Null si l'historique est insuffisant.
  String? goBack() {
    if (!canGoBack) return null;
    _history.removeLast(); // position courante
    return _history.last; // précédente, qui devient courante
  }

  /// Index de l'unité cible d'une entrée de toc, si connu.
  int? unitIndexOf(ReaderTocEntry entry) => entry.unitIndex;

  /// Entrée de toc active pour une unité donnée (la dernière entrée
  /// dont l'unité est <= unitIndex — classique « chapitre courant »).
  ReaderTocEntry? activeEntryFor(int unitIndex) {
    ReaderTocEntry? active;
    for (final entry in _flatToc) {
      final index = entry.unitIndex;
      if (index != null && index <= unitIndex) {
        active = entry;
      } else if (index != null && index > unitIndex) {
        break;
      }
    }
    return active;
  }

  /// Entrée de chapitre suivante (null en fin de livre).
  ReaderTocEntry? nextChapter(int currentUnitIndex) {
    for (final entry in _flatToc) {
      final index = entry.unitIndex;
      if (index != null && index > currentUnitIndex) return entry;
    }
    return null;
  }

  /// Entrée de chapitre précédente : le chapitre qui précède celui
  /// qui contient l'unité courante (null en début de livre).
  ReaderTocEntry? previousChapter(int currentUnitIndex) {
    ReaderTocEntry? current;
    for (final entry in _flatToc) {
      final index = entry.unitIndex;
      if (index != null && index < currentUnitIndex) {
        current = entry;
      } else if (index != null && index >= currentUnitIndex) {
        break;
      }
    }
    // Si l'unité courante est au tout début de son chapitre, on veut le
    // précédent ; sinon on revient au début du chapitre courant.
    if (current == null) return null;
    final active = activeEntryFor(currentUnitIndex);
    if (active != null &&
        active.unitIndex != null &&
        active.unitIndex! < currentUnitIndex) {
      return active; // revenir au début du chapitre en cours
    }
    return current;
  }
}
