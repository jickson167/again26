import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/admin/admin_player_form_page.dart';
import '../pages/admin/admin_player_list_page.dart';
import '../pages/home_page.dart';
import '../pages/players/player_detail_page.dart';
import '../pages/players/player_list_page.dart';
import '../services/player_service.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter({required PlayerService? playerService}) {
  if (playerService == null) {
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
        builder: (context, state) => PlayerListPage(playerService: playerService),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PlayerDetailPage(
                playerService: playerService,
                playerId: id,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => AdminPlayerListPage(playerService: playerService),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => AdminPlayerFormPage(
              playerService: playerService,
            ),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AdminPlayerFormPage(
                playerService: playerService,
                playerId: id,
              );
            },
          ),
        ],
      ),
    ],
  );
}
