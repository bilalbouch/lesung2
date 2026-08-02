import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/engine.dart';
import '../../app/router.dart';
import '../../components/app_states.dart';
import '../../components/book_grid.dart';
import '../../components/section_title.dart';
import '../../l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

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

    final header = _HomeHeader(
      greeting: _greeting(l10n),
      colors: colors,
      textTheme: textTheme,
    );

    return Scaffold(
      body: SafeArea(
        child: state.loaded && recent.isEmpty && continueReading.isEmpty
            ? Column(
                children: [
                  header,
                  Expanded(
                    child: AppEmptyState.emptyLibrary(
                      context: context,
                      onExplore: () => context.go(AppRoutes.search),
                    ),
                  ),
                ],
              )
            : ListView(
                children: [
                  header,
                  if (continueReading.isNotEmpty) ...[

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SectionTitle(title: l10n.libraryContinueReading),
                    ),
                    BookList(
                      books: continueReading,
                      onBookTap: (book) => _openBook(book.id),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SectionTitle(
                      title: l10n.libraryRecentlyAdded,
                      actionLabel: l10n.actionAll,
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

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 11) return l10n.greetingMorning;
    if (hour < 18) return l10n.greetingDay;
    return l10n.greetingEvening;
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

class _HomeHeader extends StatelessWidget {
  final String greeting;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _HomeHeader({
    required this.greeting,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lesung',
                  style: textTheme.displayMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: colors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
