import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../sudoku/domain/difficulty.dart';
import '../domain/leaderboard_entry.dart';

class LeaderboardRepository {
  LeaderboardRepository(this._client);

  final SupabaseClient _client;
  static const int defaultLimit = 100;

  Future<List<LeaderboardEntry>> fetchTop({
    required Difficulty difficulty,
    int limit = defaultLimit,
  }) async {
    final rows = await _client
        .from('leaderboard_entries')
        .select('user_id, difficulty, best_iq, best_time_seconds, achieved_at, '
            'profiles!inner(display_name, avatar_url, is_pro)')
        .eq('difficulty', difficulty.id)
        .order('best_iq', ascending: false)
        .order('achieved_at', ascending: true)
        .limit(limit);
    final entries = rows.map<LeaderboardEntry>(LeaderboardEntry.fromRow).toList();
    // Defensive re-sort. PostgREST's order= directive applied alongside
    // a `profiles!inner` embed has produced wrong orderings in the wild
    // (rank 2 with a lower IQ than rank 3). Sorting client-side
    // guarantees the displayed order matches the spec regardless of
    // server-side quirks. Tie-break: earliest achieved_at wins.
    entries.sort((a, b) {
      final iqCmp = b.bestIq.compareTo(a.bestIq);
      if (iqCmp != 0) return iqCmp;
      final timeCmp = a.bestTimeSeconds.compareTo(b.bestTimeSeconds);
      if (timeCmp != 0) return timeCmp;
      return a.achievedAt.compareTo(b.achievedAt);
    });
    return entries;
  }

  /// Realtime stream — re-fetches the top-N on any leaderboard change.
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

final leaderboardStreamProvider = StreamProvider.autoDispose
    .family<List<LeaderboardEntry>, Difficulty>((ref, difficulty) {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.watchTop(difficulty: difficulty);
});
