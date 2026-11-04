-- =====================================================================
-- LASCOT STUDIO — email notifications (bookings + newsletter)
-- Run ONCE in Supabase -> SQL Editor (safe to run again). Only ADDS columns.
-- =====================================================================
alter table public.bookings               add column if not exists notified_at     timestamptz;
alter table public.newsletter_subscribers add column if not exists welcome_sent_at timestamptz;
