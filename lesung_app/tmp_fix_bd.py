with open('lib/features/book_details/book_details_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('spacing: AppSpacing.s', 'spacing: 12')
content = content.replace('runSpacing: AppSpacing.s', 'runSpacing: 12')

with open('lib/features/book_details/book_details_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK')
