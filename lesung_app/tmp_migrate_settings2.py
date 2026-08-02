with open('lib/features/settings/settings_screen.dart', 'r', encoding='utf-8') as f:
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

# 3. Mapper couleurs (ordre important : plus specifique d'abord)
content = content.replace('colors.accentSubtle', 'colors.secondaryContainer')
content = content.replace('colors.accent', 'colors.primary')
content = content.replace('colors.surfaceAlt', 'colors.surfaceContainerHighest')
content = content.replace('colors.inkTertiary', 'colors.onSurfaceVariant')
content = content.replace('colors.divider', 'colors.outlineVariant')

# 4. Mapper radius (cardSmall D'ABORD, puis card)
content = content.replace('AppRadius.cardSmall', 'BorderRadius.circular(LuminaRadius.m)')
content = content.replace('AppRadius.card', 'BorderRadius.circular(LuminaRadius.l)')

with open('lib/features/settings/settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK')
