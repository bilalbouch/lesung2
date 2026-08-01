import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_instance_store.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_instances.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_source.dart';

import 'annas_archive_health_check_test.dart' show searchFixture;

void main() {
  ArchiveInstance inst(String id, {double score = 0.5}) => ArchiveInstance(
      id: id, name: id, baseUrl: 'https://$id.test', score: score);

  group('AnnaArchiveInstanceStore', () {
    test('persist puis restore : round-trip du classement', () async {
      final dir =
          await Directory.systemTemp.createTemp('instance_store_test');
      addTearDown(() => dir.delete(recursive: true));
      final store = AnnaArchiveInstanceStore(dir);

      final saved = [
        inst('a', score: 0.9)..lastCheckedAt = DateTime(2026, 1, 1, 10),
        inst('b', score: 0.3)..lastCheckedAt = DateTime(2026, 1, 1, 9),
      ];
      await store.persist(saved);

      // Écriture atomique : pas de fichier temporaire résiduel.
      expect(await File('${dir.path}/instance_ranking.json.tmp').exists(),
          isFalse);

      final fresh = [inst('a'), inst('b')];
      final newest = await store.restore(fresh);

      expect(fresh[0].score, closeTo(0.9, 1e-9));
      expect(fresh[1].score, closeTo(0.3, 1e-9));
      expect(fresh[0].lastCheckedAt, DateTime(2026, 1, 1, 10));
      expect(newest, DateTime(2026, 1, 1, 10),
          reason: 'mesure la plus récente restaurée');
    });

    test('restore ignore les ids inconnus et conserve les défauts', () async {
      final dir =
          await Directory.systemTemp.createTemp('instance_store_test');
      addTearDown(() => dir.delete(recursive: true));
      final store = AnnaArchiveInstanceStore(dir);
      await store.persist([inst('a', score: 0.8)]);

      final fresh = [inst('inconnu'), inst('a')];
      await store.restore(fresh);

      expect(fresh[0].score, 0.5, reason: 'id inconnu : score par défaut');
      expect(fresh[1].score, closeTo(0.8, 1e-9));
    });

    test('restore sur fichier absent ou corrompu : no-op silencieux',
        () async {
      final dir =
          await Directory.systemTemp.createTemp('instance_store_test');
      addTearDown(() => dir.delete(recursive: true));
      final store = AnnaArchiveInstanceStore(dir);

      final fresh = [inst('a')];
      expect(await store.restore(fresh), isNull,
          reason: 'fichier absent');
      expect(fresh[0].score, 0.5);

      await File('${dir.path}/instance_ranking.json')
          .writeAsString('{json cassé');
      expect(await store.restore(fresh), isNull,
          reason: 'fichier corrompu');
      expect(fresh[0].score, 0.5);
    });
  });

  group('retest régulier (maintainInstances)', () {
    AnnaArchiveSource makeSource(Directory dir,
        {Duration healthMaxAge = const Duration(hours: 6)}) {
      final mock = MockClient(
          (_) async => http.Response(searchFixture(), 200));
      return AnnaArchiveSource.custom(
        httpClient: mock,
        instances: [inst('a'), inst('b')],
        cache: null,
        instanceStore: AnnaArchiveInstanceStore(dir),
        healthMaxAge: healthMaxAge,
      );
    }

    test('premier appel : mesure + persistance du classement', () async {
      final dir =
          await Directory.systemTemp.createTemp('instance_store_test');
      addTearDown(() => dir.delete(recursive: true));
      final source = makeSource(dir);

      final reports = await source.maintainInstances();

      expect(reports, hasLength(2));
      final saved = jsonDecode(
          await File('${dir.path}/instance_ranking.json').readAsString());
      expect(saved.keys, containsAll(['a', 'b']),
          reason: 'classement sauvegardé après la mesure');
    });

    test('classement frais : aucune nouvelle mesure', () async {
      final dir =
          await Directory.systemTemp.createTemp('instance_store_test');
      addTearDown(() => dir.delete(recursive: true));
      final source = makeSource(dir);

      await source.maintainInstances();
      final reports = await source.maintainInstances();

      expect(reports, isEmpty,
          reason: 'classement plus frais que healthMaxAge : pas de retest');
    });

    test('classement périmé : retest automatique', () async {
      final dir =
          await Directory.systemTemp.createTemp('instance_store_test');
      addTearDown(() => dir.delete(recursive: true));
      final source =
          makeSource(dir, healthMaxAge: Duration.zero);

      await source.maintainInstances();
      final reports = await source.maintainInstances();

      expect(reports, hasLength(2),
          reason: 'healthMaxAge dépassé => nouvelle mesure');
    });

    test('initialize restaure le classement sauvegardé', () async {
      final dir =
          await Directory.systemTemp.createTemp('instance_store_test');
      addTearDown(() => dir.delete(recursive: true));

      // Session 1 : mesure + persistance (b meilleur que a).
      final mockA = MockClient((request) async => http.Response(
          request.url.host.startsWith('b') ? searchFixture() : 'down',
          request.url.host.startsWith('b') ? 200 : 503));
      final session1 = AnnaArchiveSource.custom(
        httpClient: mockA,
        instances: [inst('a'), inst('b')],
        cache: null,
        instanceStore: AnnaArchiveInstanceStore(dir),
      );
      await session1.maintainInstances();
      final bestScore = session1.client.instances
          .map((i) => i.score)
          .reduce((x, y) => x > y ? x : y);
      expect(bestScore, greaterThan(0.5));

      // Session 2 : le classement est restauré avant toute mesure.
      final session2 = makeSource(dir);
      await session2.initialize();
      final restored = session2.client.instances
          .firstWhere((i) => i.id == 'b');
      expect(restored.score, greaterThan(0.5),
          reason: 'score sauvegardé restauré au démarrage');
    });
  });
}
