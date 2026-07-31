import 'dart:async';

/// Résultat d'une résolution de challenge par un solver externe.
class CloudflareSession {
  /// Cookies obtenus (cf_clearance...), prêts pour l'en-tête Cookie.
  final String cookieHeader;

  /// User-Agent associé à la session (doit rester cohérent avec les
  /// cookies pour que le bypass tienne).
  final String userAgent;

  final DateTime obtainedAt;

  const CloudflareSession({
    required this.cookieHeader,
    required this.userAgent,
    required this.obtainedAt,
  });

  /// Une clearance Cloudflare vit environ 15-30 min ; on reste prudemment
  /// sous les 15 minutes.
  bool get isFresh =>
      DateTime.now().difference(obtainedAt) < const Duration(minutes: 12);
}

/// Contrat du résolveur de challenge — IMPLÉMENTÉ PAR L'APPLICATION
/// (WebView interactive via flutter_inappwebview, plugin natif...).
///
/// Le provider ne connaît QUE cette interface : il ne verra jamais
/// la WebView.
abstract class CloudflareSolver {
  /// Ouvre le flux de résolution pour [pageUrl] et retourne une session
  /// (cookies + UA) si l'utilisateur/le moteur passe le challenge.
  /// Null si la résolution a échoué ou été abandonnée.
  Future<CloudflareSession?> solve(Uri pageUrl);
}

/// CloudflareGuard — service indépendant de gestion des challenges.
///
/// Responsabilités :
/// 1. détecter automatiquement un challenge (signal remonté par le client)
/// 2. tenter d'abord le bypass « normal » : session en cache encore fraîche
/// 3. sinon déléguer au solver (WebView) — uniquement si nécessaire
/// 4. fournir les en-têtes de session au client de transport
///
/// La bascule sur une autre instance reste la responsabilité du client :
/// le guard n'est sollicité que quand le client épuise ses miroirs.
class CloudflareGuard {
  final CloudflareSolver? _solver;
  CloudflareSession? _session;

  /// Une seule résolution interactive à la fois.
  Future<CloudflareSession?>? _ongoing;

  CloudflareGuard({CloudflareSolver? solver}) : _solver = solver;

  /// True si une session utilisable existe (bypass sans WebView).
  bool get hasFreshSession => _session?.isFresh ?? false;

  /// En-têtes à injecter dans les requêtes si une session fraîche existe.
  Map<String, String> get sessionHeaders {
    final s = _session;
    if (s == null || !s.isFresh) return {};
    return {'cookie': s.cookieHeader, 'user-agent': s.userAgent};
  }

  /// Résout un challenge pour [pageUrl].
  ///
  /// Stratégie : session fraîche en cache -> bypass immédiat ; sinon
  /// appel du solver (WebView) une seule fois, résultat mis en cache.
  /// Retourne null si aucune résolution n'est possible.
  Future<CloudflareSession?> resolve(Uri pageUrl) async {
    // 1. Bypass « normal » : clearance encore valide.
    final cached = _session;
    if (cached != null && cached.isFresh) return cached;

    // 2. Pas de solver disponible : impossible de faire mieux.
    final solver = _solver;
    if (solver == null) return null;

    // 3. Une seule résolution interactive en vol à la fois.
    final ongoing = _ongoing;
    if (ongoing != null) return ongoing;

    final future = solver.solve(pageUrl);
    _ongoing = future;
    try {
      final result = await future;
      if (result != null) _session = result;
      return result;
    } finally {
      _ongoing = null;
    }
  }

  /// Invalide la session (cookies expirés côté serveur, 403 récurrent...).
  void invalidate() => _session = null;
}
