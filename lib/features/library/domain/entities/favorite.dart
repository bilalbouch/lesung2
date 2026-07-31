/// Favori : simple lien livre + date. Un livre peut être favori sans
/// être téléchargé — indépendance totale.
class Favorite {
  final String bookId;
  final DateTime addedAt;

  const Favorite({required this.bookId, required this.addedAt});

  Map<String, dynamic> toJson() =>
      {'bookId': bookId, 'addedAt': addedAt.toIso8601String()};

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
      bookId: json['bookId'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String));
}
