import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../sudoku/domain/difficulty.dart';
import '../domain/leaderboard_entry.dart';

/// Reads `public.leaderboard_entries` joined with `public.profiles`,
/// ordered by best IQ (desc) then best time (asc).
///
/// Realtime: subscribes to `leaderboard_entries` changes filtered by
/// `difficulty` so the list reorders live as users post new bests.
class LeaderboardRepository {
  LeaderboardRepository(this._client);

  final SupabaseClient _client;
  static const int defaultLimit = 100;

  /// One-shot fetch.
  Future<List<LeaderboardEntry>> fetchTop({
    required Difficulty difficulty,
    int limit = defaultLimit,
  }) async {
    // Tie-break: when two users have the same best_iq, the one who
    // *achieved that IQ first* ranks higher. (achieved_at ascending).
    final rows = await _client
        .from('leaderboard_entries')
        .select('user_id, difficulty, best_iq, best_time_seconds, achieved_at, '
            'profiles!inner(display_name, avatar_url, is_pro)')
        .eq('difficulty', difficulty.id)
        .order('best_iq', ascending: false)
        .order('achieved_at', ascending: true)
        .limit(limit);
    return rows.map<LeaderboardEntry>(LeaderboardEntry.fromRow).toList();
  }

  /// Streaming subscription. Re-fetches the whole top-100 on any change
  /// to a `leaderboard_entries` row matching the tier. Simpler and more
  /// reliable than diffing — at 100 rows it's a sub-millisecond query.
  Stream<List<LeaderboardEntry>> watchTop({
    required Difficulty difficulty,
    int limit = defaultLimit,
  }) {
    final controller = StreamController<List<LeaderboardEntry>>();

    Future<void> push() async {
      try {
        final rows = await fetchTop(difficulty: difficulty, limit: limit);
        if (!controller.isClosed) controller.add(rows);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    push();

    final channel = _client
        .channel('leaderboard:${difficulty.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leaderboard_entries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'difficulty',
            value: difficulty.id,
          ),
          callback: (_) => push(),
        )
        .subscribe();

    controller.onCancel = () async {
      await _client.removeChannel(channel);
    };
    return controller.stream;
  }
}

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(Supabase.instance.client);
});

/// Realtime-keyed family of leaderboard streams, one per difficulty.
final leaderboardStreamProvider = StreamProvider.autoDispose
    .family<List<LeaderboardEntry>, Difficulty>((ref, difficulty) {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.watchTop(difficulty: difficulty);
});
