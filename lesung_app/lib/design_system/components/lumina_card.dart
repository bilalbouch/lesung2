import 'package:flutter/material.dart';
import '../tokens/lumina_colors.dart';
import '../tokens/lumina_radius.dart';
import '../tokens/lumina_shadows.dart';

/// Card livre — Grille (défaut) ou Liste
class LuminaBookCard extends StatelessWidget {
  final String? coverUrl;
  final String title;
  final String? author;
  final String? tag;
  final bool isFavorite;
  final double? progress;
  final VoidCallback? onTap;
  final LuminaCardLayout layout;
  final int? animationIndex;

  const LuminaBookCard({
    super.key,
    this.coverUrl,
    required this.title,
    this.author,
    this.tag,
    this.isFavorite = false,
    this.progress,
    this.onTap,
    this.layout = LuminaCardLayout.grid,
    this.animationIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card;
    if (layout == LuminaCardLayout.list) {
      card = _buildListCard(context, isDark);
    } else {
      card = _buildGridCard(context, isDark);
    }

    if (animationIndex != null) {
      final delay = Duration(milliseconds: 40 * animationIndex!);
      return FutureBuilder(
        future: Future.delayed(delay),
        builder: (context, snapshot) {
          final isReady = snapshot.connectionState == ConnectionState.done;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: isReady ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 12),
                  child: card,
                ),
              );
            },
          );
        },
      );
    }

    return card;
  }

  Widget _buildGridCard(BuildContext context, bool isDark) {
    final bg = isDark ? LuminaColorsDark.surface : LuminaColors.surface;
    final textPri = isDark ? LuminaColorsDark.textPrimary : LuminaColors.textPrimary;
    final textSec = isDark ? LuminaColorsDark.textSecondary : LuminaColors.textSecondary;
    final shadows = isDark ? LuminaShadows.darkLevel1 : LuminaShadows.level1;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(LuminaRadius.l),
          boxShadow: shadows,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(LuminaRadius.l)),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: Container(
                  color: isDark ? LuminaColorsDark.surfaceSubtle : LuminaColors.surfaceSubtle,
                  child: coverUrl != null
                      ? Image.network(coverUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.book, size: 48, color: LuminaColors.textTertiary),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: textPri,
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (author != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      author!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textSec),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (tag != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? LuminaColorsDark.primarySubtle : LuminaColors.primarySubtle,
                        borderRadius: BorderRadius.circular(LuminaRadius.xs),
                      ),
                      child: Text(
                        tag!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDark ? LuminaColorsDark.primary : LuminaColors.primary,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Progress overlay
            if (progress != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: isDark ? LuminaColorsDark.primary : LuminaColors.primary,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(LuminaRadius.l),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, bool isDark) {
    final bg = isDark ? LuminaColorsDark.surface : LuminaColors.surface;
    final textPri = isDark ? LuminaColorsDark.textPrimary : LuminaColors.textPrimary;
    final textSec = isDark ? LuminaColorsDark.textSecondary : LuminaColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(LuminaRadius.m),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(LuminaRadius.s),
              child: Container(
                width: 56,
                height: 84,
                color: isDark ? LuminaColorsDark.surfaceSubtle : LuminaColors.surfaceSubtle,
                child: coverUrl != null
                    ? Image.network(coverUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.book, size: 24, color: LuminaColors.textTertiary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: textPri,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (author != null)
                    Text(
                      author!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSec),
                    ),
                ],
              ),
            ),
            if (isFavorite)
              Icon(Icons.favorite, size: 20, color: isDark ? LuminaColorsDark.accent : LuminaColors.accent),
          ],
        ),
      ),
    );
  }
}

enum LuminaCardLayout { grid, list }
