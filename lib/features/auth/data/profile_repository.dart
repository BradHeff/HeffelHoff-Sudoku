import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

/// Snapshot of a row from `public.profiles`. The leaderboard reads
/// `display_name` (the *public* username) from here. Email is
/// deliberately not stored on this domain object — it lives only in
/// `auth.users` and is never exposed to other players.
@immutable
class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.isAnonymous,
    required this.isPro,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final bool isAnonymous;
  final bool isPro;
  final DateTime updatedAt;

  factory Profile.fromRow(Map<String, dynamic> row) => Profile(
        id: row['id'] as String,
        displayName: row['display_name'] as String? ?? '',
        isAnonymous: row['is_anonymous'] as bool? ?? false,
        isPro: row['is_pro'] as bool? ?? false,
        updatedAt: DateTime.parse(
          row['updated_at'] as String? ?? row['created_at'] as String,
        ),
      );

  /// True when the user is still on the auto-generated placeholder name.
  /// Used by the AccountSheet to prompt them to pick a username.
  bool get isPlaceholderName => RegExp(r'^Player[0-9a-fA-F]{4}$').hasMatch(displayName);
}

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  Future<Profile?> fetch(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return Profile.fromRow(row);
  }

  /// Update the public username. Server-side check constraint enforces
  /// 2-24 chars; client-side validation in [validateUsername] catches
  /// other risks (e.g. an `@` symbol that would re-leak email-shaped
  /// strings).
  Future<void> updateDisplayName({
    required String userId,
    required String name,
  }) async {
    await _client
        .from('profiles')
        .update({'display_name': name})
        .eq('id', userId);
  }

  /// Returns null if [name] is acceptable, else a short error message
  /// suitable for showing under the input field.
  static String? validateUsername(String raw) {
    final name = raw.trim();
    if (name.length < 2) return 'Username must be at least 2 characters.';
    if (name.length > 24) return 'Username must be at most 24 characters.';
    if (name.contains('@')) return "Don't include @ — keep your email private.";
    if (RegExp(r'\s{2,}').hasMatch(name)) {
      return 'Avoid multiple spaces in a row.';
    }
    return null;
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

/// Profile of the currently signed-in user. Null when no auth session.
/// Re-fetches whenever the auth user changes; callers can also call
/// `ref.invalidate(currentProfileProvider)` after a successful update
/// to refresh.
final currentProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return null;
  final repo = ref.watch(profileRepositoryProvider);
  return repo.fetch(user.id);
});
