// Shared helpers for the email functions (Vercel serverless, Node).
const crypto = require('crypto');

const env = (k, d = '') => (process.env[k] || d).trim();
const SITE = () => env('SITE_URL', 'https://lascot-studios.vercel.app').replace(/\/+$/, '');
const BRAND = 'Lascot Studio';

const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

let _transport;
function transport() {
  if (_transport) return _transport;
  const nodemailer = require('nodemailer');
  _transport = nodemailer.createTransport({
    service: 'gmail',
    pool: true,
    maxConnections: 3,
    auth: { user: env('GMAIL_USER'), pass: env('GMAIL_APP_PASSWORD').replace(/\s+/g, '') }
  });
  return _transport;
}

async function sendMail({ to, subject, text, html, replyTo, headers }) {
  return transport().sendMail({
    from: `"${BRAND}" <${env('GMAIL_USER')}>`,
    to, subject, text, html,
    replyTo: replyTo || env('GMAIL_USER'),
    headers
  });
}

// ---- Supabase REST with the secret (service role) key: server side only ----
async function sb(path, { method = 'GET', body, prefer, token } = {}) {
  const url = env('SUPABASE_URL') + '/rest/v1/' + path;
  const key = token ? env('SUPABASE_ANON_KEY', env('SUPABASE_PUBLISHABLE_KEY')) : env('SUPABASE_SERVICE_ROLE_KEY');
  const r = await fetch(url, {
    method,
    headers: {
      apikey: key || env('SUPABASE_SERVICE_ROLE_KEY'),
      Authorization: 'Bearer ' + (token || env('SUPABASE_SERVICE_ROLE_KEY')),
      'Content-Type': 'application/json',
      ...(prefer ? { Prefer: prefer } : {})
    },
    body: body ? JSON.stringify(body) : undefined
  });
  const t = await r.text();
  let j; try { j = t ? JSON.parse(t) : null; } catch { j = t; }
  if (!r.ok) { const e = new Error('Supabase ' + r.status + ': ' + (j && j.message || t)); e.status = r.status; throw e; }
  return j;
}

// ---- unsubscribe links (signed so nobody can unsubscribe other people) ----
const unsubToken = email => crypto.createHmac('sha256', env('UNSUB_SECRET') || env('SUPABASE_SERVICE_ROLE_KEY'))
  .update(String(email).toLowerCase()).digest('hex').slice(0, 32);
const unsubLink = email => `${SITE()}/api/unsubscribe?e=${encodeURIComponent(email)}&t=${unsubToken(email)}`;

// ---- simple branded email layout ----
function layout(title, bodyHtml, footerHtml = '') {
  return `<!doctype html><html><body style="margin:0;background:#F5F8FF;font-family:Arial,Helvetica,sans-serif;color:#101828">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:24px 12px">
<table role="presentation" width="100%" style="max-width:600px;background:#ffffff;border-radius:14px;overflow:hidden" cellpadding="0" cellspacing="0">
<tr><td style="background:#023BE4;color:#ffffff;padding:22px 28px;font-size:16px;letter-spacing:3px;font-weight:bold">LASCOT STUDIO</td></tr>
<tr><td style="padding:28px;font-size:16px;line-height:1.6"><h1 style="font-size:24px;margin:0 0 16px">${esc(title)}</h1>${bodyHtml}</td></tr>
<tr><td style="padding:18px 28px;background:#F5F8FF;font-size:12px;color:#667085;line-height:1.5">${footerHtml || BRAND}</td></tr>
</table></td></tr></table></body></html>`;
}

const textToHtml = t => String(t || '').split(/\n{2,}/).map(p => p.trim()).filter(Boolean)
  .map(p => `<p style="margin:0 0 14px">${esc(p).replace(/\n/g, '<br>')}</p>`).join('');

function json(res, code, obj) { res.statusCode = code; res.setHeader('Content-Type', 'application/json'); res.setHeader('Cache-Control', 'no-store'); res.end(JSON.stringify(obj)); }

async function readBody(req) {
  if (req.body && typeof req.body === 'object') return req.body;
  if (typeof req.body === 'string') { try { return JSON.parse(req.body); } catch { return {}; } }
  const chunks = []; for await (const c of req) chunks.push(c);
  try { return JSON.parse(Buffer.concat(chunks).toString() || '{}'); } catch { return {}; }
}

function configured() {
  return env('GMAIL_USER') && env('GMAIL_APP_PASSWORD') && env('SUPABASE_URL') && env('SUPABASE_SERVICE_ROLE_KEY');
}

// Checks the caller is the signed-in owner (their Supabase login token).
async function requireOwner(req) {
  const tok = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  if (!tok) return null;
  const r = await fetch(env('SUPABASE_URL') + '/auth/v1/user', { headers: { apikey: env('SUPABASE_ANON_KEY', env('SUPABASE_PUBLISHABLE_KEY')) || env('SUPABASE_SERVICE_ROLE_KEY'), Authorization: 'Bearer ' + tok } });
  if (!r.ok) return null;
  const u = await r.json();
  if (!u || !u.id) return null;
  const rows = await sb(`profiles?id=eq.${encodeURIComponent(u.id)}&select=role`);
  return rows && rows[0] && rows[0].role === 'owner' ? u : null;
}

module.exports = { env, SITE, BRAND, esc, sendMail, sb, unsubLink, unsubToken, layout, textToHtml, json, readBody, configured, requireOwner };
