import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/admin/admin_coach_form_page.dart';
import '../pages/admin/admin_coach_generator_page.dart';
import '../pages/admin/admin_coach_portrait_generator_page.dart';
import '../pages/admin/admin_flag_nation_mapper_page.dart';
import '../pages/admin/admin_hub_page.dart';
import '../pages/admin/admin_player_form_page.dart';
import '../pages/admin/admin_player_generator_page.dart';
import '../pages/admin/admin_player_portrait_generator_page.dart';
import '../pages/game/game_page.dart';
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
    redirect: (context, state) {
      final path = state.uri.path;
      if (path.contains('error=') || path.startsWith('/error')) {
        return '/';
      }
      if (path == '/admin/') {
        return '/admin';
      }
      return null;
    },
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '페이지를 찾을 수 없습니다',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.error?.toString() ?? '알 수 없는 오류',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => context.go('/'),
                    child: const Text('게임 홈으로'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => GamePage(services: services),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) => GamePage(services: services),
      ),
      GoRoute(
        path: '/players',
        builder: (context, state) =>
            PlayerListPage(
              playerService: services.playerService,
              playerStyleService: services.playerStyleService,
            ),
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
      GoRoute(
        path: '/admin',
        builder: (context, state) => AdminHubPage(
          services: services,
          initialTab: state.uri.queryParameters['tab'],
          coachesRefreshToken: state.uri.queryParameters['coachesRefresh'],
        ),
        routes: [
          GoRoute(
            path: 'player-generator',
            builder: (context, state) => const AdminPlayerGeneratorPage(),
          ),
          GoRoute(
            path: 'coach-generator',
            builder: (context, state) => const AdminCoachGeneratorPage(),
          ),
          GoRoute(
            path: 'player-portrait-generator',
            builder: (context, state) => AdminPlayerPortraitGeneratorPage(
              services: services,
            ),
          ),
          GoRoute(
            path: 'coach-portrait-generator',
            builder: (context, state) => AdminCoachPortraitGeneratorPage(
              services: services,
            ),
          ),
          GoRoute(
            path: 'flag-nation-mapper',
            builder: (context, state) => const AdminFlagNationMapperPage(),
          ),
          GoRoute(
            path: 'coaches/new',
            builder: (context, state) => AdminCoachFormPage(
              services: services,
            ),
          ),
          GoRoute(
            path: 'coaches/:id/edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AdminCoachFormPage(
                services: services,
                coachId: id,
              );
            },
          ),
          GoRoute(
            path: 'new',
            builder: (context, state) => AdminPlayerFormPage(
              playerService: services.playerService,
              playerStyleService: services.playerStyleService,
            ),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AdminPlayerFormPage(
                playerService: services.playerService,
                playerStyleService: services.playerStyleService,
                playerId: id,
              );
            },
          ),
        ],
      ),
    ],
  );
}
