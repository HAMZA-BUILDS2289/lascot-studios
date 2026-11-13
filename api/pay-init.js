// Starts a Paystack payment for a booking. The amount is worked out here from the booking, never taken from the browser.
const L = require('./_lib'), P = require('./_pay');
const crypto = require('crypto');
module.exports = async (req, res) => {
  if (req.method !== 'POST') return L.json(res, 405, { error: 'POST only' });
  try {
    const { reference, kind } = await L.readBody(req);
    const st = await P.settings();
    if (!P.payConfigured() || !st.enabled) return L.json(res, 503, { error: 'Online payment is not available right now.' });
    const x = await P.loadBooking(reference);
    if (!x) return L.json(res, 404, { error: 'Booking not found.' });
    const email = String(x.b.email || '').trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return L.json(res, 422, { error: 'This booking has no valid email address.' });
    const pl = P.plan(x.b, x.pkg, st), opt = pl.options.find(o => o.kind === kind);
    if (!opt) return L.json(res, 409, { error: pl.total ? (pl.balance <= 0 ? 'This booking is already fully paid.' : 'That payment option is not available.') : 'The studio will send you a price for this booking.' });
    const ref = `LS-${x.b.reference}-${Date.now().toString(36)}-${crypto.randomBytes(2).toString('hex')}`;
    await L.sb('booking_payments', { method: 'POST', body: { booking_ref: x.b.reference, reference: ref, kind: opt.kind, amount_kobo: opt.amount }, prefer: 'return=minimal' });
    const r = await P.paystack('/transaction/initialize', { method: 'POST', body: JSON.stringify({ email, amount: opt.amount, currency: 'NGN', reference: ref,
      callback_url: `${L.SITE()}/pay.html?reference=${encodeURIComponent(x.b.reference)}`, metadata: { booking_ref: x.b.reference, kind: opt.kind, custom_fields: [{ display_name: 'Booking', variable_name: 'booking', value: x.b.reference }] } }) });
    if (!r.ok) return L.json(res, 502, { error: 'Could not start the payment. Please try again.' });
    return L.json(res, 200, { url: r.j.data.authorization_url });
  } catch (e) { return L.json(res, 500, { error: 'Something went wrong. Please try again.' }); }
};
