-- =====================================================================
-- Direct FK from leaderboard_entries.user_id → profiles.id so PostgREST
-- can resolve the embedded `profiles!inner(...)` join used by
-- lib/features/leaderboard/data/leaderboard_repository.dart.
--
-- Both leaderboard_entries.user_id and profiles.id reference
-- auth.users(id), but PostgREST only traverses FKs within exposed
-- schemas (public). Adding this redundant-but-harmless direct FK in
-- public makes the relationship visible to the auto-API.
--
-- BEFORE adding the FK we backfill any auth.users that are missing a
-- profiles row — this happens to anyone who signed up before the
-- handle_new_user trigger was deployed (or if the trigger ever fails),
-- and would otherwise cause this migration to fail with a 23503 FK
-- violation.
--
-- Idempotent: safe to re-run.
-- =====================================================================

-- 1) Backfill orphaned auth.users → profiles.
insert into public.profiles (id, display_name, is_anonymous)
select
  u.id,
  case
    when u.email is not null and length(u.email) > 0
      then substr(split_part(u.email, '@', 1), 1, 24)
    else 'Player' || substr(u.id::text, 1, 4)
  end as display_name,
  coalesce(u.is_anonymous, false)
    or (u.raw_app_meta_data->>'provider' = 'anonymous')
    as is_anonymous
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null
on conflict (id) do nothing;

-- 2) Add the direct FK if it doesn't already exist.
do $$ begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'leaderboard_entries_user_id_profiles_fkey'
      and conrelid = 'public.leaderboard_entries'::regclass
  ) then
    alter table public.leaderboard_entries
      add constraint leaderboard_entries_user_id_profiles_fkey
      foreign key (user_id) references public.profiles(id) on delete cascade;
  end if;
end $$;

-- 3) Force PostgREST to refresh its cached schema so the new FK + any
-- tables added by earlier migrations become immediately queryable.
notify pgrst, 'reload schema';
