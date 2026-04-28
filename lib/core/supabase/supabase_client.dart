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

  // Ensure every install has a session. Without this, puzzle-attempt inserts
  // silently no-op (RLS requires auth.uid()=user_id), which means no row in
  // puzzle_attempts → no trigger fire → no leaderboard entry. Anonymous
  // sessions persist locally; users can later upgrade via linkIdentity to
  // attach an email/Google/Apple identity to the same UID.
  final client = Supabase.instance.client;
  if (client.auth.currentUser == null) {
    try {
      await client.auth.signInAnonymously();
      if (kDebugMode) {
        debugPrint(
          '[Supabase] Anonymous session created: '
          '${client.auth.currentUser?.id}',
        );
      }
    } catch (e) {
      // Network failures, "anonymous sign-ins disabled" in the dashboard,
      // or rate-limit. Logged so logcat reveals the cause; the app keeps
      // working in read-only-leaderboard mode.
      debugPrint('[Supabase] Anonymous sign-in failed: $e');
    }
  } else if (kDebugMode) {
    debugPrint(
      '[Supabase] Existing session restored: ${client.auth.currentUser?.id}',
    );
  }
}
