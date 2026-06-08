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

  if target_room.expires_at <= now()
    or target_room.created_at <= now() - interval '60 seconds' then
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

  select gs.seat_value::smallint
  into open_seat
  from generate_series(1, target_room.max_players) as gs(seat_value)
  where not exists (
    select 1
    from public.room_players rp
    where rp.room_id = target_room_id
      and rp.seat = gs.seat_value
      and rp.left_at is null
  )
  order by gs.seat_value
  limit 1;

  if open_seat is null then
    raise exception 'Room is full.';
  end if;

  insert into public.room_players (room_id, user_id, seat)
  values (target_room_id, current_user_id, open_seat);

  return target_room;
end;
$$;

revoke execute on function public.join_room(uuid) from public;
revoke execute on function public.join_room(uuid) from anon;
grant execute on function public.join_room(uuid) to authenticated;
