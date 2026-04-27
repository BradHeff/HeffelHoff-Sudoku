import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/puzzle.dart';

class AttemptsRepository {
  AttemptsRepository(this._client);

  final SupabaseClient _client;

  /// Persist a winning attempt. Returns false (no throw) if no auth session.
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
