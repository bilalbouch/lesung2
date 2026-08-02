with open('lib/components/app_states.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Supprimer imports anciens
content = content.replace("import '../design_system/tokens/app_spacing.dart';\n", '')
content = content.replace("import '../design_system/tokens/app_typography.dart';\n", '')

# 2. Mapper les valeurs
content = content.replace('AppSpacing.xxl', '48')
content = content.replace('AppTypography.heightReading', '1.6')

# 3. Remplacer AppAnimations.fadeIn par une animation stagger custom
old_build = '''  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: AppAnimations.fadeIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.primary, size: 30),
              ),
              const SizedBox(height: 32),
              Text(title,
                  style: textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                message,
                style: textTheme.bodyMedium
                    ?.copyWith(height: AppTypography.heightReading),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 32),
                ActionButton(
                    label: actionLabel!,
                    variant: ActionButtonVariant.secondary,
                    onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }'''

new_build = '''  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedItem(
              delay: const Duration(milliseconds: 0),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.primary, size: 30),
              ),
            ),
            const SizedBox(height: 32),
            _AnimatedItem(
              delay: const Duration(milliseconds: 100),
              child: Text(title,
                  style: textTheme.titleLarge, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            _AnimatedItem(
              delay: const Duration(milliseconds: 200),
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              _AnimatedItem(
                delay: const Duration(milliseconds: 300),
                child: ActionButton(
                    label: actionLabel!,
                    variant: ActionButtonVariant.secondary,
                    onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }'''

content = content.replace(old_build, new_build)

# 4. Ajouter la classe _AnimatedItem à la fin du fichier
animated_item = '''

/// Widget interne pour animer les items de l'empty state avec stagger.
class _AnimatedItem extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedItem({required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        final isReady = snapshot.connectionState == ConnectionState.done;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: isReady ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 16),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}
'''

content = content.rstrip() + animated_item

with open('lib/components/app_states.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK - Empty states avec animation stagger')
