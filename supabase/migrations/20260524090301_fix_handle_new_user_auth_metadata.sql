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
    coalesce(nullif(trim(new.raw_user_meta_data->>'display_name'), ''), 'Player'),
    coalesce(new.raw_app_meta_data->>'provider', 'anonymous'),
    nullif(new.raw_user_meta_data->>'avatar_url', '')
  )
  on conflict (id) do update set
    display_name = coalesce(nullif(trim(excluded.display_name), ''), public.profiles.display_name),
    auth_provider = coalesce(excluded.auth_provider, public.profiles.auth_provider),
    avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url),
    updated_at = now();

  return new;
end;
$$;;
