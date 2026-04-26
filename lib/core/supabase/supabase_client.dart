import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client init. Reads URL + publishable (anon) key from
/// `--dart-define` at build time. The publishable key is safe to ship
/// in client builds — it's protected by Row Level Security. The
/// service-role key is only used by Edge Functions and lives in
/// `supabase functions secrets`, never in the app.
class SupabaseConfig {
  /// Pass via:
  ///   --dart-define=SUPABASE_URL=https://kosrtjwfjsdpxahgdpas.supabase.co
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kosrtjwfjsdpxahgdpas.supabase.co',
  );

  /// Publishable (anon) key. Safe to ship.
  ///   --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_NziQ8aCMyzJFU3rn0NCfWQ_c7Qm0fQd',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

/// Convenience accessor for the global Supabase client. Call after
/// [initSupabase] has resolved.
SupabaseClient get supabase => Supabase.instance.client;

/// Initialize Supabase. Call once from `main()` before `runApp`.
Future<void> initSupabase() async {
  if (!SupabaseConfig.isConfigured) {
    if (kDebugMode) {
      // ignore: avoid_print
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
