import re

# 1. action_button.dart — supprimer const avant BoxDecoration dans Container
with open('lib/components/action_button.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'const BoxDecoration(' in line:
        lines[i] = line.replace('const BoxDecoration(', 'BoxDecoration(')
    if 'const EdgeInsets.symmetric(' in line:
        lines[i] = line.replace('const EdgeInsets.symmetric(', 'EdgeInsets.symmetric(')

with open('lib/components/action_button.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)
print('OK action_button')

# 2. app_progress_indicator.dart — remettre BorderRadius.circular
with open('lib/components/app_progress_indicator.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('borderRadius: LuminaRadius.s', 'borderRadius: BorderRadius.circular(LuminaRadius.s)')

with open('lib/components/app_progress_indicator.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('OK app_progress_indicator')

# 3. app_search_bar.dart — supprimer const
with open('lib/components/app_search_bar.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'const BoxDecoration(' in line:
        lines[i] = line.replace('const BoxDecoration(', 'BoxDecoration(')
    if 'const EdgeInsets.symmetric(' in line:
        lines[i] = line.replace('const EdgeInsets.symmetric(', 'EdgeInsets.symmetric(')

with open('lib/components/app_search_bar.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)
print('OK app_search_bar')

# 4. book_cover.dart
with open('lib/components/book_cover.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('AppRadius.', 'LuminaRadius.')
content = content.replace('AppColorScheme', 'ColorScheme')

with open('lib/components/book_cover.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('OK book_cover')

print('Tous fixes appliques')
