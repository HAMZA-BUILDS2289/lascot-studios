-- LASCOT STUDIO starter content, part 8 of 8: final check
-- Run in Supabase -> SQL Editor. Safe to run again (existing rows are skipped).

select
  (select count(*) from public.services) as services,
  (select count(*) from public.service_packages) as packages,
  (select count(*) from public.blog_posts where status = 'published') as published_articles;
