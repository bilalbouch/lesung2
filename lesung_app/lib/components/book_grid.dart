import 'package:flutter/material.dart';

import '../design_system/tokens/app_breakpoints.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import 'app_animations.dart';
import 'book_card.dart';
import 'book_cover.dart';

/// Élément d'une grille/liste de livres (modèle de présentation).
class BookItem {
  final String id;
  final String title;
  final String? author;
  final String? coverUrl;
  final String? badge;
  final double? progress;

  const BookItem({
    required this.id,
    required this.title,
    this.author,
    this.coverUrl,
    this.badge,
    this.progress,
  });
}

/// Grille adaptative de livres — colonnes selon [AppBreakpoints].
class BookGrid extends StatelessWidget {
  final List<BookItem> books;
  final void Function(BookItem book)? onBookTap;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const BookGrid({
    super.key,
    required this.books,
    this.onBookTap,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = AppBreakpoints.gridColumns(constraints.maxWidth);
        final spacing = AppSpacing.l;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.xl,
            crossAxisSpacing: spacing,
            // Hauteur : couverture 2:3 + zone texte.
            childAspectRatio: itemWidth / (itemWidth / BookCover.aspectRatio + 64),
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return BookCard(
              title: book.title,
              author: book.author,
              coverUrl: book.coverUrl,
              badge: book.badge,
              progress: book.progress,
              coverWidth: itemWidth,
              onTap: onBookTap == null ? null : () => onBookTap!(book),
            );
          },
        );
      },
    );
  }
}

/// Liste horizontale de livres (sections d'accueil).
class BookList extends StatelessWidget {
  final List<BookItem> books;
  final void Function(BookItem book)? onBookTap;
  final double coverWidth;

  const BookList({
    super.key,
    required this.books,
    this.onBookTap,
    this.coverWidth = 116,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: coverWidth / BookCover.aspectRatio + 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        itemCount: books.length,
        separatorBuilder: (_, __) => AppSpacing.hGapL,
        itemBuilder: (context, index) {
          final book = books[index];
          return BookCard(
            title: book.title,
            author: book.author,
            coverUrl: book.coverUrl,
            badge: book.badge,
            progress: book.progress,
            coverWidth: coverWidth,
            onTap: onBookTap == null ? null : () => onBookTap!(book),
          );
        },
      ),
    );
  }
}

/// Ligne de livre (résultats, listes denses).
class BookListTile extends StatelessWidget {
  final BookItem book;
  final String? trailing;
  final VoidCallback? onTap;

  const BookListTile({
    super.key,
    required this.book,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return AppAnimations.pressScale(
      onTap: onTap,
      child: Padding(
        padding: AppSpacing.listItem,
        child: Row(
          children: [
            BookCover(
                title: book.title, coverUrl: book.coverUrl, width: 48),
            AppSpacing.hGapM,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      style: textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (book.author != null && book.author!.isNotEmpty)
                    Text(book.author!,
                        style: textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (trailing != null)
              Text(trailing!,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colors.inkTertiary)),
          ],
        ),
      ),
    );
  }
}
