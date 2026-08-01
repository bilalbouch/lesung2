import '../entities/book.dart';

/// ÉTAPE 2 DU PIPELINE — NORMALISATION.
///
/// Transforme les livres bruts des sources en entités comparables :
/// - titre/auteur normalisés (minuscules, sans accents, sans ponctuation)
/// - langue ramenée à l'ISO 639-1
/// - champs textuels nettoyés (espaces multiples, trim)
///
/// Fonction pure : aucune entrée n'est mutée.
List<Book> normalizeBooks(List<Book> rawBooks) {
  return rawBooks.map(normalizeBook).toList();
}

/// Normalise un livre individuel.
Book normalizeBook(Book book) {
  return book.copyWith(
    title: cleanWhitespace(book.title),
    author: book.author == null ? null : cleanWhitespace(book.author!),
    publisher:
        book.publisher == null ? null : cleanWhitespace(book.publisher!),
    language: normalizeLanguageCode(book.language),
    normalizedTitle: normalizeText(book.title),
    normalizedAuthor: normalizeText(book.author ?? ''),
  );
}

/// Minuscules + suppression des diacritiques + ponctuation -> espace
/// + espaces compacts. Sert de base à la déduplication et au scoring.
String normalizeText(String input) {
  var s = input.toLowerCase();
  s = _stripDiacritics(s);
  s = s.replaceAll(RegExp(r"[^\p{L}\p{N} ]", unicode: true), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

/// Ramène une langue quelconque ('german', 'deutsch', 'DE ', 'fr-FR'...)
/// à son code ISO 639-1. Null si indéterminable.
String? normalizeLanguageCode(String? raw) {
  if (raw == null) return null;
  var s = raw.trim().toLowerCase();
  if (s.isEmpty) return null;
  // 'fr-FR' -> 'fr', 'de_DE' -> 'de'
  s = s.split(RegExp(r'[-_]')).first;
  if (RegExp(r'^[a-z]{2}$').hasMatch(s)) return s;
  const byName = {
    'german': 'de', 'deutsch': 'de', 'allemand': 'de',
    'french': 'fr', 'francais': 'fr', 'franzosisch': 'fr',
    'english': 'en', 'englisch': 'en', 'anglais': 'en',
    'spanish': 'es', 'spanisch': 'es', 'espagnol': 'es',
    'italian': 'it', 'italienisch': 'it', 'italien': 'it',
    'portuguese': 'pt', 'russian': 'ru', 'chinese': 'zh',
    'japanese': 'ja', 'dutch': 'nl', 'polish': 'pl',
    'turkish': 'tr', 'arabic': 'ar', 'hindi': 'hi',
    'swedish': 'sv', 'korean': 'ko', 'czech': 'cs', 'greek': 'el',
    'romanian': 'ro', 'hungarian': 'hu', 'ukrainian': 'uk',
    'hebrew': 'he', 'thai': 'th', 'persian': 'fa', 'bengali': 'bn',
    'finnish': 'fi', 'norwegian': 'no', 'danish': 'da',
    'vietnamese': 'vi', 'indonesian': 'id', 'malayalam': 'ml',
  };
  return byName[s];
}

/// Supprime les diacritiques via décomposition Unicode NFD.
String _stripDiacritics(String input) {
  const map = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae',
    'ç': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ñ': 'n',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'œ': 'oe',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ý': 'y', 'ÿ': 'y',
    'ß': 'ss',
  };
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(map[ch] ?? ch);
  }
  return buffer.toString();
}

/// Compacte les espaces multiples et trime.
String cleanWhitespace(String input) =>
    input.replaceAll(RegExp(r'\s+'), ' ').trim();
