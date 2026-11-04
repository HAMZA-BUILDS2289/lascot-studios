-- LASCOT STUDIO starter content, part 1 of 8: services and packages (run this first)
-- Run in Supabase -> SQL Editor. Safe to run again (existing rows are skipped).

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
end
$seed$;
