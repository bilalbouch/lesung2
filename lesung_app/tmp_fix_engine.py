with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remplacer tout _LesungBootstrapState
old_state = '''class _LesungBootstrapState extends State<LesungBootstrap> {
  Engine? _engine;

  @override
  void initState() {
    super.initState();
    Engine.create().then((engine) async {
      final sync = CloudSyncService();
      await sync.init();
      if (mounted) setState(() => _engine = engine);
    }).catchError((e) {
      if (mounted) setState(() => _engine = null);
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _engine == null) {
        setState(() => _engine = null);
      }
    });
  }

  @override
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
  }
}'''

new_state = '''Engine? _globalEngine;

class _LesungBootstrapState extends State<LesungBootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Engine.create().then((engine) {
      _globalEngine = engine;
      if (mounted) setState(() => _ready = true);
    }).catchError((e) {
      if (mounted) setState(() => _ready = true);
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LuminaTheme.light,
        home: const SplashScreen(),
      );
    }
    final engine = _globalEngine;
    if (engine == null) {
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
                const Text('Verifiez les permissions de stockage.', textAlign: TextAlign.center),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _ready = false);
                    _globalEngine = null;
                    Engine.create().then((engine) {
                      _globalEngine = engine;
                      if (mounted) setState(() => _ready = true);
                    }).catchError((e) {
                      if (mounted) setState(() => _ready = true);
                    });
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted) setState(() => _ready = true);
                    });
                  },
                  child: const Text('Reessayer'),
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
  }
}'''

content = content.replace(old_state, new_state)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK')
