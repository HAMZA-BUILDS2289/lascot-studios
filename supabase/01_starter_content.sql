-- =====================================================================
-- LASCOT STUDIO — starter content (services, packages, journal articles)
--
-- Run ONCE in: Supabase Dashboard -> SQL Editor -> New query -> paste -> Run.
-- Safe to run again: anything that already exists (same slug / same package
-- name) is skipped, and nothing you have edited is overwritten.
--
-- Everything here is normal editable content. After running it, open
-- /admin.html and change names, text, packages and prices to your own.
-- NO PRICES ARE INCLUDED: set each package price in Admin -> Packages
-- (until then the website shows "Price on request").
-- =====================================================================

-- Helper: inserts a row using only the keys that are real columns of the table,
-- so a small difference in your table design cannot make the script fail.
create or replace function public.lascot_seed_insert(tbl text, payload jsonb)
returns jsonb language plpgsql as $f$
declare cols text; new_id jsonb;
begin
  select string_agg(quote_ident(c.column_name), ',') into cols
  from information_schema.columns c
  where c.table_schema = 'public' and c.table_name = tbl and jsonb_exists(payload, c.column_name);
  if cols is null then return null; end if;
  execute format(
    'insert into public.%1$I (%2$s) select %2$s from jsonb_populate_record(null::public.%1$I, $1) returning to_jsonb(id)',
    tbl, cols) into new_id using payload;
  return new_id;
end $f$;

do $seed$
declare
  sid jsonb;
  svc record;
  pk record;
begin
  -- ------------------------------------------------------------------
  -- SERVICES
  -- ------------------------------------------------------------------
  for svc in
    select * from (values
      (1, 'professional-headshots', 'Professional Headshots',
       'Clean, confident portraits for LinkedIn, company profiles, speaker pages and CVs.',
       E'Your headshot works before you do. It appears on LinkedIn, company websites, conference programmes and email signatures long before anyone hears your voice. Our headshot sessions are planned so that the person in the photograph looks like you on your best day: relaxed, capable and approachable.\n\nWe begin with a short conversation about where the images will be used, then light the set to suit your face and your industry, guide your posture and expression gently, and review frames with you as we go.',
       array['A photograph that represents you with confidence','Consistent images for every platform you use','Natural retouching that keeps you looking like you','Guided posing, so you do not need any experience'],
       array['A planning conversation before the session','Studio lighting and backdrop suited to your industry','Gentle direction on posture and expression','Professionally retouched final images','Private online gallery with download of all your photographs'],
       array['Executives and founders','Job seekers and career changers','Doctors, lawyers, consultants and other professionals','Speakers, authors and creators']),
      (2, 'corporate-photography', 'Corporate Photography',
       'Team portraits, leadership imagery and brand visuals for organisations.',
       E'An organisation is judged by the people it shows. Corporate photography gives your website, brochures, reports and social channels a consistent, professional face, from individual staff portraits to leadership photographs and images of your team at work.\n\nWe plan the shoot around your schedule and brand, keep sessions efficient so your team stays productive, and deliver images shot to one visual standard.',
       array['A consistent, professional face for your organisation','Efficient sessions that respect your team''s time','Images ready for web, print and press','One visual standard across every portrait'],
       array['Pre-shoot planning around your brand and schedule','Individual and group portraits','Studio or on-location lighting','Professionally retouched final images','Private online gallery with download of all your photographs'],
       array['Companies and start-ups','Hospitals, clinics and professional firms','Schools and institutions','Teams preparing a website, report or launch']),
      (3, 'personal-branding', 'Personal Branding',
       'A set of images that tells your story consistently across your website, socials and press.',
       E'Personal branding photography goes beyond a single portrait. It is a small library of images, in different settings and moods, that shows who you are and what you do, so your website, social profiles, talks and press features all feel like they belong to the same person.\n\nWe plan the session around your story: your audience, your message and the places your photographs will appear.',
       array['A varied set of images, not just one portrait','A consistent look across every channel','Photographs that support your message and audience','Content you can use for months'],
       array['A brand and story conversation before the session','Multiple looks and settings','Creative direction throughout the shoot','Professionally retouched final images','Private online gallery with download of all your photographs'],
       array['Entrepreneurs and business owners','Coaches, consultants and creatives','Public speakers and authors','Anyone building an online presence']),
      (4, 'studio-portraits', 'Studio Portraits',
       'Controlled light, a calm studio and unhurried direction.',
       E'The studio gives us complete control of light, which means we can shape a portrait deliberately: soft and flattering, dramatic and cinematic, or clean and bright. Without the distractions of a location, the focus stays on you.\n\nSessions are relaxed and unhurried. Come as an individual, a couple or a small group, and leave with portraits you will be proud to print and share.',
       array['Complete control over light and mood','A calm, distraction-free environment','Portraits that suit printing and framing','Relaxed direction for people who are not used to being photographed'],
       array['A planning conversation before the session','Studio lighting and a choice of backdrops','Guided posing for individuals, couples or groups','Professionally retouched final images','Private online gallery with download of all your photographs'],
       array['Individuals and couples','Families and small groups','Birthdays and milestones','Anyone who wants a high-quality portrait']),
      (5, 'editorial-photography', 'Editorial Photography',
       'Story-led images with a magazine sensibility.',
       E'Editorial photography treats a portrait like a page in a magazine: a considered concept, careful styling and a strong sense of story. It suits brands, creatives and publications that want imagery with character.\n\nWe develop the idea with you, plan the look and shoot with creative direction from start to finish.',
       array['Imagery with a clear concept and character','Photographs that stand out from stock-style visuals','Creative direction from idea to final image'],
       array['Concept and mood planning','Creative direction during the shoot','Styling guidance','Professionally retouched final images','Private online gallery with download of all your photographs'],
       array['Brands and designers','Musicians, artists and creatives','Magazines and publications','Campaigns and launches']),
      (6, 'event-photography', 'Event Photography',
       'The moments, people and atmosphere of your event, delivered privately.',
       E'An event passes quickly. Our event photography captures the moments that matter: the people, the atmosphere and the small details you will want to remember or share.\n\nAfter the event, your photographs are delivered through a private gallery link that only you and the people you share it with can open, with every image available to download together.',
       array['The key moments and the atmosphere of your day','Discreet, attentive coverage','Private delivery: a link only you can open','Download every photograph in one go'],
       array['Planning conversation about the event and key moments','Event coverage by the studio','Selected and edited photographs','Private online gallery link for you and your guests','Download of all your photographs together'],
       array['Weddings and receptions','Corporate events and conferences','Birthdays and celebrations','Launches and community events'])
    ) as t(ord, slug, name, summary, description, benefits, included, suitable)
  loop
    if not exists (select 1 from public.services where slug = svc.slug) then
      sid := public.lascot_seed_insert('services', jsonb_build_object(
        'name', svc.name, 'slug', svc.slug, 'summary', svc.summary, 'description', svc.description,
        'benefits', to_jsonb(svc.benefits), 'included', to_jsonb(svc.included), 'suitable_for', to_jsonb(svc.suitable),
        'sort_order', svc.ord, 'published', true));
    end if;
  end loop;

  -- ------------------------------------------------------------------
  -- PACKAGES (no prices: set them in Admin -> Packages)
  -- ------------------------------------------------------------------
  for pk in
    select * from (values
      ('professional-headshots', 1, 'Essential Headshot', 'A focused single-look session for a profile photograph.', false,
       array['One look and one backdrop','Planning conversation','Retouched final images','Private gallery link with download']),
      ('professional-headshots', 2, 'Signature Headshot', 'Multiple looks and backgrounds for broader professional use.', true,
       array['Multiple looks and backdrops','Planning conversation','Retouched final images','Private gallery link with download']),
      ('professional-headshots', 3, 'Team Headshots', 'Consistent portraits for a small team, shot to one visual standard.', false,
       array['Portraits for each team member','One consistent style and backdrop','Retouched final images','Private gallery link with download']),
      ('corporate-photography', 1, 'Team Portraits', 'Individual portraits for your staff, shot to one standard.', false,
       array['Individual staff portraits','Brand-matched backdrop and lighting','Retouched final images','Private gallery link with download']),
      ('corporate-photography', 2, 'Leadership and Brand', 'Leadership portraits plus brand and workplace imagery.', true,
       array['Leadership portraits','Workplace and brand images','Creative direction','Private gallery link with download']),
      ('personal-branding', 1, 'Brand Starter', 'A compact set of images for your website and social profiles.', false,
       array['Brand and story conversation','Two looks','Retouched final images','Private gallery link with download']),
      ('personal-branding', 2, 'Brand Story', 'A fuller library of images in several settings and moods.', true,
       array['Brand and story conversation','Multiple looks and settings','Creative direction','Private gallery link with download']),
      ('studio-portraits', 1, 'Solo Portrait', 'A studio session for one person.', false,
       array['Studio lighting and backdrop choice','Guided posing','Retouched final images','Private gallery link with download']),
      ('studio-portraits', 2, 'Couple or Group Portrait', 'A studio session for couples, families or small groups.', true,
       array['Studio lighting and backdrop choice','Guided group posing','Retouched final images','Private gallery link with download']),
      ('editorial-photography', 1, 'Editorial Feature', 'A concept-led shoot with creative direction and styling guidance.', true,
       array['Concept and mood planning','Creative direction','Retouched final images','Private gallery link with download']),
      ('event-photography', 1, 'Event Coverage', 'Photography of your event with a private delivery gallery.', true,
       array['Event planning conversation','Coverage of key moments','Edited photographs','Private gallery link with download for you and your guests'])
    ) as t(svc_slug, ord, name, description, featured, inclusions)
  loop
    select to_jsonb(id) into sid from public.services where slug = pk.svc_slug;
    if sid is not null and not exists (
         select 1 from public.service_packages p
         where to_jsonb(p.service_id) = sid and p.name = pk.name) then
      perform public.lascot_seed_insert('service_packages', jsonb_build_object(
        'service_id', sid, 'name', pk.name, 'description', pk.description,
        'inclusions', to_jsonb(pk.inclusions), 'featured', pk.featured, 'available', true, 'sort_order', pk.ord));
    end if;
  end loop;

  -- ------------------------------------------------------------------
  -- JOURNAL ARTICLES (published, written for Lascot Studio; edit freely)
  -- Body format: blank line = new paragraph, "## " = heading,
  -- "> " = pull quote, "- " = bullet point.
  -- ------------------------------------------------------------------
  if not exists (select 1 from public.blog_posts where slug = 'why-professional-headshots-matter') then
    perform public.lascot_seed_insert('blog_posts', jsonb_build_object(
      'slug', 'why-professional-headshots-matter',
      'title', 'Why Professional Headshots Matter in Today’s Professional World',
      'subtitle', 'Before anyone reads your CV or hears your pitch, they have already looked at your photograph.',
      'excerpt', 'A headshot is often the first impression you make. Here is what it communicates, when to update it, and how to get more from your session.',
      'author', 'Lascot Studio', 'status', 'published', 'featured', true,
      'seo_title', 'Why Professional Headshots Matter | Lascot Studio',
      'meta_description', 'Why a professional headshot matters for your career and business, what it communicates and how to prepare.',
      'created_at', now() - interval '1 day', 'published_at', now() - interval '1 day',
      'body', $b$Think about the last time you looked someone up before a meeting. You probably searched their name, opened a profile and glanced at their photograph for a few seconds. In those seconds you formed an impression: capable or uncertain, warm or distant, careful or careless. Nobody told you to do it. It simply happened.

Your own photograph is doing that work for you every day, in rooms you are not in. A professional headshot is the most direct way to make sure it does the job well.

## The photograph arrives before you do

Professional life is increasingly introduced through screens. Recruiters scan profiles, clients review company pages, event organisers choose speakers from a grid of faces and colleagues check a name against a picture before an email is answered. In each case the headshot is the first thing seen and often the only thing remembered.

> A headshot is a handshake delivered in advance.

## What a good headshot actually communicates

A strong headshot is not about vanity. It communicates three practical things:

- Competence: the image is clean, sharp and deliberate, which suggests the same of your work.
- Approachability: a relaxed expression and open posture make people comfortable contacting you.
- Consistency: the same quality image across your website, LinkedIn and press features suggests a person who pays attention to detail.

## Why a phone selfie rarely does the job

Modern phones are remarkable, and some self-taken photographs are perfectly acceptable for casual use. But a professional session solves problems a phone cannot. Controlled light shapes the face instead of flattening it. A clean backdrop removes distractions. A photographer can see what you cannot: a collar out of place, a tense jaw, an expression that does not feel like you.

Most importantly, someone is directing you. Most people are not comfortable being photographed, and gentle direction is what turns a stiff pose into a natural expression.

## When to update your headshot

A headshot should look like you today. Consider a new one when you change role or industry, when your appearance has changed noticeably, when your current image is several years old, or when your work has moved on and your photograph no longer matches the level you operate at.

## Getting the most from your session

Tell your photographer where the images will be used, because a profile photograph, a speaker page and a company website each call for slightly different framing. Bring two or three outfits you feel confident in, choose solid colours over busy patterns and get a good night's sleep beforehand. Then relax and let the session do its work.

Your headshot is a small investment that is seen by many people. It is worth getting right.$b$));
  end if;

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
$seed$;

drop function if exists public.lascot_seed_insert(text, jsonb);

-- Quick check (shows how many rows exist now):
select
  (select count(*) from public.services)         as services,
  (select count(*) from public.service_packages) as packages,
  (select count(*) from public.blog_posts)       as articles;
