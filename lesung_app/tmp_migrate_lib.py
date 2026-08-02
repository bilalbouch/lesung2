with open('lib/features/library/library_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remplacer imports
content = content.replace(
    "import '../../design_system/tokens/app_colors.dart';",
    "import '../../design_system/tokens/lumina_colors.dart';"
)
content = content.replace(
    "import '../../design_system/tokens/app_radius.dart';",
    "import '../../design_system/tokens/lumina_radius.dart';"
)

# 2. Remplacer AppColors par Theme
content = content.replace(
    'final colors = AppColors.of(context);',
    'final colors = Theme.of(context).colorScheme;'
)

# 3. Mapper couleurs
content = content.replace('colors.accent', 'colors.primary')
content = content.replace('colors.inkTertiary', 'colors.onSurfaceVariant')

# 4. Mapper radius
content = content.replace('AppRadius.card', 'BorderRadius.circular(LuminaRadius.l)')

# 5. Mapper spacing
content = content.replace('AppSpacing.screen', 'const EdgeInsets.all(20)')
content = content.replace('AppSpacing.hGapM', 'const SizedBox(width: 16)')
content = content.replace('AppSpacing.card', 'const EdgeInsets.all(16)')
content = content.replace('AppSpacing.gapXxl', 'const SizedBox(height: 48)')

# 6. Supprimer import app_spacing si plus utilise
if 'AppSpacing' not in content:
    content = content.replace("import '../../design_system/tokens/app_spacing.dart';\n", '')

with open('lib/features/library/library_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK - Library migre')
