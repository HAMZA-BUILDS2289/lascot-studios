// Paystack calls this when a payment succeeds. Signature checked, payment re-verified with Paystack, then recorded once.
const L = require('./_lib'), P = require('./_pay');
const handler = async (req, res) => {
  if (req.method !== 'POST') return L.json(res, 405, { error: 'POST only' });
  const chunks = []; for await (const c of req) chunks.push(c);
  const raw = Buffer.concat(chunks);
  if (!P.verifySignature(raw, req.headers['x-paystack-signature'])) return L.json(res, 401, { error: 'Bad signature' });
  let ev; try { ev = JSON.parse(raw.toString()); } catch { return L.json(res, 400, { error: 'Bad body' }); }
  if (ev.event !== 'charge.success' || !ev.data || !ev.data.reference) return L.json(res, 200, { ok: true, ignored: true });
  try {
    const ref = String(ev.data.reference);
    // never trust the message alone: ask Paystack
    const v = await P.paystack('/transaction/verify/' + encodeURIComponent(ref));
    if (!v.ok || v.j.data.status !== 'success' || v.j.data.currency !== 'NGN') return L.json(res, 200, { ok: true, ignored: 'not successful' });
    const d = v.j.data;
    const out = await L.sb('rpc/record_booking_payment', { method: 'POST', body: { p_reference: ref, p_provider_ref: String(d.id || ''), p_amount: Number(d.amount), p_fees: Number(d.fees) || 0, p_paid_at: d.paid_at || null } });
    if (out === 'unknown') return L.json(res, 200, { ok: true, ignored: 'not ours' });
    if (out === 'amount_mismatch') {
      L.sendMail({ to: L.env('OWNER_NOTIFY_EMAIL', L.env('GMAIL_USER')), subject: 'A payment needs your attention', text: `Paystack payment ${ref} for ${d.amount / 100} NGN did not match the amount we expected. Please check your Paystack dashboard.` }).catch(() => {});
      return L.json(res, 200, { ok: true, mismatch: true });
    }
    if (out === 'ok') {
      const x = await P.loadBooking(d.metadata && d.metadata.booking_ref).catch(() => null);
      if (x && L.configured()) {
        const name = x.b.full_name || x.b.name || 'there', paid = P.naira(d.amount), total = x.pkg ? P.bookingTotalKobo(x.b, x.pkg) : null;
        const left = total ? Math.max(total - (Number(x.b.paid_kobo) || 0), 0) : null;
        const line = left ? `Balance still to pay: ${P.naira(left)}, due once your photos are delivered. We will email you the link.` : 'Your booking is fully paid.';
        const owner = L.env('OWNER_NOTIFY_EMAIL', L.env('GMAIL_USER'));
        L.sendMail({ to: owner, replyTo: x.b.email || undefined, subject: `Payment received: ${paid} from ${name}`, text: `${name} paid ${paid} for booking ${x.b.reference} (${x.service}${x.pkg ? ' · ' + x.pkg.name : ''}).\n${line}\n\nOpen the dashboard: ${L.SITE()}/admin.html`, html: L.layout('Payment received', `<p>${L.esc(name)} paid <b>${L.esc(paid)}</b> for booking <b>${L.esc(x.b.reference)}</b> (${L.esc(x.service)}${x.pkg ? ' · ' + L.esc(x.pkg.name) : ''}).</p><p>${L.esc(line)}</p>`) }).catch(() => {});
        if (x.b.email) L.sendMail({ to: x.b.email, subject: `Payment received — thank you`, text: `Hello ${name},\n\nWe received your payment of ${paid} for booking ${x.b.reference}. ${line}\n\nWe will contact you to confirm your date.\n\nLascot Studio`, html: L.layout('Payment received', `<p>Hello ${L.esc(name)},</p><p>We received your payment of <b>${L.esc(paid)}</b> for booking <b>${L.esc(x.b.reference)}</b>. ${L.esc(line)}</p><p>We will contact you to confirm your date.</p>`) }).catch(() => {});
      }
    }
    return L.json(res, 200, { ok: true, result: out });
  } catch (e) { return L.json(res, 500, { error: 'Could not record payment' }); }  // Paystack will retry
};
handler.config = { api: { bodyParser: false } };   // we need the exact bytes Paystack signed
module.exports = handler;
