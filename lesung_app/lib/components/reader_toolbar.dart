import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_icons.dart';
import '../design_system/tokens/app_motion.dart';
import '../design_system/tokens/app_spacing.dart';

/// Barre d'outils du Reader — apparaît/disparaît au tap central.
///
/// Haut : retour, titre du chapitre, recherche dans le livre, options.
/// Bas : chapitre précédent, progression, chapitre suivant, réglages.
class ReaderToolbar extends StatelessWidget {
  final bool visible;
  final String? chapterTitle;
  final double progress;
  final VoidCallback? onBack;
  final VoidCallback? onSearch;
  final VoidCallback? onToc;
  final VoidCallback? onSettings;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;
  final VoidCallback? onBookmark;
  final bool bookmarked;

  const ReaderToolbar({
    super.key,
    required this.visible,
    this.chapterTitle,
    this.progress = 0,
    this.onBack,
    this.onSearch,
    this.onToc,
    this.onSettings,
    this.onPreviousChapter,
    this.onNextChapter,
    this.onBookmark,
    this.bookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -1),
      duration: AppDurations.normal,
      curve: AppMotion.standard,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppDurations.fast,
        child: Container(
          color: colors.surface,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                      icon: const Icon(AppIcons.back), onPressed: onBack),
                  Expanded(
                    child: Text(
                      chapterTitle ?? '',
                      style: textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                      icon: const Icon(AppIcons.searchInBook),
                      onPressed: onSearch),
                  IconButton(
                      icon: const Icon(AppIcons.toc), onPressed: onToc),
                  IconButton(
                    icon: Icon(bookmarked
                        ? AppIcons.bookmarkFilled
                        : AppIcons.bookmark),
                    color: bookmarked ? colors.accent : null,
                    onPressed: onBookmark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barre inférieure du Reader (navigation chapitres + progression).
class ReaderBottomBar extends StatelessWidget {
  final bool visible;
  final double progress;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;
  final VoidCallback? onSettings;

  const ReaderBottomBar({
    super.key,
    required this.visible,
    required this.progress,
    this.onPreviousChapter,
    this.onNextChapter,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1),
      duration: AppDurations.normal,
      curve: AppMotion.standard,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppDurations.fast,
        child: Container(
          color: colors.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                      icon: const Icon(AppIcons.chapterPrev),
                      onPressed: onPreviousChapter),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: colors.accent,
                        inactiveTrackColor: colors.surfaceAlt,
                        thumbColor: colors.accent,
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (_) {}, // lecture seule (v1)
                      ),
                    ),
                  ),
                  IconButton(
                      icon: const Icon(AppIcons.chapterNext),
                      onPressed: onNextChapter),
                  IconButton(
                      icon: const Icon(AppIcons.fontSize),
                      onPressed: onSettings),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
