with open('lib/features/history/history_screen.dart', 'r', encoding='utf-8') as f:
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
content = content.replace('colors.inkTertiary', 'colors.onSurfaceVariant')

# 4. Mapper radius
content = content.replace('AppRadius.cardSmall', 'BorderRadius.circular(LuminaRadius.m)')

# 5. Mapper spacing
content = content.replace(
    'AppSpacing.screen.copyWith(top: AppSpacing.l)',
    'const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 16)'
)
content = content.replace(
    'const EdgeInsets.only(bottom: AppSpacing.m)',
    'const EdgeInsets.only(bottom: 16)'
)
content = content.replace('AppSpacing.hGapM', 'const SizedBox(width: 16)')
content = content.replace('AppSpacing.gapM', 'const SizedBox(height: 16)')
content = content.replace('AppSpacing.gapXl', 'const SizedBox(height: 32)')

# 6. Supprimer import app_spacing si plus utilise
if 'AppSpacing' not in content:
    content = content.replace("import '../../design_system/tokens/app_spacing.dart';\n", '')

with open('lib/features/history/history_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK - History migre')
