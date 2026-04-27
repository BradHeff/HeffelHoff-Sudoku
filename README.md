# HeffelHoff Sudoku

A Flutter mobile Sudoku game (iOS + Android) with Supabase-backed accounts, a tiered leaderboard, per-puzzle "IQ" scores compared to Einstein's 160, and a top-3 podium designed to make every other player want to be on it.

The full implementation plan lives at [`docs/PLAN.md`](docs/PLAN.md). Branding (logo usage, color palette, animation/typography rules) lives at [`docs/BRANDING.md`](docs/BRANDING.md). Read those first.

---

## Status

**Phase 1 — Flutter scaffold + offline single-player.** No backend integration yet. See `docs/PLAN.md` for the seven-phase roadmap.

---

## Prerequisites

- Flutter 3.24+ (Dart 3.5+) — `flutter doctor` should be all green for the platforms you target
- Xcode 15+ with iOS 17 SDK (for iOS builds)
- Android Studio with Android SDK 34+
- A Supabase project — credentials below
- Optional: Supabase CLI (`brew install supabase/tap/supabase` or equivalent) for local DB migrations and Edge Function deploys

## Supabase project

Already provisioned. Project URL and **publishable** (anon) key are below — they are designed to be shipped in client builds and are protected by Row Level Security.

```
SUPABASE_URL=https://kosrtjwfjsdpxahgdpas.supabase.co
SUPABASE_ANON_KEY=sb_publishable_NziQ8aCMyzJFU3rn0NCfWQ_c7Qm0fQd
```

The **service-role** key is required for Edge Functions only and **must never be committed or shipped to the client**. Pull it from Supabase Dashboard → Project Settings → API and store it as a secret on the Edge Function runtime:

```
supabase functions secrets set SUPABASE_SERVICE_ROLE_KEY=...
```

## Build & run

Pass Supabase credentials via `--dart-define` so they are baked into the build, not into source. Convenience scripts can wrap this; the canonical commands are:

```bash
# Get dependencies
flutter pub get

# Run code generators (Riverpod, freezed, drift, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Debug run — Android / iOS
flutter run \
  --dart-define=SUPABASE_URL=https://kosrtjwfjsdpxahgdpas.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_NziQ8aCMyzJFU3rn0NCfWQ_c7Qm0fQd

# Release builds
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...

flutter build ipa --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

For local convenience you may put the same values in a gitignored `.env` at the repo root; `lib/core/supabase/supabase_client.dart` reads `String.fromEnvironment(...)` first and falls back to dotenv only when `kDebugMode`.

## Tests

```bash
flutter test                                  # unit + widget
flutter test integration_test                 # on a running device/emulator
dart format --output=none --set-exit-if-changed lib test
flutter analyze
```

## Repo layout

```
lib/
  core/        # supabase, theme, storage (drift), network, util
  features/    # auth, profile, sudoku, leaderboard, achievements, monetization, settings
supabase/
  migrations/  # 0001_init.sql, 0002_rls.sql, 0003_functions_triggers.sql
  functions/   # submit-attempt, verify-purchase
docs/
  PLAN.md      # full implementation plan — source of truth
test/          # unit, widget, integration
```

## Cross-machine continuation

This project is set up to be cloned and resumed on any machine:

1. `git clone <remote>`
2. `flutter pub get && dart run build_runner build --delete-conflicting-outputs`
3. `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
4. Read `docs/PLAN.md` to find the current phase and next steps.

The plan file is the single source of truth; update it as decisions evolve.
