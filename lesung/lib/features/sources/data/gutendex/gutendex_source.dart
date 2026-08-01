import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lesung/features/search/domain/entities/book.dart';
import 'package:lesung/features/search/domain/entities/book_details.dart';
import 'package:lesung/features/search/domain/entities/download_link.dart';
import 'package:lesung/features/search/domain/entities/search_query.dart';
import 'package:lesung/features/sources/domain/book_source.dart';

class GutendexSource implements BookSource {
  final http.Client _client;
  GutendexSource({http.Client? client}) : _client = client ?? http.Client();

  @override
  SourceMeta get meta => const SourceMeta(id: 'gutendex', displayName: 'Project Gutenberg', supportsPagination: true);

  @override
  Future<PagedResult<Book>> search(SearchQuery query) async {
    final q = Uri.encodeComponent(query.text);
    final response = await _client.get(Uri.parse('https://gutendex.com/books/?search=$q&page=${query.page}'));
    if (response.statusCode != 200) return const PagedResult(items: [], hasMore: false);
    final data = jsonDecode(response.body);
    final results = (data['results'] as List<dynamic>? ?? []);
    final items = results.map((r) {
      final book = r as Map<String, dynamic>;
      final title = book['title'] as String?;
      if (title == null || title.isEmpty) return null;
      final authors = (book['authors'] as List<dynamic>?) ?? [];
      final authorName = authors.isNotEmpty ? (authors.first as Map<String, dynamic>)['name'] as String? : null;
      final formats = book['formats'] as Map<String, dynamic>? ?? {};
      final coverUrl = formats['image/jpeg'] as String?;
      final epubUrl = formats['application/epub+zip'] as String?;
      final pdfUrl = formats['application/pdf'] as String?;
      BookFormat format = BookFormat.epub;
      String? downloadUrl = epubUrl;
      if (epubUrl == null && pdfUrl != null) { format = BookFormat.pdf; downloadUrl = pdfUrl; }
      final bookId = book['id'].toString();
      final refs = <SourceBookRef>[];
      if (downloadUrl != null) refs.add(SourceBookRef(sourceId: meta.id, sourceBookId: bookId, url: Uri.parse(downloadUrl)));
      return Book(title: title, author: authorName, language: 'en', coverUrl: coverUrl, format: format, refs: refs);
    }).whereType<Book>().toList();
    return PagedResult(items: items, hasMore: data['next'] != null);
  }

  @override
  Future<BookDetails> details(String sourceBookId) async {
    return BookDetails(book: Book(title: 'Unknown', format: BookFormat.unknown, refs: [SourceBookRef(sourceId: meta.id, sourceBookId: sourceBookId)]));
  }

  @override
  Future<List<DownloadLink>> resolveDownloadLinks(String sourceBookId) async {
    final response = await _client.get(Uri.parse('https://gutendex.com/books/$sourceBookId/'));
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    final formats = (data['formats'] as Map<String, dynamic>? ?? {});
    final links = <DownloadLink>[];
    if (formats.containsKey('application/epub+zip')) links.add(DownloadLink(url: Uri.parse(formats['application/epub+zip'] as String), kind: DownloadLinkKind.direct, format: BookFormat.epub));
    if (formats.containsKey('application/pdf')) links.add(DownloadLink(url: Uri.parse(formats['application/pdf'] as String), kind: DownloadLinkKind.direct, format: BookFormat.pdf));
    return links;
  }

  @override
  Future<SourceHealth> healthCheck() async {
    try {
      final r = await _client.get(Uri.parse('https://gutendex.com/books/?search=test&page=1'));
      return SourceHealth(reachable: r.statusCode == 200);
    } catch (e) { return const SourceHealth(reachable: false); }
  }
}
