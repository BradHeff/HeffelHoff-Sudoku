import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract class InterstitialAdService {
  /// Shows an interstitial if frequency-cap allows. Returns true if an
  /// ad was shown (or attempted), false if throttled / failed to load.
  Future<bool> maybeShow();
}

class AdMobInterstitialAdService implements InterstitialAdService {
  AdMobInterstitialAdService();

  static const _testAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testIos = 'ca-app-pub-3940256099942544/4411468910';

  /// TODO: replace with the real Android interstitial unit ID once
  /// created in AdMob console.
  static const _prodAndroid = '';
  static const _prodIos = '';

  static const _overrideAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
    defaultValue: '',
  );
  static const _overrideIos = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
    defaultValue: '',
  );

  /// Show an ad after every Nth completion. 1 = every completion.
  static const int _frequencyCap = 1;

  int _completionCount = 0;

  String get _adUnitId {
    if (kDebugMode) {
      if (Platform.isIOS) return _testIos;
      return _testAndroid;
    }
    if (Platform.isAndroid) {
      if (_overrideAndroid.isNotEmpty) return _overrideAndroid;
      return _prodAndroid.isEmpty ? _testAndroid : _prodAndroid;
    }
    if (Platform.isIOS) {
      if (_overrideIos.isNotEmpty) return _overrideIos;
      return _prodIos.isEmpty ? _testIos : _prodIos;
    }
    return _testAndroid;
  }

  @override
  Future<bool> maybeShow() async {
    _completionCount++;
    if (_completionCount % _frequencyCap != 0) return false;

    final completer = Completer<bool>();
    await InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(true);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (kDebugMode) debugPrint('[AdMob] Interstitial show failed: $error');
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) debugPrint('[AdMob] Interstitial load failed: $error');
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }
}

class NoOpInterstitialAdService implements InterstitialAdService {
  @override
  Future<bool> maybeShow() async => false;
}
