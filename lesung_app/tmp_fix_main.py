with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Ajouter les imports si manquants
if "import 'design_system/tokens/lumina_colors.dart';" not in content:
    lines = content.split('\n')
    last_imp = max(i for i, line in enumerate(lines) if line.strip().startswith('import '))
    lines.insert(last_imp + 1, "import 'design_system/tokens/lumina_colors.dart';")
    content = '\n'.join(lines)

# Mapper AppColors
content = content.replace('AppColors.of(context)', 'Theme.of(context).colorScheme')

# Mapper AppSpacing
content = content.replace('AppSpacing.screen', 'const EdgeInsets.all(20)')
content = content.replace('AppSpacing.xl', '32')
content = content.replace('AppSpacing.l', '24')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK')
