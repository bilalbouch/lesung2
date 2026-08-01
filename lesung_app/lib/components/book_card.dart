import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import 'app_animations.dart';
import 'book_cover.dart';

/// Carte livre — verticale (couverture dominante) ou horizontale.
/// La couverture reste l'élément principal ; les métadonnées sont
/// volontairement discrètes.
class BookCard extends StatelessWidget {
  final String title;
  final String? author;
  final String? coverUrl;
  final String? badge;
  final double? progress;
  final VoidCallback? onTap;
  final double coverWidth;

  const BookCard({
    super.key,
    required this.title,
    this.author,
    this.coverUrl,
    this.badge,
    this.progress,
    this.onTap,
    this.coverWidth = 120,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return AppAnimations.pressScale(
      onTap: onTap,
      child: SizedBox(
        width: coverWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                BookCover(title: title, coverUrl: coverUrl, width: coverWidth),
                if (badge != null)
                  Positioned(
                    top: AppSpacing.xs,
                    left: AppSpacing.xs,
                    child: _Badge(label: badge!),
                  ),
                if (progress != null && progress! > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: colors.scrim,
                      valueColor:
                          AlwaysStoppedAnimation(colors.onAccent),
                    ),
                  ),
              ],
            ),
            AppSpacing.gapS,
            Text(
              title,
              style: textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (author != null && author!.isNotEmpty)
              Text(
                author!,
                style: textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: colors.inkSecondary, fontSize: 9),
      ),
    );
  }
}
