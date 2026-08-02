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
      pageBuilder: (context, state) => CustomTransitionPage(
        child: BookDetailsScreen(
          item: state.extra as SearchResultItem,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.05);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var fadeTween = Tween<double>(begin: 0.0, end: 1.0);
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.reader,
      parentNavigatorKey: _rootKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: ReaderScreen(book: state.extra as ReaderBookArgs),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.favorites,
      parentNavigatorKey: _rootKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const FavoritesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.collections,
      parentNavigatorKey: _rootKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const CollectionsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.history,
      parentNavigatorKey: _rootKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const HistoryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
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
