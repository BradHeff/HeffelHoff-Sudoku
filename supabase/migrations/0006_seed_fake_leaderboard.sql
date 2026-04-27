-- =====================================================================
-- Seed the leaderboard with 50 synthetic users + their entries so the
-- top-100 looks populated before real users dominate.
--
-- Properties:
--   - Idempotent. Re-running is a no-op (ON CONFLICT DO NOTHING).
--   - Never overwrites real users — UUIDs are derived from md5 of a
--     dedicated namespace, collision with real auth.users.id is
--     astronomically unlikely. The username UPDATE is also gated by a
--     "still on Player#### placeholder" predicate as a safety net.
--   - Tier participation pyramid: 100% Easy / 75% Medium / 50% Hard /
--     25% Expert / 10% Evil so harder tiers feel scarcer + more elite.
--   - IQs are computed via the same compute_iq() function the app uses
--     so seeded scores are indistinguishable from real player scores.
--   - Lets the existing update_leaderboard_on_attempt trigger upsert
--     leaderboard_entries; we only insert puzzle_attempts.
--
-- To remove the seeded data later:
--   delete from auth.users
--    where raw_app_meta_data->>'provider' = 'hh_seed';
-- =====================================================================

do $$
declare
  i int;
  tier_idx int;
  fake_uid uuid;
  attempt_id uuid;
  tier difficulty_tier;
  username text;
  iq smallint;
  time_seconds int;
  mistakes smallint;
  achieved timestamptz;
  rnd int;
  has_entry boolean;
  target int;
  usernames text[] := array[
    'NeonFox','QuasarQueen','PixelBard','CipherSloth','GlitchKing',
    'NebulaCat','ZenithRook','OrbitJay','VortexLynx','SpectraOwl',
    'EmberJade','FluxBlaze','ProtonRed','AlloyVox','RidgeCrest',
    'AzureFin','CrimsonHex','IndigoMoth','MarbleSky','OnyxStorm',
    'PythonZen','QuartzVein','RogueGate','SolarFin','TitanLark',
    'UmberFox','ValkyrSnow','WispRune','XenonHaze','YarrowJay',
    'ZestfulOwl','AmberLynx','BinaryBee','CometSilk','DriftWolf',
    'EchoVane','FrostHaven','GravesLake','HelixDawn','IvyCobra',
    'JubilantOx','KettleHawk','LunarOpus','MesaGhost','NorthStar',
    'OakshadeOwl','PrismRook','RiftWanderer','StoneVesper','TwilightSong'
  ];
begin
  for i in 1..50 loop
    fake_uid := md5('hh_seed_user_' || i)::uuid;
    username := usernames[i];

    insert into auth.users (
      id, instance_id, aud, role,
      raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, is_anonymous
    ) values (
      fake_uid,
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      jsonb_build_object('provider', 'hh_seed', 'providers', jsonb_build_array('hh_seed')),
      '{}'::jsonb,
      now() - (interval '60 days') + (i * interval '1 hour'),
      now() - (interval '60 days') + (i * interval '1 hour'),
      false
    )
    on conflict (id) do nothing;

    update public.profiles
       set display_name = username,
           is_anonymous = false
     where id = fake_uid
       and (display_name is null or display_name like 'Player%');

    tier_idx := 0;
    for tier in select unnest(enum_range(null::difficulty_tier)) loop
      tier_idx := tier_idx + 1;

      has_entry := case tier
        when 'easy'   then true
        when 'medium' then (i % 4) <> 0
        when 'hard'   then (i % 2) = 0
        when 'expert' then (i % 4) = 0
        when 'evil'   then (i % 10) = 0
      end;

      if not has_entry then continue; end if;

      rnd := ((i * 37 + tier_idx * 13 + i * tier_idx * 7) * 11) % 200;
      if rnd < 0 then rnd := rnd + 200; end if;

      case tier
        when 'easy'   then target := 420;
        when 'medium' then target := 720;
        when 'hard'   then target := 1200;
        when 'expert' then target := 1800;
        when 'evil'   then target := 2700;
      end case;

      time_seconds := (target * (45 + (rnd % 110)) / 100)::int;
      mistakes := ((rnd / 7) % 6)::smallint;
      iq := public.compute_iq(tier, time_seconds, mistakes, 0);
      achieved := now() - (interval '1 day' * (1 + (rnd % 60)));

      attempt_id := md5('hh_seed_attempt_' || i || '_' || tier)::uuid;

      insert into public.puzzle_attempts (
        id, user_id, puzzle_seed, difficulty,
        started_at, completed_at,
        time_seconds, mistakes, hints_used, lives_used,
        completed, failed,
        iq_score_client, iq_score, client_version
      ) values (
        attempt_id, fake_uid, 0, tier,
        achieved - (interval '1 second' * time_seconds), achieved,
        time_seconds, mistakes, 0, 0,
        true, false,
        iq, iq, 'hh_seed'
      )
      on conflict (id) do nothing;
    end loop;
  end loop;
end $$;

notify pgrst, 'reload schema';
