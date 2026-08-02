with open('lib/features/book_details/book_details_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remplacer imports
content = content.replace(
    "import '../../design_system/tokens/app_colors.dart';",
    "import '../../design_system/tokens/lumina_colors.dart';"
)

# 2. Remplacer AppColors par Theme
content = content.replace(
    'final colors = AppColors.of(context);',
    'final colors = Theme.of(context).colorScheme;'
)

# 3. Mapper couleurs
content = content.replace('colors.inkSecondary', 'colors.onSurfaceVariant')
content = content.replace('colors.surfaceAlt', 'colors.surfaceContainerHighest')

# 4. Mapper spacing (dans EdgeInsets et widgets)
content = content.replace('AppSpacing.screen', 'const EdgeInsets.all(20)')
content = content.replace('AppSpacing.gapXxl', 'const SizedBox(height: 48)')
content = content.replace('AppSpacing.gapXl', 'const SizedBox(height: 32)')
content = content.replace('AppSpacing.gapM', 'const SizedBox(height: 16)')
content = content.replace('AppSpacing.gapS', 'const SizedBox(height: 12)')

# 5. Mapper spacing dans EdgeInsets (horizontal/vertical)
content = content.replace('horizontal: AppSpacing.m', 'horizontal: 16')
content = content.replace('vertical: AppSpacing.xs', 'vertical: 4')

# 6. Supprimer import app_spacing
content = content.replace("import '../../design_system/tokens/app_spacing.dart';\n", '')

with open('lib/features/book_details/book_details_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK - Book Details migre')
