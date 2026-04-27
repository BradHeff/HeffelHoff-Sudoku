import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/products.dart';

abstract class MonetizationService {
  /// Buys [product]. Resolves true on a successful, server-verified
  /// purchase; false if the user cancelled or the receipt failed
  /// validation.
  Future<bool> purchase(MonetizationProduct product);

  /// Shows a rewarded ad. Resolves true if the user watched it through
  /// to the reward callback; false if they dismissed early or no ad
  /// was available.
  Future<bool> showRewardedAd();
}

/// In-memory implementation that always succeeds after a small delay.
/// Lets the rest of the app exercise the purchase flow before any real
/// store accounts are wired up. Replace with an `IapMonetizationService`
/// (in_app_purchase + google_mobile_ads) for production.
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

final monetizationServiceProvider = Provider<MonetizationService>((ref) {
  return MockMonetizationService();
});
