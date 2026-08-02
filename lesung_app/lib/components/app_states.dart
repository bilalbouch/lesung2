import 'package:flutter/material.dart';

import '../design_system/tokens/app_icons.dart';
import '../l10n/generated/app_localizations.dart';
import 'action_button.dart';
import 'app_progress_indicator.dart';

/// ÉTATS PREMIUM — aucun écran vide « mort ».
///
/// Chaque état : icône sobre dans un disque teinté, titre serif,
/// message secondaire discret, action optionnelle.
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

  factory AppEmptyState.noResults(
      {Key? key, required BuildContext context, required String query}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      key: key,
      icon: AppIcons.search,
      title: l10n.searchNoResults(query),
      message: l10n.searchNoResultsMessage,
    );
  }

  factory AppEmptyState.offline(
      {Key? key, required BuildContext context, VoidCallback? onRetry}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      key: key,
      icon: AppIcons.offline,
      title: l10n.errorOfflineTitle,
      message: l10n.errorOfflineMessage,
      actionLabel: l10n.actionRetry,
      onAction: onRetry,
    );
  }

  factory AppEmptyState.emptyLibrary(
      {Key? key, required BuildContext context, VoidCallback? onExplore}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      key: key,
      icon: AppIcons.library,
      title: l10n.libraryEmpty,
      message: l10n.libraryEmptyMessage,
      actionLabel: l10n.libraryExplore,
      onAction: onExplore,
    );
  }

  factory AppEmptyState.noDownloads(
      {Key? key, required BuildContext context}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      key: key,
      icon: AppIcons.downloads,
      title: l10n.downloadsEmpty,
      message: l10n.downloadsEmptyMessage,
    );
  }

  factory AppEmptyState.noFavorites(
      {Key? key, required BuildContext context}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      key: key,
      icon: AppIcons.favorite,
      title: l10n.favoritesEmpty,
      message: l10n.favoritesEmptyMessage,
    );
  }

  factory AppEmptyState.noHistory(
      {Key? key, required BuildContext context}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      key: key,
      icon: AppIcons.history,
      title: l10n.historyEmpty,
      message: l10n.historyEmptyMessage,
    );
  }

  factory AppEmptyState.emptyCollection(
      {Key? key, required BuildContext context}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      key: key,
      icon: AppIcons.collection,
      title: l10n.collectionEmpty,
      message: l10n.collectionEmptyMessage,
    );
  }

  factory AppEmptyState.errorNetwork(
      {Key? key, required BuildContext context, VoidCallback? onRetry}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      key: key,
      icon: AppIcons.error,
      title: l10n.errorNetworkTitle,
      message: l10n.errorNetworkMessage,
      actionLabel: l10n.actionRetry,
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedItem(
              delay: const Duration(milliseconds: 0),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.primary, size: 30),
              ),
            ),
            const SizedBox(height: 32),
            _AnimatedItem(
              delay: const Duration(milliseconds: 100),
              child: Text(title,
                  style: textTheme.titleLarge, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            _AnimatedItem(
              delay: const Duration(milliseconds: 200),
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              _AnimatedItem(
                delay: const Duration(milliseconds: 300),
                child: ActionButton(
                    label: actionLabel!,
                    variant: ActionButtonVariant.secondary,
                    onPressed: onAction),
              ),
            ],
          ],
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
            const SizedBox(height: 24),
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

/// Widget interne pour animer les items de l'empty state avec stagger.
class _AnimatedItem extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedItem({required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        final isReady = snapshot.connectionState == ConnectionState.done;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: isReady ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 16),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}
