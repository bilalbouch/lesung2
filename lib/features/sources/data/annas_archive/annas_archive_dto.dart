/// DTO bruts produits par le parser.
///
/// Ces objets reflètent FIDÈLEMENT ce que le HTML contient, sans
/// interprétation métier : la conversion vers le modèle unifié Book
/// est la responsabilité exclusive du Mapper.
library;

/// Un résultat de recherche brut (une carte de la page /search).
class RawSearchHit {
  final String title;
  final String? author;
  final String? publisher;
  final String? coverUrl;

  /// Ligne d'informations fichier brute (langue, format, taille...).
  final String infoLine;

  /// Identifiant md5 extrait du lien /md5/<id>.
  final String md5;

  /// Chemin relatif de la page de détail (/md5/<id>).
  final String detailPath;

  /// Ligne de langue brute si identifiée séparément.
  final String? languageHint;

  /// Année brute si repérée dans les métadonnées.
  final int? yearHint;

  const RawSearchHit({
    required this.title,
    this.author,
    this.publisher,
    this.coverUrl,
    this.infoLine = '',
    required this.md5,
    required this.detailPath,
    this.languageHint,
    this.yearHint,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'publisher': publisher,
        'coverUrl': coverUrl,
        'infoLine': infoLine,
        'md5': md5,
        'detailPath': detailPath,
        'languageHint': languageHint,
        'yearHint': yearHint,
      };

  factory RawSearchHit.fromJson(Map<String, dynamic> json) => RawSearchHit(
        title: json['title'] as String,
        author: json['author'] as String?,
        publisher: json['publisher'] as String?,
        coverUrl: json['coverUrl'] as String?,
        infoLine: json['infoLine'] as String? ?? '',
        md5: json['md5'] as String,
        detailPath: json['detailPath'] as String,
        languageHint: json['languageHint'] as String?,
        yearHint: json['yearHint'] as int?,
      );
}

/// Une page de résultats brute.
class RawSearchPage {
  final List<RawSearchHit> hits;

  /// La page HTML annonce une page suivante.
  final bool hasNextPage;

  const RawSearchPage({required this.hits, required this.hasNextPage});

  Map<String, dynamic> toJson() => {
        'hits': hits.map((h) => h.toJson()).toList(),
        'hasNextPage': hasNextPage,
      };

  factory RawSearchPage.fromJson(Map<String, dynamic> json) => RawSearchPage(
        hits: (json['hits'] as List)
            .map((h) => RawSearchHit.fromJson(h as Map<String, dynamic>))
            .toList(),
        hasNextPage: json['hasNextPage'] as bool,
      );
}

/// Contenu brut d'une page de détail /md5/<id>.
class RawDetailPage {
  final String? title;
  final String? author;
  final String? coverUrl;
  final String? synopsis;
  final String? isbn;
  final String infoLine;
  final List<String> slowDownloadPaths;

  const RawDetailPage({
    this.title,
    this.author,
    this.coverUrl,
    this.synopsis,
    this.isbn,
    this.infoLine = '',
    this.slowDownloadPaths = const [],
  });
}
