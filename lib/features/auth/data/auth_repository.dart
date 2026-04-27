import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps the Supabase auth client with the methods the rest of the app
/// actually uses. Callers stay decoupled from `SupabaseClient` so this
/// can be swapped or stubbed in tests.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with email/password. Surface platform-friendly errors to
  /// callers via `AuthException`.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Sign up with email/password. Sends a confirmation email if the
  /// project has email-confirm enabled in the Supabase dashboard.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  /// Anonymous (guest) sign-in. Requires "Anonymous sign-ins" to be
  /// enabled in the Supabase dashboard → Authentication → Providers.
  Future<AuthResponse> signInAnonymously() {
    return _client.auth.signInAnonymously();
  }

  Future<void> signOut() => _client.auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

/// Stream of the current `User?`. Emits the cached current user
/// immediately, then yields on every auth state change.
final authStateProvider = StreamProvider<User?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  yield repo.currentUser;
  await for (final state in repo.authStateChanges) {
    yield state.session?.user;
  }
});
