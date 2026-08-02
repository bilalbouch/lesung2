import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lesung/features/library/domain/entities/library_book.dart';

import '../../app/engine.dart';
import '../../app/router.dart';
import '../../components/app_states.dart';
import '../../components/book_grid.dart';

/// Favoriten — tous les livres marqués d'un cœur, téléchargés ou non.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(engineProvider).library.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.read(engineProvider).library.state;
    final items = state.favorites
        .map((book) => BookItem(
              id: book.id,
              title: book.title,
              author: book.author,
              coverUrl: book.coverUrl,
              badge: book.format?.toUpperCase(),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favoriten')),
      body: state.loaded && items.isEmpty
          ? AppEmptyState.noFavorites()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 16),
              child: BookGrid(
                books: items,
                onBookTap: (item) => _open(item.id),
              ),
            ),
    );
  }

  Future<void> _open(String bookId) async {
    final book =
        await ref.read(engineProvider).libraryManager.bookById(bookId);
    if (book == null || !mounted) return;
    _openBook(book);
  }

  void _openBook(LibraryBook book) {
    if (book.isReadable) {
      context.push(AppRoutes.reader,
          extra: ReaderBookArgs(
              bookId: book.id,
              filePath: book.filePath!,
              title: book.title));
    }
  }
}
