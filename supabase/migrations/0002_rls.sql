-- =====================================================================
-- Row Level Security policies (idempotent: safe to re-run).
-- =====================================================================

alter table public.profiles            enable row level security;
alter table public.puzzles             enable row level security;
alter table public.puzzle_attempts     enable row level security;
alter table public.leaderboard_entries enable row level security;
alter table public.achievements        enable row level security;
alter table public.user_achievements   enable row level security;
alter table public.purchases           enable row level security;

-- profiles
drop policy if exists profiles_select_all on public.profiles;
create policy profiles_select_all on public.profiles for select using (true);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- puzzles (read for any authenticated user; writes via service role only)
drop policy if exists puzzles_select_auth on public.puzzles;
create policy puzzles_select_auth on public.puzzles
  for select to authenticated using (true);

-- puzzle_attempts (owner read/insert; updates via service role only)
drop policy if exists attempts_select_own on public.puzzle_attempts;
create policy attempts_select_own on public.puzzle_attempts
  for select using (auth.uid() = user_id);

drop policy if exists attempts_insert_own on public.puzzle_attempts;
create policy attempts_insert_own on public.puzzle_attempts
  for insert with check (auth.uid() = user_id);

-- leaderboard_entries (world-readable; writes via trigger)
drop policy if exists leaderboard_select_all on public.leaderboard_entries;
create policy leaderboard_select_all on public.leaderboard_entries
  for select using (true);

-- achievements (world-readable definitions)
drop policy if exists achievements_select_all on public.achievements;
create policy achievements_select_all on public.achievements for select using (true);

-- user_achievements (owner read/insert)
drop policy if exists user_ach_select_own on public.user_achievements;
create policy user_ach_select_own on public.user_achievements
  for select using (auth.uid() = user_id);

drop policy if exists user_ach_insert_own on public.user_achievements;
create policy user_ach_insert_own on public.user_achievements
  for insert with check (auth.uid() = user_id);

-- purchases (owner read; writes via Edge Function only)
drop policy if exists purchases_select_own on public.purchases;
create policy purchases_select_own on public.purchases
  for select using (auth.uid() = user_id);
