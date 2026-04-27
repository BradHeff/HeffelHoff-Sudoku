-- =====================================================================
-- HeffelHoff Sudoku — initial schema
-- Run via:
--   supabase db push          (CLI, recommended)
--   or paste into Supabase Dashboard → SQL Editor and run
-- See docs/PLAN.md §Database schema for canonical reference.
-- =====================================================================

create type difficulty_tier as enum ('easy','medium','hard','expert','evil');

-- ============= PROFILES =============
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
create index profiles_display_name_idx
  on public.profiles using gin (to_tsvector('simple', display_name));

-- ============= PUZZLES =============
-- Stored only when first solved/submitted, so the server can verify
-- future submissions of the same seed in Phase 5.
create table public.puzzles (
  id                uuid primary key default gen_random_uuid(),
  seed              bigint not null,
  difficulty        difficulty_tier not null,
  clues             text not null,           -- 81-char string, '0' = blank
  solution          text not null,           -- 81-char string
  clue_count        smallint not null,
  generator_version smallint not null default 1,
  created_at        timestamptz not null default now(),
  unique (seed, difficulty, generator_version)
);
create index puzzles_difficulty_idx on public.puzzles (difficulty);

-- ============= PUZZLE ATTEMPTS =============
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
  iq_score        smallint,                  -- authoritative (Phase 5 server-side recompute)
  client_solution text,
  client_version  text,
  created_at      timestamptz not null default now()
);
create index puzzle_attempts_user_idx
  on public.puzzle_attempts (user_id, completed_at desc);
create index puzzle_attempts_tier_iq_idx
  on public.puzzle_attempts (difficulty, iq_score desc) where completed = true;

-- ============= LEADERBOARD (best IQ per (user, tier)) =============
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

-- ============= ACHIEVEMENTS =============
create table public.achievements (
  code        text primary key,
  title       text not null,
  description text not null,
  icon_key    text not null,
  rarity      text not null check (rarity in ('common','rare','epic','legendary')),
  sort_order  int not null default 0
);

create table public.user_achievements (
  user_id          uuid not null references auth.users(id) on delete cascade,
  achievement_code text not null references public.achievements(code) on delete cascade,
  unlocked_at      timestamptz not null default now(),
  context          jsonb,
  primary key (user_id, achievement_code)
);

-- ============= PURCHASES (audit trail) =============
create table public.purchases (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  platform     text not null check (platform in ('ios','android')),
  product_id   text not null,
  receipt_hash text not null,
  verified     boolean not null default false,
  raw_response jsonb,
  created_at   timestamptz not null default now(),
  unique (platform, receipt_hash)
);
