import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract class RewardedAdService {
  /// Resolves true if the user watched through to the reward callback.
  Future<bool> show();
}

class AdMobRewardedAdService implements RewardedAdService {
  AdMobRewardedAdService();

  static const _testAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testIos = 'ca-app-pub-3940256099942544/1712485313';

  static const _prodAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
    defaultValue: '',
  );
  static const _prodIos = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
    defaultValue: '',
  );

  String get _adUnitId {
    if (Platform.isAndroid) {
      return _prodAndroid.isEmpty ? _testAndroid : _prodAndroid;
    }
    if (Platform.isIOS) {
      return _prodIos.isEmpty ? _testIos : _prodIos;
    }
    return _testAndroid;
  }

  RewardedAd? _loaded;

  Future<bool> _load() async {
    final completer = Completer<RewardedAd?>();
    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => completer.complete(ad),
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            debugPrint('[AdMob] Rewarded load failed: $error');
          }
          completer.complete(null);
        },
      ),
    );
    _loaded = await completer.future;
    return _loaded != null;
  }

  @override
  Future<bool> show() async {
    if (_loaded == null) {
      final ok = await _load();
      if (!ok) return false;
    }
    final ad = _loaded!;
    _loaded = null;

    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!result.isCompleted) result.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (kDebugMode) debugPrint('[AdMob] Rewarded show failed: $error');
        if (!result.isCompleted) result.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return result.future;
  }
}
