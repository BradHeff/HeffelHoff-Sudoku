# HeffelHoff Sudoku

A polished mobile Sudoku game (iOS + Android) built in Flutter, backed by Supabase. Every puzzle ends with a per-puzzle **IQ score** compared to Einstein's commonly-cited 160, and every tier (Easy → Evil) has its own realtime leaderboard with an animated podium designed to make every other player want to be on it.

> Solve smart, score high, beat Einstein.

![Difficulty: 5 tiers](https://img.shields.io/badge/difficulty-Easy%20%E2%86%92%20Evil-7C4DFF) ![Stack](https://img.shields.io/badge/stack-Flutter%20%2B%20Supabase-00E0FF) ![Status](https://img.shields.io/badge/status-internal--testing-yellow)

---

## Highlights

- **5 tiered leaderboards** — Easy, Medium, Hard, Expert, Evil — each with its own per-tier ranking by **personal-best IQ**.
- **Per-puzzle IQ score** computed from time, mistakes, hints used, and tier difficulty. Beat 160 to outscore Einstein.
- **Animated post-game** — count-up IQ marker, Einstein bar, sparkle particles, and a sync indicator that confirms your result reached the leaderboard (with a Retry on failure).
- **Realtime podium** — Supabase Realtime streams leaderboard changes; the top-3 cards re-flow live.
- **Home-screen progression card** — your all-tier best IQ animated against the Einstein 160 reference line.
- **Free with optional Pro IAP** — removes ads, +2 lives, unlocks the Evil tier, upgraded podium frames.
- **Material You theming** — deep-violet seed, dark default + neon alternate, Outfit + Inter typography.
- **Frictionless auth** — auto-anonymous play on first launch (no signup wall), then upgrade to email / Google / Apple whenever you're ready. UID and leaderboard rows preserved across the upgrade.
- **AdMob with safety net** — rewarded "watch a quick ad to recover a life" + throttled completion interstitials. Test-device hashes baked at build time keep dev devices on test ads even in release builds.

---

## Tech stack

| Layer | Choice |
|---|---|
| App | Flutter 3.x (Dart 3.x), Material 3, Riverpod 2 + freezed, go_router |
| Persistence (local) | drift (SQLite) — sync queue + puzzle cache (Phase 5) |
| Backend | Supabase — Postgres, Auth, Realtime, Edge Functions |
| Anti-cheat | Server-side IQ recompute + solution verification via Edge Functions (Phase 5) |
| Auth providers | Email/password, Google Sign-In (OAuth), Sign in with Apple (OAuth), Anonymous |
| Animations | `flutter_animate`, `confetti`, `lottie`, custom `CustomPainter` particle field |
| Monetization | `in_app_purchase` (one-time Pro), `google_mobile_ads` (rewarded + interstitial) |
| iOS CI | CodeMagic → App Store Connect API key → TestFlight / App Store |

---

## Repo layout

```
lib/
  core/        # supabase client, theme, drift storage, network, util
  features/
    auth/            # signin / signup / guest upgrade / OAuth
    profile/         # progression header + best-IQ repository
    sudoku/          # generator, validator, controller, game UI, sync status
    leaderboard/     # podium, realtime, climb animation
    achievements/    # engine, unlock overlay, definitions (Phase 4)
    monetization/    # IAP, ads, paywall
    settings/
supabase/
  migrations/        # idempotent SQL — schema, RLS, functions, triggers, seed data
  functions/         # submit-attempt, verify-purchase (Phase 5/6)
  diagnostics/       # ad-hoc SQL snippets (e.g. leaderboard_check.sql)
docs/
  PLAN.md            # 8-phase implementation plan — source of truth
  BRANDING.md        # color palette, logo rules, animation principles
  SUPABASE.md        # one-time dashboard setup
  MONETIZATION.md    # Pro IAP, AdMob, store accounts
Screenshots/
  generate_screenshots.py      # 1080x1920 Play Store stills + feature graphic
  generate_screenshots_ios.py  # 1284x2778 App Store stills + 886x1920 App Previews
test/                          # unit, widget, integration
```

---

## Getting started

### Prerequisites

- Flutter 3.24+ (Dart 3.5+) — `flutter doctor` should be all-green for the platforms you target
- **JDK 21** for Android builds (`flutter config --jdk-dir=/path/to/jdk-21`) — JDK 25 currently breaks Kotlin DSL during Gradle stage1
- Xcode 15+ with iOS 17 SDK (for iOS); Linux dev machines build for iOS via CodeMagic
- Android SDK 36+
- A Supabase project (free tier is plenty for testing; Pro recommended before going public — pause-protection + daily backups)
- Optional: Supabase CLI for local migrations and Edge Function deploys

### 1. Clone

```bash
git clone https://github.com/BradHeff/HeffelHoff-Sudoku.git
cd HeffelHoff-Sudoku
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 2. Configure Supabase credentials

This repo deliberately does **not** ship Supabase URLs or keys. Two equally-supported mechanisms:

**Option A — `--dart-define` at build time** (recommended for CI / release)

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_ANON_KEY
```

**Option B — gitignored `.env`** (debug-only, convenient locally)

Create `.env` at the repo root (gitignored):

```
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_ANON_KEY
```

`lib/core/supabase/supabase_client.dart` reads `String.fromEnvironment(...)` first and falls back to dotenv only when `kDebugMode` is true. Release builds ignore `.env` entirely.

> **Never commit secret keys.** The Supabase publishable (anon) key is designed to be shipped to clients and is protected by Row Level Security, so embedding it in a release binary is fine. The service-role key, in contrast, must only ever live on the Edge Function runtime — it bypasses RLS.

### 3. Enable required Supabase providers

Without these, fresh users won't be able to record any results:

1. **Authentication → Providers → Anonymous → Enable.** The app calls `signInAnonymously()` at startup so RLS-gated puzzle inserts always succeed; without this, every fresh-install puzzle win is silently dropped.
2. **(Optional) Google + Apple providers** if you want OAuth sign-in. See [`docs/MONETIZATION.md`](docs/MONETIZATION.md) for the full setup walk-through.
3. **Authentication → URL Configuration → Redirect URLs** must include `heffelhoffsudoku://auth-callback` for the OAuth deep-link callback to resolve back into the app.

### 4. Apply Supabase schema

```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

Migrations are idempotent (`CREATE TABLE IF NOT EXISTS`, `DROP POLICY ... CREATE POLICY`, etc.) so re-running is safe. If a fresh push leaves the leaderboard reporting `PGRST205` (schema cache stale), run in the Supabase SQL editor:

```sql
NOTIFY pgrst, 'reload schema';
```

### 5. Edge Functions (Phase 5+)

```bash
supabase functions secrets set SUPABASE_SERVICE_ROLE_KEY=...
supabase functions deploy submit-attempt
supabase functions deploy verify-purchase
```

The service-role key lives **only** as a Supabase secret. It is never present in any built APK / IPA, in source, or in this repo.

---

## Build & run

### Android — debug

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-XXXX/YYYY \
  --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-XXXX/YYYY \
  --dart-define=ADMOB_TEST_DEVICE_IDS=hash1,hash2
```

Debug builds always serve Google's universal test ad IDs regardless of the prod-unit flags (AdMob's no-self-impressions policy enforced via `kDebugMode`).

### Android — release for Play Store

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-XXXX/YYYY \
  --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-XXXX/YYYY \
  --dart-define=ADMOB_TEST_DEVICE_IDS=hash1,hash2
```

Output: `build/app/outputs/bundle/release/app-release.aab`. Upload to **Play Console → Internal Testing → Create new release**.

The release `signingConfig` reads from `android/key.properties` (gitignored) and points at `android/app/upload-keystore.jks` (also gitignored). On a fresh clone, regenerate or restore both — without them, release builds fall back to debug signing and Play Store rejects the upload.

### Android — AdMob App ID injection

The AdMob App ID is **not** in the tracked `AndroidManifest.xml`. It's a Gradle `manifestPlaceholder` (`${admobAppId}`) injected at build time from `android/local.properties`:

```
ADMOB_APP_ID_ANDROID=ca-app-pub-XXXX~YYYY
```

`android/local.properties` is gitignored. Without an entry, the build falls back to Google's sample iOS-style App ID, which lets the SDK initialize but never serves real ads.

### Android — test-device protection

Every dev / QA phone should be registered as a test device so accidental clicks on real ads can't suspend the AdMob account. Two layers:

1. **Build flag**: `--dart-define=ADMOB_TEST_DEVICE_IDS=hash1,hash2,...` — wired through `lib/main.dart` `_initMobileAds()` to `RequestConfiguration.testDeviceIds`. Hashes are logged by GMA on first ad request:
   ```
   I/Ads: Use RequestConfiguration.Builder().setTestDeviceIds(Arrays.asList("ABC123…"))
   ```
2. **AdMob Console → Settings → Test Devices → Add**. Independent of the app build; protects you even if a build skips the flag.

### iOS — release via CodeMagic

iOS distribution is via [CodeMagic](https://codemagic.io). The repo intentionally has no `codemagic.yaml` — workflow is configured via the CodeMagic web UI. Setup:

1. **App Store Connect API Key** uploaded to CodeMagic Code Signing Identities — issued from App Store Connect → Users and Access → Integrations → Keys with role **App Manager**. Different `.p8` than the Sign-in-with-Apple key.
2. **iOS code signing** in workflow: Automatic, profile type **App Store**, API key reference name from step 1. Apple distribution certs auto-rotate.
3. **Publishing → App Store Connect**: enable, same API key, "Submit to TestFlight" (or "Submit to App Store").
4. **Environment variables / dart-defines** for the iOS build: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `ADMOB_TEST_DEVICE_IDS`, plus `ADMOB_REWARDED_IOS` and `ADMOB_INTERSTITIAL_IOS` once those units exist.

If the upload fails with `ITMS-90161` (Invalid Provisioning Profile / Missing code-signing certificate), revoke any orphaned distribution certs in the Apple Developer Portal and clear `CERTIFICATE_KEY` in the CodeMagic env vars so the API auto-creates a fresh key + cert pair.

---

## Tests

```bash
flutter test                                       # unit + widget
flutter test integration_test                      # on a running device/emulator
flutter analyze                                    # 0 errors expected
dart format --output=none --set-exit-if-changed lib test
```

---

## Platform notes

### Android

- `applicationId` and namespace: `com.heffelhoff.heffelhoffsudoku` (single word, no separator)
- Launcher label: **HeffelHoff Sudoku**
- `MainActivity` uses `launchMode="singleTask"` so the app appears as a single card in Recents
- AdMob App ID injected via Gradle `manifestPlaceholder` from `android/local.properties` (gitignored)
- OAuth deep-link callback: intent-filter on `MainActivity` for `heffelhoffsudoku://auth-callback`
- Upload keystore: `android/app/upload-keystore.jks` (gitignored, RSA 2048, valid until 2053). Back this up off-machine — losing it means no future updates under the same upload key.

### iOS

- Bundle ID: `com.heffelhoff.heffelhoff-sudoku` (Apple Dev Portal forbids underscores)
- **iPhone-only** (`TARGETED_DEVICE_FAMILY = "1"`). Set after iPad multitasking validation (ITMS-90474) blocked an upload — restoring Universal also requires iPad screenshots.
- `Runner.entitlements` declares Sign in with Apple (wired into all build configs via `CODE_SIGN_ENTITLEMENTS`)
- `PrivacyInfo.xcprivacy` declares ATT/AdMob tracking + Required Reason API uses (required by App Review since May 2024)
- `Info.plist` includes:
  - `GADApplicationIdentifier` (placeholder iOS test ID — replace with real iOS AdMob App ID once registered)
  - `NSUserTrackingUsageDescription` (required when AdMob is present)
  - `SKAdNetworkItems` (44-entry AdMob-recommended set)
  - `CFBundleURLTypes` (OAuth deep-link callback)
  - `ITSAppUsesNonExemptEncryption=false` (bypasses the export-compliance prompt on every TestFlight upload)
- Sign-in-with-Apple `.p8` key at `ios/AuthKey_<KEY_ID>.p8` (gitignored). Generate the OAuth JWT with `python3 tools/generate_apple_jwt.py …` (180-day max lifetime).

---

## Marketing assets

Both stores' screenshot specs are auto-generated by the Python scripts in `Screenshots/`:

```bash
# Google Play — 1080x1920 stills + feature graphic
python3 Screenshots/generate_screenshots.py
# Output → Screenshots/generated/

# Apple App Store — 1284x2778 stills + 886x1920 App Previews (mp4)
python3 Screenshots/generate_screenshots_ios.py
# Output → Screenshots/generated_ios/
```

Both scripts auto-resolve fonts (Montserrat preferred; Liberation / Noto fallback) and pull source device screenshots from `Screenshots/`. iOS preview videos are stitched via ffmpeg — install with your distro's package manager if missing.

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
| 4 | Particles, Lottie, achievement engine + 12 achievements, neon theme alt, Statistics tab | In progress |
| 5 | drift sync queue + `submit-attempt` Edge Function + anti-cheat + server IQ authority | Planned |
| 6 | Pro IAP + AdMob + `verify-purchase` Edge Function + Restore Purchases | In progress (AdMob + OAuth done; IAP wiring pending) |
| 7 | Icons / splash / store screenshots / privacy policy / TestFlight / Play internal track | In progress (Play internal-testing AAB live; iOS App Store via CodeMagic in flight) |
| 8 | Daily Challenge calendar, Championship season, Trophy room | Future |

---

## License

Proprietary — © Brad Heffernan. All rights reserved.
