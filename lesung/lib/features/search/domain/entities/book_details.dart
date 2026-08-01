import 'book.dart';

/// Détails complets d'un livre (page de détail d'une source).
class BookDetails {
  /// Livre de base (métadonnées déjà normalisées par la source).
  final Book book;

  /// Synopsis / description longue.
  final String? synopsis;

  /// Identifiants complémentaires (ISBN10, ISBN13, ASIN...).
  final Map<String, String> identifiers;

  const BookDetails({
    required this.book,
    this.synopsis,
    this.identifiers = const {},
  });
}
