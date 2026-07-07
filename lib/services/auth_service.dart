import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// OAuth 완료 후 돌아올 앱 URL (로컬·GitHub Pages 모두 Uri.base 기준).
  static String get redirectUrl {
    final uri = Uri.base;
    final path = uri.path.isEmpty ? '/' : uri.path;
    final normalizedPath = path.endsWith('/') ? path : '$path/';
    return '${uri.origin}$normalizedPath';
  }

  /// Supabase Custom Provider identifier (Dashboard에서 동일하게 등록).
  static const naverProvider = OAuthProvider('custom:naver');

  Future<void> _signInWithOAuthProvider(OAuthProvider provider) async {
    await _client.auth.signInWithOAuth(
      provider,
      redirectTo: redirectUrl,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  Future<void> signInWithGoogle() async {
    await _signInWithOAuthProvider(OAuthProvider.google);
  }

  Future<void> signInWithNaver() async {
    await _signInWithOAuthProvider(naverProvider);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
