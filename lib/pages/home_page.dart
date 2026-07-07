import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.disabled = false});

  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Again26 - 축구 매니저'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.sports_soccer, size: 72, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  '축구 매니저 MVP',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '선수·포메이션·키포지션 마스터 데이터를 관리하고 조회할 수 있습니다.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: disabled ? null : () => context.go('/game'),
                  icon: const Icon(Icons.sports_esports),
                  label: const Text('게임 시작'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: disabled ? null : () => context.go('/players'),
                  icon: const Icon(Icons.people),
                  label: const Text('선수 목록'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: disabled ? null : () => context.go('/admin'),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('매니저 데이터 관리'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
