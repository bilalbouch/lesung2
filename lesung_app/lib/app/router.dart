import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lesung/features/search/domain/entities/search_result.dart';

import '../components/app_navigation_bar.dart';
import '../features/book_details/book_details_screen.dart';
import '../features/collections/collections_screen.dart';
import '../features/downloads/downloads_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';

/// Routeur — navigation par onglets (shell) + pages poussées.
class AppRoutes {
  static const home = '/home';
  static const search = '/search';
  static const library = '/library';
  static const downloads = '/downloads';
  static const more = '/more';
  static const bookDetails = '/book';
  static const reader = '/reader';
  static const favorites = '/favorites';
  static const collections = '/collections';
  static const history = '/history';
}

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: AppRoutes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _ShellHost(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
              path: AppRoutes.home,
              builder: (_, __) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: AppRoutes.search,
              builder: (_, __) => const SearchScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: AppRoutes.library,
              builder: (_, __) => const LibraryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: AppRoutes.downloads,
              builder: (_, __) => const DownloadsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: AppRoutes.more,
              builder: (_, __) => const SettingsScreen()),
        ]),
      ],
    ),
    GoRoute(
      path: AppRoutes.bookDetails,
      parentNavigatorKey: _rootKey,
      builder: (_, state) => BookDetailsScreen(
        item: state.extra as SearchResultItem,
      ),
    ),
    GoRoute(
      path: AppRoutes.reader,
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          ReaderScreen(book: state.extra as ReaderBookArgs),
    ),
    GoRoute(
      path: AppRoutes.favorites,
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const FavoritesScreen(),
    ),
    GoRoute(
      path: AppRoutes.collections,
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const CollectionsScreen(),
    ),
    GoRoute(
      path: AppRoutes.history,
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const HistoryScreen(),
    ),
  ],
);

final _rootKey = GlobalKey<NavigatorState>();

/// Arguments d'ouverture du Reader.
class ReaderBookArgs {
  final String bookId;
  final String filePath;
  final String? title;

  const ReaderBookArgs({
    required this.bookId,
    required this.filePath,
    this.title,
  });
}

class _ShellHost extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _ShellHost({required this.shell});

  @override
  Widget build(BuildContext context) {
    return AppNavigationScaffold(
      currentIndex: shell.currentIndex,
      onDestinationSelected: (index) => shell.goBranch(
        index,
        initialLocation: index == shell.currentIndex,
      ),
      child: shell,
    );
  }
}
