-- LASCOT STUDIO starter content, part 2 of 8: journal article 1 of 6 (needs part 1 first)
-- Run in Supabase -> SQL Editor. Safe to run again (existing rows are skipped).

do $a$
begin
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
end
$a$;
