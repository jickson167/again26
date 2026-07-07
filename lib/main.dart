import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'router/app_router.dart';
import 'services/app_services.dart';
import 'services/nation_flag_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  AppServices? services;

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    services = AppServices(Supabase.instance.client);
    NationFlagService.instance.ensureLoaded();
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
        if (!SupabaseConfig.isConfigured) {
          return _SetupRequiredScreen(child: child);
        }
        if (child == null) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('앱 불러오는 중...'),
                ],
              ),
            ),
          );
        }
        return child;
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
