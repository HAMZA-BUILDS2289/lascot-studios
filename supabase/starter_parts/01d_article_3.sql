-- LASCOT STUDIO starter content, part 4 of 8: journal article 3 of 6 (needs part 1 first)
-- Run in Supabase -> SQL Editor. Safe to run again (existing rows are skipped).

do $a$
begin
  if not exists (select 1 from public.blog_posts where slug = 'the-power-of-personal-branding-through-photography') then
    perform public.lascot_seed_insert('blog_posts', jsonb_build_object(
      'slug', 'the-power-of-personal-branding-through-photography',
      'title', 'The Power of Personal Branding Through Photography',
      'subtitle', 'Your photographs tell people who you are before you say a word. Here is how to make them tell the right story.',
      'excerpt', 'Personal branding photography is more than a portrait. It is a consistent visual story for your work and message.',
      'author', 'Lascot Studio', 'status', 'published', 'featured', false,
      'seo_title', 'The Power of Personal Branding Through Photography | Lascot Studio',
      'meta_description', 'How personal branding photography builds trust and a consistent visual identity for professionals and business owners.',
      'created_at', now() - interval '5 days', 'published_at', now() - interval '5 days',
      'body', $b$Whether you intend it or not, you already have a personal brand. It is the impression people form from your website, your social profiles, your talks and the photographs that go with them. Personal branding photography is the practice of shaping that impression on purpose.

## More than a portrait

A single headshot answers one question: what do you look like? Personal branding photography answers a bigger one: who are you and what do you do? It is a small library of images, in different settings and moods, that supports your message wherever it appears.

A consultant might need a confident studio portrait, a photograph working with a client and a candid image that shows personality. A baker might need images at the oven, with the finished product and with customers. In both cases the photographs are doing the work of introduction.

## Start with your story, not the camera

The best brand photographs begin with questions, not poses:

- Who are you trying to reach?
- What do you want them to feel when they see you?
- Where will the photographs appear: website, social media, speaking slides, press?
- What makes your work different from others in your field?

The answers decide the clothing, the settings, the lighting and even the expressions we aim for. Photographs made without them tend to look generic.

## Consistency builds trust

People trust what feels familiar. When your website, LinkedIn photograph, social posts and printed material share the same quality, colours and mood, you look established and deliberate. When they do not match, you look uncertain, even if your work is excellent.

Consistency does not mean every image looks identical. It means a recognisable thread: similar lighting, a repeated colour palette, a common attitude.

## Variety gives you content

One of the practical benefits of a branding session is the amount of usable material it produces. Different looks and settings give you images for a website header, a social post, a speaker introduction, a press kit and a profile picture without reusing the same photograph everywhere.

> Good branding photographs do not make you look like someone else. They make you look like the clearest version of yourself.

## Keep it honest

The strongest personal brands are believable. Avoid trying to look like someone you are not. Clients and colleagues will meet you in person eventually, and your photographs should be a promise you can keep.

## Making it work

Plan the session around your goals, choose clothing that reflects how you really present yourself, and let your photographer direct the rest. Then use the images with intention: update every channel, keep them current and let them work for you.

Your photographs are always being seen. Make sure they are saying what you mean.$b$));
  end if;
end
$a$;
