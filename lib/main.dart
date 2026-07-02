import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'router/app_router.dart';
import 'services/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppServices? services;

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    services = AppServices(Supabase.instance.client);
  }

  runApp(Again26App(services: services));
}

class Again26App extends StatelessWidget {
  const Again26App({super.key, this.services});

  final AppServices? services;

  @override
  Widget build(BuildContext context) {
    final router = createRouter(services: services);

    return MaterialApp.router(
      title: 'Again26 - 축구 매니저',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
      builder: (context, child) {
        if (SupabaseConfig.isConfigured) {
          return child ?? const SizedBox.shrink();
        }

        return _SetupRequiredScreen(child: child);
      },
    );
  }
}

class _SetupRequiredScreen extends StatelessWidget {
  const _SetupRequiredScreen({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.settings, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Supabase 설정 필요',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Flutter Web 실행 시 dart-define으로 Supabase URL과 anon key를 전달하세요.\n\n'
                  'flutter run -d chrome '
                  '--dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co '
                  '--dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
