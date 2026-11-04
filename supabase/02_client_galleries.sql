-- =====================================================================
-- LASCOT STUDIO — private client galleries
--
-- Run ONCE in: Supabase Dashboard -> SQL Editor -> New query -> paste -> Run.
-- Safe to run again.
--
-- How it works
--   * The owner creates a gallery in Admin -> Client galleries and uploads photos.
--   * Each gallery gets a long random code (64 characters) that cannot be guessed.
--   * The client opens  gallery.html#<code>  and can view and download everything.
--   * Visitors cannot list, search or read any gallery: only the function
--     get_client_gallery() can return a gallery, and only when it is given the
--     exact code, the gallery is switched on and it has not expired.
-- =====================================================================

-- Who is the owner? (the same rule your admin page already uses: profiles.role = 'owner')
create or replace function public.lascot_is_owner()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'owner');
$$;
revoke all on function public.lascot_is_owner() from public;
grant execute on function public.lascot_is_owner() to anon, authenticated;

-- ---------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------
create table if not exists public.client_galleries (
  id            uuid primary key default gen_random_uuid(),
  title         text not null check (char_length(trim(title)) between 2 and 160),
  client_name   text,
  client_email  text,
  event_date    date,
  message       text,
  token         text not null unique
                  default replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
  enabled       boolean not null default true,
  expires_at    timestamptz,
  view_count    integer not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint client_galleries_token_len check (char_length(token) >= 40)
);

create table if not exists public.gallery_photos (
  id           uuid primary key default gen_random_uuid(),
  gallery_id   uuid not null references public.client_galleries(id) on delete cascade,
  path         text not null unique,          -- file inside the "client-galleries" bucket
  thumb_path   text,                           -- small preview used in the grid
  filename     text not null,                  -- original file name, used for downloads
  kind         text not null default 'image' check (kind in ('image','video')),
  size_bytes   bigint check (size_bytes is null or size_bytes >= 0),
  sort_order   integer not null default 0,
  created_at   timestamptz not null default now()
);
create index if not exists gallery_photos_gallery_idx on public.gallery_photos (gallery_id, sort_order, created_at);

create or replace function public.lascot_touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end $$;

drop trigger if exists client_galleries_touch on public.client_galleries;
create trigger client_galleries_touch before update on public.client_galleries
  for each row execute function public.lascot_touch_updated_at();

-- ---------------------------------------------------------------------
-- Access rules: ONLY the owner can touch these tables. Visitors get nothing.
-- ---------------------------------------------------------------------
alter table public.client_galleries enable row level security;
alter table public.gallery_photos   enable row level security;

drop policy if exists "owner manages galleries" on public.client_galleries;
create policy "owner manages galleries" on public.client_galleries
  for all to authenticated using (public.lascot_is_owner()) with check (public.lascot_is_owner());

drop policy if exists "owner manages gallery photos" on public.gallery_photos;
create policy "owner manages gallery photos" on public.gallery_photos
  for all to authenticated using (public.lascot_is_owner()) with check (public.lascot_is_owner());

revoke all on public.client_galleries, public.gallery_photos from anon;

-- ---------------------------------------------------------------------
-- The one door visitors can use: give it the exact code, get that gallery.
-- ---------------------------------------------------------------------
create or replace function public.get_client_gallery(p_token text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare g public.client_galleries; res jsonb;
begin
  if p_token is null or char_length(p_token) < 40 then
    return null;
  end if;

  select * into g from public.client_galleries
   where token = p_token
     and enabled
     and (expires_at is null or expires_at > now());
  if not found then
    return null;
  end if;

  update public.client_galleries set view_count = view_count + 1 where id = g.id;

  select jsonb_build_object(
    'title', g.title,
    'client_name', g.client_name,
    'event_date', g.event_date,
    'message', g.message,
    'expires_at', g.expires_at,
    'bucket', 'client-galleries',
    'photos', coalesce((
      select jsonb_agg(jsonb_build_object(
               'path', p.path, 'thumb', p.thumb_path, 'filename', p.filename,
               'kind', p.kind, 'size', p.size_bytes)
             order by p.sort_order, p.created_at)
      from public.gallery_photos p where p.gallery_id = g.id), '[]'::jsonb)
  ) into res;
  return res;
end $$;

revoke all on function public.get_client_gallery(text) from public;
grant execute on function public.get_client_gallery(text) to anon, authenticated;

-- ---------------------------------------------------------------------
-- Storage bucket for the photos. Files are named  <code>/<random>.jpg  so a
-- file's address cannot be guessed. Visitors cannot list the bucket; only the
-- owner can upload, replace, list or delete.
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('client-galleries', 'client-galleries', true, 52428800,
        array['image/jpeg','image/png','image/webp','video/mp4','video/webm','video/quicktime'])
on conflict (id) do update
  set public = true,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "owner lists client gallery files" on storage.objects;
create policy "owner lists client gallery files" on storage.objects
  for select to authenticated using (bucket_id = 'client-galleries' and public.lascot_is_owner());

drop policy if exists "owner uploads client gallery files" on storage.objects;
create policy "owner uploads client gallery files" on storage.objects
  for insert to authenticated with check (bucket_id = 'client-galleries' and public.lascot_is_owner());

drop policy if exists "owner updates client gallery files" on storage.objects;
create policy "owner updates client gallery files" on storage.objects
  for update to authenticated
  using (bucket_id = 'client-galleries' and public.lascot_is_owner())
  with check (bucket_id = 'client-galleries' and public.lascot_is_owner());

drop policy if exists "owner deletes client gallery files" on storage.objects;
create policy "owner deletes client gallery files" on storage.objects
  for delete to authenticated using (bucket_id = 'client-galleries' and public.lascot_is_owner());
