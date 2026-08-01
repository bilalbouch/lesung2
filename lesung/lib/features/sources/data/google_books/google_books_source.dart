import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lesung/features/search/domain/entities/book.dart';
import 'package:lesung/features/search/domain/entities/book_details.dart';
import 'package:lesung/features/search/domain/entities/download_link.dart';
import 'package:lesung/features/search/domain/entities/search_query.dart';
import 'package:lesung/features/sources/domain/book_source.dart';

class GoogleBooksSource implements BookSource {
  final http.Client _client;
  final String? _apiKey;
  GoogleBooksSource({http.Client? client, String? apiKey}) : _client = client ?? http.Client(), _apiKey = apiKey;

  @override
  SourceMeta get meta => const SourceMeta(id: 'google_books', displayName: 'Google Books', supportsPagination: true);

  @override
  Future<PagedResult<Book>> search(SearchQuery query) async {
    final q = Uri.encodeComponent(query.text);
    var url = 'https://www.googleapis.com/books/v1/volumes?q=$q&startIndex=${(query.page - 1) * 20}&maxResults=20';
    if (_apiKey != null && _apiKey!.isNotEmpty) url += '&key=$_apiKey';
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) return const PagedResult(items: [], hasMore: false);
    final data = jsonDecode(response.body);
    final items = (data['items'] as List<dynamic>? ?? []);
    final books = items.map((i) {
      final item = i as Map<String, dynamic>;
      final volumeInfo = item['volumeInfo'] as Map<String, dynamic>?;
      if (volumeInfo == null) return null;
      final title = volumeInfo['title'] as String?;
      if (title == null || title.isEmpty) return null;
      final authors = (volumeInfo['authors'] as List<dynamic>?)?.cast<String>() ?? [];
      final year = volumeInfo['publishedDate'] != null ? int.tryParse(volumeInfo['publishedDate'].toString().substring(0, 4)) : null;
      final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
      final coverUrl = imageLinks?['thumbnail'] as String?;
      final bookId = item['id'] as String? ?? '';
      return Book(
        title: title, author: authors.isNotEmpty ? authors.first : null, year: year,
        language: volumeInfo['language'] as String? ?? 'en', coverUrl: coverUrl,
        format: BookFormat.epub,
        refs: [SourceBookRef(sourceId: meta.id, sourceBookId: bookId, url: Uri.parse(volumeInfo['previewLink'] as String? ?? 'https://books.google.com/books?id=$bookId'))],
      );
    }).whereType<Book>().toList();
    return PagedResult(items: books, hasMore: (data['totalItems'] as int? ?? 0) > query.page * 20);
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
      final r = await _client.get(Uri.parse('https://www.googleapis.com/books/v1/volumes?q=test&maxResults=1'));
      return SourceHealth(reachable: r.statusCode == 200);
    } catch (e) { return const SourceHealth(reachable: false); }
  }
}
