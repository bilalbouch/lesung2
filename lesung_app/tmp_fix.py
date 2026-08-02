# --- LIRE LE FICHIER ---
with open('lib/features/reader/reader_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# --- 1. AJOUTER IMPORTS ---
imports_to_add = [
    "import '../../features/reader/reader_text_provider.dart';",
    "import 'reader_page_content.dart';",
]
for imp in imports_to_add:
    if imp not in content:
        lines = content.split('\n')
        last_imp = max(i for i, line in enumerate(lines) if line.strip().startswith('import '))
        lines.insert(last_imp + 1, imp)
        content = '\n'.join(lines)

# --- 2. AJOUTER LIGNE TTS DANS _loadUnitText ---
old_tts = "setState(() => _unitText = text ?? '');"
new_tts = old_tts + "\n      ref.read(readerTextProvider.notifier).state = text ?? '';"
content = content.replace(old_tts, new_tts)

# --- 3. REMPLACER LE RETURN DE _buildBody ---
old_body = '''    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.l + settings.marginHorizontal,
        vertical: AppSpacing.xl + settings.marginVertical,
      ),
      child: AppAnimations.fadeIn(
        key: ValueKey(_loadedUnit),
        child: SelectableText(
          text.isEmpty ? '—' : text,
          style: _readingTextStyle(settings),
          textAlign: _flutterAlign(settings.textAlign),
        ),
      ),
    );'''

new_body = '''    return ReaderPageContent(
      text: text,
      settings: settings,
      theme: _theme,
      loadedUnit: _loadedUnit ?? 0,
    );'''

assert old_body in content, 'Bloc _buildBody non trouve'
content = content.replace(old_body, new_body)

# --- 4. SUPPRIMER _readingTextStyle ---
old_m1 = '''  TextStyle _readingTextStyle(ReaderSettings settings) {
    final base = switch (settings.fontFamily) {
      'lora' => GoogleFonts.lora(),
      'inter' => GoogleFonts.inter(),
      'system_serif' => const TextStyle(fontFamily: 'serif'),
      'mono' => const TextStyle(fontFamily: 'monospace'),
      _ => const TextStyle(),
    };
    return base.copyWith(
      fontSize: settings.fontSize,
      height: settings.lineHeight,
      color: Color(_theme.textColor),
    );
  }

'''
content = content.replace(old_m1, '')

# --- 5. SUPPRIMER _flutterAlign ---
old_m2 = '''  TextAlign _flutterAlign(ReaderTextAlign align) => switch (align) {
    ReaderTextAlign.left => TextAlign.left,
    ReaderTextAlign.justify => TextAlign.justify,
    ReaderTextAlign.right => TextAlign.right,
  };

'''
content = content.replace(old_m2, '')

# --- 6. SUPPRIMER IMPORTS INUTILES ---
content = content.replace("import 'package:google_fonts/google_fonts.dart';\n", '')
content = content.replace("import '../../components/app_animations.dart';\n", '')

with open('lib/features/reader/reader_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK - TTS + Paysage integres')
