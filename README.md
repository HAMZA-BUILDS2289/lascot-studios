# Lascot Studio website

Static site (no build step), deployed on Vercel from this repo. Backend: Supabase.

| File | What it is |
|---|---|
| `index.html` | Public website |
| `admin.html` | Owner dashboard (auto sign-out after 60 s of inactivity) |
| `gallery.html` | Private client gallery page: `gallery.html#<private code>` |
| `assets/` | Logo, favicon, founder photo |
| `supabase/starter_parts/01a…01h` | Starter services, packages and 6 journal articles in small parts (use these on a phone) |
| `supabase/01_starter_content_ALL_IN_ONE.sql` | Same content as one big file (laptop only) |
| `supabase/02_client_galleries.sql` | Private client galleries (tables, rules, storage) |
| `supabase/03_package_options.sql` | Package sample pictures and photo-count options (6 photos, 10 photos, custom) |

## Setup (once)
1. Supabase → SQL Editor → run the `starter_parts` files in order (01a, 01b … 01h), then `02_client_galleries.sql`.
2. Make sure the owner's row in `profiles` has `role = 'owner'`.
3. Open `/admin.html`, sign in, and edit everything from there.

## Client galleries
Admin → Client galleries → create → upload photos → copy/email/WhatsApp the link.
The link holds a 64-character random code. Only someone with the exact link can load the gallery,
and they can download everything as zip file(s). Turn a link off or make a new one at any time.
Note: photo file addresses are unguessable but not password-protected; treat the link like a key.

## Email notifications (Gmail)
Run `supabase/04_email_notifications.sql`, then add these in Vercel → Project → Settings → Environment Variables, and redeploy:

| Name | Value |
|---|---|
| `GMAIL_USER` | Lascotstudios@gmail.com |
| `GMAIL_APP_PASSWORD` | 16-character Google App Password (Google Account → Security → 2-Step Verification → App passwords) |
| `SUPABASE_URL` | https://vapxkssbrggpuyfehqwi.supabase.co |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Project Settings → API Keys → secret key. **Never put this in the website files.** |
| `SITE_URL` | https://lascot-studios.vercel.app |
| `OWNER_NOTIFY_EMAIL` | (optional) where booking alerts go; defaults to GMAIL_USER |
| `UNSUB_SECRET` | (optional) any long random text, used to sign unsubscribe links |

Functions in `api/`: `booking-notify` (studio + customer emails), `newsletter-welcome`, `newsletter-send` (owner only, Admin → Send newsletter), `unsubscribe`.
