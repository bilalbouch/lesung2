import 'dart:io';
import 'package:test/test.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_cache.dart';

void main() {
  group('cache mémoire', () {
    test('set/get dans le TTL', () async {
      final cache = AnnaArchiveCache();
      await cache.set('k', 'v');
      expect(await cache.get('k'), 'v');
    });

    test('entrée expirée -> null', () async {
      final cache = AnnaArchiveCache();
      await cache.set('k', 'v', ttl: const Duration(milliseconds: -1));
      expect(await cache.get('k'), isNull);
    });

    test('éviction LRU au-delà de la capacité', () async {
      final cache = AnnaArchiveCache(memoryMaxEntries: 3);
      await cache.set('a', '1');
      await cache.set('b', '2');
      await cache.set('c', '3');
      await cache.get('a'); // a redevient récent
      await cache.set('d', '4'); // évince b (le plus ancien touché)

      expect(await cache.get('b'), isNull);
      expect(await cache.get('a'), '1');
      expect(await cache.get('d'), '4');
      expect(cache.memorySize, 3);
    });
  });

  group('cache disque', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('lesung_cache_test');
    });
    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('persistance entre deux instances de cache', () async {
      final cache1 = AnnaArchiveCache(diskDirectory: dir);
      await cache1.initialize();
      await cache1.set('persist', 'data');

      // Nouveau cache, mémoire vide : lecture disque.
      final cache2 = AnnaArchiveCache(diskDirectory: dir);
      await cache2.initialize();
      expect(await cache2.get('persist'), 'data');
    });

    test('nettoyage automatique des entrées expirées', () async {
      final cache = AnnaArchiveCache(
          diskDirectory: dir, cleanupEveryNWrites: 2);
      await cache.initialize();
      await cache.set('expired', 'x',
          ttl: const Duration(milliseconds: -1));
      await cache.set('fresh', 'y'); // déclenche le nettoyage (2e écriture)

      final files = dir
          .listSync()
          .where((f) => f.path.endsWith('.cache'))
          .toList();
      expect(files.length, 1, reason: 'l\'entrée expirée est purgée');
      expect(await cache.get('fresh'), 'y');
    });

    test('fichier corrompu supprimé préventivement', () async {
      final cache = AnnaArchiveCache(diskDirectory: dir);
      await cache.initialize();
      await File('${dir.path}/broken.cache').writeAsString('not json');
      await cache.cleanup();
      expect(await File('${dir.path}/broken.cache').exists(), isFalse);
    });
  });
}
