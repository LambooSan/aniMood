import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/home/home_screen.dart';
import 'features/library/library_screen.dart';
import 'features/player/player_screen.dart';
import 'features/reader/reader_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'platform/adaptive_scaffold.dart';

/// Роутинг приложения. Home/Search/Library/Settings живут внутри
/// [AdaptiveScaffold] (общая навигация, docs/architecture.md, п.9);
/// Player/Reader открываются поверх, на весь экран — как самостоятельные
/// Core Engine экраны (docs/architecture.md, п.4).
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, __) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (_, __) => const LibraryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/player/:sourceId/:entryId',
      builder: (context, state) => PlayerScreen(
        sourceId: state.pathParameters['sourceId']!,
        entryId: state.pathParameters['entryId']!,
      ),
    ),
    GoRoute(
      path: '/reader/:entryId',
      builder: (context, state) =>
          ReaderScreen(entryId: state.pathParameters['entryId']!),
    ),
  ],
);

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      destinations: const [
        AdaptiveDestination(icon: Icons.home, label: 'Главная'),
        AdaptiveDestination(icon: Icons.search, label: 'Поиск'),
        AdaptiveDestination(icon: Icons.bookmark, label: 'Библиотека'),
        AdaptiveDestination(icon: Icons.settings, label: 'Настройки'),
      ],
      body: navigationShell,
    );
  }
}
