import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');

  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

SupabaseClient get supabase => Supabase.instance.client;

Future<void> initSupabase() async {
  if (!SupabaseConfig.isConfigured) {
    if (kDebugMode) {
      debugPrint('[Supabase] URL/anon key missing — skipping init in debug.');
    }
    return;
  }
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    debug: kDebugMode,
  );
}
