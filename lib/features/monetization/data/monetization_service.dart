import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/products.dart';
import 'rewarded_ad_service.dart';

abstract class MonetizationService {
  /// Buys [product]. True on a successful, server-verified purchase;
  /// false if the user cancelled or the receipt failed validation.
  Future<bool> purchase(MonetizationProduct product);

  /// Shows a rewarded ad. True if the user watched it through.
  Future<bool> showRewardedAd();
}

/// Real ads via AdMob, mock IAPs until store accounts are configured.
class HybridMonetizationService implements MonetizationService {
  HybridMonetizationService(this._ads);

  final RewardedAdService _ads;

  @override
  Future<bool> purchase(MonetizationProduct product) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return true;
  }

  @override
  Future<bool> showRewardedAd() => _ads.show();
}

/// Both sides mocked. Useful for unit tests and emulators that lack
/// Google Play Services.
class MockMonetizationService implements MonetizationService {
  @override
  Future<bool> purchase(MonetizationProduct product) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return true;
  }

  @override
  Future<bool> showRewardedAd() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    return true;
  }
}

final rewardedAdServiceProvider = Provider<RewardedAdService>((ref) {
  return AdMobRewardedAdService();
});

final monetizationServiceProvider = Provider<MonetizationService>((ref) {
  return HybridMonetizationService(ref.watch(rewardedAdServiceProvider));
});
