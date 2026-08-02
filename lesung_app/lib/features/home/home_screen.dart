import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/engine.dart';
import '../../app/router.dart';
import '../../components/app_states.dart';
import '../../components/book_grid.dart';
import '../../components/section_title.dart';

/// Accueil — « Start ». Continuer la lecture + ajouts récents.
/// Le livre est toujours l'élément principal ; le reste est discret.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Rafraîchissement sur chaque événement de bibliothèque.
    ref.read(engineProvider).library.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.read(engineProvider);
    final state = engine.library.state;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final continueReading = state.continueReading
        .map((book) => BookItem(
              id: book.id,
              title: book.title,
              author: book.author,
              coverUrl: book.coverUrl,
              progress: null,
            ))
        .toList();
    final recent = state.recentBooks
        .map((book) => BookItem(
              id: book.id,
              title: book.title,
              author: book.author,
              coverUrl: book.coverUrl,
              badge: book.format?.toUpperCase(),
            ))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: state.loaded && recent.isEmpty && continueReading.isEmpty
            ? AppEmptyState.emptyLibrary(
                onExplore: () => context.go(AppRoutes.search))
            : ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        Text('Lesung',
                            style: textTheme.displayLarge
                                ?.copyWith(color: colors.onSurface)),
                        const SizedBox(height: 8),
                        Text(
                          _greeting(),
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (continueReading.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child:
                          SectionTitle(title: 'Weiterlesen'),
                    ),
                    BookList(
                      books: continueReading,
                      onBookTap: (book) => _openBook(book.id),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SectionTitle(
                      title: 'Zuletzt hinzugefügt',
                      actionLabel: 'Alle',
                      onAction: () => context.go(AppRoutes.library),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: BookGrid(
                      books: recent.take(6).toList(),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onBookTap: (book) => _openBook(book.id),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Guten Morgen.';
    if (hour < 18) return 'Guten Tag.';
    return 'Guten Abend.';
  }

  void _openBook(String bookId) async {
    final book = await ref.read(engineProvider).libraryManager.bookById(bookId);
    if (!mounted || book == null) return;
    if (book.isReadable) {
      context.push(AppRoutes.reader,
          extra: ReaderBookArgs(
              bookId: book.id,
              filePath: book.filePath!,
              title: book.title));
    } else {
      context.go(AppRoutes.library);
    }
  }
}
