import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lesung/features/search/domain/entities/book.dart';
import 'package:lesung/features/search/domain/entities/book_details.dart';
import 'package:lesung/features/search/domain/entities/download_link.dart';
import 'package:lesung/features/search/domain/entities/search_query.dart';
import 'package:lesung/features/sources/domain/book_source.dart';

class OpenLibrarySource implements BookSource {
  final http.Client _client;
  OpenLibrarySource({http.Client? client}) : _client = client ?? http.Client();

  @override
  SourceMeta get meta => const SourceMeta(id: 'open_library', displayName: 'Open Library', supportsPagination: true);

  @override
  Future<PagedResult<Book>> search(SearchQuery query) async {
    final q = Uri.encodeComponent(query.text);
    final response = await _client.get(Uri.parse('https://openlibrary.org/search.json?q=$q&page=${query.page}&limit=20'));
    if (response.statusCode != 200) return const PagedResult(items: [], hasMore: false);
    final data = jsonDecode(response.body);
    final docs = (data['docs'] as List<dynamic>? ?? []);
    final items = docs.map((d) {
      final doc = d as Map<String, dynamic>;
      final title = doc['title'] as String?;
      if (title == null || title.isEmpty) return null;
      final authors = (doc['author_name'] as List<dynamic>?)?.cast<String>() ?? [];
      final year = doc['first_publish_year'] as int?;
      final coverId = doc['cover_i'] as int?;
      final coverUrl = coverId != null ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg' : null;
      final key = doc['key'] as String? ?? '';
      final isbnList = (doc['isbn'] as List<dynamic>?)?.cast<String>() ?? [];
      return Book(
        title: title, author: authors.isNotEmpty ? authors.first : null, year: year,
        language: 'en', coverUrl: coverUrl, isbn: isbnList.isNotEmpty ? isbnList.first : null,
        format: BookFormat.epub,
        refs: [SourceBookRef(sourceId: meta.id, sourceBookId: key, url: Uri.parse('https://openlibrary.org$key'))],
      );
    }).whereType<Book>().toList();
    return PagedResult(items: items, hasMore: (data['numFound'] as int? ?? 0) > query.page * 20);
  }

  @override
  Future<BookDetails> details(String sourceBookId) async {
    return BookDetails(book: Book(title: 'Unknown', format: BookFormat.unknown, refs: [SourceBookRef(sourceId: meta.id, sourceBookId: sourceBookId)]));
  }

  @override
  Future<List<DownloadLink>> resolveDownloadLinks(String sourceBookId) async => [];

  @override
  Future<SourceHealth> healthCheck() async {
    try {
      final r = await _client.get(Uri.parse('https://openlibrary.org/search.json?q=test&limit=1'));
      return SourceHealth(reachable: r.statusCode == 200);
    } catch (e) { return const SourceHealth(reachable: false); }
  }
}
