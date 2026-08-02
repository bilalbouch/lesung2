import os

files = [
    'lib/components/action_button.dart',
    'lib/components/app_bottom_sheet.dart',
    'lib/components/app_dialogs.dart',
    'lib/components/app_progress_indicator.dart',
    'lib/components/app_search_bar.dart',
    'lib/components/app_states.dart',
    'lib/components/book_card.dart',
    'lib/components/book_cover.dart',
]

for filepath in files:
    if not os.path.exists(filepath):
        print(f'SKIP: {filepath}')
        continue
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remplacer imports
    content = content.replace(
        "import '../design_system/tokens/app_colors.dart';",
        "import '../design_system/tokens/lumina_colors.dart';"
    )
    content = content.replace(
        "import '../design_system/tokens/app_radius.dart';",
        "import '../design_system/tokens/lumina_radius.dart';"
    )
    
    # Remplacer AppColors par Theme
    content = content.replace(
        'final colors = AppColors.of(context);',
        'final colors = Theme.of(context).colorScheme;'
    )
    
    # Mapper couleurs
    content = content.replace('colors.surface', 'colors.surface')
    content = content.replace('colors.surfaceAlt', 'colors.surfaceContainerHighest')
    content = content.replace('colors.background', 'colors.surface')
    content = content.replace('colors.accent', 'colors.primary')
    content = content.replace('colors.accentSubtle', 'colors.primaryContainer')
    content = content.replace('colors.inkPrimary', 'colors.onSurface')
    content = content.replace('colors.inkSecondary', 'colors.onSurfaceVariant')
    content = content.replace('colors.inkTertiary', 'colors.onSurfaceVariant')
    content = content.replace('colors.ink', 'colors.onSurface')
    content = content.replace('colors.divider', 'colors.outlineVariant')
    
    # Mapper radius
    content = content.replace('AppRadius.sheet', 'BorderRadius.vertical(top: Radius.circular(LuminaRadius.xl))')
    content = content.replace('AppRadius.card', 'BorderRadius.circular(LuminaRadius.l)')
    content = content.replace('AppRadius.cardSmall', 'BorderRadius.circular(LuminaRadius.m)')
    content = content.replace('AppRadius.button', 'BorderRadius.circular(LuminaRadius.s)')
    content = content.replace('AppRadius.full', 'BorderRadius.circular(LuminaRadius.full)')
    
    # Mapper spacing
    content = content.replace('AppSpacing.screen', 'const EdgeInsets.all(20)')
    content = content.replace('AppSpacing.card', 'const EdgeInsets.all(16)')
    content = content.replace('AppSpacing.sheet', 'const EdgeInsets.all(24)')
    content = content.replace('AppSpacing.gapXxl', 'const SizedBox(height: 48)')
    content = content.replace('AppSpacing.gapXl', 'const SizedBox(height: 32)')
    content = content.replace('AppSpacing.gapL', 'const SizedBox(height: 24)')
    content = content.replace('AppSpacing.gapM', 'const SizedBox(height: 16)')
    content = content.replace('AppSpacing.gapS', 'const SizedBox(height: 12)')
    content = content.replace('AppSpacing.gapXs', 'const SizedBox(height: 8)')
    content = content.replace('AppSpacing.hGapM', 'const SizedBox(width: 16)')
    content = content.replace('AppSpacing.hGapS', 'const SizedBox(width: 8)')
    content = content.replace('AppSpacing.listItem', 'const EdgeInsets.symmetric(horizontal: 20, vertical: 8)')
    
    # Supprimer imports app_spacing si plus utilise
    if 'AppSpacing' not in content:
        content = content.replace("import '../design_system/tokens/app_spacing.dart';\n", '')
    
    # Supprimer imports lumina inutiles
    if 'LuminaColors' not in content and 'lumina_colors' in content:
        content = content.replace("import '../design_system/tokens/lumina_colors.dart';\n", '')
    if 'LuminaRadius' not in content and 'lumina_radius' in content:
        content = content.replace("import '../design_system/tokens/lumina_radius.dart';\n", '')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f'OK: {filepath}')

print('Migration terminee')
