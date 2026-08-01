import 'package:test/test.dart';
import 'package:lesung/core/network/cloudflare_guard.dart';

class FakeSolver implements CloudflareSolver {
  int callCount = 0;
  CloudflareSession? result;

  @override
  Future<CloudflareSession?> solve(Uri pageUrl) async {
    callCount++;
    await Future.delayed(const Duration(milliseconds: 50));
    return result;
  }
}

CloudflareSession session({int ageMinutes = 0}) => CloudflareSession(
      cookieHeader: 'cf_clearance=token',
      userAgent: 'UA',
      obtainedAt: DateTime.now().subtract(Duration(minutes: ageMinutes)),
    );

void main() {
  final url = Uri.parse('https://annas-archive.gl/');

  group('CloudflareGuard', () {
    test('sans session ni solver -> null', () async {
      final guard = CloudflareGuard();
      expect(await guard.resolve(url), isNull);
      expect(guard.hasFreshSession, isFalse);
    });

    test('résolution via solver puis cache de la session', () async {
      final solver = FakeSolver()..result = session();
      final guard = CloudflareGuard(solver: solver);

      final first = await guard.resolve(url);
      expect(first, isNotNull);
      expect(solver.callCount, 1);

      // Deuxième appel : bypass « normal » via le cache, pas de WebView.
      final second = await guard.resolve(url);
      expect(second, isNotNull);
      expect(solver.callCount, 1, reason: 'session fraîche réutilisée');
    });

    test('session expirée -> nouvelle résolution', () async {
      final solver = FakeSolver()..result = session(ageMinutes: 20);
      final guard = CloudflareGuard(solver: solver);

      await guard.resolve(url); // stocke une session déjà vieille
      await guard.resolve(url); // expirée -> re-solve
      expect(solver.callCount, 2);
    });

    test('une seule résolution interactive en vol', () async {
      final solver = FakeSolver()..result = session();
      final guard = CloudflareGuard(solver: solver);

      final results = await Future.wait([
        guard.resolve(url),
        guard.resolve(url),
        guard.resolve(url),
      ]);
      expect(results.every((r) => r != null), isTrue);
      expect(solver.callCount, 1,
          reason: 'appels concurrents mutualisés');
    });

    test('invalidate force une nouvelle résolution', () async {
      final solver = FakeSolver()..result = session();
      final guard = CloudflareGuard(solver: solver);

      await guard.resolve(url);
      guard.invalidate();
      await guard.resolve(url);
      expect(solver.callCount, 2);
    });

    test('sessionHeaders exposés seulement si session fraîche', () async {
      final solver = FakeSolver()..result = session();
      final guard = CloudflareGuard(solver: solver);

      expect(guard.sessionHeaders, isEmpty);
      await guard.resolve(url);
      expect(guard.sessionHeaders['cookie'], 'cf_clearance=token');
      guard.invalidate();
      expect(guard.sessionHeaders, isEmpty);
    });
  });
}
