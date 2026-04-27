import 'package:flutter/foundation.dart';

import '../../sudoku/domain/difficulty.dart';

@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.difficulty,
    required this.bestIq,
    required this.bestTimeSeconds,
    required this.achievedAt,
    required this.displayName,
    this.avatarUrl,
    this.isPro = false,
  });

  final String userId;
  final Difficulty difficulty;
  final int bestIq;
  final int bestTimeSeconds;
  final DateTime achievedAt;
  final String displayName;
  final String? avatarUrl;
  final bool isPro;

  factory LeaderboardEntry.fromRow(Map<String, dynamic> row) {
    final profile = (row['profiles'] as Map<String, dynamic>?) ?? const {};
    final tierId = row['difficulty'] as String? ?? 'easy';
    return LeaderboardEntry(
      userId: row['user_id'] as String,
      difficulty: Difficulty.values.firstWhere(
        (d) => d.id == tierId,
        orElse: () => Difficulty.easy,
      ),
      bestIq: (row['best_iq'] as num).toInt(),
      bestTimeSeconds: (row['best_time_seconds'] as num).toInt(),
      achievedAt: DateTime.parse(row['achieved_at'] as String),
      displayName: profile['display_name'] as String? ?? 'Player',
      avatarUrl: profile['avatar_url'] as String?,
      isPro: profile['is_pro'] as bool? ?? false,
    );
  }
}
