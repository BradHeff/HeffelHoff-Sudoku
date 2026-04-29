import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Replaces the previous Pro IAP with a rewarded-ad economy. Persistent
/// state lives in SharedPreferences so the player's progress survives
/// app restarts without needing a Supabase round-trip on every change.
///
/// State schema:
///   evil_unlocked          (bool, default false)
///   pending_lives_boost    (int 0|2, applied to NEXT puzzle then cleared)
///   pending_hints_boost    (int 0|1, applied to NEXT puzzle then cleared)
///   rewarded_ad_count      (int, lifetime counter — gates the loyalty reward)
///   bonus_lives_pool       (int, persistent extra-life budget that drains
///                           across puzzles; replenished by loyalty milestones)
///   loyalty_milestones_claimed (int, how many 10-ad rewards have been granted)
///   loss_count             (int, lifetime puzzles failed — gates the
///                           every-3rd-loss boost-offer cadence)
@immutable
class RewardedEconomyState {
  const RewardedEconomyState({
    required this.evilUnlocked,
    required this.pendingLivesBoost,
    required this.pendingHintsBoost,
    required this.rewardedAdCount,
    required this.bonusLivesPool,
    required this.loyaltyMilestonesClaimed,
    required this.lossCount,
  });

  final bool evilUnlocked;
  final int pendingLivesBoost;
  final int pendingHintsBoost;
  final int rewardedAdCount;
  final int bonusLivesPool;
  final int loyaltyMilestonesClaimed;
  final int lossCount;

  /// Number of ads still needed before the next loyalty reward. Hits 0
  /// the moment a milestone is granted, then resets to 10.
  int get adsToNextMilestone {
    final earned = (rewardedAdCount ~/ _milestoneInterval);
    final next = (earned + 1) * _milestoneInterval;
    return next - rewardedAdCount;
  }

  RewardedEconomyState copyWith({
    bool? evilUnlocked,
    int? pendingLivesBoost,
    int? pendingHintsBoost,
    int? rewardedAdCount,
    int? bonusLivesPool,
    int? loyaltyMilestonesClaimed,
    int? lossCount,
  }) {
    return RewardedEconomyState(
      evilUnlocked: evilUnlocked ?? this.evilUnlocked,
      pendingLivesBoost: pendingLivesBoost ?? this.pendingLivesBoost,
      pendingHintsBoost: pendingHintsBoost ?? this.pendingHintsBoost,
      rewardedAdCount: rewardedAdCount ?? this.rewardedAdCount,
      bonusLivesPool: bonusLivesPool ?? this.bonusLivesPool,
      loyaltyMilestonesClaimed:
          loyaltyMilestonesClaimed ?? this.loyaltyMilestonesClaimed,
      lossCount: lossCount ?? this.lossCount,
    );
  }
}

/// Show the post-loss boost-offer sheet on every Nth failed puzzle.
/// Set to 1 to fire every loss (annoying); set to 3 for the current
/// design (offer feels rewarding rather than nagging).
const int _boostOfferLossCadence = 3;

/// Number of bonus lives the +2-lives boost gives.
const int kPendingLivesBoostAmount = 2;

/// Number of bonus hints the +1-hint boost gives.
const int kPendingHintsBoostAmount = 1;

/// Cap on per-puzzle lives — game balance constraint independent of pool size.
const int kMaxPuzzleLives = 5;

/// Cap on per-puzzle hints — game balance constraint independent of pool size.
const int kMaxPuzzleHints = 2;

/// Lifetime ads required to claim each loyalty reward.
const int _milestoneInterval = 10;

/// How many lives a loyalty milestone adds to the persistent pool.
const int _milestoneReward = 5;

const _kEvilUnlocked = 'rew_evil_unlocked';
const _kPendingLives = 'rew_pending_lives';
const _kPendingHints = 'rew_pending_hints';
const _kAdCount = 'rew_ad_count';
const _kBonusPool = 'rew_bonus_pool';
const _kMilestones = 'rew_milestones_claimed';
const _kLossCount = 'rew_loss_count';

class RewardedEconomyNotifier extends StateNotifier<RewardedEconomyState> {
  RewardedEconomyNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static RewardedEconomyState _load(SharedPreferences p) {
    return RewardedEconomyState(
      evilUnlocked: p.getBool(_kEvilUnlocked) ?? false,
      pendingLivesBoost: p.getInt(_kPendingLives) ?? 0,
      pendingHintsBoost: p.getInt(_kPendingHints) ?? 0,
      rewardedAdCount: p.getInt(_kAdCount) ?? 0,
      bonusLivesPool: p.getInt(_kBonusPool) ?? 0,
      loyaltyMilestonesClaimed: p.getInt(_kMilestones) ?? 0,
      lossCount: p.getInt(_kLossCount) ?? 0,
    );
  }

  Future<void> _persist(RewardedEconomyState next) async {
    state = next;
    await Future.wait([
      _prefs.setBool(_kEvilUnlocked, next.evilUnlocked),
      _prefs.setInt(_kPendingLives, next.pendingLivesBoost),
      _prefs.setInt(_kPendingHints, next.pendingHintsBoost),
      _prefs.setInt(_kAdCount, next.rewardedAdCount),
      _prefs.setInt(_kBonusPool, next.bonusLivesPool),
      _prefs.setInt(_kMilestones, next.loyaltyMilestonesClaimed),
      _prefs.setInt(_kLossCount, next.lossCount),
    ]);
  }

  /// Permanently unlocks the Evil tier. Idempotent.
  Future<void> unlockEvil() => _persist(state.copyWith(evilUnlocked: true));

  /// Queues +2 lives and +1 hint for the very next puzzle. Cleared by
  /// [consumeNextPuzzleBoost] when that puzzle starts.
  Future<void> grantBoostNextPuzzle() => _persist(state.copyWith(
        pendingLivesBoost: kPendingLivesBoostAmount,
        pendingHintsBoost: kPendingHintsBoostAmount,
      ));

  /// Reads + clears the pending boost. Called by the GameController on
  /// construction so the boost applies to exactly one puzzle.
  /// Returns the (lives, hints) that should be added on top of the
  /// base 3 / 1 budget.
  ({int lives, int hints}) consumeNextPuzzleBoost() {
    final out = (
      lives: state.pendingLivesBoost,
      hints: state.pendingHintsBoost,
    );
    if (out.lives == 0 && out.hints == 0) return out;
    unawaited(_persist(state.copyWith(
      pendingLivesBoost: 0,
      pendingHintsBoost: 0,
    )));
    return out;
  }

  /// Drains up to [requested] lives from the persistent bonus pool.
  /// Returns how many were actually drained.
  int drainBonusPool(int requested) {
    if (requested <= 0 || state.bonusLivesPool <= 0) return 0;
    final drained =
        requested < state.bonusLivesPool ? requested : state.bonusLivesPool;
    unawaited(_persist(state.copyWith(
      bonusLivesPool: state.bonusLivesPool - drained,
    )));
    return drained;
  }

  /// Records a rewarded-ad watch (any path: evil-unlock, boost-offer,
  /// continue-on-loss, buy-extra-hint). Auto-grants the next loyalty
  /// milestone if the running total just crossed an interval boundary.
  /// Returns true iff a milestone was just claimed (UI cue).
  Future<bool> recordAdWatched() async {
    final newCount = state.rewardedAdCount + 1;
    final earned = newCount ~/ _milestoneInterval;
    final shouldClaim = earned > state.loyaltyMilestonesClaimed;
    await _persist(state.copyWith(
      rewardedAdCount: newCount,
      loyaltyMilestonesClaimed:
          shouldClaim ? earned : state.loyaltyMilestonesClaimed,
      bonusLivesPool: shouldClaim
          ? state.bonusLivesPool + _milestoneReward
          : state.bonusLivesPool,
    ));
    return shouldClaim;
  }

  /// Records a puzzle failure. Returns true iff this loss should fire
  /// the boost-offer sheet — i.e. every Nth failure (cadence defined
  /// by [_boostOfferLossCadence]). Persists the running count so the
  /// cadence survives app restarts.
  Future<bool> recordLossAndShouldOffer() async {
    final next = state.lossCount + 1;
    await _persist(state.copyWith(lossCount: next));
    return next % _boostOfferLossCadence == 0;
  }

  /// Test/debug helper — wipes all persistent rewarded-ad state. Not
  /// surfaced in the UI today; reserved for a future "reset rewards"
  /// option in settings.
  @visibleForTesting
  Future<void> reset() => _persist(const RewardedEconomyState(
        evilUnlocked: false,
        pendingLivesBoost: 0,
        pendingHintsBoost: 0,
        rewardedAdCount: 0,
        bonusLivesPool: 0,
        loyaltyMilestonesClaimed: 0,
        lossCount: 0,
      ));
}

/// Override in main() with the SharedPreferences instance loaded at
/// startup. Reads from this provider before the override is in place
/// throw — call sites must wait until after `runApp(ProviderScope(...))`.
final sharedPreferencesProvider = Provider<SharedPreferences>((_) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  );
});

final rewardedEconomyProvider =
    StateNotifierProvider<RewardedEconomyNotifier, RewardedEconomyState>(
  (ref) => RewardedEconomyNotifier(ref.watch(sharedPreferencesProvider)),
);
