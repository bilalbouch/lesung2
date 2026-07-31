import 'dart:convert';
import 'dart:io';

/// Cache double niveau pour le provider : mémoire (LRU) + disque (TTL).
///
/// - mémoire : accès instantané, capacité bornée, éviction LRU
/// - disque : persistance entre sessions, TTL par entrée
/// - nettoyage automatique : à l'initialisation et périodiquement
///   (toutes les [cleanupEveryNWrites] écritures), les entrées
///   expirées sont supprimées sans intervention extérieure.
///
/// Le répertoire disque est INJECTÉ : testable dans un dossier temporaire,
/// et la couche app fournira le vrai chemin (application support).
class AnnaArchiveCache {
  final Directory? diskDirectory;
  final int memoryMaxEntries;
  final Duration defaultTtl;
  final int cleanupEveryNWrites;

  /// Mémoire : LinkedHashMap = ordre d'insertion, base du LRU.
  final Map<String, _MemoryEntry> _memory = {};

  int _writesSinceCleanup = 0;
  bool _diskReady = false;

  AnnaArchiveCache({
    this.diskDirectory,
    this.memoryMaxEntries = 150,
    this.defaultTtl = const Duration(minutes: 30),
    this.cleanupEveryNWrites = 25,
  });

  /// À appeler au démarrage : prépare le disque et purge les expirés.
  Future<void> initialize() async {
    final dir = diskDirectory;
    if (dir == null) return;
    try {
      if (!await dir.exists()) await dir.create(recursive: true);
      _diskReady = true;
      await cleanup();
    } catch (_) {
      _diskReady = false; // Disque indisponible : mémoire seule.
    }
  }

  /// Lecture : mémoire d'abord, disque ensuite (remonte en mémoire).
  /// Retourne null si absente ou expirée.
  Future<String?> get(String key) async {
    final mem = _memory[key];
    if (mem != null) {
      if (!mem.isExpired) {
        _touch(key); // LRU : l'entrée redevient la plus récente.
        return mem.payload;
      }
      _memory.remove(key);
    }

    if (!_diskReady) return null;
    final file = _fileFor(key);
    try {
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(decoded['expiresAt'] as int);
      if (DateTime.now().isAfter(expiresAt)) {
        await file.delete();
        return null;
      }
      final payload = decoded['payload'] as String;
      _putMemory(key, payload, expiresAt);
      return payload;
    } catch (_) {
      return null;
    }
  }

  /// Écriture : mémoire + disque, TTL identique des deux côtés.
  Future<void> set(String key, String payload, {Duration? ttl}) async {
    final expiresAt = DateTime.now().add(ttl ?? defaultTtl);
    _putMemory(key, payload, expiresAt);

    if (_diskReady) {
      try {
        await _fileFor(key).writeAsString(jsonEncode({
          'expiresAt': expiresAt.millisecondsSinceEpoch,
          'payload': payload,
        }));
      } catch (_) {/* disque plein/indisponible : mémoire suffit */}
    }

    // Nettoyage automatique périodique.
    if (++_writesSinceCleanup >= cleanupEveryNWrites) {
      _writesSinceCleanup = 0;
      await cleanup();
    }
  }

  /// Purge toutes les entrées expirées (mémoire + disque).
  Future<void> cleanup() async {
    _memory.removeWhere((_, e) => e.isExpired);

    if (!_diskReady) return;
    try {
      await for (final entity in diskDirectory!.list()) {
        if (entity is! File || !entity.path.endsWith('.cache')) continue;
        try {
          final decoded = jsonDecode(await entity.readAsString());
          final expiresAt = DateTime.fromMillisecondsSinceEpoch(
              decoded['expiresAt'] as int);
          if (DateTime.now().isAfter(expiresAt)) await entity.delete();
        } catch (_) {
          // Fichier illisible/corrompu : suppression préventive.
          await entity.delete();
        }
      }
    } catch (_) {/* ignore */}
  }

  Future<void> clear() async {
    _memory.clear();
    if (!_diskReady) return;
    try {
      await for (final entity in diskDirectory!.list()) {
        if (entity is File && entity.path.endsWith('.cache')) {
          await entity.delete();
        }
      }
    } catch (_) {/* ignore */}
  }

  int get memorySize => _memory.length;

  // ------------------------------------------------------------------

  void _putMemory(String key, String payload, DateTime expiresAt) {
    _memory.remove(key); // réinsertion en fin = plus récent
    _memory[key] = _MemoryEntry(payload, expiresAt);
    while (_memory.length > memoryMaxEntries) {
      _memory.remove(_memory.keys.first); // éviction LRU
    }
  }

  void _touch(String key) {
    final entry = _memory.remove(key);
    if (entry != null) _memory[key] = entry;
  }

  File _fileFor(String key) {
    // Clé URL/query -> nom de fichier sûr et stable.
    final safe = key
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final trimmed =
        safe.length > 120 ? safe.substring(safe.length - 120) : safe;
    return File('${diskDirectory!.path}/$trimmed.cache');
  }
}

class _MemoryEntry {
  final String payload;
  final DateTime expiresAt;
  _MemoryEntry(this.payload, this.expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
