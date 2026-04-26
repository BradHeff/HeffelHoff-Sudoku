# HeffelHoff Sudoku — Implementation Plan

> **Portability note:** On plan approval, this file will be copied to `/media/Windows1/Projectz/HeffelHoff-Sudoku/docs/PLAN.md` so development can resume on any machine that clones the project. The `~/.claude/plans/` copy is machine-local and exists only to satisfy plan mode — the project copy is the source of truth going forward.

## Context

Greenfield Flutter mobile game (iOS + Android) for solving Sudoku puzzles, with cloud accounts, a tiered leaderboard, and a per-puzzle "IQ" score that compares the player's result to Einstein's commonly-cited 160. Built with Supabase as the only backend (Postgres + Auth + Realtime + Edge Functions). The product hook is the **post-solve celebration** — sparkles, particles, an animated IQ-vs-Einstein bar — and a **top-3 podium** designed to make every other player want to be on it. Free-to-play with a one-time $4.99 Pro IAP.

The directory `/media/Windows1/Projectz/HeffelHoff-Sudoku/` is currently empty. Phase 1 starts from `flutter create`.

## Locked-in product decisions

- **Frontend:** Flutter (single codebase, Android + iOS).
- **Backend:** Supabase only — Postgres, Auth, Realtime, Storage, Edge Functions. (MongoDB dropped after clarification.)
- **Auth:** email/password, Google Sign-In, Sign in with Apple (mandatory on iOS when other social providers are present), and anonymous play with later upgrade via `linkIdentity`.
- **Offline-first** with sync queue; server is authoritative.
- **Difficulty tiers:** Easy / Medium / Hard / Expert / Evil — each with its own leaderboard.
- **IQ model:** per-puzzle IQ that resets every game. Profile shows running average + personal best. Leaderboard ranks personal-best IQ per tier.
- **Lives:** 3 free / 5 Pro. Wrong entry = -1 life. Out of lives = puzzle fails (no IQ; free users can watch a rewarded ad to continue once).
- **Monetization:** Free + one-time `com.heffelhoff.sudoku.pro` IAP at ~$4.99. Removes ads, +2 lives, unlocks Evil tier, upgrades podium frames.
- **Visual feel:** Material 3 (You) with deep-violet seed `#6750A4`, dark default + neon alternate, Outfit display font + Inter body, sparkle/twinkle particle layer over IQ result and top-3 podium.

## Supabase project (already provisioned)

- **Project URL:** `https://kosrtjwfjsdpxahgdpas.supabase.co`
- **Publishable (anon) key:** `sb_publishable_NziQ8aCMyzJFU3rn0NCfWQ_c7Qm0fQd`
- **Service-role key:** **not yet captured** — needed for Edge Functions only, never shipped to the client. Pull from Supabase dashboard → Project Settings → API and store as a secret in `supabase functions secrets set SUPABASE_SERVICE_ROLE_KEY=...`.

**Wiring in Flutter (no `.env` file in repo):**

- Pass via `--dart-define` at build time so secrets aren't baked into source:
  - `flutter run --dart-define=SUPABASE_URL=https://kosrtjwfjsdpxahgdpas.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_NziQ8aCMyzJFU3rn0NCfWQ_c7Qm0fQd`
- For local dev convenience, support reading the same vars from a gitignored `.env` via `flutter_dotenv` *only* when `kDebugMode`.
- `lib/core/supabase/supabase_client.dart` reads from `String.fromEnvironment('SUPABASE_URL')` first, falls back to dotenv in debug.
- `.gitignore` must include: `.env`, `.env.*`, `ios/Flutter/Generated.xcconfig`, `android/key.properties`, Supabase service-role secrets.

## Tech stack

- **State:** Riverpod 2.x with `riverpod_generator` + `freezed`.
- **Routing:** `go_router`.
- **Local DB:** `drift` (SQLite) for the offline sync queue and puzzle cache.
- **Network awareness:** `connectivity_plus`.
- **Animations:** `flutter_animate`, `confetti`, `lottie`, custom `CustomPainter` for the persistent twinkle field.
- **Auth packages:** `supabase_flutter`, `google_sign_in`, `sign_in_with_apple`.
- **Monetization:** `in_app_purchase`, `google_mobile_ads`.
- **Fonts:** `google_fonts` (Outfit + Inter).
- **Haptics:** `flutter_haptic_feedback` (or `vibration`).

## Project structure

Feature-first layout under `lib/`:

```
lib/
  main.dart, app.dart, router.dart
  core/
    supabase/        # client init, auth repo, realtime channels
    theme/           # Material 3 ColorScheme, custom tokens
    storage/         # drift, sync queue
    network/, error/, util/
  features/
    auth/            # signin/signup/guest upgrade
    profile/
    sudoku/
      domain/        # board, cell, difficulty, game_state (freezed)
      data/          # backtracking_generator, validator, repo
      application/   # game_controller, iq_calculator, timer
      presentation/  # game_screen + widgets, post_game_iq_screen
    leaderboard/
      presentation/widgets/  # podium_view, particle_aura, crown_icon
    achievements/    # engine, unlock overlay, definitions
    monetization/    # IAP, ads, paywall
    settings/
supabase/
  migrations/        # 0001_init, 0002_rls, 0003_functions_triggers
  functions/         # submit-attempt, verify-purchase
assets/lottie, assets/fonts, assets/icons
test/unit, test/widget, test/integration
```

## Database schema (Supabase)

Single migration `supabase/migrations/0001_init.sql`:

```sql
create type difficulty_tier as enum ('easy','medium','hard','expert','evil');

create table public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  display_name    text not null check (char_length(display_name) between 2 and 24),
  avatar_url      text,
  is_pro          boolean not null default false,
  pro_purchased_at timestamptz,
  is_anonymous    boolean not null default false,
  country_code    char(2),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create table public.puzzles (
  id              uuid primary key default gen_random_uuid(),
  seed            bigint not null,
  difficulty      difficulty_tier not null,
  clues           text not null,           -- 81 chars, '0' = blank
  solution        text not null,           -- 81 chars
  clue_count      smallint not null,
  generator_version smallint not null default 1,
  created_at      timestamptz not null default now(),
  unique (seed, difficulty, generator_version)
);

create table public.puzzle_attempts (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  puzzle_id       uuid references public.puzzles(id) on delete set null,
  puzzle_seed     bigint not null,
  difficulty      difficulty_tier not null,
  started_at      timestamptz not null,
  completed_at    timestamptz,
  time_seconds    integer,
  mistakes        smallint not null default 0,
  hints_used      smallint not null default 0,
  lives_used      smallint not null default 0,
  completed       boolean not null default false,
  failed          boolean not null default false,
  iq_score_client smallint,
  iq_score        smallint,                -- authoritative, server-computed
  client_solution text,
  client_version  text,
  created_at      timestamptz not null default now()
);
create index puzzle_attempts_tier_iq_idx
  on public.puzzle_attempts (difficulty, iq_score desc) where completed = true;

create table public.leaderboard_entries (
  user_id           uuid not null references auth.users(id) on delete cascade,
  difficulty        difficulty_tier not null,
  best_iq           smallint not null,
  best_attempt_id   uuid not null references public.puzzle_attempts(id) on delete cascade,
  best_time_seconds integer not null,
  achieved_at       timestamptz not null,
  primary key (user_id, difficulty)
);
create index leaderboard_tier_iq_idx
  on public.leaderboard_entries (difficulty, best_iq desc, best_time_seconds asc);

create table public.achievements (
  code text primary key, title text not null, description text not null,
  icon_key text not null,
  rarity text not null check (rarity in ('common','rare','epic','legendary')),
  sort_order int not null default 0
);

create table public.user_achievements (
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_code text not null references public.achievements(code) on delete cascade,
  unlocked_at timestamptz not null default now(),
  context jsonb,
  primary key (user_id, achievement_code)
);

create table public.purchases (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  platform      text not null check (platform in ('ios','android')),
  product_id    text not null,
  receipt_hash  text not null,
  verified      boolean not null default false,
  raw_response  jsonb,
  created_at    timestamptz not null default now(),
  unique (platform, receipt_hash)
);
```

RLS in `0002_rls.sql`:

- `profiles`: select for everyone, update only by owner.
- `puzzles`: select for authenticated users; writes only via service role.
- `puzzle_attempts`: select/insert by owner; updates only via service role (server IQ recompute).
- `leaderboard_entries`: world-readable; writes only via trigger.
- `achievements`: world-readable. `user_achievements`: owner-only.
- `purchases`: owner read, writes via Edge Function only.

Triggers in `0003_functions_triggers.sql`:

- `handle_new_user()` on `auth.users` insert → seeds `profiles` with `Player#1234`-style display name and `is_anonymous` flag from JWT metadata.
- `update_leaderboard_on_attempt()` AFTER UPDATE on `puzzle_attempts` when `completed AND iq_score IS NOT NULL` → upsert into `leaderboard_entries` only if new IQ beats existing best (tie-break: lower `time_seconds`).
- `compute_iq(difficulty, time_seconds, mistakes, hints_used) returns smallint` — Postgres function used by Edge Function and as a defensive trigger fallback.

## IQ scoring formula

| Tier   | base | target_time (s) | clue count | time_bonus_cap | time_penalty_cap |
|--------|-----:|----------------:|-----------:|---------------:|-----------------:|
| Easy   |  100 |             420 |      40–45 |            +12 |              -10 |
| Medium |  115 |             720 |      32–36 |            +15 |              -12 |
| Hard   |  130 |            1200 |      28–31 |            +18 |              -15 |
| Expert |  145 |            1800 |      25–27 |            +22 |              -18 |
| Evil   |  160 |            2700 |      22–24 |            +28 |              -22 |

```
ratio = time_seconds / target_time_for_tier   # 1.0 = on target

if ratio <= 1.0:
    time_component = lerp(time_bonus_cap, 0, ratio)
else:
    over = min(ratio - 1.0, 2.0)
    time_component = -lerp(0, time_penalty_cap, over / 2.0)

mistake_penalty = mistakes * 4
hint_penalty    = hints_used * 6

iq_score = clamp(round(base + time_component - mistake_penalty - hint_penalty), 70, 200)
```

Sanity examples:

- Easy / 5:00 / 0 mistakes → ~104
- Hard / 18:00 / 2 mistakes → ~124
- Expert / 25:00 / 0 mistakes → ~149
- Evil / 35:00 / 0 mistakes → ~166 (Beat Einstein)
- Evil / 25:00 / 0 mistakes → ~172

Beating 160 should be hard but achievable on Hard with a clean fast run, comfortable on Expert, and easy-ish on Evil — keeping the Einstein moment aspirational without being unattainable.

**Einstein-comparison UI:**

- `delta = iq_score - 160`
- `delta ≥ 0`: gold accent, "You beat Einstein by {delta} IQ!", sparkle aura.
- `-10 ≤ delta < 0`: silver accent, "Just {abs(delta)} points away from Einstein."
- `-25 ≤ delta < -10`: "{abs(delta)} IQ points to catch Einstein. Keep grinding."
- `delta < -25`: "Einstein's still {abs(delta)} ahead. Climb the tiers."
- Horizontal bar 70→200 with a fixed glowing tick at 160 labelled "Einstein". User's marker animates a 1.2s ease-out count-up + small recoil bounce.

## Sudoku generator

Pure-Dart, client-side, deterministic-seeded. ~200 LOC.

1. Backtracking solver with a seeded shuffle fills a complete valid grid.
2. Symmetric (rotational 180°) clue removal: blank a pair, run a uniqueness solver, restore if non-unique.
3. Stop at the tier's clue-count lower bound or after 50 consecutive failed removals.
4. Emit `(seed, clues, solution, difficulty, generator_version=1)`.

Run inside an `Isolate` via `compute()` so the UI never freezes; show a "shuffling tiles" Lottie. Performance budget: Easy/Medium <100ms, Hard <300ms, Expert <800ms, Evil <2s on a Pixel 4a-class device. Bundled JSON fallback (~50 puzzles per tier) for the rare case generation exceeds 3s.

Server stores the resulting puzzle on first submission so it can verify subsequent submissions of the same seed. Daily-puzzle support is trivial later: `seed = hash(yyyymmdd + difficulty)`.

## Game UI

Portrait, top → bottom: app bar (difficulty chip, settings) → stats row (lives ❤️❤️❤️ / timer / mistakes) → 9×9 board → tools (undo, erase, pencil, hint) → number pad with remaining-count badges.

Cell states map to Material 3 ColorScheme roles: given (`surfaceContainerHigh`), correct (`surface` + `primary` text), wrong (`errorContainer`, shake + flash), selected (`secondaryContainer`), peer-highlighted (`surfaceContainerLow`), same-number-highlighted (`tertiaryContainer` 30% alpha).

Wrong-entry sequence: 200ms shake (`Curves.elasticOut`, 8px) → red flash → heart scales to 1.3× then crumbles → strong haptic → cell auto-clears at 1.2s.

Game state is a freezed union: `Loading | Playing(...) | Won(...) | Lost(...) | Reviewing(...)`. Timer is a 1Hz stream paused via `WidgetsBindingObserver` when the app backgrounds.

## Particles & celebration

- `flutter_animate` — micro animations (cell fill, number-pad press, lives pulse).
- `confetti` — quick burst on solve.
- `lottie` — achievement burst, podium crown idle, generator loader.
- Custom `CustomPainter` + `Ticker` — persistent twinkling field around the IQ result and behind top-3 podium rows. ~60 particles, sin-wave drift, alpha twinkle, color-tinted by Material 3 `primary`/`secondary`/`tertiary`.
- Haptics: light on cell select, medium on number place, heavy on wrong entry, success pattern on win.

**Achievement-unlock sequence (full-screen):**

1. Screen dims to 80%, Hero from app bar.
2. Lottie burst plays (1.5s).
3. Particle storm (200 particles, color-tinted by rarity).
4. Card scales 0→1 with `elasticOut`; title typewriter-reveals.
5. IQ number counts up (1.2s) with `TweenAnimationBuilder`.
6. Einstein bar fills, marker snaps to position.
7. "Tap to continue" + success haptic pattern.
8. On dismiss, card flies via Hero to the achievements tab icon.

## Leaderboard (the envy machine)

Tier chips at top: Easy / Medium / Hard / Expert / **Evil** (locked-grey for free users — tap opens paywall).

**Podium (ranks 1–3):**

- 3-column layout. Center column (#1) is taller with a 4px / 2.4s sine bob.
- Each card: 24px rounded, animated gradient frame border. #1 = gold `#FFD700`→`#FFA500` with slow hue rotation; #2 = silver `#C0C0C0`→`#E5E4E2`; #3 = bronze `#CD7F32`→`#B87333`.
- 96px avatar with pulsing radial-gradient ring.
- Crown Lottie hovers above #1.
- IQ in Outfit 56pt with frame-color drop shadow.
- 40 particles per card, denser for #1, color-matched.
- Pro users get thicker frame stroke + extra particle layer.

**Below podium (ranks 4–100):** standard list. Current user's row gets a `primaryContainer` gradient and auto-scroll-to.

**Realtime:** subscribe to `leaderboard_entries` filtered by tier. On change, `AnimatedSwitcher` reorders with a 400ms slide; displaced #3 flies off-screen, new #3 flies in.

## Offline-first sync

Local store (`drift`):

- `local_attempts` mirrors `puzzle_attempts` plus `sync_state: pending | synced | failed`.
- `local_puzzle_cache` stores `(seed, difficulty, clues, solution)` for replay/review.
- `local_user_state` stores last-known `display_name`, `is_pro`, `last_sync_at`.

`SyncQueueService` (Riverpod, listens to `connectivity_plus`) drains pending rows by POSTing to `submit-attempt` Edge Function. On 200, marks `synced` and replaces local IQ with the server-authoritative value. UI shows "Pending sync (n)" or "Synced" badge.

Server is authoritative. Client IQ is shown as "provisional" (grey pill) until sync. Server rejection (anti-cheat) → mark `failed`, show "couldn't verify this run". Leaderboard never reflects unsynced/failed attempts.

Edge cases: persist `Playing` snapshot every 10s for app-kill recovery; gate anonymous→email upgrade behind "must be online + queue empty".

## Anti-cheat

`submit-attempt` Edge Function pipeline:

1. Auth: pull `user_id` from JWT.
2. Resolve `puzzles` row by `(seed, difficulty, generator_version)` — solve server-side and insert if missing.
3. Verify `client_solution` byte-equals stored `solution`. Mismatch → 422.
4. Sanity bounds (per tier floor: Easy 30s, Medium 60s, Hard 90s, Expert 150s, Evil 240s; max 24h; mistakes ≤ 50; hints ≤ 9).
5. Recompute IQ via `compute_iq(...)`.
6. Insert attempt with `iq_score = server_value`. Trigger updates leaderboard.
7. Return `{ iq_score, achievements_unlocked: [...] }`.

Future hardening (deferred): per-user rate limit (60/hr), statistical outlier flagging, Play Integrity API + App Attest if leaderboard abuse appears.

## Auth flow

Supabase Auth providers to enable in dashboard: Email/password, Google, Apple, Anonymous.

**Apple:** App ID with "Sign in with Apple" capability, Services ID + Key uploaded to Supabase. Xcode capability added. Mandatory on iOS because Google is offered.

**Google:** OAuth 2.0 client IDs (Android with SHA-1, iOS bundle ID, Web for Supabase). Reversed-client-ID URL scheme in iOS Info.plist.

**Anonymous → real account upgrade:** call `supabase.auth.linkIdentity({ provider })` or `updateUser({ email, password })`. UID is preserved, so attempts and leaderboard rows stay attached. `profiles.is_anonymous` flips via trigger.

## Monetization

**Pro IAP** — single non-consumable, both stores, ID `com.heffelhoff.sudoku.pro` at ~$4.99. `in_app_purchase` package wrapped in `IapService` exposing `Stream<ProStatus>`.

**`verify-purchase` Edge Function** — calls Apple `verifyReceipt` (prod with sandbox fallback) or Google `purchases.products.get` with a service-account JSON stored in Edge Function secrets. On success: insert `purchases` row, set `profiles.is_pro = true`. Required: working Restore Purchases path (Apple mandates it).

**Ads** — `google_mobile_ads`. Banner on home + leaderboard, interstitial every 3rd completion (skipped for Pro), rewarded "continue with one extra life" max once per puzzle. Test IDs in dev, real IDs via `--dart-define` in release.

**`is_pro` is read only from `profiles`.** SharedPreferences mirror is for fast UI but never trusted.

## Achievements (initial set)

`first_solve`, `no_mistakes`, `sub_3_easy`, `sub_5_medium`, `sub_10_hard`, `sub_20_expert`, `evil_solver`, `beat_einstein` (>160), `iq_180`, `streak_10`, `solves_100`, `solves_500`, `top_10`, `top_3`, `night_owl`, `daily_7`, `pro_supporter`.

Celebration tier scales with rarity: common (confetti + light haptic), rare (confetti + Lottie + medium), epic (particle storm + Lottie + heavy), legendary (full sequence + screen flash).

## Theme & branding

```dart
ColorScheme.fromSeed(
  seedColor: Color(0xFF6750A4),    // deep violet, Material 3 baseline
  brightness: Brightness.dark,     // dark default
  dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
)
```

Settings exposes a "Neon" alternate (seed `#00E0FF`) shipped Phase 4. Display + numerals: Outfit (Google Fonts). Body: Inter. Custom theme extension for `goldFrame`, `silverFrame`, `bronzeFrame`, `lifeRed`, `iqGenius`, `particleTints`. App icon + native splash via `flutter_launcher_icons` + `flutter_native_splash` in Phase 7.

## Implementation phases

| Phase | Scope | Approx. duration |
|------:|------|-----------------:|
| 1 | Flutter scaffold, Material 3 theme, generator, game screen, lives, timer — fully offline | ~1 week |
| 2 | Supabase auth (email + anonymous), profile, attempts, IQ formula, post-game screen | ~1 week |
| 3 | Leaderboard + Realtime + Google/Apple sign-in + tier chips + basic podium | ~1 week |
| 4 | Particles, Lottie, achievement engine + 12 achievements, neon theme, Statistics tab | ~1 week |
| 5 | Drift sync queue, `submit-attempt` Edge Function, anti-cheat, server IQ authority, peer solve % | ~1 week |
| 6 | Pro IAP + AdMob + `verify-purchase` Edge Function + Restore Purchases | ~1 week |
| 7 | Icons/splash, store screenshots, privacy policy, TestFlight, Play internal track, release | ~1 week |
| 8 | Daily Challenge calendar, Championship season, Trophy room (post-launch growth) | ~2 weeks |

## Inspiration & roadmap additions

Reference: screenshots from Sudoku Master in `Screenshots/` (kept gitignored — local reference). Patterns absorbed:

**Bake into Phase 1 game screen (UI wins, no extra backend):**

- **Peer solve % banner** at puzzle start: a slide-in card showing "X.XX% of players have solved this puzzle" — meaningful difficulty calibration *from real peer data*, not just a static tier label. Phase 1 shows a placeholder ("—%"); Phase 5 wires real data via `puzzle_stats` aggregation.
- **Streak counter** chip in the top-left header ("Streak 4"). Drives daily return.
- **Mistakes as star icon** (★ N) for visual compactness instead of "Mistakes 1".
- **Pencil/Notes toggle** with explicit ON/OFF label badge (not just an icon color change) — clearer state.
- **Hint button** shows a count badge with hints remaining (cap 3 free / 5 Pro per puzzle). Tapping at zero opens the rewarded-ad-for-hint flow (free) or paywall (Pro upsell).
- **Number-pad remaining-count subscripts** under each digit (e.g., "5₄" = four 5s left to place).
- **Same-row / same-column / same-box dimming** + **same-digit highlighting** when a cell is selected.
- **Pause icon** in the header (timer pauses, board obscures to prevent peeking).

**Add to Phase 4 (after particles/achievements ship):**

- **Statistics tab** per difficulty tier: `Games Started`, `Wins`, `Win Rate`, `Wins with No Mistakes`, `Best Time`, `Average Time`, `Current Win Streak`, `Best Win Streak`. Drives engagement post-game.
- **Inline hint tutorial** (cross-hatching, naked single, hidden single explanations rendered on the board with dashed lines + R/C labels) instead of just revealing the digit. Distinguishes us from competitors.

**Phase 5 backend additions:**

- New table `puzzle_stats (puzzle_id, attempts, wins, fails, last_aggregated_at)` — updated by trigger on `puzzle_attempts` change. The peer solve % banner reads this.

**Phase 8 — post-launch growth (new phase):**

- **Daily Challenge mode**: deterministic seed `hash(yyyymmdd)`, calendar UI showing which days were completed (gold star), missed (greyed), today (highlight). Increases day-1 retention.
- **Championship season**: time-limited (e.g., 5-day) leaderboard with countdown timer, separate from the persistent IQ leaderboard. Score = sum of session IQs above a tier threshold during the window. Top finishers get a Roman-numeral seasonal trophy ("Trophy IV" for 4th season).
- **Trophy room**: gallery of unlocked seasonal trophies + achievement medals, with sparkle/twinkle particle background.
- **Home screen redesign**: horizontal scrolling mode cards (Daily / Championship / Tier Practice) above a hero "current streak" block and a "Continue Level N" / "New Game" button row.

Ship the core (Phases 1–7) first, then layer Phase 8 once real users signal which return loops they re-engage with.

## Critical paths & risks

1. **Apple App Review.** Sign-in-with-Apple parity, visible Restore Purchases, accurate Privacy Nutrition Labels, no external payment links. *Mitigation:* TestFlight early; review notes covering anonymous auth flow and IAP.
2. **Generator perf on low-end Android.** Evil-tier uniqueness checks can spike. *Mitigation:* `compute()` isolate, bundled fallback JSON, removal-loop iteration cap.
3. **Anti-cheat tradeoff.** Baseline (server IQ + solution check + sanity bounds + rate limit) catches casual cheating; Play Integrity / App Attest deferred until needed.
4. **Offline-sync edge cases.** Anonymous-then-upgrade mid-flight is the hairy one. *Mitigation:* gate upgrade behind "online + queue empty".
5. **AdMob policy & age rating.** Set 12+, cap ad content rating, integrate UMP SDK for GDPR consent.

## Critical files to be created

- `/media/Windows1/Projectz/HeffelHoff-Sudoku/pubspec.yaml`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/lib/main.dart`, `app.dart`, `router.dart`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/lib/core/supabase/supabase_client.dart`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/lib/core/theme/app_theme.dart`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/lib/features/sudoku/data/backtracking_generator.dart`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/lib/features/sudoku/application/iq_calculator.dart`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/lib/features/sudoku/presentation/game_screen.dart`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/lib/features/sudoku/presentation/post_game_iq_screen.dart`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/lib/features/leaderboard/presentation/widgets/podium_view.dart`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/lib/features/achievements/presentation/widgets/achievement_unlock_overlay.dart`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/supabase/migrations/0001_init.sql`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/supabase/migrations/0002_rls.sql`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/supabase/migrations/0003_functions_triggers.sql`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/supabase/functions/submit-attempt/index.ts`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/supabase/functions/verify-purchase/index.ts`
- `/media/Windows1/Projectz/HeffelHoff-Sudoku/.gitignore`, `README.md`, `docs/PLAN.md` (this plan, copied into the repo on approval)

## Verification

**Per-phase manual checklist** — run each on iOS simulator + Android emulator, plus a real device once available.

- **Phase 1:** generate one puzzle per tier with correct clue count; solve a puzzle; wrong entries shake and decrement lives; losing all lives shows Failed screen.
- **Phase 2:** sign up via email (verify email arrives); anonymous sign-in creates a `profiles` row; completing a puzzle inserts a `puzzle_attempts` row visible in Supabase Studio with correct IQ; post-game screen plays count-up.
- **Phase 3:** Google sign-in on Android; Apple sign-in on real iOS device; with two accounts on two devices, solving on A reorders B's leaderboard within ~1s; tier chips switch list under 200ms.
- **Phase 4:** trigger every achievement once; profile-mode build holds 60fps with particles; neon theme passes WCAG AA contrast.
- **Phase 5:** airplane-mode mid-game → "Pending sync (1)" badge; reconnect clears badge and IQ is overwritten by server value; manually editing local DB to IQ=200 then syncing → server recomputes correctly; curl with bogus `client_solution` → 422.
- **Phase 6:** sandbox Apple/test Google account purchase removes ads, sets lives=5, unlocks Evil; Restore on fresh install returns Pro.
- **Phase 7:** physical device check on latest + n-2 OS versions; TestFlight + Play internal test with ≥5 testers; privacy policy + ToS URLs resolve.

## Cross-machine continuation

After ExitPlanMode and your approval, the very first implementation steps will be:

1. Create `/media/Windows1/Projectz/HeffelHoff-Sudoku/docs/PLAN.md` with this content.
2. Create `/media/Windows1/Projectz/HeffelHoff-Sudoku/.gitignore` (Flutter + Dart + JetBrains + VSCode + `.env*` + `**/google-services.json` + `**/GoogleService-Info.plist`).
3. Create `/media/Windows1/Projectz/HeffelHoff-Sudoku/README.md` with: build commands including the `--dart-define` Supabase incantation, Supabase project URL, link to `docs/PLAN.md`, and a one-liner about where to put the service-role key for Edge Functions.
4. `git init` (you'll need to confirm — currently not a git repo) and an initial commit so the plan travels via git.

That way any clone on any machine has the full plan + build instructions in-tree.
