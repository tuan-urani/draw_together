alter table public.target_images
  add column if not exists stroke_color text,
  add column if not exists player1_color text,
  add column if not exists player2_color text;

alter table public.target_images
  drop constraint if exists target_images_stroke_color_hex_check,
  drop constraint if exists target_images_player1_color_hex_check,
  drop constraint if exists target_images_player2_color_hex_check;

alter table public.target_images
  add constraint target_images_stroke_color_hex_check
    check (stroke_color is null or stroke_color ~* '^#[0-9a-f]{6}$'),
  add constraint target_images_player1_color_hex_check
    check (player1_color is null or player1_color ~* '^#[0-9a-f]{6}$'),
  add constraint target_images_player2_color_hex_check
    check (player2_color is null or player2_color ~* '^#[0-9a-f]{6}$');

comment on column public.target_images.stroke_color is
  'Stroke color used by all players for versus targets.';

comment on column public.target_images.player1_color is
  'Assigned stroke color for seat 1 on co-op targets.';

comment on column public.target_images.player2_color is
  'Assigned stroke color for seat 2 on co-op targets.';
