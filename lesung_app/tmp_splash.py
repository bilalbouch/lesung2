with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remplacer le SplashScreen par une version plus animée
old_splash = '''class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppDurations.normal,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(size: 88),
              const SizedBox(height: 32),
              Text(
                'Lesung',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Deine Bibliothek.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}'''

new_splash = '''class SplashScreen extends StatefulWidget {
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
}'''

content = content.replace(old_splash, new_splash)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK - SplashScreen ameliore')
