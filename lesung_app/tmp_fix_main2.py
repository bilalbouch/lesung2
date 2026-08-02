with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Fix background déprécié
content = content.replace('backgroundColor: colors.background,', 'backgroundColor: colors.surface,')

# 2. Fix AppSpacing.gapXl
content = content.replace('AppSpacing.gapXl,', 'const SizedBox(height: 32),')

# 3. Fix AppSpacing.gapS
content = content.replace('AppSpacing.gapS,', 'const SizedBox(height: 12),')

# 4. Fix colors.accent dans _BrandLogoPainter
content = content.replace('colors.accent', 'LuminaColors.accent')

# 5. Ajouter import LuminaColors si manquant
if "import 'design_system/tokens/lumina_colors.dart';" not in content:
    lines = content.split('\n')
    last_imp = max(i for i, line in enumerate(lines) if line.strip().startswith('import '))
    lines.insert(last_imp + 1, "import 'design_system/tokens/lumina_colors.dart';")
    content = '\n'.join(lines)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK')
