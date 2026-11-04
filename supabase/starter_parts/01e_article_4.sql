-- LASCOT STUDIO starter content, part 5 of 8: journal article 4 of 6 (needs part 1 first)
-- Run in Supabase -> SQL Editor. Safe to run again (existing rows are skipped).

do $a$
begin
  if not exists (select 1 from public.blog_posts where slug = 'what-makes-a-great-corporate-portrait') then
    perform public.lascot_seed_insert('blog_posts', jsonb_build_object(
      'slug', 'what-makes-a-great-corporate-portrait',
      'title', 'What Makes a Great Corporate Portrait?',
      'subtitle', 'Light, background, expression and consistency: the details that separate a forgettable staff photograph from a strong one.',
      'excerpt', 'A look at the ingredients of a corporate portrait that represents both the person and the organisation well.',
      'author', 'Lascot Studio', 'status', 'published', 'featured', false,
      'seo_title', 'What Makes a Great Corporate Portrait? | Lascot Studio',
      'meta_description', 'The key elements of a great corporate portrait: lighting, background, expression, consistency and planning.',
      'created_at', now() - interval '8 days', 'published_at', now() - interval '8 days',
      'body', $b$A corporate portrait has two jobs. It must show the person well, and it must represent the organisation they work for. When both are done properly, a staff page looks credible and welcoming. When they are not, even a strong company can look careless.

## Lighting that flatters and is consistent

Light is the foundation. Soft, directional light shapes the face and gives it dimension, while harsh or uneven light adds shadows and tiredness. For a team, the lighting must also be repeatable, so the person photographed first looks like they belong with the person photographed last.

That is one reason a controlled setting matters. A planned lighting setup, fixed once and kept the same, produces a team that looks like a team.

## A background that stays out of the way

The background should support the person, not compete with them. A clean, neutral backdrop in a colour that suits your brand works in most cases. If you shoot in an office, the setting should be tidy and uncluttered, with enough separation between the subject and the background that the face remains the focus.

## Expression and posture

The most important quality in a corporate portrait is the expression. We are looking for a face that is relaxed, attentive and natural: confident without being stern, warm without being forced.

- Shoulders slightly angled, rather than square to the camera
- Chin slightly forward and down, which defines the jaw
- Eyes engaged with the lens, as if speaking to someone across a table
- A gentle expression, which often looks better than a broad smile

> The best corporate portraits look like the person on a good day, not a person posing.

## Consistency across the team

A staff page where every photograph has a different crop, colour and mood looks improvised. Agree the framing, background and style in advance so every portrait matches. Consistency suggests an organisation that works to a standard.

## Planning makes the day efficient

Corporate sessions are most successful when they are planned: a clear schedule, a quiet space, guidance for staff on what to wear and a single point of contact. Short, well-organised sessions keep staff relaxed and keep the working day moving.

## Finishing and delivery

Retouching should be careful and restrained. Tidy distractions, even out skin tones and correct colour, but keep each person looking like themselves. Deliver files in the formats you need for web, print and social profiles.

When light, background, expression and planning come together, a corporate portrait does exactly what it is meant to do: it makes people feel they are already dealing with professionals.$b$));
  end if;
end
$a$;
