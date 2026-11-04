-- LASCOT STUDIO starter content, part 6 of 8: journal article 5 of 6 (needs part 1 first)
-- Run in Supabase -> SQL Editor. Safe to run again (existing rows are skipped).

do $a$
begin
  if not exists (select 1 from public.blog_posts where slug = 'behind-the-lens-understanding-the-photography-process') then
    perform public.lascot_seed_insert('blog_posts', jsonb_build_object(
      'slug', 'behind-the-lens-understanding-the-photography-process',
      'title', 'Behind the Lens: Understanding the Photography Process',
      'subtitle', 'From the first message to the final download, here is what really happens when you work with a photography studio.',
      'excerpt', 'A clear walk-through of the photography process, from booking and planning to the shoot, editing and delivery.',
      'author', 'Lascot Studio', 'status', 'published', 'featured', false,
      'seo_title', 'Behind the Lens: The Photography Process | Lascot Studio',
      'meta_description', 'What really happens in a professional photography session: booking, planning, the shoot, editing and delivery.',
      'created_at', now() - interval '11 days', 'published_at', now() - interval '11 days',
      'body', $b$Good photographs seem effortless, which hides how much goes into them. Knowing the process helps you prepare, relax and get the best from your session. Here is how it typically works at a professional studio.

## 1. The enquiry and booking

Everything starts with a message. You tell us who you are, what you need and which service interests you. We reply to discuss the details, agree a package and confirm a session. A booking request is not a confirmed booking until the studio has replied.

## 2. Planning the look

Before the session we talk about how the photographs will be used, how you want to be seen and what you plan to wear. A short conversation here saves time later and prevents surprises on the day. This is also the moment to ask questions. Nothing is too small.

## 3. Setting the stage

On the day, the studio is prepared before you arrive: backdrop, lighting and camera settings are planned for the look we discussed. When you walk in, the technical work is largely done, so the attention can go to you.

## 4. The shoot

Direction is the heart of a session. You are guided through posture and expression, with small adjustments that make a visible difference: a shifted shoulder, a lowered chin, a thought that brings a natural smile. We pause regularly to check frames, often together, so you can see the result and relax.

> The camera is only a part of the process. The conversation is where most of a good portrait is made.

## 5. Selecting the best frames

A session produces many more frames than you will ever need. We review them carefully, choosing the strongest for expression, light and composition. Selecting is a skill in itself, because the technically perfect frame is not always the one that looks most like you.

## 6. Editing and retouching

Chosen images are edited for colour, contrast and tone, then retouched with restraint. We remove distractions and tidy small details, but we do not reshape you. The aim is to look like yourself on your best day.

## 7. Private delivery

Finally, your photographs are uploaded to a private gallery. You receive a link that only you can use, where you can view your photographs and download them all together. The link is for you alone: please do not share it publicly.

## What to take from this

A professional session is a collaboration with clear stages. When you understand them, you can prepare well, ask the right questions and walk away with photographs you are proud of.$b$));
  end if;
end
$a$;
