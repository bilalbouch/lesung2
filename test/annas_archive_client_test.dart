import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_client.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_instances.dart';

ArchiveInstance inst(String id, {double score = 0.5}) =>
    ArchiveInstance(id: id, name: id, baseUrl: 'https://$id.test', score: score);

void main() {
  group('failover ordonné par score', () {
    test('essaie la meilleure instance en premier', () async {
      final calls = <String>[];
      final mock = MockClient((request) async {
        calls.add(request.url.host);
        if (request.url.host == 'good.test') {
          return http.Response('<html>ok</html>', 200);
        }
        throw http.ClientException('connection refused');
      });

      final client = AnnaArchiveClient(httpClient: mock, instances: [
        inst('bad', score: 0.9),
        inst('good', score: 0.8),
      ]);

      final response = await client.get('/search?q=x');
      expect(response.body, '<html>ok</html>');
      expect(response.instanceBaseUrl, 'https://good.test');
      expect(calls.first, 'bad.test', reason: 'meilleur score d\'abord');
    });
  });

  group('retry intelligent', () {
    test('retente avec backoff sur erreur réseau transitoire', () async {
      var attempts = 0;
      final mock = MockClient((request) async {
        attempts++;
        if (attempts < 2) throw http.ClientException('reset');
        return http.Response('ok', 200);
      });

      final client = AnnaArchiveClient(
          httpClient: mock,
          instances: [inst('a')],
          maxAttemptsPerInstance: 3);
      final response = await client.get('/x');
      expect(response.body, 'ok');
      expect(attempts, 2);
    });

    test('5xx -> instance suivante sans retry inutile', () async {
      final calls = <String>[];
      final mock = MockClient((request) async {
        calls.add(request.url.host);
        if (request.url.host == 'sick.test') {
          return http.Response('err', 502);
        }
        return http.Response('ok', 200);
      });

      final client = AnnaArchiveClient(httpClient: mock, instances: [
        inst('sick', score: 0.9),
        inst('fine', score: 0.5),
      ]);
      final r = await client.get('/x');
      expect(r.body, 'ok');
      expect(calls.where((h) => h == 'sick.test').length, 1);
    });

    test('toutes les instances en échec -> AllInstancesFailedException', () {
      final mock = MockClient((_) async => throw http.ClientException('down'));
      final client = AnnaArchiveClient(
          httpClient: mock,
          instances: [inst('a'), inst('b')],
          maxAttemptsPerInstance: 1);
      expect(client.get('/x'), throwsA(isA<AllInstancesFailedException>()));
    });
  });

  group('Cloudflare', () {
    test('challenge détecté -> bascule instance + flag cloudflareOnAll', () {
      final mock = MockClient((request) async => http.Response(
          '<html><title>Just a moment...</title>cf-chl</html>', 403));
      final client = AnnaArchiveClient(
          httpClient: mock, instances: [inst('a'), inst('b')]);

      expect(
        client.get('/x'),
        throwsA(isA<AllInstancesFailedException>()
            .having((e) => e.cloudflareOnAll, 'cloudflareOnAll', isTrue)),
      );
    });

    test('les en-têtes de session sont injectés', () async {
      Map<String, String>? seenHeaders;
      final mock = MockClient((request) async {
        seenHeaders = request.headers;
        return http.Response('ok', 200);
      });
      final client = AnnaArchiveClient(httpClient: mock, instances: [inst('a')])
        ..sessionHeaders = {'cookie': 'cf_clearance=abc'};
      await client.get('/x');
      expect(seenHeaders!['cookie'], 'cf_clearance=abc');
    });
  });

  group('annulation', () {
    test('jeton annulé avant -> RequestCancelledException immédiate', () {
      final mock = MockClient((_) async => http.Response('ok', 200));
      final client = AnnaArchiveClient(httpClient: mock, instances: [inst('a')]);
      final token = CancellationToken()..cancel();
      expect(client.get('/x', token: token),
          throwsA(isA<RequestCancelledException>()));
    });

    test('annulation pendant un retry interrompt la boucle', () async {
      final token = CancellationToken();
      var attempts = 0;
      final mock = MockClient((_) async {
        attempts++;
        if (attempts == 1) token.cancel();
        throw http.ClientException('down');
      });
      final client = AnnaArchiveClient(
          httpClient: mock,
          instances: [inst('a'), inst('b')],
          maxAttemptsPerInstance: 3);
      await expectLater(client.get('/x', token: token),
          throwsA(isA<RequestCancelledException>()));
      expect(attempts, lessThan(4), reason: 'boucle interrompue tôt');
    });
  });

  group('timeout', () {
    test('une instance qui traîne dépasse le timeout et bascule', () async {
      final mock = MockClient((request) async {
        if (request.url.host == 'slow.test') {
          await Future.delayed(const Duration(seconds: 5));
        }
        return http.Response('ok', 200);
      });
      final client = AnnaArchiveClient(
          httpClient: mock,
          instances: [inst('slow', score: 0.9), inst('fast', score: 0.1)],
          attemptTimeout: const Duration(milliseconds: 200),
          maxAttemptsPerInstance: 1);
      final r = await client.get('/x');
      expect(r.instanceBaseUrl, 'https://fast.test');
    });
  });
}
