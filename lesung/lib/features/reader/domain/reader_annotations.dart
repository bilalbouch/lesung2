/// Annotations du Reader : surlignages + notes.
library;

/// Une annotation = un passage sélectionné, une couleur, une note
/// optionnelle. Persistée indépendamment des signets.
class ReaderAnnotation {
  final String id;
  final String bookId;
  final String locator;
  final int unitIndex;

  /// Texte sélectionné au moment de l'annotation.
  final String selectedText;

  /// Note libre de l'utilisateur (peut être vide pour un simple
  /// surlignage).
  final String note;

  /// Couleur ARGB (0xFFxxxxxx) — jaune par défaut.
  final int color;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ReaderAnnotation({
    required this.id,
    required this.bookId,
    required this.locator,
    required this.unitIndex,
    required this.selectedText,
    this.note = '',
    this.color = 0xFFFFD966,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Couleurs proposées par l'UI (clés stables).
  static const highlightColors = <String, int>{
    'yellow': 0xFFFFD966,
    'green': 0xFFA8D5A2,
    'blue': 0xFFA8C6E8,
    'pink': 0xFFE8A8C0,
    'orange': 0xFFF2B880,
  };

  ReaderAnnotation copyWith({
    String? note,
    int? color,
    DateTime? updatedAt,
  }) =>
      ReaderAnnotation(
        id: id,
        bookId: bookId,
        locator: locator,
        unitIndex: unitIndex,
        selectedText: selectedText,
        note: note ?? this.note,
        color: color ?? this.color,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'locator': locator,
        'unitIndex': unitIndex,
        'selectedText': selectedText,
        'note': note,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ReaderAnnotation.fromJson(Map<String, dynamic> json) =>
      ReaderAnnotation(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        locator: json['locator'] as String,
        unitIndex: (json['unitIndex'] as num?)?.toInt() ?? 0,
        selectedText: json['selectedText'] as String? ?? '',
        note: json['note'] as String? ?? '',
        color: (json['color'] as num?)?.toInt() ?? 0xFFFFD966,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// Gestion des annotations d'un livre, persistées via le repository.
class ReaderAnnotations {
  final Future<List<ReaderAnnotation>> Function() _load;
  final Future<void> Function(ReaderAnnotation) _save;
  final Future<void> Function(String) _remove;

  List<ReaderAnnotation> _cache = const [];

  ReaderAnnotations({
    required Future<List<ReaderAnnotation>> Function() load,
    required Future<void> Function(ReaderAnnotation) save,
    required Future<void> Function(String) remove,
  })  : _load = load,
        _save = save,
        _remove = remove;

  Future<void> init() async {
    _cache = [...await _load()];
    _cache.sort((a, b) => a.unitIndex.compareTo(b.unitIndex));
  }

  List<ReaderAnnotation> get all => List.unmodifiable(_cache);

  List<ReaderAnnotation> forUnit(int unitIndex) =>
      _cache.where((a) => a.unitIndex == unitIndex).toList();

  Future<ReaderAnnotation> add({
    required String id,
    required String bookId,
    required String locator,
    required int unitIndex,
    required String selectedText,
    String note = '',
    int color = 0xFFFFD966,
  }) async {
    if (selectedText.trim().isEmpty) {
      throw ArgumentError.value(
          selectedText, 'selectedText', 'Sélection vide.');
    }
    final now = DateTime.now();
    final annotation = ReaderAnnotation(
      id: id,
      bookId: bookId,
      locator: locator,
      unitIndex: unitIndex,
      selectedText: selectedText,
      note: note,
      color: color,
      createdAt: now,
      updatedAt: now,
    );
    _cache.removeWhere((a) => a.id == id);
    _cache.add(annotation);
    await _save(annotation);
    return annotation;
  }

  Future<ReaderAnnotation?> updateNote(String annotationId, String note) =>
      _update(annotationId, (a) => a.copyWith(note: note));

  Future<ReaderAnnotation?> changeColor(String annotationId, int color) =>
      _update(annotationId, (a) => a.copyWith(color: color));

  Future<ReaderAnnotation?> _update(
    String annotationId,
    ReaderAnnotation Function(ReaderAnnotation) transform,
  ) async {
    final index = _cache.indexWhere((a) => a.id == annotationId);
    if (index == -1) return null;
    final updated =
        transform(_cache[index]).copyWith(updatedAt: DateTime.now());
    _cache[index] = updated;
    await _save(updated);
    return updated;
  }

  Future<void> remove(String annotationId) async {
    if (!_cache.any((a) => a.id == annotationId)) return;
    _cache.removeWhere((a) => a.id == annotationId);
    await _remove(annotationId);
  }
}
