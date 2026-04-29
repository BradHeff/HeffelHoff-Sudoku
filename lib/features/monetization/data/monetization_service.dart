import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'interstitial_ad_service.dart';
import 'rewarded_ad_service.dart';

abstract class MonetizationService {
  /// Throttled interstitial shown on puzzle completion.
  Future<bool> maybeShowCompletionAd();

  /// Plays a rewarded ad and returns true once the user has earned the
  /// reward (closed the ad past the threshold). Used by every reward
  /// flow: out-of-lives, evil-unlock, post-loss boost, in-puzzle hint.
  Future<bool> showRewardedAd();
}

class HybridMonetizationService implements MonetizationService {
  HybridMonetizationService({
    required this.interstitial,
    required this.rewarded,
  });

  final InterstitialAdService interstitial;
  final RewardedAdService rewarded;

  @override
  Future<bool> maybeShowCompletionAd() => interstitial.maybeShow();

  @override
  Future<bool> showRewardedAd() => rewarded.show();
}

class MockMonetizationService implements MonetizationService {
  @override
  Future<bool> maybeShowCompletionAd() async => false;

  @override
  Future<bool> showRewardedAd() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    return true;
  }
}

final rewardedAdServiceProvider = Provider<RewardedAdService>((ref) {
  return AdMobRewardedAdService();
});

final interstitialAdServiceProvider = Provider<InterstitialAdService>((ref) {
  return AdMobInterstitialAdService();
});

final monetizationServiceProvider = Provider<MonetizationService>((ref) {
  return HybridMonetizationService(
    interstitial: ref.watch(interstitialAdServiceProvider),
    rewarded: ref.watch(rewardedAdServiceProvider),
  );
});
