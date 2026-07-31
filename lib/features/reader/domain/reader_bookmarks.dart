/// Signets (bookmarks/favoris de lecture) du Reader.
library;

/// Un signet pointe vers une position précise d'un livre.
class ReaderBookmark {
  final String id;
  final String bookId;
  final String locator;
  final int unitIndex;
  final String? label;
  final String? chapterTitle;
  final DateTime createdAt;

  const ReaderBookmark({
    required this.id,
    required this.bookId,
    required this.locator,
    required this.unitIndex,
    this.label,
    this.chapterTitle,
    required this.createdAt,
  });

  ReaderBookmark copyWith({String? label}) => ReaderBookmark(
        id: id,
        bookId: bookId,
        locator: locator,
        unitIndex: unitIndex,
        label: label ?? this.label,
        chapterTitle: chapterTitle,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'locator': locator,
        'unitIndex': unitIndex,
        'label': label,
        'chapterTitle': chapterTitle,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ReaderBookmark.fromJson(Map<String, dynamic> json) =>
      ReaderBookmark(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        locator: json['locator'] as String,
        unitIndex: (json['unitIndex'] as num?)?.toInt() ?? 0,
        label: json['label'] as String?,
        chapterTitle: json['chapterTitle'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// Gestion des signets d'un livre, persistés via le repository.
class ReaderBookmarks {
  /// Callback de persistance injecté par le ReaderManager (qui connaît
  /// le repository) — ReaderBookmarks reste sans dépendance concrète.
  final Future<List<ReaderBookmark>> Function() _load;
  final Future<void> Function(ReaderBookmark) _save;
  final Future<void> Function(String) _remove;

  List<ReaderBookmark> _cache = const [];

  ReaderBookmarks({
    required Future<List<ReaderBookmark>> Function() load,
    required Future<void> Function(ReaderBookmark) save,
    required Future<void> Function(String) remove,
  })  : _load = load,
        _save = save,
        _remove = remove;

  Future<void> init() async {
    // Copie modifiable : le repository peut retourner une vue non
    // modifiable.
    _cache = [...await _load()];
    _cache.sort((a, b) => a.unitIndex.compareTo(b.unitIndex));
  }

  List<ReaderBookmark> get all => List.unmodifiable(_cache);

  bool hasBookmarkAt(String locator) =>
      _cache.any((b) => b.locator == locator);

  Future<ReaderBookmark> add({
    required String id,
    required String bookId,
    required String locator,
    required int unitIndex,
    String? label,
    String? chapterTitle,
  }) async {
    final bookmark = ReaderBookmark(
      id: id,
      bookId: bookId,
      locator: locator,
      unitIndex: unitIndex,
      label: label,
      chapterTitle: chapterTitle,
      createdAt: DateTime.now(),
    );
    _cache.removeWhere((b) => b.id == id);
    _cache.add(bookmark);
    _cache.sort((a, b) => a.unitIndex.compareTo(b.unitIndex));
    await _save(bookmark);
    return bookmark;
  }

  Future<void> remove(String bookmarkId) async {
    if (!_cache.any((b) => b.id == bookmarkId)) return;
    _cache.removeWhere((b) => b.id == bookmarkId);
    await _remove(bookmarkId);
  }

  /// Bascule un signet sur la position courante. Retourne true si un
  /// signet a été ajouté, false s'il a été retiré.
  Future<bool> toggle({
    required String id,
    required String bookId,
    required String locator,
    required int unitIndex,
    String? chapterTitle,
  }) async {
    for (final b in _cache) {
      if (b.locator == locator) {
        await remove(b.id);
        return false;
      }
    }
    await add(
        id: id,
        bookId: bookId,
        locator: locator,
        unitIndex: unitIndex,
        chapterTitle: chapterTitle);
    return true;
  }
}
