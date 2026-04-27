import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

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

  /// True when display_name is still the auto-generated Player####.
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

  Future<void> updateDisplayName({
    required String userId,
    required String name,
  }) async {
    await _client
        .from('profiles')
        .update({'display_name': name})
        .eq('id', userId);
  }

  /// Returns null if the username is acceptable, else a short error.
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

final currentProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return null;
  final repo = ref.watch(profileRepositoryProvider);
  return repo.fetch(user.id);
});
