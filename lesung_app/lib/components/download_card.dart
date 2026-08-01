import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_icons.dart';
import '../design_system/tokens/app_spacing.dart';
import 'app_progress_indicator.dart';
import 'book_cover.dart';

/// État d'affichage d'une carte de téléchargement.
enum DownloadCardState { active, paused, completed, failed }

/// Carte de téléchargement — couverture, progression temps réel,
/// vitesse/ETA, actions (pause/reprendre/annuler).
class DownloadCard extends StatelessWidget {
  final String title;
  final String? author;
  final String? coverUrl;
  final DownloadCardState state;
  final double progress;
  final String? subtitle;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onOpen;

  const DownloadCard({
    super.key,
    required this.title,
    this.author,
    this.coverUrl,
    required this.state,
    required this.progress,
    this.subtitle,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onRetry,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final completed = state == DownloadCardState.completed;

    return Card(
      child: InkWell(
        onTap: completed ? onOpen : null,
        borderRadius: AppRadiusTweaks.card,
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            children: [
              BookCover(title: title, coverUrl: coverUrl, width: 44),
              AppSpacing.hGapM,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (author != null && author!.isNotEmpty)
                      Text(author!,
                          style: textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    AppSpacing.gapS,
                    if (!completed) ...[
                      AppProgressIndicator(value: progress.clamp(0.0, 1.0)),
                      AppSpacing.gapXs,
                    ],
                    Text(
                      subtitle ?? _defaultSubtitle(),
                      style: textTheme.bodySmall
                          ?.copyWith(color: colors.inkTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ..._actions(context),
            ],
          ),
        ),
      ),
    );
  }

  String _defaultSubtitle() => switch (state) {
        DownloadCardState.active =>
          '${(progress * 100).toStringAsFixed(0)} %',
        DownloadCardState.paused => 'Pausiert',
        DownloadCardState.completed => 'Abgeschlossen',
        DownloadCardState.failed => 'Fehlgeschlagen',
      };

  List<Widget> _actions(BuildContext context) {
    final colors = AppColors.of(context);
    IconData iconFor(VoidCallback? action, IconData active, IconData alt) =>
        action != null ? active : alt;
    switch (state) {
      case DownloadCardState.active:
        return [
          IconButton(
              icon: const Icon(AppIcons.pause),
              color: colors.inkSecondary,
              onPressed: onPause),
          IconButton(
              icon: const Icon(AppIcons.cancel),
              color: colors.inkSecondary,
              onPressed: onCancel),
        ];
      case DownloadCardState.paused:
        return [
          IconButton(
              icon: Icon(iconFor(onResume, AppIcons.play, AppIcons.play)),
              color: colors.accent,
              onPressed: onResume),
          IconButton(
              icon: const Icon(AppIcons.cancel),
              color: colors.inkSecondary,
              onPressed: onCancel),
        ];
      case DownloadCardState.failed:
        return [
          IconButton(
              icon: const Icon(AppIcons.download),
              color: colors.accent,
              onPressed: onRetry),
        ];
      case DownloadCardState.completed:
        return [
          Icon(AppIcons.check, color: colors.success, size: AppIcons.sizeM),
        ];
    }
  }
}

/// Alias interne pour le rayon de carte (évite une dépendance circulaire
/// d'import dans certains fichiers).
class AppRadiusTweaks {
  static const card = BorderRadius.all(Radius.circular(14));
}
