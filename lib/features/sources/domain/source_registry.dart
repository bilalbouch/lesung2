import 'book_source.dart';

/// Registre des sources de livres.
///
/// Fournit au moteur la liste des providers ACTIFS. Les sources
/// s'enregistrent au démarrage ; l'activation/désactivation est
/// dynamique et n'exige aucune modification du moteur.
class SourceRegistry {
  final Map<String, BookSource> _sources = {};
  final Set<String> _disabled = {};

  /// Enregistre une source (active par défaut).
  void register(BookSource source) {
    _sources[source.meta.id] = source;
  }

  /// Retire complètement une source.
  bool unregister(String sourceId) => _sources.remove(sourceId) != null;

  void enable(String sourceId) => _disabled.remove(sourceId);

  void disable(String sourceId) {
    if (_sources.containsKey(sourceId)) _disabled.add(sourceId);
  }

  bool isEnabled(String sourceId) =>
      _sources.containsKey(sourceId) && !_disabled.contains(sourceId);

  /// Sources actives, dans l'ordre d'enregistrement.
  List<BookSource> get activeSources =>
      _sources.values.where((s) => !_disabled.contains(s.meta.id)).toList();

  /// Toutes les sources enregistrées (actives ou non).
  List<BookSource> get allSources => List.unmodifiable(_sources.values);

  BookSource? byId(String sourceId) => _sources[sourceId];

  int get activeCount => activeSources.length;
}
