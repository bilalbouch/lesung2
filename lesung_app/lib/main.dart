import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/engine.dart';
import 'app/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/cloud_sync_service.dart';
import 'design_system/lumina_theme.dart';
import 'design_system/tokens/lumina_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Symboles de date allemands (Verlauf, groupage par jour).
  initializeDateFormatting('de');
  runApp(const LesungBootstrap());
}

/// Démarrage : écran de marque pendant l'initialisation du moteur,
/// puis bascule douce vers l'application.
class LesungBootstrap extends StatefulWidget {
  const LesungBootstrap({super.key});

  @override
  State<LesungBootstrap> createState() => _LesungBootstrapState();
}

class _LesungBootstrapState extends State<LesungBootstrap> {
  Engine? _engine;

  @override
  void initState() {
    super.initState();
    Engine.create().then((engine) async {
      final sync = CloudSyncService();
      await sync.init();
      if (mounted) setState(() => _engine = engine);
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
}

class LesungApp extends StatelessWidget {
  const LesungApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lesung',
      debugShowCheckedModeBanner: false,
      theme: LuminaTheme.light,
      darkTheme: LuminaTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}

/// Écran de marque (splash) : logo, nom, point accentué — apparition
/// douce, aucune animation décorative.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final logoScale = Tween<double>(begin: 0.8, end: 1.0)
                .animate(CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
                ));
            final titleOpacity = Tween<double>(begin: 0.0, end: 1.0)
                .animate(CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
                ));
            final subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0)
                .animate(CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
                ));

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: logoScale.value,
                  child: const BrandLogo(size: 88),
                ),
                const SizedBox(height: 32),
                Opacity(
                  opacity: titleOpacity.value,
                  child: Text(
                    'Lesung',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
                const SizedBox(height: 12),
                Opacity(
                  opacity: subtitleOpacity.value,
                  child: Text(
                    'Deine Bibliothek.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Logo de marque — livre ouvert minimal, trait unique, accent sauge.
class BrandLogo extends StatelessWidget {
  final double size;

  const BrandLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BrandLogoPainter(LuminaColors.accent),
    );
  }
}

class _BrandLogoPainter extends CustomPainter {
  final Color accent;

  _BrandLogoPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    // Livre ouvert : deux pages courbes qui se rejoignent au centre.
    final left = Path()
      ..moveTo(w * 0.5, h * 0.22)
      ..cubicTo(w * 0.38, h * 0.12, w * 0.18, h * 0.12, w * 0.1, h * 0.2)
      ..lineTo(w * 0.1, h * 0.78)
      ..cubicTo(w * 0.18, h * 0.7, w * 0.38, h * 0.7, w * 0.5, h * 0.8)
      ..lineTo(w * 0.5, h * 0.22);
    final right = Path()
      ..moveTo(w * 0.5, h * 0.22)
      ..cubicTo(w * 0.62, h * 0.12, w * 0.82, h * 0.12, w * 0.9, h * 0.2)
      ..lineTo(w * 0.9, h * 0.78)
      ..cubicTo(w * 0.82, h * 0.7, w * 0.62, h * 0.7, w * 0.5, h * 0.8);
    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
  }

  @override
  bool shouldRepaint(_BrandLogoPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
