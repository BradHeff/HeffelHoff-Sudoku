import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/products.dart';
import 'interstitial_ad_service.dart';
import 'rewarded_ad_service.dart';

abstract class MonetizationService {
  /// Buy [product]. True on a successful, server-verified purchase.
  Future<bool> purchase(MonetizationProduct product);

  /// Throttled interstitial shown on puzzle completion. Returns true
  /// if an ad was actually shown, false if throttled / failed.
  Future<bool> maybeShowCompletionAd();

  /// Manual rewarded ad — kept for future opt-in flows. Currently
  /// unused; the app no longer triggers rewarded ads mid-puzzle.
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
  Future<bool> purchase(MonetizationProduct product) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return true;
  }

  @override
  Future<bool> maybeShowCompletionAd() => interstitial.maybeShow();

  @override
  Future<bool> showRewardedAd() => rewarded.show();
}

class MockMonetizationService implements MonetizationService {
  @override
  Future<bool> purchase(MonetizationProduct product) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return true;
  }

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
