-- =====================================================================
-- Row Level Security policies. Run AFTER 0001_init.sql.
-- =====================================================================

alter table public.profiles            enable row level security;
alter table public.puzzles             enable row level security;
alter table public.puzzle_attempts     enable row level security;
alter table public.leaderboard_entries enable row level security;
alter table public.achievements        enable row level security;
alter table public.user_achievements   enable row level security;
alter table public.purchases           enable row level security;

-- profiles: anyone can read (display_name + avatar are public for the
-- leaderboard); only owner can update; insert handled by signup trigger.
create policy profiles_select_all on public.profiles for select using (true);
create policy profiles_update_own on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- puzzles: read for any authenticated user. Writes only via service-role
-- (Edge Function in Phase 5). Phase 2/3 doesn't write to this table.
create policy puzzles_select_auth on public.puzzles
  for select to authenticated using (true);

-- puzzle_attempts: user reads/inserts their own. Updates only by
-- service-role (Phase 5 server-side IQ recompute).
create policy attempts_select_own on public.puzzle_attempts
  for select using (auth.uid() = user_id);
create policy attempts_insert_own on public.puzzle_attempts
  for insert with check (auth.uid() = user_id);

-- leaderboard_entries: world-readable (public ranking), writes only by
-- the trigger that fires on puzzle_attempts insert/update.
create policy leaderboard_select_all on public.leaderboard_entries
  for select using (true);

-- achievements (definitions): world-readable.
create policy achievements_select_all on public.achievements for select using (true);

-- user_achievements: owner read/insert.
create policy user_ach_select_own on public.user_achievements
  for select using (auth.uid() = user_id);
create policy user_ach_insert_own on public.user_achievements
  for insert with check (auth.uid() = user_id);

-- purchases: owner read; writes via Edge Function only (Phase 6).
create policy purchases_select_own on public.purchases
  for select using (auth.uid() = user_id);
