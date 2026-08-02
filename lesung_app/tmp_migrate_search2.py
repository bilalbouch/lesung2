with open('lib/features/search/search_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remplacer imports
content = content.replace(
    "import '../../design_system/tokens/app_colors.dart';",
    "import '../../design_system/tokens/lumina_colors.dart';"
)

# Remplacer AppColors par Theme
content = content.replace(
    'final colors = AppColors.of(context);',
    'final colors = Theme.of(context).colorScheme;'
)

# Mapper couleurs
content = content.replace('colors.inkTertiary', 'colors.onSurfaceVariant')
content = content.replace('colors.surfaceAlt', 'colors.surfaceContainerHighest')

# Mapper spacing (ORDRE IMPORTANT : plus specifique d'abord)
content = content.replace('AppSpacing.listItem', 'const EdgeInsets.symmetric(horizontal: 20, vertical: 8)')
content = content.replace('AppSpacing.screen', 'const EdgeInsets.symmetric(horizontal: 20)')
content = content.replace('AppSpacing.xxxl', '128')
content = content.replace('AppSpacing.xxl', '96')
content = content.replace('AppSpacing.xl', '32')
content = content.replace('AppSpacing.l', '24')
content = content.replace('AppSpacing.m', '16')
content = content.replace('AppSpacing.s', '12')
content = content.replace('AppSpacing.xs', '4')
content = content.replace('AppSpacing.xxs', '2')
content = content.replace('AppSpacing.hGapS', 'const SizedBox(width: 8)')
content = content.replace('AppSpacing.gapL', 'const SizedBox(height: 24)')
content = content.replace('AppSpacing.gapM', 'const SizedBox(height: 16)')
content = content.replace('AppSpacing.gapS', 'const SizedBox(height: 12)')

# Supprimer import app_spacing
content = content.replace("import '../../design_system/tokens/app_spacing.dart';\n", '')

with open('lib/features/search/search_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK - Search migre v2')
