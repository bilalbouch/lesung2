import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lesung/features/library/domain/entities/library_book.dart';

import '../../app/engine.dart';
import '../../app/router.dart';
import '../../components/app_states.dart';
import '../../components/book_grid.dart';
import '../../components/section_title.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_radius.dart';
import '../../design_system/tokens/app_icons.dart';
import '../../design_system/tokens/app_spacing.dart';

/// Bibliothèque — Weiterlesen, Heruntergeladen, Favoris, accès
/// Collections/Verlauf.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(engineProvider).library.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  BookItem _toItem(LibraryBook book) => BookItem(
        id: book.id,
        title: book.title,
        author: book.author,
        coverUrl: book.coverUrl,
        badge: book.format?.toUpperCase(),
      );

  @override
  Widget build(BuildContext context) {
    final engine = ref.read(engineProvider);
    final state = engine.library.state;

    final downloaded = state.downloadedBooks.map(_toItem).toList();
    final favorites = state.favorites.map(_toItem).toList();
    final continueReading = state.continueReading.map(_toItem).toList();

    final isEmpty = state.loaded &&
        downloaded.isEmpty &&
        favorites.isEmpty &&
        continueReading.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothek'),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.history),
            tooltip: 'Verlauf',
            onPressed: () => context.push(AppRoutes.history),
          ),
        ],
      ),
      body: isEmpty
          ? AppEmptyState.emptyLibrary(
              onExplore: () => context.go(AppRoutes.search))
          : ListView(
              children: [
                Padding(
                  padding: AppSpacing.screen,
                  child: Row(
                    children: [
                      Expanded(
                        child: _Shortcut(
                          icon: AppIcons.collection,
                          label: 'Sammlungen',
                          onTap: () => context.push(AppRoutes.collections),
                        ),
                      ),
                      AppSpacing.hGapM,
                      Expanded(
                        child: _Shortcut(
                          icon: AppIcons.favorite,
                          label: 'Favoriten',
                          onTap: () => context.push(AppRoutes.favorites),
                        ),
                      ),
                    ],
                  ),
                ),
                if (continueReading.isNotEmpty) ...[
                  const Padding(
                    padding: AppSpacing.screen,
                    child: SectionTitle(title: 'Weiterlesen'),
                  ),
                  BookList(
                    books: continueReading,
                    onBookTap: (book) => _open(book.id),
                  ),
                ],
                if (downloaded.isNotEmpty) ...[
                  const Padding(
                    padding: AppSpacing.screen,
                    child: SectionTitle(title: 'Heruntergeladen'),
                  ),
                  Padding(
                    padding: AppSpacing.screen,
                    child: BookGrid(
                      books: downloaded,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onBookTap: (book) => _open(book.id),
                    ),
                  ),
                ],
                if (favorites.isNotEmpty) ...[
                  Padding(
                    padding: AppSpacing.screen,
                    child: SectionTitle(
                      title: 'Favoriten',
                      actionLabel: 'Alle',
                      onAction: () => context.push(AppRoutes.favorites),
                    ),
                  ),
                  BookList(
                    books: favorites,
                    onBookTap: (book) => _open(book.id),
                  ),
                ],
                AppSpacing.gapXxl,
              ],
            ),
    );
  }

  void _open(String bookId) async {
    final book =
        await ref.read(engineProvider).libraryManager.bookById(bookId);
    if (!mounted || book == null) return;
    if (book.isReadable) {
      context.push(AppRoutes.reader,
          extra: ReaderBookArgs(
              bookId: book.id,
              filePath: book.filePath!,
              title: book.title));
    }
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Shortcut(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            children: [
              Icon(icon, color: colors.accent),
              AppSpacing.hGapM,
              Expanded(
                child: Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Icon(AppIcons.chapterNext, color: colors.inkTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
