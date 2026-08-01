import '../../../search/domain/entities/book.dart';
import '../../../search/domain/entities/book_details.dart';
import '../../../search/domain/entities/download_link.dart';
import '../../../search/domain/entities/search_query.dart';
import 'annas_archive_dto.dart';
import 'annas_archive_parser.dart';

/// Mapper Anna's Archive : DTO bruts -> modèle unifié.
///
/// SEUL endroit où la logique de conversion vit. Le parser ne connaît
/// pas Book ; le client ne connaît ni l'un ni l'autre.
class AnnaArchiveMapper {
  final AnnaArchiveParser _parser;

  /// Identifiant source utilisé dans les [SourceBookRef].
  static const sourceId = 'annas_archive';

  AnnaArchiveMapper({AnnaArchiveParser? parser})
      : _parser = parser ?? AnnaArchiveParser();

  /// Page brute -> livres du modèle unifié.
  List<Book> mapSearchHits(List<RawSearchHit> hits, String instanceBaseUrl) {
    return hits.map((h) => mapSearchHit(h, instanceBaseUrl)).toList();
  }

  /// Un hit brut -> un Book.
  Book mapSearchHit(RawSearchHit hit, String instanceBaseUrl) {
    return Book(
      title: hit.title,
      author: hit.author,
      publisher: hit.publisher,
      coverUrl: hit.coverUrl,
      language: hit.languageHint,
      format: _formatFromInfoLine(hit.infoLine),
      fileSizeBytes: _sizeFromInfoLine(hit.infoLine),
      year: hit.yearHint,
      refs: [
        SourceBookRef(
          sourceId: sourceId,
          sourceBookId: hit.md5,
          url: Uri.tryParse('$instanceBaseUrl${hit.detailPath}'),
        ),
      ],
    );
  }

  /// Détail brut -> BookDetails (livre complété si possible).
  BookDetails mapDetail(RawDetailPage raw, String md5, String instanceBaseUrl,
      {Book? baseBook}) {
    final book = (baseBook ??
            Book(
              title: raw.title ?? md5,
              author: raw.author,
              coverUrl: raw.coverUrl,
              refs: [
                SourceBookRef(
                  sourceId: sourceId,
                  sourceBookId: md5,
                  url: Uri.tryParse('$instanceBaseUrl/md5/$md5'),
                ),
              ],
            ))
        .copyWith(
      title: raw.title ?? baseBook?.title ?? md5,
      author: raw.author ?? baseBook?.author,
      coverUrl: raw.coverUrl ?? baseBook?.coverUrl,
      isbn: raw.isbn ?? baseBook?.isbn,
      format: (baseBook != null && baseBook.format != BookFormat.unknown)
          ? baseBook.format
          : _formatFromInfoLine(raw.infoLine),
      fileSizeBytes:
          baseBook?.fileSizeBytes ?? _sizeFromInfoLine(raw.infoLine),
      language:
          baseBook?.language ?? _parser.extractLanguageHint(raw.infoLine),
      year: baseBook?.year ?? _parser.extractYear(raw.infoLine),
    );

    return BookDetails(
      book: book,
      synopsis: raw.synopsis,
      identifiers: {if (raw.isbn != null) 'isbn': raw.isbn!},
    );
  }

  /// Liens de téléchargement depuis le détail brut.
  List<DownloadLink> mapDownloadLinks(RawDetailPage raw, String md5,
      String instanceBaseUrl) {
    return [
      for (final path in raw.slowDownloadPaths)
        DownloadLink(
          url: path.startsWith('http')
              ? Uri.parse(path)
              : Uri.parse('$instanceBaseUrl$path'),
          kind: DownloadLinkKind.intermediatePage,
          md5: md5,
        ),
    ];
  }

  // ------------------------------------------------------------------

  BookFormat _formatFromInfoLine(String infoLine) {
    final match = RegExp(r'\b(epub|pdf|cbr|cbz|azw3|mobi|fb2|djvu)\b',
            caseSensitive: false)
        .firstMatch(infoLine);
    return match == null
        ? BookFormat.unknown
        : bookFormatFromString(match.group(1));
  }

  int? _sizeFromInfoLine(String infoLine) {
    final match = RegExp(r'(\d+(?:[.,]\d+)?)\s*(kb|mb|gb|kib|mib|gib)\b',
            caseSensitive: false)
        .firstMatch(infoLine);
    if (match == null) return null;
    final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (value == null) return null;
    final multiplier = switch (match.group(2)!.toLowerCase()) {
      'kb' || 'kib' => 1024,
      'mb' || 'mib' => 1024 * 1024,
      'gb' || 'gib' => 1024 * 1024 * 1024,
      _ => 1,
    };
    return (value * multiplier).round();
  }
}
