-- =====================================================================
-- Privacy fix: never expose email prefixes as public display_names.
--
-- Before this migration the handle_new_user() trigger seeded
-- profiles.display_name from `split_part(email, '@', 1)`, which leaks
-- the email's local-part on the public leaderboard. Two changes:
--
--   1. Replace the trigger so new accounts always get a neutral
--      "Player####" placeholder. Users set their real public username
--      via the AccountSheet in the app.
--
--   2. Backfill existing profiles whose display_name still equals
--      the email prefix — reset them to a Player#### placeholder so
--      the leak is plugged for accounts that pre-date this migration.
--      Custom display_names that the user has already set are left
--      alone.
--
-- Idempotent: safe to re-run.
-- =====================================================================

-- 1) Replace the trigger function.
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

  -- Always neutral. Users override via the in-app username editor.
  display := 'Player' || substr(new.id::text, 1, 4);

  insert into public.profiles (id, display_name, is_anonymous)
  values (new.id, display, is_anon)
  on conflict (id) do nothing;
  return new;
end;
$$;

-- 2) Backfill: any existing profile whose display_name matches the
-- email's local-part is reset to a Player#### placeholder.
update public.profiles p
set display_name = 'Player' || substr(p.id::text, 1, 4)
from auth.users u
where u.id = p.id
  and u.email is not null
  and length(u.email) > 0
  and p.display_name = substr(split_part(u.email, '@', 1), 1, 24);

-- Force the schema cache to pick up any pending changes.
notify pgrst, 'reload schema';
