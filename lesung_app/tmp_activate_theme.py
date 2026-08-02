with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Ajouter import LuminaTheme
import_line = "import 'design_system/lumina_theme.dart';"
if import_line not in content:
    lines = content.split('\n')
    last_imp = max(i for i, line in enumerate(lines) if line.strip().startswith('import '))
    lines.insert(last_imp + 1, import_line)
    content = '\n'.join(lines)

# 2. Remplacer AppTheme par LuminaTheme dans LesungApp
content = content.replace('theme: AppTheme.light(),', 'theme: LuminaTheme.light,')
content = content.replace('darkTheme: AppTheme.dark(),', 'darkTheme: LuminaTheme.dark,')
content = content.replace('theme: AppTheme.light(),', 'theme: LuminaTheme.light,')

# 3. Remplacer aussi dans SplashScreen
content = content.replace('theme: AppTheme.light(),', 'theme: LuminaTheme.light,')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK - LuminaTheme active')
