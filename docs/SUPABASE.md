# Supabase setup

Project URL and publishable key already live in `README.md` and `lib/core/supabase/supabase_client.dart`. This doc covers the **one-time** project configuration the dashboard needs before auth + leaderboard work end-to-end.

---

## 1. Run the migrations

Three SQL files in `supabase/migrations/`:

```
0001_init.sql                # tables: profiles, puzzles, puzzle_attempts,
                             # leaderboard_entries, achievements,
                             # user_achievements, purchases
0002_rls.sql                 # row-level security policies
0003_functions_triggers.sql  # handle_new_user, set_updated_at,
                             # compute_iq, update_leaderboard_on_attempt
```

### Option A — Supabase CLI (recommended)

```bash
# Install (Linux / macOS)
brew install supabase/tap/supabase
# or
npm install -g supabase

# Link local repo to the remote project
supabase login
supabase link --project-ref kosrtjwfjsdpxahgdpas

# Push migrations
supabase db push
```

### Option B — Dashboard SQL editor

1. Open https://supabase.com/dashboard/project/kosrtjwfjsdpxahgdpas
2. **SQL Editor** → New query
3. Paste the contents of `0001_init.sql`, run
4. Repeat for `0002_rls.sql` and `0003_functions_triggers.sql` **in order**

---

## 2. Enable auth providers

**Authentication → Providers** in the dashboard.

| Provider | Action | Required for |
|---|---|---|
| **Email** | Enabled by default. **Turn OFF "Confirm email"** while iterating (see below). | Email/password sign in + sign up |
| **Anonymous Sign-Ins** | Toggle ON. | "Continue as guest" button |
| Google (Phase 3+) | Skip until you have OAuth client IDs. | Google sign-in button |
| Apple (Phase 3+) | Skip until you have an Apple Service ID + key. | Apple sign-in button |

If anonymous is OFF, the "Continue as guest" button will show an error from Supabase — that's expected until you flip the toggle.

### Why disable "Confirm email"

By default Supabase sends a confirmation email after sign-up and blocks login until the user clicks the link. The link points to the project's **Site URL** which defaults to `http://localhost:3000` — so on a phone the link goes to a non-existent local server and you can't confirm. Result: `Email not confirmed` blocks every login.

Two ways to fix:

**Quickest (dev only)** — Authentication → Providers → Email → toggle "Confirm email" to **OFF**. Sign up + sign in works immediately, no confirmation step. Re-enable for production.

**Proper fix (when ready for production)** — Authentication → URL Configuration:

- Set **Site URL** to a real URL: a custom-domain landing page, a `https://heffelhoff-sudoku.example/auth/callback` static page, OR an Android/iOS deep-link scheme (e.g. `heffelhoff://auth/callback`) that the app handles via a deep-link plugin.
- Add the same URL to **Redirect URLs**.
- Customise the email template at Authentication → Email Templates → Confirm signup if you want to brand it.

Until either of those is done, expect the "Email not confirmed" error after sign-up. The AccountSheet surfaces Supabase's exact message — that's the signal to flip the toggle off (or finish the deep-link setup).

---

## 3. Sanity-check the leaderboard pipeline

After migrations + auth providers are set up:

1. Open the app → tap the avatar → sign up with an email (or continue as guest)
2. Solve any puzzle (Easy is fastest)
3. Open **Leaderboard** (trophy icon in the home screen header)
4. Pick the tier you played → you should be #1 with your IQ

If the leaderboard stays empty:

- **SQL Editor** → run `select * from public.puzzle_attempts order by created_at desc limit 5;` — should show your row
- Run `select * from public.leaderboard_entries;` — should show one row per (user, tier)
- If `puzzle_attempts` has the row but `leaderboard_entries` doesn't, the trigger didn't fire. Re-run `0003_functions_triggers.sql`

---

## 4. Realtime

Realtime ships enabled on every Supabase project. The Flutter client subscribes to `leaderboard_entries` filtered by `difficulty` and re-fetches the top-100 on any change. To verify live updates work:

1. Sign in on two devices (phone + emulator) with different accounts
2. Both open Leaderboard on the same tier
3. One device solves a puzzle → the other device's list reorders within ~1s

---

## 5. Service-role key (Phase 5+)

The Edge Functions in `supabase/functions/` (Phase 5: `submit-attempt`, Phase 6: `verify-purchase`) need the service-role key. Get it from **Project Settings → API** and store as a function secret — **never** commit it:

```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

The publishable (anon) key in `supabase_client.dart` is **safe** to ship in client builds — it's protected by the RLS policies in `0002_rls.sql`. The service-role key is **not** safe and must stay on the server.
