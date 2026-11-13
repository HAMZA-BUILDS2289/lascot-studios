-- =====================================================================
-- LASCOT STUDIO — online payments with Paystack (deposit or full price)
-- Run ONCE in Supabase -> SQL Editor (safe to run again). Only ADDS things.
-- =====================================================================

alter table public.bookings add column if not exists paid_kobo       bigint not null default 0;
alter table public.bookings add column if not exists payment_status  text   not null default 'unpaid';

-- Every payment attempt. Written only by the server (never by visitors).
create table if not exists public.booking_payments (
  id            uuid primary key default gen_random_uuid(),
  booking_ref   text not null,
  reference     text not null unique,           -- our reference sent to Paystack
  kind          text not null check (kind in ('deposit', 'full', 'balance')),
  amount_kobo   bigint not null check (amount_kobo > 0),
  status        text not null default 'pending' check (status in ('pending', 'paid')),
  provider_ref  text,
  fees_kobo     bigint,
  paid_at       timestamptz,
  created_at    timestamptz not null default now()
);
create index if not exists booking_payments_booking on public.booking_payments (booking_ref);
alter table public.booking_payments enable row level security;
revoke all on public.booking_payments from anon, authenticated;
grant select on public.booking_payments to authenticated;
grant all on public.booking_payments to service_role;

drop policy if exists "owner reads payments" on public.booking_payments;
create policy "owner reads payments" on public.booking_payments for select to authenticated
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'owner'));

-- Marks a payment as paid exactly once and updates the booking. Server only.
create or replace function public.record_booking_payment(p_reference text, p_provider_ref text, p_amount bigint, p_fees bigint, p_paid_at timestamptz)
returns text language plpgsql security definer set search_path = public as $$
declare pay public.booking_payments; total bigint; due bigint;
begin
  select * into pay from public.booking_payments where reference = p_reference for update;
  if not found then return 'unknown'; end if;
  if pay.status = 'paid' then return 'already'; end if;
  if p_amount <> pay.amount_kobo then return 'amount_mismatch'; end if;
  update public.booking_payments
     set status = 'paid', provider_ref = p_provider_ref, fees_kobo = p_fees, paid_at = coalesce(p_paid_at, now())
   where id = pay.id;
  update public.bookings
     set paid_kobo = paid_kobo + pay.amount_kobo,
         payment_status = case when pay.kind in ('full', 'balance') then 'paid' else 'deposit_paid' end
   where reference = pay.booking_ref;
  return 'ok';
end $$;

revoke all on function public.record_booking_payment(text, text, bigint, bigint, timestamptz) from public, anon, authenticated;
grant execute on function public.record_booking_payment(text, text, bigint, bigint, timestamptz) to service_role;

-- Settings the owner can change in the dashboard (Payments page)
do $$ begin
  if not exists (select 1 from public.website_settings where key = 'payments') then
    insert into public.website_settings (key, value) values ('payments', '{"enabled": true, "deposit_percent": 50}'::jsonb);
  end if;
exception when others then null;  -- the website works with these defaults even if this is skipped
end $$;

select 'Payments ready' as result;
