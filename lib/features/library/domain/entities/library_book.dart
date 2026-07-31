/// Livre de bibliothèque — entité centrale, indépendante des sources.
///
/// Un livre peut être téléchargé, favori, dans des collections,
/// commencé ou terminé : tout cela INDÉPENDAMMENT. L'état de
/// téléchargement est une propriété du livre, pas sa raison d'être.
class LibraryBook {
  /// Identifiant stable du livre dans la bibliothèque.
  final String id;

  final String title;
  final String? author;
  final String? coverUrl;
  final String? language;
  final String? format;
  final String? publisher;
  final int? year;
  final String? description;
  final String? isbn;

  // -- État de téléchargement (indépendant du reste) --

  /// Le fichier a été téléchargé et est associé à ce livre.
  final bool downloaded;

  /// Chemin du fichier sur disque, si téléchargé.
  final String? filePath;

  final int? fileSizeBytes;

  /// Le fichier était présent mais a disparu du disque (détecté par
  /// la synchronisation) : correction automatique à prévoir.
  final bool fileMissing;

  // -- Cycle de vie de lecture --

  final DateTime addedAt;
  final DateTime updatedAt;
  final DateTime? lastOpenedAt;
  final DateTime? finishedAt;

  const LibraryBook({
    required this.id,
    required this.title,
    this.author,
    this.coverUrl,
    this.language,
    this.format,
    this.publisher,
    this.year,
    this.description,
    this.isbn,
    this.downloaded = false,
    this.filePath,
    this.fileSizeBytes,
    this.fileMissing = false,
    required this.addedAt,
    required this.updatedAt,
    this.lastOpenedAt,
    this.finishedAt,
  });

  /// Livre effectivement lisible (fichier présent sur disque).
  bool get isReadable => downloaded && !fileMissing && filePath != null;

  bool get isFinished => finishedAt != null;

  LibraryBook copyWith({
    String? title,
    String? author,
    String? coverUrl,
    String? language,
    String? format,
    String? publisher,
    int? year,
    String? description,
    String? isbn,
    bool? downloaded,
    String? filePath,
    int? fileSizeBytes,
    bool? fileMissing,
    DateTime? updatedAt,
    DateTime? lastOpenedAt,
    DateTime? finishedAt,
    bool clearFilePath = false,
    bool clearFinishedAt = false,
  }) {
    return LibraryBook(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      language: language ?? this.language,
      format: format ?? this.format,
      publisher: publisher ?? this.publisher,
      year: year ?? this.year,
      description: description ?? this.description,
      isbn: isbn ?? this.isbn,
      downloaded: downloaded ?? this.downloaded,
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      fileMissing: fileMissing ?? this.fileMissing,
      addedAt: addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      finishedAt: clearFinishedAt ? null : (finishedAt ?? this.finishedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'coverUrl': coverUrl,
        'language': language,
        'format': format,
        'publisher': publisher,
        'year': year,
        'description': description,
        'isbn': isbn,
        'downloaded': downloaded ? 1 : 0,
        'filePath': filePath,
        'fileSizeBytes': fileSizeBytes,
        'fileMissing': fileMissing ? 1 : 0,
        'addedAt': addedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastOpenedAt': lastOpenedAt?.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
      };

  factory LibraryBook.fromJson(Map<String, dynamic> json) => LibraryBook(
        id: json['id'] as String,
        title: json['title'] as String,
        author: json['author'] as String?,
        coverUrl: json['coverUrl'] as String?,
        language: json['language'] as String?,
        format: json['format'] as String?,
        publisher: json['publisher'] as String?,
        year: json['year'] as int?,
        description: json['description'] as String?,
        isbn: json['isbn'] as String?,
        downloaded: (json['downloaded'] as int? ?? 0) == 1,
        filePath: json['filePath'] as String?,
        fileSizeBytes: json['fileSizeBytes'] as int?,
        fileMissing: (json['fileMissing'] as int? ?? 0) == 1,
        addedAt: DateTime.parse(json['addedAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        lastOpenedAt: json['lastOpenedAt'] == null
            ? null
            : DateTime.parse(json['lastOpenedAt'] as String),
        finishedAt: json['finishedAt'] == null
            ? null
            : DateTime.parse(json['finishedAt'] as String),
      );
}
