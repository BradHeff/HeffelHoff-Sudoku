import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';
import 'core/supabase/supabase_client.dart';

/// Comma-separated AdMob test device hashes. Devices whose advertising
/// ID matches one of these IDs always receive test ads, even in release
/// builds — so dev / QA phones can install the production binary
/// without risking accidental clicks on real ads (which would get the
/// AdMob account suspended).
///
/// Hashes are logged to logcat by GMA on first ad request, e.g.:
///   I/Ads: Use RequestConfiguration.Builder().setTestDeviceIds(
///     Arrays.asList("C81B398E…")) to get test ads on this device.
///
/// Pass via `--dart-define=ADMOB_TEST_DEVICE_IDS=hash1,hash2,...`.
const _testDeviceIds = String.fromEnvironment('ADMOB_TEST_DEVICE_IDS');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await initSupabase();
  unawaited(_initMobileAds());
  runApp(const ProviderScope(child: HeffelHoffSudokuApp()));
}

Future<void> _initMobileAds() async {
  if (_testDeviceIds.isNotEmpty) {
    final ids = _testDeviceIds
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (ids.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: ids),
      );
    }
  }
  await MobileAds.instance.initialize();
}

