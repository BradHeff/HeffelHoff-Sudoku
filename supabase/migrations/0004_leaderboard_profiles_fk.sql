-- =====================================================================
-- Direct FK from leaderboard_entries.user_id → profiles.id so PostgREST
-- can resolve the embedded `profiles!inner(...)` join used by the
-- leaderboard query in lib/features/leaderboard/data/leaderboard_repository.dart.
--
-- Both leaderboard_entries.user_id and profiles.id reference
-- auth.users(id) but PostgREST only traverses FKs within exposed
-- schemas (public). Adding this redundant-but-harmless FK in public
-- makes the relationship visible to the auto-API.
--
-- Idempotent: re-running is safe.
-- =====================================================================

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

-- Force PostgREST to refresh its cached schema so the new FK + any
-- tables added in earlier migrations become immediately queryable.
-- (Without this, the cache lazily refreshes within a few minutes.)
notify pgrst, 'reload schema';
