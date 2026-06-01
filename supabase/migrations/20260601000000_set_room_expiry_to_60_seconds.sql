alter table public.rooms
  alter column expires_at set default (now() + interval '60 seconds');

comment on column public.rooms.expires_at is
  'Rooms are joinable for 60 seconds after creation.';
