drop policy if exists rooms_select_accessible on public.rooms;
drop policy if exists rooms_update_host on public.rooms;
drop policy if exists room_players_select_room_members on public.room_players;
drop policy if exists room_players_insert_self_join on public.room_players;
drop policy if exists room_players_update_self_or_host on public.room_players;
drop policy if exists rounds_select_room_members on public.rounds;
drop policy if exists rounds_insert_host on public.rounds;
drop policy if exists rounds_update_host on public.rounds;
drop policy if exists submissions_select_round_members on public.submissions;
drop policy if exists submissions_insert_round_members on public.submissions;
drop policy if exists ai_judgements_select_round_members on public.ai_judgements;
drop policy if exists scores_select_round_members on public.scores;

create schema if not exists app_private;
revoke all on schema app_private from public;
grant usage on schema app_private to authenticated;

alter function public.set_updated_at() set schema app_private;
alter function public.handle_new_user() set schema app_private;
alter function public.is_room_member(uuid, uuid) set schema app_private;
alter function public.is_room_host(uuid, uuid) set schema app_private;
alter function public.room_player_count(uuid) set schema app_private;
alter function public.can_join_room(uuid, uuid) set schema app_private;
alter function public.can_access_round(uuid, uuid) set schema app_private;

revoke all on function app_private.set_updated_at() from public;
revoke all on function app_private.handle_new_user() from public;
revoke all on function app_private.is_room_member(uuid, uuid) from public;
revoke all on function app_private.is_room_host(uuid, uuid) from public;
revoke all on function app_private.room_player_count(uuid) from public;
revoke all on function app_private.can_join_room(uuid, uuid) from public;
revoke all on function app_private.can_access_round(uuid, uuid) from public;

grant execute on function app_private.is_room_member(uuid, uuid) to authenticated;
grant execute on function app_private.is_room_host(uuid, uuid) to authenticated;
grant execute on function app_private.room_player_count(uuid) to authenticated;
grant execute on function app_private.can_join_room(uuid, uuid) to authenticated;
grant execute on function app_private.can_access_round(uuid, uuid) to authenticated;

create or replace function app_private.is_room_member(check_room_id uuid, check_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.room_players rp
    where rp.room_id = check_room_id
      and rp.user_id = check_user_id
      and rp.left_at is null
  );
$$;

create or replace function app_private.is_room_host(check_room_id uuid, check_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.rooms r
    where r.id = check_room_id
      and r.host_user_id = check_user_id
  );
$$;

create or replace function app_private.room_player_count(check_room_id uuid)
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select count(*)::integer
  from public.room_players rp
  where rp.room_id = check_room_id
    and rp.left_at is null;
$$;

create or replace function app_private.can_join_room(check_room_id uuid, check_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.rooms r
    where r.id = check_room_id
      and r.status = 'waiting'
      and r.expires_at > now()
      and (
        app_private.is_room_member(check_room_id, check_user_id)
        or app_private.room_player_count(check_room_id) < r.max_players
      )
  );
$$;

create or replace function app_private.can_access_round(check_round_id uuid, check_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.rounds rd
    where rd.id = check_round_id
      and (
        app_private.is_room_member(rd.room_id, check_user_id)
        or app_private.is_room_host(rd.room_id, check_user_id)
      )
  );
$$;

create or replace function app_private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, display_name, auth_provider, avatar_url)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'display_name', ''), 'Player'),
    new.app_metadata->>'provider',
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create or replace function app_private.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create policy rooms_select_accessible
on public.rooms for select
to authenticated
using (
  (status = 'waiting' and expires_at > now())
  or host_user_id = (select auth.uid())
  or app_private.is_room_member(id, (select auth.uid()))
);

create policy rooms_update_host
on public.rooms for update
to authenticated
using (app_private.is_room_host(id, (select auth.uid())))
with check (app_private.is_room_host(id, (select auth.uid())));

create policy room_players_select_room_members
on public.room_players for select
to authenticated
using (
  app_private.is_room_member(room_id, (select auth.uid()))
  or app_private.is_room_host(room_id, (select auth.uid()))
);

create policy room_players_insert_self_join
on public.room_players for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and app_private.can_join_room(room_id, user_id)
);

create policy room_players_update_self_or_host
on public.room_players for update
to authenticated
using (
  user_id = (select auth.uid())
  or app_private.is_room_host(room_id, (select auth.uid()))
)
with check (
  user_id = (select auth.uid())
  or app_private.is_room_host(room_id, (select auth.uid()))
);

create policy rounds_select_room_members
on public.rounds for select
to authenticated
using (
  app_private.is_room_member(room_id, (select auth.uid()))
  or app_private.is_room_host(room_id, (select auth.uid()))
);

create policy rounds_insert_host
on public.rounds for insert
to authenticated
with check (app_private.is_room_host(room_id, (select auth.uid())));

create policy rounds_update_host
on public.rounds for update
to authenticated
using (app_private.is_room_host(room_id, (select auth.uid())))
with check (app_private.is_room_host(room_id, (select auth.uid())));

create policy submissions_select_round_members
on public.submissions for select
to authenticated
using (app_private.can_access_round(round_id, (select auth.uid())));

create policy submissions_insert_round_members
on public.submissions for insert
to authenticated
with check (
  submitted_by = (select auth.uid())
  and app_private.can_access_round(round_id, (select auth.uid()))
  and (
    is_team_submission
    or user_id = (select auth.uid())
  )
);

create policy ai_judgements_select_round_members
on public.ai_judgements for select
to authenticated
using (app_private.can_access_round(round_id, (select auth.uid())));

create policy scores_select_round_members
on public.scores for select
to authenticated
using (app_private.can_access_round(round_id, (select auth.uid())));

drop policy if exists targets_public_read on storage.objects;

create index if not exists ai_judgements_round_id_idx on public.ai_judgements (round_id);
create index if not exists rooms_host_user_id_idx on public.rooms (host_user_id);
create index if not exists rounds_target_image_id_idx on public.rounds (target_image_id);
create index if not exists scores_submission_id_idx on public.scores (submission_id);
create index if not exists scores_user_id_idx on public.scores (user_id);
create index if not exists submissions_user_id_idx on public.submissions (user_id);;
