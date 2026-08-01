import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_health_check.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_instances.dart';

String searchFixture() =>
    File('test/fixtures/aa_search.html').readAsStringSync();

void main() {
  ArchiveInstance inst(String id) =>
      ArchiveInstance(id: id, name: id, baseUrl: 'https://$id.test');

  group('health check fonctionnel', () {
    test('mesure disponibilité, latence, qualité et calcule le score', () async {
      final mock = MockClient((_) async => http.Response(searchFixture(), 200));
      final hc = AnnaArchiveHealthCheck(httpClient: mock);

      final report = await hc.checkInstance(inst('ok'));

      expect(report.available, isTrue);
      expect(report.latency, isNotNull);
      expect(report.challengeDetected, isFalse);
      expect(report.quality, lessThan(1),
          reason: 'fixture de 3 hits -> qualité partielle');
      expect(report.quality, greaterThan(0));
      expect(report.score, greaterThan(0.5));
    });

    test('challenge Cloudflare -> score faible mais disponible', () async {
      final mock = MockClient((_) async => http.Response(
          '<html><title>Just a moment...</title>cf-chl</html>', 403));
      final hc = AnnaArchiveHealthCheck(httpClient: mock);

      final report = await hc.checkInstance(inst('cf'));
      expect(report.available, isTrue);
      expect(report.challengeDetected, isTrue);
      expect(report.score, lessThan(0.3));
    });

    test('instance en panne -> score 0', () async {
      final mock =
          MockClient((_) async => throw http.ClientException('down'));
      final hc = AnnaArchiveHealthCheck(httpClient: mock);

      final report = await hc.checkInstance(inst('down'));
      expect(report.available, isFalse);
      expect(report.score, 0);
      expect(report.error, isNotNull);
    });

    test('checkAll trie et met à jour les scores des instances', () async {
      final mock = MockClient((request) async {
        if (request.url.host == 'good.test') {
          return http.Response(searchFixture(), 200);
        }
        return http.Response('err', 500);
      });
      final instances = [inst('bad'), inst('good')];
      final hc = AnnaArchiveHealthCheck(httpClient: mock);

      final reports = await hc.checkAll(instances);

      expect(reports.first.instanceId, 'good');
      expect(instances.firstWhere((i) => i.id == 'good').score,
          greaterThan(instances.firstWhere((i) => i.id == 'bad').score));
      expect(instances.every((i) => i.lastCheckedAt != null), isTrue);
    });
  });
}
