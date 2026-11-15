// Checks Paystack for payments that were made but not recorded yet, and records them (safe to call many times).
//  - customer: { reference: "<booking reference>" }  → checks that booking's unfinished payment attempts (used when the customer comes back from Paystack)
//  - owner (signed in to the dashboard): { all: true } → checks every unfinished attempt of the last 14 days
// Paystack is always asked directly; the browser can never tell us a payment succeeded.
const L = require('./_lib'), P = require('./_pay'), S = require('./_settle');
module.exports = async (req, res) => {
  if (req.method !== 'POST') return L.json(res, 405, { error: 'POST only' });
  try {
    if (!P.payConfigured()) return L.json(res, 503, { error: 'Online payment is not set up.' });
    const body = await L.readBody(req); let q;
    if (body && body.all === true) {
      const owner = await L.requireOwner(req);
      if (!owner) return L.json(res, 401, { error: 'Please sign in to the dashboard again.' });
      q = `booking_payments?status=neq.paid&created_at=gte.${encodeURIComponent(new Date(Date.now() - 14 * 864e5).toISOString())}&select=reference&order=created_at.desc&limit=40`;
    } else {
      const ref = body && body.reference;
      if (!ref || typeof ref !== 'string' || ref.length > 60 || !/^[\w-]+$/.test(ref)) return L.json(res, 400, { error: 'Missing reference' });
      q = `booking_payments?booking_ref=eq.${encodeURIComponent(ref)}&status=neq.paid&created_at=gte.${encodeURIComponent(new Date(Date.now() - 3 * 864e5).toISOString())}&select=reference&order=created_at.desc&limit=5`;
    }
    const rows = await L.sb(q) || [], found = [], results = [];
    for (const r of rows) { let out; try { out = await S.settle(r.reference); } catch (e) { out = 'error: ' + String(e && e.message || e).slice(0, 160); } if (out === 'ok') found.push(r.reference); results.push({ reference: r.reference, outcome: out }); }
    return L.json(res, 200, { ok: true, checked: rows.length, recorded: found.length, results });
  } catch (e) { console.error(e); return L.json(res, 500, { error: 'Could not check payments.' }); }
};
