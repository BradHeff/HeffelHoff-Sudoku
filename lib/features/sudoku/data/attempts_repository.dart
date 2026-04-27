import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/puzzle.dart';

/// Writes the player's completed-puzzle attempt to
/// `public.puzzle_attempts`. The trigger `update_leaderboard_on_attempt`
/// then upserts `leaderboard_entries`.
///
/// Phase 2/3 path: client computes IQ and writes it directly. Phase 5
/// switches this to a server-side recompute via the `submit-attempt`
/// Edge Function so the leaderboard can't be tampered with.
class AttemptsRepository {
  AttemptsRepository(this._client);

  final SupabaseClient _client;

  /// Returns true if the attempt was persisted. Returns false (without
  /// throwing) if no user is signed in — the game stays playable
  /// offline / pre-auth.
  Future<bool> submitWin({
    required Puzzle puzzle,
    required DateTime startedAt,
    required int timeSeconds,
    required int mistakes,
    required int hintsUsed,
    required int livesUsed,
    required int iqScore,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    await _client.from('puzzle_attempts').insert({
      'user_id': user.id,
      'puzzle_seed': puzzle.seed,
      'difficulty': puzzle.difficulty.id,
      'started_at': startedAt.toUtc().toIso8601String(),
      'completed_at': DateTime.now().toUtc().toIso8601String(),
      'time_seconds': timeSeconds,
      'mistakes': mistakes,
      'hints_used': hintsUsed,
      'lives_used': livesUsed,
      'completed': true,
      'failed': false,
      'iq_score_client': iqScore,
      // Phase 2/3 sets iq_score directly so the leaderboard trigger can
      // pick it up. Phase 5 will null this out and let the Edge Function
      // recompute server-side.
      'iq_score': iqScore,
      'client_version': 'phase3-direct-insert',
    });
    return true;
  }

  Future<bool> submitFail({
    required Puzzle puzzle,
    required DateTime startedAt,
    required int timeSeconds,
    required int mistakes,
    required int hintsUsed,
    required int livesUsed,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    await _client.from('puzzle_attempts').insert({
      'user_id': user.id,
      'puzzle_seed': puzzle.seed,
      'difficulty': puzzle.difficulty.id,
      'started_at': startedAt.toUtc().toIso8601String(),
      'completed_at': DateTime.now().toUtc().toIso8601String(),
      'time_seconds': timeSeconds,
      'mistakes': mistakes,
      'hints_used': hintsUsed,
      'lives_used': livesUsed,
      'completed': false,
      'failed': true,
      'client_version': 'phase3-direct-insert',
    });
    return true;
  }
}

final attemptsRepositoryProvider = Provider<AttemptsRepository>((ref) {
  return AttemptsRepository(Supabase.instance.client);
});
