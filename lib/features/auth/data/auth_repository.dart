import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// Custom URI scheme the OAuth providers redirect back to. Must match
  /// the intent-filter in `android/app/src/main/AndroidManifest.xml`
  /// AND be added to the Supabase dashboard's "Redirect URLs" allowlist
  /// (Authentication → URL Configuration).
  static const String _oauthRedirect =
      'heffelhoffsudoku://auth-callback';

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInAnonymously() {
    return _client.auth.signInAnonymously();
  }

  /// Launches the Google OAuth flow in the system browser. The callback
  /// returns to the app via the [_oauthRedirect] deep link, which the
  /// Supabase SDK auto-completes — `currentUser` is non-null shortly after.
  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _oauthRedirect,
    );
  }

  /// Launches the Apple OAuth flow. On iOS this still uses the system
  /// browser (sufficient for v1; native sign_in_with_apple would be a
  /// later polish pass — Apple App Review accepts the browser flow as
  /// long as Sign in with Apple is offered when other social providers
  /// are present).
  Future<bool> signInWithApple() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: _oauthRedirect,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final authStateProvider = StreamProvider<User?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  yield repo.currentUser;
  await for (final state in repo.authStateChanges) {
    yield state.session?.user;
  }
});
