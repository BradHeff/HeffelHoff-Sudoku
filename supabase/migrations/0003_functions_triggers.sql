-- =====================================================================
-- Triggers + helper functions. Run AFTER 0002_rls.sql.
-- =====================================================================

-- ---- handle_new_user: seeds public.profiles on auth.users insert ----
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  is_anon boolean;
  display text;
begin
  is_anon := coalesce(new.is_anonymous, false)
          or (new.raw_app_meta_data->>'provider' = 'anonymous');

  -- Display name: use email prefix when available, else "Player#NNNN"
  if new.email is not null and length(new.email) > 0 then
    display := split_part(new.email, '@', 1);
    if length(display) < 2 then display := 'Player' || substr(new.id::text, 1, 4); end if;
    if length(display) > 24 then display := substr(display, 1, 24); end if;
  else
    display := 'Player' || substr(new.id::text, 1, 4);
  end if;

  insert into public.profiles (id, display_name, is_anonymous)
  values (new.id, display, is_anon)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---- updated_at maintenance for profiles ----
create or replace function public.set_updated_at()
returns trigger
language plpgsql as $$
begin new.updated_at := now(); return new; end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ---- compute_iq: server-side IQ formula (used in Phase 5) ----
-- Mirrors lib/features/sudoku/application/iq_calculator.dart and the
-- formula in docs/PLAN.md.
create or replace function public.compute_iq(
  p_difficulty difficulty_tier,
  p_time_seconds integer,
  p_mistakes integer,
  p_hints_used integer
) returns smallint
language plpgsql immutable as $$
declare
  base int;
  target int;
  bonus_cap int;
  penalty_cap int;
  ratio float;
  time_component float;
  raw_iq float;
begin
  case p_difficulty
    when 'easy'   then base := 100; target := 420;  bonus_cap := 12; penalty_cap := 10;
    when 'medium' then base := 115; target := 720;  bonus_cap := 15; penalty_cap := 12;
    when 'hard'   then base := 130; target := 1200; bonus_cap := 18; penalty_cap := 15;
    when 'expert' then base := 145; target := 1800; bonus_cap := 22; penalty_cap := 18;
    when 'evil'   then base := 160; target := 2700; bonus_cap := 28; penalty_cap := 22;
  end case;

  ratio := p_time_seconds::float / target::float;
  if ratio <= 1.0 then
    time_component := bonus_cap * (1.0 - ratio);
  else
    time_component := -penalty_cap * least(ratio - 1.0, 2.0) / 2.0;
  end if;

  raw_iq := base + time_component - (p_mistakes * 4) - (p_hints_used * 6);
  return greatest(70, least(200, round(raw_iq)))::smallint;
end;
$$;

-- ---- update_leaderboard_on_attempt: keeps leaderboard_entries fresh ----
-- Fires AFTER INSERT OR UPDATE on puzzle_attempts. Upserts only when
-- new IQ exceeds the existing best (tie-break: lower time_seconds).
create or replace function public.update_leaderboard_on_attempt()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  current_best_iq int;
  current_best_time int;
  effective_iq smallint;
begin
  -- Skip non-completed or no-IQ rows.
  if new.completed is not true or coalesce(new.iq_score, new.iq_score_client) is null then
    return new;
  end if;
  effective_iq := coalesce(new.iq_score, new.iq_score_client);

  select best_iq, best_time_seconds
    into current_best_iq, current_best_time
    from public.leaderboard_entries
    where user_id = new.user_id and difficulty = new.difficulty;

  if current_best_iq is null
     or effective_iq > current_best_iq
     or (effective_iq = current_best_iq
         and coalesce(new.time_seconds, 999999) < coalesce(current_best_time, 999999))
  then
    insert into public.leaderboard_entries (
      user_id, difficulty, best_iq, best_attempt_id,
      best_time_seconds, achieved_at
    ) values (
      new.user_id, new.difficulty, effective_iq, new.id,
      coalesce(new.time_seconds, 0),
      coalesce(new.completed_at, now())
    )
    on conflict (user_id, difficulty) do update set
      best_iq           = excluded.best_iq,
      best_attempt_id   = excluded.best_attempt_id,
      best_time_seconds = excluded.best_time_seconds,
      achieved_at       = excluded.achieved_at;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_update_leaderboard on public.puzzle_attempts;
create trigger trg_update_leaderboard
  after insert or update on public.puzzle_attempts
  for each row execute function public.update_leaderboard_on_attempt();
