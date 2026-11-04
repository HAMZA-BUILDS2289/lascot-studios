-- LASCOT STUDIO starter content, part 7 of 8: journal article 6 of 6 (needs part 1 first)
-- Run in Supabase -> SQL Editor. Safe to run again (existing rows are skipped).

do $a$
begin
  if not exists (select 1 from public.blog_posts where slug = 'how-lighting-changes-the-way-a-portrait-feels') then
    perform public.lascot_seed_insert('blog_posts', jsonb_build_object(
      'slug', 'how-lighting-changes-the-way-a-portrait-feels',
      'title', 'How Lighting Changes the Way a Portrait Feels',
      'subtitle', 'The same face can look warm, serious, glamorous or tired depending on where the light comes from.',
      'excerpt', 'Light is the most powerful tool in portrait photography. Here is how direction, softness and contrast change the mood.',
      'author', 'Lascot Studio', 'status', 'published', 'featured', false,
      'seo_title', 'How Lighting Changes a Portrait | Lascot Studio',
      'meta_description', 'How direction, softness and contrast of light change the mood of a portrait.',
      'created_at', now() - interval '14 days', 'published_at', now() - interval '14 days',
      'body', $b$Photography means writing with light, and nowhere is that clearer than in portraits. The same face, photographed with the same camera, can look friendly, serious, dramatic or tired purely because of how it is lit.

## Direction: where the light comes from

The position of the main light decides where shadows fall, and shadows decide how the face reads.

- Light from the front is even and gentle, with few shadows. It is simple and flattering, but can look flat.
- Light from slightly to one side creates gentle shadows that give the face shape and depth. It is a classic choice for professional portraits.
- Light from high above can deepen the eye sockets and add seriousness, which is not always wanted.
- Light from below is unusual and often unsettling, which is why it is used in horror films.

## Softness: how the light falls

Soft light comes from a large source close to the subject. Its edges are gradual, so skin looks smooth and shadows are gentle. Hard light comes from a small or distant source and produces crisp shadows and visible texture.

Most flattering professional portraits use soft light, because it is kind to skin and makes people look relaxed. Hard light can be powerful for character portraits, but it must be placed carefully.

## Contrast: how much shadow

Contrast describes the difference between light and dark areas. A low-contrast portrait has light shadows and feels open, bright and approachable. A high-contrast portrait has deep shadows and feels dramatic, serious and cinematic.

> Choosing the light is choosing the mood, before the subject has said a word.

## Light and the background

The background is lit too. A dark backdrop with a single directional light, for example, makes a face glow and creates drama. A light backdrop with soft, even illumination feels clean and modern. The relationship between subject and background sets the whole tone.

## Catchlights: the sparkle in the eyes

The small reflections of the light in the eyes are called catchlights, and they bring a portrait to life. Without them, eyes can look dull. A good photographer positions the light so every portrait has bright, natural catchlights.

## Choosing the right light for you

Think about what the photograph is for. A corporate headshot usually calls for soft, even, approachable light. A creative portrait might embrace shadow and drama. A good photographer will talk this through with you and test the options during the session.

Light is not a technical detail. It is the mood of the picture.$b$));
  end if;
end
$a$;
