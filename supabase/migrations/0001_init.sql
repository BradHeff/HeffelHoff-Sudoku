-- =====================================================================
-- HeffelHoff Sudoku — initial schema (idempotent: safe to re-run).
-- =====================================================================

-- ============= ENUM =============
do $$ begin
  if not exists (select 1 from pg_type where typname = 'difficulty_tier') then
    create type difficulty_tier as enum ('easy','medium','hard','expert','evil');
  end if;
end $$;

-- ============= PROFILES =============
create table if not exists public.profiles (
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
create index if not exists profiles_display_name_idx
  on public.profiles using gin (to_tsvector('simple', display_name));

-- ============= PUZZLES =============
create table if not exists public.puzzles (
  id                uuid primary key default gen_random_uuid(),
  seed              bigint not null,
  difficulty        difficulty_tier not null,
  clues             text not null,
  solution          text not null,
  clue_count        smallint not null,
  generator_version smallint not null default 1,
  created_at        timestamptz not null default now(),
  unique (seed, difficulty, generator_version)
);
create index if not exists puzzles_difficulty_idx on public.puzzles (difficulty);

-- ============= PUZZLE ATTEMPTS =============
create table if not exists public.puzzle_attempts (
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
  iq_score        smallint,
  client_solution text,
  client_version  text,
  created_at      timestamptz not null default now()
);
create index if not exists puzzle_attempts_user_idx
  on public.puzzle_attempts (user_id, completed_at desc);
create index if not exists puzzle_attempts_tier_iq_idx
  on public.puzzle_attempts (difficulty, iq_score desc) where completed = true;

-- ============= LEADERBOARD =============
create table if not exists public.leaderboard_entries (
  user_id           uuid not null references auth.users(id) on delete cascade,
  difficulty        difficulty_tier not null,
  best_iq           smallint not null,
  best_attempt_id   uuid not null references public.puzzle_attempts(id) on delete cascade,
  best_time_seconds integer not null,
  achieved_at       timestamptz not null,
  primary key (user_id, difficulty)
);
create index if not exists leaderboard_tier_iq_idx
  on public.leaderboard_entries (difficulty, best_iq desc, best_time_seconds asc);

-- ============= ACHIEVEMENTS =============
create table if not exists public.achievements (
  code        text primary key,
  title       text not null,
  description text not null,
  icon_key    text not null,
  rarity      text not null check (rarity in ('common','rare','epic','legendary')),
  sort_order  int not null default 0
);

create table if not exists public.user_achievements (
  user_id          uuid not null references auth.users(id) on delete cascade,
  achievement_code text not null references public.achievements(code) on delete cascade,
  unlocked_at      timestamptz not null default now(),
  context          jsonb,
  primary key (user_id, achievement_code)
);

-- ============= PURCHASES =============
create table if not exists public.purchases (
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
