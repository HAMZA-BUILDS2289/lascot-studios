-- LASCOT STUDIO starter content, part 3 of 8: journal article 2 of 6 (needs part 1 first)
-- Run in Supabase -> SQL Editor. Safe to run again (existing rows are skipped).

do $a$
begin
  if not exists (select 1 from public.blog_posts where slug = 'preparing-for-your-first-professional-photoshoot') then
    perform public.lascot_seed_insert('blog_posts', jsonb_build_object(
      'slug', 'preparing-for-your-first-professional-photoshoot',
      'title', 'Preparing for Your First Professional Photoshoot',
      'subtitle', 'A calm, practical guide to what to wear, what to expect and how to feel relaxed in front of the camera.',
      'excerpt', 'Nervous about your first session? Here is exactly how to prepare, from outfits to the night before.',
      'author', 'Lascot Studio', 'status', 'published', 'featured', false,
      'seo_title', 'How to Prepare for Your First Professional Photoshoot | Lascot Studio',
      'meta_description', 'A practical guide to preparing for your first professional photoshoot: what to wear, how to prepare and what to expect.',
      'created_at', now() - interval '3 days', 'published_at', now() - interval '3 days',
      'body', $b$If you are nervous about your first professional photoshoot, you are in good company. Most people feel a little awkward the first time a camera is pointed at them. The good news is that a session is much easier than you expect, and a little preparation makes it easier still.

## Start with the purpose

Before anything else, decide what the photographs are for. A headshot for a professional profile, a set for your personal brand, a family portrait and a team photograph all call for different looks. Knowing the purpose helps you choose outfits, backgrounds and even the expression you aim for. Share it with your photographer when you book.

## Choose your outfits carefully

Wardrobe is the part of preparation that makes the most visible difference. A few guidelines help:

- Bring two or three options so you and your photographer can choose together.
- Pick solid colours or very subtle textures. Busy patterns and large logos distract from your face.
- Choose clothes that fit well and that you already feel confident in. Comfort shows.
- Check that everything is clean and pressed. Creases are easy to see and slow to remove.
- Keep jewellery and accessories simple.

## In the days before

Look after the basics. Drink plenty of water, sleep well and avoid trying anything new on your skin right before the session. If you want a haircut or a trim, have it a few days ahead rather than the day before, so it has time to settle.

## On the day

Arrive a little early so you are not rushing. Bring your outfits, any accessories you plan to use and a comb or brush. Eat something light beforehand, because hunger shows in the face and the mood.

## What happens in the session

A good session starts with a conversation. We talk about the purpose of the images and how you want to look. The lights and backdrop are set, then you are guided through poses and expressions. You do not need to know how to pose. That is our job.

We usually review a few frames with you as we go, which helps you relax once you see how well you look. Nobody expects a perfect expression on the first frame. Relaxed expressions usually arrive after the first few minutes.

> You do not need to know how to pose. You only need to show up as yourself.

## After the session

Your photographs are selected, edited and delivered to you. At Lascot Studio, they are delivered through a private gallery link that only you can open, where you can view and download all your photographs together.

Prepare a little, arrive relaxed, and trust the process. The rest is simply being yourself.$b$));
  end if;
end
$a$;
