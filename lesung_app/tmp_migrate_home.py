with open('lib/features/home/home_screen.dart', 'r', encoding='utf-8') as f:
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
content = content.replace('colors.ink', 'colors.onSurface')

# 4. Mapper spacing
content = content.replace('AppSpacing.screen', 'const EdgeInsets.all(20)')
content = content.replace('AppSpacing.gapXl', 'const SizedBox(height: 32)')
content = content.replace('AppSpacing.gapXs', 'const SizedBox(height: 8)')
content = content.replace('AppSpacing.gapXxl', 'const SizedBox(height: 48)')

# 5. Supprimer import app_spacing
content = content.replace("import '../../design_system/tokens/app_spacing.dart';\n", '')

with open('lib/features/home/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK - Home migre')
