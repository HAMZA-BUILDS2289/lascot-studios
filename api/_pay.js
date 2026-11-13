// Shared helpers for online payments (Paystack, Vercel serverless, Node).
// Money is always handled in kobo (1 naira = 100 kobo). The server decides every amount; the browser never does.
const crypto = require('crypto');
const L = require('./_lib');

const MIN_KOBO = 10000;                         // NGN 100: smallest online payment
const naira = k => '₦' + (Number(k) / 100).toLocaleString('en-NG', { minimumFractionDigits: 0, maximumFractionDigits: 2 });
const secret = () => L.env('PAYSTACK_SECRET_KEY');
const payConfigured = () => !!(secret() && L.env('SUPABASE_URL') && L.env('SUPABASE_SERVICE_ROLE_KEY'));

async function settings() {
  let v = {};
  try { const r = await L.sb('website_settings?key=eq.payments&select=value'); v = (r && r[0] && r[0].value) || {}; } catch { /* defaults */ }
  const pct = Number(v.deposit_percent);
  return { enabled: v.enabled !== false, deposit_percent: pct >= 1 && pct <= 99 ? Math.round(pct) : 50 };
}

// Price of a booking in kobo, worked out from the package and the photo choice the customer made. null = studio to quote.
function bookingTotalKobo(b, pkg) {
  if (!pkg) return null;
  let naira_ = Number(pkg.price_ngn) || 0;
  if (!naira_) {
    const opts = Array.isArray(pkg.photo_options) ? pkg.photo_options.filter(o => o && o.label) : [];
    const ch = String(b.photo_choice || '');
    if (/^custom:/i.test(ch)) return null;
    const hit = opts.find(o => ch === o.label || ch.startsWith(o.label + ' ·') || ch.startsWith(o.label + ' '));
    naira_ = hit ? Number(hit.price) || 0 : 0;
  }
  return naira_ > 0 ? Math.round(naira_ * 100) : null;
}

async function loadBooking(reference) {
  if (!reference || typeof reference !== 'string' || reference.length > 60 || !/^[\w-]+$/.test(reference)) return null;
  const rows = await L.sb(`bookings?reference=eq.${encodeURIComponent(reference)}&select=*`);
  const b = rows && rows[0]; if (!b) return null;
  const [svc, pkg] = await Promise.all([
    b.service_id ? L.sb(`services?id=eq.${b.service_id}&select=name,slug`).catch(() => []) : [],
    b.package_id ? L.sb(`service_packages?id=eq.${b.package_id}&select=*`).catch(() => []) : []]);
  return { b, service: svc && svc[0] ? svc[0].name : '', slug: svc && svc[0] ? svc[0].slug : '', pkg: pkg && pkg[0] || null };
}

// What can still be paid on this booking.
// Graduation bookings: full payment only. Everything else: a deposit first, and the balance once the photos are delivered.
function plan(b, pkg, st, slug) {
  const total = bookingTotalKobo(b, pkg), paid = Number(b.paid_kobo) || 0;
  if (!total) return { total: null, paid, balance: null, options: [], locked: false };
  const grad = slug === 'graduation';
  const balance = Math.max(total - paid, 0), options = []; let locked = false;
  if (balance >= MIN_KOBO) {
    if (paid === 0) {
      const dep = Math.round(total * st.deposit_percent / 100);
      if (!grad && dep >= MIN_KOBO && balance - dep >= MIN_KOBO) options.push({ kind: 'deposit', amount: dep });
      options.push({ kind: 'full', amount: balance });
    } else if (b.status === 'completed') options.push({ kind: 'balance', amount: balance });
    else locked = true;
  }
  return { total, paid, balance, options, locked };
}

const verifySignature = (raw, sig) => {
  if (!sig || !secret()) return false;
  const h = crypto.createHmac('sha512', secret()).update(raw).digest('hex');
  const a = Buffer.from(h), c = Buffer.from(String(sig));
  return a.length === c.length && crypto.timingSafeEqual(a, c);
};

async function paystack(path, init = {}) {
  const r = await fetch('https://api.paystack.co' + path, { ...init, headers: { Authorization: 'Bearer ' + secret(), 'Content-Type': 'application/json' } });
  const j = await r.json().catch(() => null);
  return { ok: r.ok && j && j.status, j };
}

module.exports = { MIN_KOBO, naira, payConfigured, settings, bookingTotalKobo, loadBooking, plan, verifySignature, paystack, secret };
