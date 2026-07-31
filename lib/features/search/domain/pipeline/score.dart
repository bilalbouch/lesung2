import '../entities/book.dart';
import '../entities/search_query.dart';
import '../entities/search_result.dart';

/// Pondérations du système de score (total 100).
///
/// Toutes les valeurs vivent ici et ici seulement : ajuster le
/// classement ne demande aucune modification du pipeline.
/// Priorité charte : allemand > français > autres langues.
class ScoringConfig {
  /// Langue : DE = [languageGerman], FR = [languageFrench], autre = [languageOther].
  final double languageGerman;
  final double languageFrench;
  final double languageOther;
  final double languageUnknown;

  /// Pertinence textuelle (match titre/auteur/description).
  final double relevanceMax;

  /// Format préféré disponible (EPUB = plein, PDF = 2/3).
  final double formatMax;

  /// Complétude des métadonnées (couverture, année, éditeur, taille).
  final double metadataMax;

  /// Fiabilité de la source (santé mesurée).
  final double sourceHealthMax;

  /// Fraîcheur de l'édition.
  final double recencyMax;

  /// Année considérée comme « récente » pour le plein score.
  final int recentYearThreshold;

  const ScoringConfig({
    this.languageGerman = 35,
    this.languageFrench = 30,
    this.languageOther = 10,
    this.languageUnknown = 5,
    this.relevanceMax = 25,
    this.formatMax = 15,
    this.metadataMax = 10,
    this.sourceHealthMax = 10,
    this.recencyMax = 5,
    this.recentYearThreshold = 2020,
  });

  double get maxTotal =>
      languageGerman +
      relevanceMax +
      formatMax +
      metadataMax +
      sourceHealthMax +
      recencyMax;
}

/// ÉTAPE 4 DU PIPELINE — SCORING.
///
/// Attribue à chaque livre un score 0..100 et trie par score décroissant.
/// [sourceHealth] : fiabilité 0..1 par sourceId (mesurée par healthCheck ;
/// 1.0 par défaut si inconnue). Fonction pure.
List<SearchResultItem> scoreAndSortBooks(
  List<Book> books,
  SearchQuery query, {
  ScoringConfig config = const ScoringConfig(),
  Map<String, double> sourceHealth = const {},
}) {
  final scored = books
      .map((book) => _scoreBook(book, query, config, sourceHealth))
      .toList();
  scored.sort((a, b) {
    final cmp = b.score.compareTo(a.score);
    if (cmp != 0) return cmp;
    // Ex-aequo : ordre alphabétique stable.
    return a.book.normalizedTitle.compareTo(b.book.normalizedTitle);
  });
  return scored;
}

SearchResultItem _scoreBook(
  Book book,
  SearchQuery query,
  ScoringConfig config,
  Map<String, double> sourceHealth,
) {
  final breakdown = <String, double>{
    'language': _languageScore(book, config),
    'relevance': _relevanceScore(book, query, config),
    'format': _formatScore(book, config),
    'metadata': _metadataScore(book, config),
    'sourceHealth': _sourceHealthScore(book, config, sourceHealth),
    'recency': _recencyScore(book, config),
  };
  final total =
      breakdown.values.fold<double>(0, (sum, v) => sum + v).clamp(0, 100);
  return SearchResultItem(
    book: book,
    score: total.toDouble(),
    scoreBreakdown: breakdown,
  );
}

/// Priorité absolue : allemand > français > autres.
double _languageScore(Book book, ScoringConfig config) {
  switch (book.language) {
    case 'de':
      return config.languageGerman;
    case 'fr':
      return config.languageFrench;
    case null:
      return config.languageUnknown;
    default:
      return config.languageOther;
  }
}

/// Pertinence : match exact du titre > titre contient la requête >
/// auteur > description. Sur le texte NORMALISÉ des deux côtés.
double _relevanceScore(Book book, SearchQuery query, ScoringConfig config) {
  final q = query.text.trim().toLowerCase();
  if (q.isEmpty) return 0;
  // La requête est normalisée avec le même traitement que les livres.
  final nq = _normalizeForMatch(q);
  if (nq.isEmpty) return 0;

  final title = book.normalizedTitle;
  final author = book.normalizedAuthor;

  if (title == nq) return config.relevanceMax;
  if (title.startsWith(nq)) return config.relevanceMax * 0.85;
  if (_containsAllTerms(title, nq)) return config.relevanceMax * 0.7;
  if (_containsAllTerms(author, nq)) return config.relevanceMax * 0.45;
  final desc = book.description?.toLowerCase() ?? '';
  if (desc.isNotEmpty && _containsAllTerms(desc, nq)) {
    return config.relevanceMax * 0.2;
  }
  // Match partiel : au moins un terme dans le titre.
  final terms = nq.split(' ');
  final hits = terms.where((t) => title.contains(t)).length;
  if (hits > 0) return config.relevanceMax * 0.3 * (hits / terms.length);
  return 0;
}

bool _containsAllTerms(String haystack, String needle) {
  if (haystack.isEmpty) return false;
  return needle.split(' ').every((t) => haystack.contains(t));
}

String _normalizeForMatch(String input) {
  var s = input.toLowerCase();
  s = s.replaceAll(RegExp(r"[^\p{L}\p{N} ]", unicode: true), ' ');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Format : EPUB plein score, PDF 2/3, autres lisibles 1/3, inconnu 0.
double _formatScore(Book book, ScoringConfig config) {
  switch (book.format) {
    case BookFormat.epub:
      return config.formatMax;
    case BookFormat.pdf:
      return config.formatMax * (2 / 3);
    case BookFormat.cbr:
    case BookFormat.cbz:
    case BookFormat.azw3:
    case BookFormat.mobi:
    case BookFormat.fb2:
    case BookFormat.djvu:
      return config.formatMax / 3;
    case BookFormat.unknown:
      return 0;
  }
}

/// Métadonnées : 25% par champ présent (couverture, année, éditeur, taille).
double _metadataScore(Book book, ScoringConfig config) {
  var present = 0;
  if (book.coverUrl != null && book.coverUrl!.isNotEmpty) present++;
  if (book.year != null) present++;
  if (book.publisher != null && book.publisher!.isNotEmpty) present++;
  if (book.fileSizeBytes != null && book.fileSizeBytes! > 0) present++;
  return config.metadataMax * (present / 4);
}

/// Fiabilité : meilleure santé parmi les sources référençant ce livre.
double _sourceHealthScore(
  Book book,
  ScoringConfig config,
  Map<String, double> sourceHealth,
) {
  if (book.refs.isEmpty) return 0;
  var best = 0.0;
  for (final ref in book.refs) {
    final h = sourceHealth[ref.sourceId] ?? 1.0;
    if (h > best) best = h;
  }
  return config.sourceHealthMax * best;
}

/// Fraîcheur : plein score si édition >= seuil, dégradé ensuite.
double _recencyScore(Book book, ScoringConfig config) {
  final year = book.year;
  if (year == null) return 0;
  if (year >= config.recentYearThreshold) return config.recencyMax;
  if (year >= config.recentYearThreshold - 10) return config.recencyMax * 0.5;
  return config.recencyMax * 0.2;
}
