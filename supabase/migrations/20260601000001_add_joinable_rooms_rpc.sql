create or replace function public.list_joinable_rooms(target_mode public.room_mode)
returns table (
  room_id uuid,
  code text,
  mode public.room_mode,
  status public.room_status,
  host_user_id uuid,
  max_players smallint,
  created_at timestamptz,
  expires_at timestamptz,
  player_count integer
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    r.id as room_id,
    r.code,
    r.mode,
    r.status,
    r.host_user_id,
    r.max_players,
    r.created_at,
    r.expires_at,
    count(rp.user_id)::integer as player_count
  from public.rooms r
  left join public.room_players rp
    on rp.room_id = r.id
    and rp.left_at is null
  where r.mode = target_mode
    and r.status = 'waiting'
    and r.expires_at > now()
  group by r.id
  having count(rp.user_id) < r.max_players
  order by r.created_at desc;
$$;

create or replace function public.join_room(target_room_id uuid)
returns public.rooms
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  target_room public.rooms%rowtype;
  current_user_id uuid := auth.uid();
  open_seat smallint;
begin
  if current_user_id is null then
    raise exception 'Missing authenticated user.';
  end if;

  select *
  into target_room
  from public.rooms
  where id = target_room_id
  for update;

  if not found then
    raise exception 'Room not found.';
  end if;

  if target_room.status <> 'waiting' then
    raise exception 'Room is not joinable.';
  end if;

  if target_room.expires_at <= now() then
    raise exception 'Room expired.';
  end if;

  if exists (
    select 1
    from public.room_players rp
    where rp.room_id = target_room_id
      and rp.user_id = current_user_id
      and rp.left_at is null
  ) then
    return target_room;
  end if;

  select seat
  into open_seat
  from generate_series(1, target_room.max_players) as seat
  where not exists (
    select 1
    from public.room_players rp
    where rp.room_id = target_room_id
      and rp.seat = seat
      and rp.left_at is null
  )
  order by seat
  limit 1;

  if open_seat is null then
    raise exception 'Room is full.';
  end if;

  insert into public.room_players (room_id, user_id, seat)
  values (target_room_id, current_user_id, open_seat);

  return target_room;
end;
$$;

grant execute on function public.list_joinable_rooms(public.room_mode) to authenticated;
grant execute on function public.join_room(uuid) to authenticated;
