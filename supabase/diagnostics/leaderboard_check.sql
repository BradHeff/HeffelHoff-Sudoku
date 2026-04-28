-- Diagnostic: did your last Medium win make it to the leaderboard?
-- Paste this entire file into Supabase Studio → SQL Editor → Run.
-- It checks the four spots a row can get stuck.

-- 1) Auth — who am I?
select 'AUTH' as step, auth.uid() as user_id;

-- 2) Profile exists?
select 'PROFILE' as step, count(*)::text as rows, display_name, is_anonymous
from public.profiles
where id = auth.uid()
group by display_name, is_anonymous;

-- 3) Puzzle attempts — every Medium row I've inserted, newest first
select 'ATTEMPTS' as step,
       difficulty,
       completed,
       failed,
       iq_score,
       iq_score_client,
       time_seconds,
       mistakes,
       hints_used,
       completed_at
from public.puzzle_attempts
where user_id = auth.uid()
  and difficulty = 'medium'
order by completed_at desc nulls last
limit 10;

-- 4) Leaderboard — my entry for Medium (if the trigger fired)
select 'LEADERBOARD_ME' as step, *
from public.leaderboard_entries
where user_id = auth.uid()
  and difficulty = 'medium';

-- 5) Where would I rank on Medium?  (counts how many beat me; rank = N+1)
with me as (
  select best_iq, best_time_seconds
  from public.leaderboard_entries
  where user_id = auth.uid() and difficulty = 'medium'
)
select 'MY_RANK' as step,
       coalesce((
         select count(*) + 1
         from public.leaderboard_entries le, me
         where le.difficulty = 'medium'
           and (le.best_iq > me.best_iq
                or (le.best_iq = me.best_iq
                    and le.best_time_seconds < me.best_time_seconds))
       ), -1) as rank;

-- 6) Bottom of the visible Medium leaderboard (rank 100) — am I above this?
select 'CUTOFF_AT_100' as step, best_iq, best_time_seconds
from public.leaderboard_entries
where difficulty = 'medium'
order by best_iq desc, achieved_at asc
offset 99 limit 1;
