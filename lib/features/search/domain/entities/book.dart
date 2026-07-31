import 'search_query.dart';

/// Référence d'un livre chez une source donnée.
///
/// Un même livre physique peut exister chez plusieurs sources :
/// la déduplication fusionne leurs références dans [Book.refs].
class SourceBookRef {
  /// Identifiant de la source (ex. 'annas_archive').
  final String sourceId;

  /// Identifiant du livre chez cette source (ex. md5 Anna's Archive,
  /// clé de work Open Library...).
  final String sourceBookId;

  /// URL canonique de la page du livre chez la source.
  final Uri? url;

  const SourceBookRef({
    required this.sourceId,
    required this.sourceBookId,
    this.url,
  });

  @override
  bool operator ==(Object other) =>
      other is SourceBookRef &&
      other.sourceId == sourceId &&
      other.sourceBookId == sourceBookId;

  @override
  int get hashCode => Object.hash(sourceId, sourceBookId);

  @override
  String toString() => 'SourceBookRef($sourceId:$sourceBookId)';
}

/// Entité livre unifiée produite par la normalisation.
///
/// Champs bruts fournis par la source + champs dérivés calculés par le
/// pipeline ([normalizedTitle], [normalizedAuthor], [dedupKey]).
class Book {
  final String title;
  final String? author;
  final String? publisher;
  final String? coverUrl;
  final String? description;

  /// Langue ISO 639-1 normalisée ('de', 'fr'...). Null si inconnue.
  final String? language;

  final BookFormat format;

  /// Taille du fichier en octets, si connue.
  final int? fileSizeBytes;

  /// Année de publication, si connue.
  final int? year;

  /// ISBN (10 ou 13), si connu — clé de déduplication forte.
  final String? isbn;

  /// Références chez la ou les sources ayant retourné ce livre.
  final List<SourceBookRef> refs;

  // -- Champs dérivés (calculés par la normalisation) --

  /// Titre normalisé : minuscules, sans accents ni ponctuation.
  final String normalizedTitle;

  /// Auteur normalisé (même traitement que le titre).
  final String normalizedAuthor;

  const Book({
    required this.title,
    this.author,
    this.publisher,
    this.coverUrl,
    this.description,
    this.language,
    this.format = BookFormat.unknown,
    this.fileSizeBytes,
    this.year,
    this.isbn,
    required this.refs,
    this.normalizedTitle = '',
    this.normalizedAuthor = '',
  });

  /// Clé de déduplication floue : titre + auteur normalisés.
  String get dedupKey => '$normalizedTitle|$normalizedAuthor';

  Book copyWith({
    String? title,
    String? author,
    String? publisher,
    String? coverUrl,
    String? description,
    String? language,
    BookFormat? format,
    int? fileSizeBytes,
    int? year,
    String? isbn,
    List<SourceBookRef>? refs,
    String? normalizedTitle,
    String? normalizedAuthor,
  }) {
    return Book(
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      language: language ?? this.language,
      format: format ?? this.format,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      year: year ?? this.year,
      isbn: isbn ?? this.isbn,
      refs: refs ?? this.refs,
      normalizedTitle: normalizedTitle ?? this.normalizedTitle,
      normalizedAuthor: normalizedAuthor ?? this.normalizedAuthor,
    );
  }

  @override
  String toString() => 'Book($title — ${author ?? "?"}, $language, $format)';
}
