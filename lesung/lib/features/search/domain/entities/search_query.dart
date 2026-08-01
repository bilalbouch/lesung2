/// Requête de recherche unifiée, indépendante de toute source.
library;

/// Formats de fichier reconnus par le moteur.
enum BookFormat { epub, pdf, cbr, cbz, azw3, mobi, fb2, djvu, unknown }

BookFormat bookFormatFromString(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'epub':
      return BookFormat.epub;
    case 'pdf':
      return BookFormat.pdf;
    case 'cbr':
      return BookFormat.cbr;
    case 'cbz':
      return BookFormat.cbz;
    case 'azw3':
    case 'azw':
      return BookFormat.azw3;
    case 'mobi':
      return BookFormat.mobi;
    case 'fb2':
      return BookFormat.fb2;
    case 'djvu':
      return BookFormat.djvu;
    default:
      return BookFormat.unknown;
  }
}

/// Tri demandé par l'utilisateur.
enum SearchSort { relevance, newest, oldest, largest, smallest }

/// Requête de recherche immuable. Pagination 1-indexée.
class SearchQuery {
  final String text;

  /// Filtre langue ISO 639-1 ('de', 'fr', 'en'...). Null = toutes.
  final String? language;

  /// Filtre format de fichier. Null = tous.
  final BookFormat? format;

  /// Filtre année de publication exacte. Null = toutes.
  final int? year;

  final SearchSort sort;
  final int page;

  const SearchQuery({
    required this.text,
    this.language,
    this.format,
    this.year,
    this.sort = SearchSort.relevance,
    this.page = 1,
  }) : assert(page >= 1, 'La pagination est 1-indexée (page >= 1).');

  SearchQuery copyWith({
    String? text,
    String? language,
    BookFormat? format,
    int? year,
    SearchSort? sort,
    int? page,
  }) {
    return SearchQuery(
      text: text ?? this.text,
      language: language ?? this.language,
      format: format ?? this.format,
      year: year ?? this.year,
      sort: sort ?? this.sort,
      page: page ?? this.page,
    );
  }

  bool get hasFilters => language != null || format != null || year != null;

  @override
  String toString() =>
      'SearchQuery(text: $text, lang: $language, format: $format, '
      'year: $year, sort: $sort, page: $page)';

  @override
  bool operator ==(Object other) =>
      other is SearchQuery &&
      other.text == text &&
      other.language == language &&
      other.format == format &&
      other.year == year &&
      other.sort == sort &&
      other.page == page;

  @override
  int get hashCode => Object.hash(text, language, format, year, sort, page);
}
