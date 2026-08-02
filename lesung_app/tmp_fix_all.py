import os

# 1. Fix action_button.dart
with open('lib/components/action_button.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('colors.onAccent', 'colors.onPrimary')
content = content.replace('colors.primarySubtle', 'colors.primaryContainer')
content = content.replace('const BoxDecoration(', 'BoxDecoration(')
content = content.replace('const EdgeInsets.symmetric(', 'EdgeInsets.symmetric(')
with open('lib/components/action_button.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('OK action_button')

# 2. Fix app_progress_indicator.dart
with open('lib/components/app_progress_indicator.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('BorderRadius.circular(LuminaRadius.s)', 'LuminaRadius.s')
with open('lib/components/app_progress_indicator.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('OK app_progress_indicator')

# 3. Fix app_search_bar.dart — restaurer et refaire proprement
with open('lib/components/app_search_bar.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('BorderRadius.circular(LuminaRadius.l)Small', 'BorderRadius.circular(LuminaRadius.m)')
content = content.replace('const BoxDecoration(', 'BoxDecoration(')
content = content.replace('const EdgeInsets.symmetric(', 'EdgeInsets.symmetric(')
with open('lib/components/app_search_bar.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('OK app_search_bar')

# 4. Fix book_cover.dart
with open('lib/components/book_cover.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('AppRadius.cardSmall', 'BorderRadius.circular(LuminaRadius.m)')
content = content.replace('AppColorScheme', 'ColorScheme')
content = content.replace('colors.primarySubtle', 'colors.primaryContainer')
with open('lib/components/book_cover.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('OK book_cover')

print('Tous les fixes appliques')
