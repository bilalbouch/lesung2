import 'package:flutter/material.dart';

import '../design_system/tokens/app_breakpoints.dart';
import '../design_system/tokens/app_icons.dart';
import '../l10n/generated/app_localizations.dart';

/// Destination de l'application (barre du bas / rail latéral).
class AppDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

/// Destinations principales (ordre stable).
List<AppDestination> appDestinations(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return [
    AppDestination(
        label: l10n.tabHome,
        icon: AppIcons.home,
        selectedIcon: AppIcons.homeFilled),
    AppDestination(
        label: l10n.tabSearch,
        icon: AppIcons.search,
        selectedIcon: AppIcons.search),
    AppDestination(
        label: l10n.tabLibrary,
        icon: AppIcons.library,
        selectedIcon: AppIcons.libraryFilled),
    AppDestination(
        label: l10n.tabDownloads,
        icon: AppIcons.downloads,
        selectedIcon: AppIcons.downloadsFilled),
    AppDestination(
        label: l10n.tabMore,
        icon: AppIcons.settings,
        selectedIcon: AppIcons.settings),
  ];
}

/// Navigation adaptative : NavigationBar sur téléphone, NavigationRail
/// sur tablette. Même source de destinations, mêmes tokens.
class AppNavigationScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const AppNavigationScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tablet = AppBreakpoints.isTablet(context);
    final destinations = appDestinations(context);

    if (tablet) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
            ),
            VerticalDivider(width: 1, color: colors.outlineVariant),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
