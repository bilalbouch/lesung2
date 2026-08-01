import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_icons.dart';
import '../design_system/tokens/app_radius.dart';
import '../design_system/tokens/app_spacing.dart';
import 'app_animations.dart';

/// Carte de collection — mosaïque discrète de couvertures (jusqu'à 4)
/// ou icône dossier, nom serif, compteur secondaire.
class CollectionCard extends StatelessWidget {
  final String name;
  final int bookCount;
  final List<String> coverUrls;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CollectionCard({
    super.key,
    required this.name,
    required this.bookCount,
    this.coverUrls = const [],
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return AppAnimations.pressScale(
      onTap: onTap,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          padding: AppSpacing.card,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: colors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.accentSubtle,
                  borderRadius: AppRadius.cardSmall,
                ),
                child: Icon(AppIcons.collection, color: colors.accent),
              ),
              AppSpacing.hGapM,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '$bookCount ${bookCount == 1 ? 'Buch' : 'Bücher'}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(AppIcons.chapterNext, color: colors.inkTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
