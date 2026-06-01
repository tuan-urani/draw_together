alter table public.target_images
  add column if not exists mode public.room_mode not null
  default 'versus'::public.room_mode;

create index if not exists target_images_active_mode_idx
  on public.target_images (mode, active);

comment on column public.target_images.mode is
  'Gameplay mode allowed to select this target: coop or versus.';;
