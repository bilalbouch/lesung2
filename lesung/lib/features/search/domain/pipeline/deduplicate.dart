import '../entities/book.dart';

/// ÉTAPE 3 DU PIPELINE — DÉDUPLICATION.
///
/// Fusionne les livres identiques retournés par plusieurs sources
/// (ou par la même source). Stratégie à trois niveaux, par priorité :
/// 1. clé forte : ISBN identique
/// 2. clé forte : MD5 identique (même fichier exact, détecté via un
///    identifiant de référence hexadécimal de 32 caractères — format
///    utilisé par les sources indexées par MD5, sans que le moteur ne
///    connaisse aucune source en particulier)
/// 3. clé floue : titre normalisé + auteur normalisé identiques
///
/// Le doublon absorbé transmet ses références ([Book.refs]) au livre
/// conservé ; les métadonnées manquantes sont complétées quand le
/// doublon est plus riche. Fonction pure.
List<Book> deduplicateBooks(List<Book> books) {
  final kept = <Book>[];
  final indexByIsbn = <String, int>{};
  final indexByMd5 = <String, int>{};
  final indexByFuzzyKey = <String, int>{};

  for (final candidate in books) {
    if (candidate.normalizedTitle.isEmpty) continue;

    final isbnKey = _cleanIsbn(candidate.isbn);
    final md5Key = _md5Key(candidate);
    final fuzzyKey = candidate.dedupKey;

    int? existingIndex;
    if (isbnKey != null && indexByIsbn.containsKey(isbnKey)) {
      existingIndex = indexByIsbn[isbnKey];
    } else if (md5Key != null && indexByMd5.containsKey(md5Key)) {
      existingIndex = indexByMd5[md5Key];
    } else if (indexByFuzzyKey.containsKey(fuzzyKey)) {
      existingIndex = indexByFuzzyKey[fuzzyKey];
    }

    if (existingIndex == null) {
      final newIndex = kept.length;
      kept.add(candidate);
      if (isbnKey != null) indexByIsbn[isbnKey] = newIndex;
      if (md5Key != null) indexByMd5[md5Key] = newIndex;
      indexByFuzzyKey[fuzzyKey] = newIndex;
    } else {
      final merged = mergeBooks(kept[existingIndex], candidate);
      kept[existingIndex] = merged;
      // Le livre fusionné peut avoir gagné un ISBN ou un MD5 :
      // on ré-indexe ses clés fortes.
      final mergedIsbn = _cleanIsbn(merged.isbn);
      if (mergedIsbn != null) indexByIsbn[mergedIsbn] = existingIndex;
      final mergedMd5 = _md5Key(merged);
      if (mergedMd5 != null) indexByMd5[mergedMd5] = existingIndex;
    }
  }
  return kept;
}

/// Fusionne deux livres identifiés comme doublons.
///
/// [base] est conservé comme référence ; [duplicate] complète les
/// champs manquants et ajoute ses références de source.
Book mergeBooks(Book base, Book duplicate) {
  final mergedRefs = <SourceBookRef>{...base.refs, ...duplicate.refs}.toList();

  String? pick(String? a, String? b) =>
      (a == null || a.isEmpty) ? (b == null || b.isEmpty ? null : b) : a;

  return base.copyWith(
    author: pick(base.author, duplicate.author),
    publisher: pick(base.publisher, duplicate.publisher),
    coverUrl: pick(base.coverUrl, duplicate.coverUrl),
    description: pick(base.description, duplicate.description),
    language: base.language ?? duplicate.language,
    isbn: pick(base.isbn, duplicate.isbn),
    fileSizeBytes: base.fileSizeBytes ?? duplicate.fileSizeBytes,
    year: base.year ?? duplicate.year,
    format: base.format.index > 0 || duplicate.format.index == 0
        ? base.format
        : duplicate.format,
    refs: mergedRefs,
  );
}

/// MD5 du livre, détecté via une référence dont l'identifiant est un
/// hexadécimal de 32 caractères (convention des sources indexées par
/// MD5). Null si aucune référence n'est un MD5.
String? _md5Key(Book book) {
  for (final ref in book.refs) {
    final id = ref.sourceBookId.trim().toLowerCase();
    if (RegExp(r'^[a-f0-9]{32}$').hasMatch(id)) return id;
  }
  return null;
}

/// Nettoie un ISBN (retire tirets/espaces). Null si absent.
String? _cleanIsbn(String? isbn) {
  if (isbn == null) return null;
  final cleaned = isbn.replaceAll(RegExp(r'[- ]'), '').toUpperCase();
  return cleaned.isEmpty ? null : cleaned;
}
