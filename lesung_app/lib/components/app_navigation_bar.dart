import 'package:flutter/material.dart';

import '../design_system/tokens/app_breakpoints.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_icons.dart';

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
const appDestinations = [
  AppDestination(
      label: 'Start',
      icon: AppIcons.home,
      selectedIcon: AppIcons.homeFilled),
  AppDestination(
      label: 'Suche',
      icon: AppIcons.search,
      selectedIcon: AppIcons.search),
  AppDestination(
      label: 'Bibliothek',
      icon: AppIcons.library,
      selectedIcon: AppIcons.libraryFilled),
  AppDestination(
      label: 'Downloads',
      icon: AppIcons.downloads,
      selectedIcon: AppIcons.downloadsFilled),
  AppDestination(
      label: 'Mehr',
      icon: AppIcons.settings,
      selectedIcon: AppIcons.settings),
];

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
    final colors = AppColors.of(context);
    final tablet = AppBreakpoints.isTablet(context);

    if (tablet) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final destination in appDestinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
            ),
            VerticalDivider(width: 1, color: colors.divider),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          for (final destination in appDestinations)
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
