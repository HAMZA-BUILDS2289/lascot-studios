-- ============================================================
-- LASCOT STUDIO — booking date, confirm, delivered, review request
-- Safe to run more than once.
-- ============================================================

-- Bookings: the date the customer wants, and what the owner agreed
alter table public.bookings add column if not exists preferred_date  date;
alter table public.bookings add column if not exists preferred_time  text;
alter table public.bookings add column if not exists confirmed_date  date;
alter table public.bookings add column if not exists confirmed_time  text;
alter table public.bookings add column if not exists owner_message   text;
alter table public.bookings add column if not exists confirmed_at    timestamptz;
alter table public.bookings add column if not exists delivered_at    timestamptz;
alter table public.bookings add column if not exists review_token    text;
alter table public.bookings add column if not exists review_sent_at  timestamptz;

-- Reviews: remember which booking a review came from (one review per booking)
alter table public.reviews add column if not exists booking_ref text;
create unique index if not exists reviews_booking_ref_uidx on public.reviews (booking_ref) where booking_ref is not null;

-- 1) Booking form: save the preferred date right after the booking is sent.
--    Works only for the booking the visitor just made, once, within 15 minutes.
create or replace function public.set_booking_date(p_ref text, p_date date, p_time text)
returns boolean language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  if p_ref is null or p_date is null then return false; end if;
  if p_date < current_date or p_date > current_date + 730 then return false; end if;
  if p_time is not null and char_length(p_time) > 60 then return false; end if;
  update public.bookings
     set preferred_date = p_date, preferred_time = nullif(trim(p_time), '')
   where reference = p_ref
     and preferred_date is null
     and created_at > now() - interval '15 minutes';
  get diagnostics n = row_count;
  return n > 0;
end $$;
revoke all on function public.set_booking_date(text, date, text) from public;
grant execute on function public.set_booking_date(text, date, text) to anon, authenticated;

-- 2) Review page: who is this review link for? (only for delivered bookings)
create or replace function public.get_review_invite(p_token text)
returns json language plpgsql security definer set search_path = public as $$
declare b record; svc text;
begin
  if p_token is null or char_length(p_token) < 20 then return null; end if;
  select * into b from public.bookings where review_token = p_token and status = 'completed';
  if not found then return null; end if;
  select name into svc from public.services where id = b.service_id;
  return json_build_object(
    'name', split_part(coalesce(b.full_name, ''), ' ', 1),
    'service', svc,
    'done', exists (select 1 from public.reviews r where r.booking_ref = b.reference)
  );
end $$;
revoke all on function public.get_review_invite(text) from public;
grant execute on function public.get_review_invite(text) to anon, authenticated;

-- 3) Review page: save the review. It arrives as "pending" until the owner approves it.
create or replace function public.submit_booking_review(p_token text, p_name text, p_rating integer, p_body text)
returns boolean language plpgsql security definer set search_path = public as $$
declare b record;
begin
  if p_token is null or char_length(p_token) < 20 then return false; end if;
  if p_rating is null or p_rating < 1 or p_rating > 5 then return false; end if;
  if p_body is null or char_length(trim(p_body)) < 10 or char_length(p_body) > 2000 then return false; end if;
  select * into b from public.bookings where review_token = p_token and status = 'completed';
  if not found then return false; end if;
  if exists (select 1 from public.reviews r where r.booking_ref = b.reference) then return false; end if;
  insert into public.reviews (name, rating, body, status, booking_ref)
  values (left(trim(coalesce(nullif(p_name, ''), split_part(b.full_name, ' ', 1), 'Client')), 80), p_rating, trim(p_body), 'pending', b.reference);
  return true;
end $$;
revoke all on function public.submit_booking_review(text, text, integer, text) from public;
grant execute on function public.submit_booking_review(text, text, integer, text) to anon, authenticated;
