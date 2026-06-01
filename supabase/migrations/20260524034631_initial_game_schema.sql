create type public.room_mode as enum ('coop', 'versus');
create type public.room_status as enum ('waiting', 'ready', 'drawing', 'submitting', 'scoring', 'finished', 'expired');
create type public.round_status as enum ('pending', 'drawing', 'submitting', 'scoring', 'scored', 'failed');
create type public.target_difficulty as enum ('easy', 'medium', 'hard');
create type public.ai_judgement_status as enum ('pending', 'succeeded', 'failed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Player',
  auth_provider text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_length check (char_length(display_name) between 1 and 40)
);

create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  mode public.room_mode not null,
  host_user_id uuid not null references public.profiles(id) on delete cascade,
  status public.room_status not null default 'waiting',
  max_players smallint not null default 2,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '30 minutes'),
  constraint rooms_code_format check (code ~ '^[A-Z0-9]{4,12}$'),
  constraint rooms_max_players_check check (max_players = 2)
);

create table public.room_players (
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  seat smallint not null,
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  primary key (room_id, user_id),
  constraint room_players_seat_check check (seat in (1, 2)),
  constraint room_players_room_seat_unique unique (room_id, seat)
);

create table public.target_images (
  id text primary key,
  storage_path text not null unique,
  title text not null,
  difficulty public.target_difficulty not null default 'easy',
  width integer not null default 1024,
  height integer not null default 1024,
  mime_type text not null default 'image/png',
  checksum text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint target_images_dimensions_check check (width > 0 and height > 0),
  constraint target_images_storage_path_check check (storage_path !~ '^targets/'),
  constraint target_images_mime_type_check check (mime_type in ('image/png', 'image/webp'))
);

create table public.rounds (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  mode public.room_mode not null,
  target_image_id text not null references public.target_images(id),
  status public.round_status not null default 'pending',
  started_at timestamptz,
  duration_ms integer not null default 60000,
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint rounds_duration_ms_check check (duration_ms between 10000 and 300000)
);

create table public.submissions (
  id uuid primary key default gen_random_uuid(),
  round_id uuid not null references public.rounds(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  submitted_by uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  is_team_submission boolean not null default false,
  image_path text not null unique,
  width integer not null,
  height integer not null,
  created_at timestamptz not null default now(),
  constraint submissions_dimensions_check check (width > 0 and height > 0),
  constraint submissions_team_user_check check (
    (is_team_submission and user_id is null) or
    (not is_team_submission and user_id is not null)
  )
);

create table public.ai_judgements (
  id uuid primary key default gen_random_uuid(),
  round_id uuid not null references public.rounds(id) on delete cascade,
  model text not null,
  prompt_version text not null,
  status public.ai_judgement_status not null default 'pending',
  raw_response jsonb not null default '{}'::jsonb,
  error_message text,
  created_at timestamptz not null default now()
);

create table public.scores (
  id uuid primary key default gen_random_uuid(),
  round_id uuid not null references public.rounds(id) on delete cascade,
  submission_id uuid not null references public.submissions(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  team_score integer,
  similarity_score integer not null,
  winner boolean not null default false,
  created_at timestamptz not null default now(),
  constraint scores_similarity_score_check check (similarity_score between 0 and 100),
  constraint scores_team_score_check check (team_score is null or team_score between 0 and 100),
  constraint scores_round_submission_unique unique (round_id, submission_id)
);

create index rooms_code_idx on public.rooms (code);
create index rooms_status_expires_at_idx on public.rooms (status, expires_at);
create index room_players_user_id_idx on public.room_players (user_id);
create index rounds_room_id_created_at_idx on public.rounds (room_id, created_at desc);
create index rounds_status_idx on public.rounds (status);
create index submissions_round_id_idx on public.submissions (round_id);
create index submissions_submitted_by_idx on public.submissions (submitted_by);
create index scores_round_id_idx on public.scores (round_id);
create index target_images_active_difficulty_idx on public.target_images (active, difficulty);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger rooms_set_updated_at
before update on public.rooms
for each row execute function public.set_updated_at();

create trigger rounds_set_updated_at
before update on public.rounds
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
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

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_room_member(check_room_id uuid, check_user_id uuid)
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

create or replace function public.is_room_host(check_room_id uuid, check_user_id uuid)
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

create or replace function public.room_player_count(check_room_id uuid)
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

create or replace function public.can_join_room(check_room_id uuid, check_user_id uuid)
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
        public.is_room_member(check_room_id, check_user_id)
        or public.room_player_count(check_room_id) < r.max_players
      )
  );
$$;

create or replace function public.can_access_round(check_round_id uuid, check_user_id uuid)
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
        public.is_room_member(rd.room_id, check_user_id)
        or public.is_room_host(rd.room_id, check_user_id)
      )
  );
$$;

alter table public.profiles enable row level security;
alter table public.rooms enable row level security;
alter table public.room_players enable row level security;
alter table public.target_images enable row level security;
alter table public.rounds enable row level security;
alter table public.submissions enable row level security;
alter table public.ai_judgements enable row level security;
alter table public.scores enable row level security;

create policy profiles_select_authenticated
on public.profiles for select
to authenticated
using (true);

create policy profiles_insert_own
on public.profiles for insert
to authenticated
with check (id = (select auth.uid()));

create policy profiles_update_own
on public.profiles for update
to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy rooms_select_accessible
on public.rooms for select
to authenticated
using (
  (status = 'waiting' and expires_at > now())
  or host_user_id = (select auth.uid())
  or public.is_room_member(id, (select auth.uid()))
);

create policy rooms_insert_own_host
on public.rooms for insert
to authenticated
with check (host_user_id = (select auth.uid()));

create policy rooms_update_host
on public.rooms for update
to authenticated
using (public.is_room_host(id, (select auth.uid())))
with check (public.is_room_host(id, (select auth.uid())));

create policy room_players_select_room_members
on public.room_players for select
to authenticated
using (
  public.is_room_member(room_id, (select auth.uid()))
  or public.is_room_host(room_id, (select auth.uid()))
);

create policy room_players_insert_self_join
on public.room_players for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and public.can_join_room(room_id, user_id)
);

create policy room_players_update_self_or_host
on public.room_players for update
to authenticated
using (
  user_id = (select auth.uid())
  or public.is_room_host(room_id, (select auth.uid()))
)
with check (
  user_id = (select auth.uid())
  or public.is_room_host(room_id, (select auth.uid()))
);

create policy target_images_public_active_select
on public.target_images for select
to anon, authenticated
using (active = true);

create policy rounds_select_room_members
on public.rounds for select
to authenticated
using (
  public.is_room_member(room_id, (select auth.uid()))
  or public.is_room_host(room_id, (select auth.uid()))
);

create policy rounds_insert_host
on public.rounds for insert
to authenticated
with check (public.is_room_host(room_id, (select auth.uid())));

create policy rounds_update_host
on public.rounds for update
to authenticated
using (public.is_room_host(room_id, (select auth.uid())))
with check (public.is_room_host(room_id, (select auth.uid())));

create policy submissions_select_round_members
on public.submissions for select
to authenticated
using (public.can_access_round(round_id, (select auth.uid())));

create policy submissions_insert_round_members
on public.submissions for insert
to authenticated
with check (
  submitted_by = (select auth.uid())
  and public.can_access_round(round_id, (select auth.uid()))
  and (
    is_team_submission
    or user_id = (select auth.uid())
  )
);

create policy submissions_update_submitter
on public.submissions for update
to authenticated
using (submitted_by = (select auth.uid()))
with check (submitted_by = (select auth.uid()));

create policy ai_judgements_select_round_members
on public.ai_judgements for select
to authenticated
using (public.can_access_round(round_id, (select auth.uid())));

create policy scores_select_round_members
on public.scores for select
to authenticated
using (public.can_access_round(round_id, (select auth.uid())));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('targets', 'targets', true, 5242880, array['image/png', 'image/webp']),
  ('submissions', 'submissions', false, 5242880, array['image/png', 'image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy targets_public_read
on storage.objects for select
to public
using (bucket_id = 'targets');

create policy submissions_authenticated_read
on storage.objects for select
to authenticated
using (bucket_id = 'submissions');

create policy submissions_authenticated_insert_own_folder
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'submissions'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and lower(storage.extension(name)) in ('png', 'webp')
);

create policy submissions_authenticated_update_own_objects
on storage.objects for update
to authenticated
using (
  bucket_id = 'submissions'
  and owner_id = (select auth.uid())::text
)
with check (
  bucket_id = 'submissions'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and lower(storage.extension(name)) in ('png', 'webp')
);

create policy submissions_authenticated_delete_own_objects
on storage.objects for delete
to authenticated
using (
  bucket_id = 'submissions'
  and owner_id = (select auth.uid())::text
);;
