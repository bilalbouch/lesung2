/// Collection personnalisée (étagère thématique).
class Collection {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Ordre d'affichage (drag & drop côté UI).
  final int sortOrder;

  const Collection({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder = 0,
  });

  Collection copyWith({String? name, DateTime? updatedAt, int? sortOrder}) =>
      Collection(
          id: id,
          name: name ?? this.name,
          createdAt: createdAt,
          updatedAt: updatedAt ?? this.updatedAt,
          sortOrder: sortOrder ?? this.sortOrder);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'sortOrder': sortOrder,
      };

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}

/// Lien collection <-> livre (table collection_books).
class CollectionBook {
  final String collectionId;
  final String bookId;
  final DateTime addedAt;
  final int position;

  const CollectionBook({
    required this.collectionId,
    required this.bookId,
    required this.addedAt,
    this.position = 0,
  });

  Map<String, dynamic> toJson() => {
        'collectionId': collectionId,
        'bookId': bookId,
        'addedAt': addedAt.toIso8601String(),
        'position': position,
      };

  factory CollectionBook.fromJson(Map<String, dynamic> json) =>
      CollectionBook(
        collectionId: json['collectionId'] as String,
        bookId: json['bookId'] as String,
        addedAt: DateTime.parse(json['addedAt'] as String),
        position: json['position'] as int? ?? 0,
      );
}
