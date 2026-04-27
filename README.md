# HeffelHoff Sudoku

A polished mobile Sudoku game (iOS + Android) built in Flutter, backed by Supabase. Every puzzle ends with a per-puzzle **IQ score** compared to Einstein's commonly-cited 160, and every tier (Easy → Evil) has its own realtime leaderboard with an animated podium designed to make every other player want to be on it.

> Solve smart, score high, beat Einstein.

![Difficulty: 5 tiers](https://img.shields.io/badge/difficulty-Easy%20%E2%86%92%20Evil-7C4DFF) ![Stack](https://img.shields.io/badge/stack-Flutter%20%2B%20Supabase-00E0FF) ![Status](https://img.shields.io/badge/status-pre--launch-orange)

---

## Highlights

- **5 tiered leaderboards** — Easy, Medium, Hard, Expert, Evil — each with its own per-tier ranking by **personal-best IQ**.
- **Per-puzzle IQ score** computed from time, mistakes, hints used, and tier difficulty. Beat 160 to outscore Einstein.
- **Animated post-game** — count-up IQ marker, Einstein bar, sparkle particles, achievement unlocks.
- **Realtime podium** — Supabase Realtime streams leaderboard changes; the top-3 cards re-flow live with smooth slide animations.
- **Offline-first** — solve without a connection; results queue locally and reconcile when the device is back online. Server is authoritative.
- **Free with optional Pro IAP** — removes ads, +2 lives, unlocks the Evil tier, upgraded podium frames.
- **Material You theming** — deep-violet seed, dark default + neon alternate, Outfit + Inter typography.
- **Anonymous play with later upgrade** — try without signing up; convert the same account to email + Google + Apple later. UID and leaderboard rows are preserved.

---

## Tech stack

| Layer | Choice |
|---|---|
| App | Flutter 3.x (Dart 3.x), Material 3, Riverpod 2 + freezed, go_router |
| Persistence (local) | drift (SQLite) — sync queue + puzzle cache |
| Backend | Supabase — Postgres, Auth, Realtime, Edge Functions |
| Anti-cheat | Server-side IQ recompute + solution verification via Edge Functions |
| Auth providers | Email/password, Google Sign-In, Sign in with Apple, anonymous |
| Animations | `flutter_animate`, `confetti`, `lottie`, custom `CustomPainter` particle field |
| Monetization | `in_app_purchase` (one-time Pro), `google_mobile_ads` (rewarded + interstitial) |

---

## Repo layout

```
lib/
  core/        # supabase client, theme, drift storage, network, util
  features/
    auth/            # signin / signup / guest upgrade
    profile/
    sudoku/          # generator, validator, controller, game UI
    leaderboard/     # podium, realtime, climb animation
    achievements/    # engine, unlock overlay, definitions
    monetization/    # IAP, ads, paywall
    settings/
supabase/
  migrations/  # idempotent SQL — schema, RLS, functions, triggers, seed data
  functions/   # submit-attempt, verify-purchase
docs/
  PLAN.md      # 8-phase implementation plan — source of truth
  BRANDING.md  # color palette, logo rules, animation principles
  SUPABASE.md  # one-time dashboard setup
  MONETIZATION.md
test/          # unit, widget, integration
```

---

## Getting started

### Prerequisites

- Flutter 3.24+ (Dart 3.5+) — `flutter doctor` should be all-green for the platforms you target
- JDK 21 for Android builds (`flutter config --jdk-dir=/path/to/jdk-21`)
- Xcode 15+ with iOS 17 SDK (for iOS)
- Android SDK 34+
- A Supabase project (free tier is plenty)
- Optional: Supabase CLI for local migrations and Edge Function deploys

### 1. Clone

```bash
git clone https://github.com/BradHeff/HeffelHoff-Sudoku.git
cd HeffelHoff-Sudoku
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 2. Configure Supabase credentials

This repo deliberately does **not** ship Supabase URLs or keys. You bring your own. Two equally-supported mechanisms:

**Option A — `--dart-define` at build time (recommended for CI / release)**

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_ANON_KEY
```

**Option B — gitignored `.env` (debug-only, convenient locally)**

Create `.env` at the repo root (already in `.gitignore`):

```
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_ANON_KEY
```

`lib/core/supabase/supabase_client.dart` reads `String.fromEnvironment(...)` first and falls back to dotenv only when `kDebugMode` is true. Release builds ignore the `.env` file entirely.

> **Never commit secret keys.** The Supabase publishable (anon) key is designed to be shipped to clients and is protected by Row Level Security, so embedding it in a release binary is fine. The service-role key, in contrast, must only ever live on the Edge Function runtime — it bypasses RLS.

### 3. Apply Supabase schema

```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

Migrations are idempotent (`CREATE TABLE IF NOT EXISTS`, `DROP POLICY ... CREATE POLICY`, etc.) so re-running is safe.

If a fresh push leaves the leaderboard reporting `PGRST205` (schema cache stale), run this in the Supabase SQL editor:

```sql
NOTIFY pgrst, 'reload schema';
```

### 4. Edge Functions (Phase 5+)

```bash
supabase functions secrets set SUPABASE_SERVICE_ROLE_KEY=...
supabase functions deploy submit-attempt
supabase functions deploy verify-purchase
```

The service-role key lives **only** as a Supabase secret. It is never present in any built APK / IPA, in source, or in this repo.

---

## Build & run

```bash
# Debug
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

# Release APK
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...

# Release IPA
flutter build ipa --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

Override AdMob ad-unit IDs via additional `--dart-define`s if needed:

```
--dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-XXXX/YYYY
--dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-XXXX/YYYY
```

Debug builds always use Google's universal test ad IDs (AdMob's no-self-impressions policy).

---

## Tests

```bash
flutter test                                       # unit + widget
flutter test integration_test                      # on a running device/emulator
flutter analyze
dart format --output=none --set-exit-if-changed lib test
```

---

## Platform notes

### Android

- `applicationId` and namespace: `com.heffelhoff.heffelhoffsudoku`
- Launcher label: **HeffelHoff Sudoku**
- `MainActivity` uses `launchMode="singleTask"` so the app is always a single card in Recents
- AdMob App ID is required as a `<meta-data>` in `AndroidManifest.xml` — using your own AdMob account, replace the placeholder before shipping

### iOS

- Bundle ID: `com.heffelhoff.heffelhoff-sudoku` (Apple Dev Portal forbids underscores)
- Sign in with Apple is required when other social providers (Google) are offered
- Privacy Nutrition Labels and a "Restore Purchases" path are mandatory for review

---

## Documentation

- [`docs/PLAN.md`](docs/PLAN.md) — full 8-phase implementation plan (source of truth)
- [`docs/BRANDING.md`](docs/BRANDING.md) — palette, logo rules, animation principles
- [`docs/SUPABASE.md`](docs/SUPABASE.md) — Supabase project setup walk-through (auth providers, schema, NOTIFY pgrst)
- [`docs/MONETIZATION.md`](docs/MONETIZATION.md) — Pro IAP, AdMob, store accounts

---

## Roadmap

| Phase | Scope | Status |
|------:|------|------|
| 1 | Flutter scaffold, theme, generator, game screen, lives, timer | Done |
| 2 | Supabase auth (email + anonymous), profile, attempts, IQ formula, post-game | Done |
| 3 | Leaderboard + Realtime + tier chips + podium + climb animation | Done |
| 4 | Particles, Lottie, achievement engine + 12 achievements, neon theme | In progress |
| 5 | drift sync queue + `submit-attempt` Edge Function + anti-cheat + server IQ authority | Planned |
| 6 | Pro IAP + AdMob + `verify-purchase` Edge Function + Restore Purchases | In progress |
| 7 | Icons / splash / store screenshots / privacy policy / TestFlight / Play internal track | Planned |
| 8 | Daily Challenge calendar, Championship season, Trophy room | Future |

---

## License

Proprietary — © Brad Heffernan. All rights reserved.
