import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:lesung/core/network/cloudflare_guard.dart';
import 'package:lesung/features/search/domain/entities/search_query.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_instances.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_mapper.dart';
import 'package:lesung/features/sources/data/annas_archive/annas_archive_source.dart';

String fixture(String n) => File('test/fixtures/$n').readAsStringSync();

ArchiveInstance inst(String id) =>
    ArchiveInstance(id: id, name: id, baseUrl: 'https://$id.test');

void main() {
  group('AnnaArchiveSource intégrée', () {
    test('recherche -> Book unifié avec mapping complet', () async {
      final mock = MockClient((_) async => http.Response(
          fixture('aa_search.html'), 200));
      final source = AnnaArchiveSource.custom(
          httpClient: mock, instances: [inst('a')]);

      final page = await source.search(const SearchQuery(text: 'kafka'));

      expect(page.items, hasLength(3));
      final kafka = page.items.first;
      expect(kafka.title, 'Die Verwandlung');
      expect(kafka.language, 'de');
      expect(kafka.format, BookFormat.epub);
      expect(kafka.year, 1915);
      expect(kafka.refs.single.sourceId, AnnaArchiveMapper.sourceId);
      expect(kafka.refs.single.url.toString(),
          'https://a.test/md5/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
      expect(page.hasMore, isTrue);
    });

    test('cache mémoire : 2e recherche identique sans réseau', () async {
      var networkCalls = 0;
      final mock = MockClient((_) async {
        networkCalls++;
        return http.Response(fixture('aa_search.html'), 200);
      });
      final source = AnnaArchiveSource.custom(
          httpClient: mock, instances: [inst('a')]);

      await source.search(const SearchQuery(text: 'kafka'));
      await source.search(const SearchQuery(text: 'kafka'));
      expect(networkCalls, 1, reason: 'réponse servie par le cache');
    });

    test('pagination : page 1 et page 2 sont des clés de cache distinctes',
        () async {
      var networkCalls = 0;
      final mock = MockClient((_) async {
        networkCalls++;
        return http.Response(fixture('aa_search.html'), 200);
      });
      final source = AnnaArchiveSource.custom(
          httpClient: mock, instances: [inst('a')]);

      await source.search(const SearchQuery(text: 'kafka', page: 1));
      await source.search(const SearchQuery(text: 'kafka', page: 2));
      expect(networkCalls, 2);
    });

    test('annulation : nouvelle recherche annule l\'ancienne', () async {
      final started = <String>[];
      final mock = MockClient((request) async {
        started.add(request.url.queryParameters['q'] ?? '');
        await Future.delayed(const Duration(milliseconds: 300));
        return http.Response(fixture('aa_search.html'), 200);
      });
      final source = AnnaArchiveSource.custom(
          httpClient: mock, instances: [inst('a')]);

      final first = source.search(const SearchQuery(text: 'premier'));
      // Attente attachée immédiatement : l'erreur d'annulation est
      // consommée par le matcher dès qu'elle survient.
      final firstExpectation =
          expectLater(first, throwsA(isA<Exception>()));
      await Future.delayed(const Duration(milliseconds: 50));
      final second = source.search(const SearchQuery(text: 'second'));

      final secondResult = await second;
      expect(secondResult.items, isNotEmpty);
      await firstExpectation;
    });

    test('détail : synopsis + isbn + liens slow_download mappés', () async {
      final mock = MockClient((_) async =>
          http.Response(fixture('aa_detail.html'), 200));
      final source = AnnaArchiveSource.custom(
          httpClient: mock, instances: [inst('a')]);

      final details =
          await source.details('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
      expect(details.synopsis, contains('Kafka'));
      expect(details.identifiers['isbn'], '9783150098148');

      final links = await source
          .resolveDownloadLinks('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
      expect(links, hasLength(2));
      expect(links.first.url.toString(),
          'https://a.test/slow_download/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/0/0');
    });

    test('Cloudflare partout -> guard sollicité, session injectée, succès',
        () async {
      var challenged = true;
      Map<String, String>? headersAfterSolve;
      final mock = MockClient((request) async {
        if (challenged) {
          return http.Response(
              '<html><title>Just a moment...</title>cf-chl</html>', 403);
        }
        headersAfterSolve = request.headers;
        return http.Response(fixture('aa_search.html'), 200);
      });

      final solver = _FakeSolver();
      final guard = CloudflareGuard(solver: solver);
      final source = AnnaArchiveSource.custom(
          httpClient: mock, instances: [inst('a')], guard: guard);

      // Première vague : challenge ; le guard appelle le solver, qui
      // attend le signal du test avant de rendre sa session.
      final future = source.search(const SearchQuery(text: 'kafka'));
      await solver.waitUntilCalled();
      challenged = false; // le solver a « passé » le challenge
      solver.complete();

      final page = await future;
      expect(page.items, isNotEmpty);
      expect(headersAfterSolve?['cookie'], 'cf_clearance=token',
          reason: 'session Cloudflare injectée après résolution');
    });

    test('healthCheck délègue au health checker et résume le meilleur',
        () async {
      final mock = MockClient((request) async {
        if (request.url.host == 'good.test') {
          return http.Response(fixture('aa_search.html'), 200);
        }
        return http.Response('err', 500);
      });
      final source = AnnaArchiveSource.custom(
          httpClient: mock, instances: [inst('bad'), inst('good')]);

      final health = await source.healthCheck();
      expect(health.reachable, isTrue);
      expect(health.challengeDetected, isFalse);

      // Le score de la bonne instance a été mis à jour.
      final good = source.client.instances
          .firstWhere((i) => i.baseUrl == 'https://good.test');
      expect(good.score, greaterThan(0.5));
    });
  });
}

class _FakeSolver implements CloudflareSolver {
  final _completer = Completer<void>();
  final _called = Completer<void>();

  @override
  Future<CloudflareSession?> solve(Uri pageUrl) async {
    if (!_called.isCompleted) _called.complete();
    await _completer.future;
    return CloudflareSession(
      cookieHeader: 'cf_clearance=token',
      userAgent: 'UA',
      obtainedAt: DateTime.now(),
    );
  }

  Future<void> waitUntilCalled() =>
      _called.future.timeout(const Duration(seconds: 5));

  void complete() {
    if (!_completer.isCompleted) _completer.complete();
  }
}
