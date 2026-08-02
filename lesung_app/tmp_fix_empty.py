with open('lib/components/app_states.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remplacer le build de AppEmptyState
old_build = '''  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
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
                    ?.copyWith(height: 1.6),
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

with open('lib/components/app_states.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK')
