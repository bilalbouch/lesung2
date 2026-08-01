import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_icons.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'action_button.dart';
import 'app_animations.dart';
import 'app_progress_indicator.dart';

/// ÉTATS PREMIUM — aucun écran vide « mort ».
///
/// Chaque état : icône sobre dans un disque teinté, titre serif,
/// message secondaire discret, action optionnelle. Les textes sont en
/// allemand (langue principale), prêts pour l'i18n de l'application.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  // ---------------- États prédéfinis --------------------------------

  factory AppEmptyState.noResults({Key? key, required String query}) => AppEmptyState(
        key: key,
        icon: AppIcons.search,
        title: 'Keine Treffer',
        message: 'Für „$query“ wurde nichts gefunden.\n'
            'Versuche einen anderen Titel oder Autor.',
      );

  factory AppEmptyState.offline({Key? key, VoidCallback? onRetry}) => AppEmptyState(
        key: key,
        icon: AppIcons.offline,
        title: 'Offline',
        message: 'Keine Verbindung. Deine Bibliothek bleibt verfügbar.',
        actionLabel: 'Erneut versuchen',
        onAction: onRetry,
      );

  factory AppEmptyState.emptyLibrary({Key? key, VoidCallback? onExplore}) =>
      AppEmptyState(
        key: key,
        icon: AppIcons.library,
        title: 'Deine Bibliothek ist leer',
        message: 'Suche ein Buch und lade es herunter —\n'
            'es erscheint hier.',
        actionLabel: 'Entdecken',
        onAction: onExplore,
      );

  factory AppEmptyState.noDownloads({Key? key}) => AppEmptyState(
        key: key,
        icon: AppIcons.downloads,
        title: 'Keine Downloads',
        message: 'Heruntergeladene Bücher erscheinen hier.',
      );

  factory AppEmptyState.noFavorites({Key? key}) => AppEmptyState(
        key: key,
        icon: AppIcons.favorite,
        title: 'Keine Favoriten',
        message: 'Markiere Bücher mit dem Herz,\num sie hier zu sammeln.',
      );

  factory AppEmptyState.noHistory({Key? key}) => AppEmptyState(
        key: key,
        icon: AppIcons.history,
        title: 'Noch kein Verlauf',
        message: 'Gelesene Bücher erscheinen hier.',
      );

  factory AppEmptyState.emptyCollection({Key? key}) => AppEmptyState(
        key: key,
        icon: AppIcons.collection,
        title: 'Leere Sammlung',
        message: 'Füge Bücher hinzu, um sie hier zu sehen.',
      );

  factory AppEmptyState.errorNetwork({Key? key, VoidCallback? onRetry}) =>
      AppEmptyState(
        key: key,
        icon: AppIcons.error,
        title: 'Etwas ist schiefgelaufen',
        message: 'Netzwerkfehler. Bitte versuche es erneut.',
        actionLabel: 'Erneut versuchen',
        onAction: onRetry,
      );

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: AppAnimations.fadeIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.accentSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.accent, size: 30),
              ),
              AppSpacing.gapXl,
              Text(title,
                  style: textTheme.titleLarge, textAlign: TextAlign.center),
              AppSpacing.gapM,
              Text(
                message,
                style: textTheme.bodyMedium
                    ?.copyWith(height: AppTypography.heightReading),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                AppSpacing.gapXl,
                ActionButton(
                    label: actionLabel!,
                    variant: ActionButtonVariant.secondary,
                    onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// État de chargement plein écran (avec libellé discret optionnel).
class AppLoadingState extends StatelessWidget {
  final String? label;

  const AppLoadingState({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoadingSpinner(),
          if (label != null) ...[
            AppSpacing.gapL,
            Text(label!, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// État d'erreur plein écran.
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: AppIcons.error,
      title: 'Fehler',
      message: message,
      actionLabel: onRetry == null ? null : 'Erneut versuchen',
      onAction: onRetry,
    );
  }
}
