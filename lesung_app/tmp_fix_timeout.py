with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Ajouter _timedOut au state
old_state = '''class _LesungBootstrapState extends State<LesungBootstrap> {
  Engine? _engine;'''

new_state = '''class _LesungBootstrapState extends State<LesungBootstrap> {
  Engine? _engine;
  bool _timedOut = false;'''

content = content.replace(old_state, new_state)

# 2. Modifier le timeout pour mettre _timedOut à true
old_timeout = '''    // Timeout de secours — afficher l'app après 5s même si l'engine bloque
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _engine == null) {
        setState(() => _engine = null);
      }
    });'''

new_timeout = '''    // Timeout de secours — afficher l'app après 5s même si l'engine bloque
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _engine == null) {
        setState(() => _timedOut = true);
      }
    });'''

content = content.replace(old_timeout, new_timeout)

# 3. Modifier le build pour gérer le timeout
old_build = '''  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    if (engine == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LuminaTheme.light,
        home: const SplashScreen(),
      );
    }
    return ProviderScope(
      overrides: [engineProvider.overrideWithValue(engine)],
      child: const LesungApp(),
    );
  }'''

new_build = '''  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    if (engine == null && !_timedOut) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LuminaTheme.light,
        home: const SplashScreen(),
      );
    }
    if (engine == null && _timedOut) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LuminaTheme.light,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                const SizedBox(height: 24),
                const Text('Initialisation impossible', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('L\'application ne peut pas démarrer.\nVérifiez les permissions de stockage.', textAlign: TextAlign.center),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _timedOut = false);
                    Engine.create().then((engine) async {
                      final sync = CloudSyncService();
                      await sync.init();
                      if (mounted) setState(() => _engine = engine);
                    }).catchError((e) {
                      if (mounted) setState(() => _timedOut = true);
                    });
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ProviderScope(
      overrides: [engineProvider.overrideWithValue(engine)],
      child: const LesungApp(),
    );
  }'''

content = content.replace(old_build, new_build)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK')
