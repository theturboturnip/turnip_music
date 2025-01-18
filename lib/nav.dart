import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:turnip_music/library/pages.dart';
import 'package:turnip_music/util/empty_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

enum NavBarRoute {
  library(
    icon: Icons.library_music,
    iconOutlined: Icons.library_music_outlined,
    label: "Library",
    route: "/library",
  ),
  nowPlaying(
    icon: Icons.play_circle,
    iconOutlined: Icons.play_circle_outlined,
    label: "Now Playing",
    route: "/now_playing",
  ),
  queues(
    icon: Icons.queue,
    iconOutlined: Icons.queue_outlined,
    label: "Queues",
    route: "/queues",
  );

  const NavBarRoute({
    required this.icon,
    required this.iconOutlined,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData iconOutlined;
  final String label;
  final String route;
}

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: NavBarRoute.library.route,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            onDestinationSelected: (int index) {
              context.go(NavBarRoute.values[index].route);
            },
            selectedIndex: navigationShell.currentIndex,
            destinations: NavBarRoute.values
                .map(
                  (page) => NavigationDestination(
                    icon: Icon((page.index == navigationShell.currentIndex) ? page.icon : page.iconOutlined),
                    label: page.label,
                  ),
                )
                .toList(),
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: NavBarRoute.library.route,
              builder: (context, state) => const LibraryPage(),
              routes: [
                GoRoute(
                  path: "import",
                  builder: (context, state) => const LibraryImportPage(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: NavBarRoute.nowPlaying.route,
              builder: (context, state) => const EmptyPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: NavBarRoute.queues.route,
              builder: (context, state) => const EmptyPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
