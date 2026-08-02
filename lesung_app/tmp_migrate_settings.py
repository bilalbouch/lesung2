with open('lib/features/settings/settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remplacer imports anciens tokens
content = content.replace(
    "import '../../design_system/tokens/app_colors.dart';",
    "import '../../design_system/tokens/lumina_colors.dart';"
)
content = content.replace(
    "import '../../design_system/tokens/app_radius.dart';",
    "import '../../design_system/tokens/lumina_radius.dart';"
)

# 2. Remplacer AppColors par Theme colorScheme
content = content.replace(
    'final colors = AppColors.of(context);',
    'final colors = Theme.of(context).colorScheme;'
)

# 3. Mapper les proprietes de couleurs
content = content.replace('colors.surfaceAlt', 'colors.surfaceContainerHighest')
content = content.replace('colors.accentSubtle', 'colors.secondaryContainer')
content = content.replace('colors.accent', 'colors.primary')
content = content.replace('colors.inkTertiary', 'colors.onSurfaceVariant')
content = content.replace('colors.divider', 'colors.outlineVariant')

# 4. Mapper les radius
content = content.replace('AppRadius.card', 'BorderRadius.circular(LuminaRadius.l)')
content = content.replace('AppRadius.cardSmall', 'BorderRadius.circular(LuminaRadius.m)')

with open('lib/features/settings/settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK - Settings migre vers Lumina')
