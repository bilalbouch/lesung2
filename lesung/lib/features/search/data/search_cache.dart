import '../domain/entities/search_query.dart';
import '../domain/entities/search_result.dart';

/// Entrée de cache : résultat + date d'expiration.
class _CacheEntry {
  final SearchResult result;
  final DateTime expiresAt;

  const _CacheEntry(this.result, this.expiresAt);
}

/// CACHE MÉMOIRE DU MOTEUR DE RECHERCHE.
///
/// Clé : la [SearchQuery] complète — texte, langue, format, page et tri
/// (égalité structurelle déjà définie sur l'entité). Deux requêtes qui
/// ne diffèrent que par la page ou le tri sont donc des entrées
/// distinctes, comme exigé.
///
/// Invalidation automatique :
/// - chaque entrée expire après [ttl] (vérifiée paresseusement à la
///   lecture — aucune minuterie n'est nécessaire) ;
/// - à l'écriture, les entrées expirées sont balayées, puis les plus
///   anciennes sont évincées si [maxEntries] est atteint.
///
/// [clock] est injectable pour rendre l'expiration testable sans
/// attendre réellement.
class SearchCache {
  /// Durée de vie d'une entrée.
  final Duration ttl;

  /// Nombre maximal d'entrées conservées.
  final int maxEntries;

  final DateTime Function() _clock;

  /// LinkedHashMap : l'ordre d'itération est l'ordre d'insertion,
  /// ce qui permet l'éviction des plus anciennes entrées.
  final Map<SearchQuery, _CacheEntry> _entries = {};

  SearchCache({
    this.ttl = const Duration(minutes: 5),
    this.maxEntries = 64,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Résultat en cache pour [query], ou null si absent ou expiré.
  SearchResult? get(SearchQuery query) {
    final entry = _entries[query];
    if (entry == null) return null;
    if (_clock().isAfter(entry.expiresAt)) {
      _entries.remove(query); // expiration => invalidation immédiate
      return null;
    }
    return entry.result;
  }

  /// Met en cache le [result] de [query] (remplace une entrée
  /// existante pour la même clé).
  void put(SearchQuery query, SearchResult result) {
    _sweepExpired();
    if (_entries.containsKey(query)) _entries.remove(query);
    _entries[query] = _CacheEntry(result, _clock().add(ttl));
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first); // plus ancienne
    }
  }

  /// Invalide tout le cache (changement de configuration des sources,
  /// nouvelle session, etc.).
  void invalidate() => _entries.clear();

  /// Nombre d'entrées actuellement conservées (expirées incluses
  /// jusqu'au prochain accès).
  int get size => _entries.length;

  void _sweepExpired() {
    final now = _clock();
    _entries.removeWhere((_, entry) => now.isAfter(entry.expiresAt));
  }
}
