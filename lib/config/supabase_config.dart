import 'runtime_config.dart';

class SupabaseConfig {
  static String get url {
    const fromEnv = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return readRuntimeConfig('SUPABASE_URL') ?? '';
  }

  static String get anonKey {
    const fromEnv = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return readRuntimeConfig('SUPABASE_ANON_KEY') ?? '';
  }

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
