import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lesung/features/library/domain/entities/library_book.dart';

import '../../app/engine.dart';
import '../../app/router.dart';
import '../../components/app_states.dart';
import '../../components/book_grid.dart';
import '../../components/section_title.dart';
import '../../design_system/tokens/lumina_radius.dart';
import '../../design_system/tokens/app_icons.dart';
import '../../l10n/generated/app_localizations.dart';

/// Bibliothèque — Weiterlesen, Heruntergeladen, Favoris, accès
/// Collections/Verlauf.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late final StreamSubscription<dynamic> _librarySubscription;

  @override
  void initState() {
    super.initState();
    _librarySubscription =
        ref.read(engineProvider).library.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    unawaited(_librarySubscription.cancel());
    super.dispose();
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
    final l10n = AppLocalizations.of(context)!;

    final downloaded = state.downloadedBooks.map(_toItem).toList();
    final favorites = state.favorites.map(_toItem).toList();
    final continueReading = state.continueReading.map(_toItem).toList();

    final isEmpty = state.loaded &&
        downloaded.isEmpty &&
        favorites.isEmpty &&
        continueReading.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.history),
            tooltip: l10n.libraryHistory,
            onPressed: () => context.push(AppRoutes.history),
          ),
        ],
      ),
      body: isEmpty
          ? AppEmptyState.emptyLibrary(
              context: context,
              onExplore: () => context.go(AppRoutes.search))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Shortcut(
                          icon: AppIcons.collection,
                          label: l10n.libraryCollections,
                          onTap: () => context.push(AppRoutes.collections),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _Shortcut(
                          icon: AppIcons.favorite,
                          label: l10n.libraryFavorites,
                          onTap: () => context.push(AppRoutes.favorites),
                        ),
                      ),
                    ],
                  ),
                ),
                if (continueReading.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SectionTitle(title: l10n.libraryContinueReading),
                  ),
                  BookList(
                    books: continueReading,
                    onBookTap: (book) => _open(book.id),
                  ),
                ],
                if (downloaded.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SectionTitle(title: l10n.libraryDownloaded),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
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
                    padding: const EdgeInsets.all(20),
                    child: SectionTitle(
                      title: l10n.libraryFavorites,
                      actionLabel: l10n.actionAll,
                      onAction: () => context.push(AppRoutes.favorites),
                    ),
                  ),
                  BookList(
                    books: favorites,
                    onBookTap: (book) => _open(book.id),
                  ),
                ],
                const SizedBox(height: 48),
              ],
            ),
          ),
    );
  }

  Future<void> _refresh() async {
    // Force rebuild pour rafraichir depuis le state actuel
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 800));
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
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(LuminaRadius.l),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LuminaRadius.l),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: colors.primary, size: 21),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),

                    Icon(
                      AppIcons.chapterNext,
                      color: colors.onSurfaceVariant,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
