import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/home_page.dart';
import '../pages/players/player_detail_page.dart';
import '../pages/players/player_list_page.dart';
import '../services/app_services.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter({required AppServices? services}) {
  if (services == null) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(disabled: true),
        ),
      ],
    );
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/players',
        builder: (context, state) =>
            PlayerListPage(playerService: services.playerService),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PlayerDetailPage(
                services: services,
                playerId: id,
              );
            },
          ),
        ],
      ),
    ],
  );
}
