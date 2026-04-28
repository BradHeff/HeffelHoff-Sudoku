import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lifecycle of the most recent puzzle-attempt submission.
///
/// Surfaced on the post-game screen so the player can tell at a glance
/// whether their result actually reached the leaderboard. Without this,
/// silent submit failures (network blip, expired token, RLS rejection)
/// would only become visible later as a missing leaderboard row.
enum SyncStatus {
  idle,
  syncing,
  synced,
  failed,
}

/// Globally-readable status of the last `submitWin` attempt. The
/// `GameController` writes here as it submits; the post-game screen
/// reads + offers a retry on failure.
final lastSubmitStatusProvider =
    StateProvider<SyncStatus>((ref) => SyncStatus.idle);
