-- =====================================================================
-- LASCOT STUDIO — package sample pictures + "number of photos" options
-- Run ONCE in Supabase -> SQL Editor (safe to run again).
-- It only ADDS things; nothing existing is changed or removed.
-- =====================================================================

-- Packages: sample pictures, photo-count options with prices, custom quantity
alter table public.service_packages add column if not exists sample_images       text[]  not null default '{}';
alter table public.service_packages add column if not exists photo_options       jsonb   not null default '[]'::jsonb;
alter table public.service_packages add column if not exists allow_custom_photos boolean not null default false;
alter table public.service_packages add column if not exists custom_photos_note  text;

-- Bookings: remember which option the customer picked
alter table public.bookings add column if not exists photo_choice text;

-- Called by the booking form right after a booking is sent. It can only fill in
-- the choice for the booking whose reference the visitor just received, only once,
-- and only within 15 minutes.
create or replace function public.set_booking_photo_choice(p_ref text, p_choice text)
returns boolean language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  if p_ref is null or p_choice is null or char_length(p_choice) > 200 then return false; end if;
  update public.bookings
     set photo_choice = trim(p_choice)
   where reference = p_ref
     and photo_choice is null
     and created_at > now() - interval '15 minutes';
  get diagnostics n = row_count;
  return n > 0;
end $$;

revoke all on function public.set_booking_photo_choice(text, text) from public;
grant execute on function public.set_booking_photo_choice(text, text) to anon, authenticated;
