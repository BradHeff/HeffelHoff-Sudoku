import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../../sudoku/domain/difficulty.dart';

/// The user's single highest leaderboard row, regardless of tier — used
/// by the home-screen "progression vs Einstein" header.
class BestIqEntry {
  const BestIqEntry({required this.iq, required this.tier});
  final int iq;
  final Difficulty tier;
}

/// Returns the user's best leaderboard row across all tiers, or null
/// when the user has no entries yet (fresh anonymous session, or
/// signed out). Re-fetches when the auth user changes.
final userBestIqProvider =
    FutureProvider.autoDispose<BestIqEntry?>((ref) async {
  // Re-evaluate when auth state changes (sign-in / sign-out / link).
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return null;

  final client = Supabase.instance.client;
  final rows = await client
      .from('leaderboard_entries')
      .select('best_iq, difficulty')
      .eq('user_id', user.id)
      .order('best_iq', ascending: false)
      .order('achieved_at', ascending: true)
      .limit(1);
  if (rows.isEmpty) return null;
  final row = rows.first;
  final tier = Difficulty.values.firstWhere(
    (d) => d.id == row['difficulty'] as String,
    orElse: () => Difficulty.easy,
  );
  return BestIqEntry(iq: row['best_iq'] as int, tier: tier);
});
