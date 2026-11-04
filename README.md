# Lascot Studio website

Static site (no build step), deployed on Vercel from this repo. Backend: Supabase.

| File | What it is |
|---|---|
| `index.html` | Public website |
| `admin.html` | Owner dashboard (auto sign-out after 60 s of inactivity) |
| `gallery.html` | Private client gallery page: `gallery.html#<private code>` |
| `assets/` | Logo, favicon, founder photo |
| `supabase/01_starter_content.sql` | Starter services, packages and 6 journal articles |
| `supabase/02_client_galleries.sql` | Private client galleries (tables, rules, storage) |

## Setup (once)
1. Supabase → SQL Editor → run `01_starter_content.sql`, then `02_client_galleries.sql`.
2. Make sure the owner's row in `profiles` has `role = 'owner'`.
3. Open `/admin.html`, sign in, and edit everything from there.

## Client galleries
Admin → Client galleries → create → upload photos → copy/email/WhatsApp the link.
The link holds a 64-character random code. Only someone with the exact link can load the gallery,
and they can download everything as zip file(s). Turn a link off or make a new one at any time.
Note: photo file addresses are unguessable but not password-protected; treat the link like a key.
