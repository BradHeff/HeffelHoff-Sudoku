import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/puzzle.dart';

class AttemptsRepository {
  AttemptsRepository(this._client);

  final SupabaseClient _client;

  /// Best-effort session recovery. Returns the active user (after recovery
  /// if needed) or null if every fallback failed. Order:
  ///   1. existing currentUser
  ///   2. refreshSession() — uses persisted refresh token
  ///   3. signInAnonymously() — last-ditch so the win can still be recorded
  ///      under a fresh anon UID (Anonymous provider must be enabled)
  Future<User?> _ensureSession() async {
    final existing = _client.auth.currentUser;
    if (existing != null) return existing;

    debugPrint('[Attempts] no session — attempting refreshSession()');
    try {
      final res = await _client.auth.refreshSession();
      if (res.user != null) {
        debugPrint('[Attempts] session refreshed for ${res.user!.id}');
        return res.user;
      }
    } catch (e) {
      debugPrint('[Attempts] refreshSession failed: $e');
    }

    debugPrint('[Attempts] falling back to signInAnonymously()');
    try {
      final res = await _client.auth.signInAnonymously();
      if (res.user != null) {
        debugPrint('[Attempts] new anon session ${res.user!.id}');
        return res.user;
      }
    } catch (e) {
      debugPrint('[Attempts] anonymous fallback failed: $e');
    }

    return null;
  }

  /// Persist a winning attempt. Returns false (no throw) if no auth session
  /// or the insert fails — errors are logged so silent failures (RLS,
  /// schema cache, network) are visible in logcat. Will attempt to recover
  /// a missing session via refreshSession + anonymous fallback before
  /// giving up.
  Future<bool> submitWin({
    required Puzzle puzzle,
    required DateTime startedAt,
    required int timeSeconds,
    required int mistakes,
    required int hintsUsed,
    required int livesUsed,
    required int iqScore,
  }) async {
    final user = await _ensureSession();
    if (user == null) {
      debugPrint('[Attempts] submitWin skipped: no auth session (recovery failed)');
      return false;
    }

    try {
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
      debugPrint(
        '[Attempts] submitWin OK: user=${user.id} tier=${puzzle.difficulty.id} '
        'iq=$iqScore time=${timeSeconds}s',
      );
      return true;
    } catch (e, st) {
      debugPrint('[Attempts] submitWin FAILED: $e');
      debugPrintStack(stackTrace: st, label: 'submitWin');
      return false;
    }
  }

  Future<bool> submitFail({
    required Puzzle puzzle,
    required DateTime startedAt,
    required int timeSeconds,
    required int mistakes,
    required int hintsUsed,
    required int livesUsed,
  }) async {
    final user = await _ensureSession();
    if (user == null) {
      debugPrint('[Attempts] submitFail skipped: no auth session (recovery failed)');
      return false;
    }
    try {
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
    } catch (e, st) {
      debugPrint('[Attempts] submitFail FAILED: $e');
      debugPrintStack(stackTrace: st, label: 'submitFail');
      return false;
    }
  }
}

final attemptsRepositoryProvider = Provider<AttemptsRepository>((ref) {
  return AttemptsRepository(Supabase.instance.client);
});
