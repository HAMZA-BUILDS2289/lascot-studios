// Paystack calls this when a payment succeeds. Signature checked, payment re-verified with Paystack, then recorded once.
const L = require('./_lib'), P = require('./_pay'), S = require('./_settle');
const handler = async (req, res) => {
  if (req.method !== 'POST') return L.json(res, 405, { error: 'POST only' });
  const chunks = []; for await (const c of req) chunks.push(c);
  const raw = Buffer.concat(chunks);
  if (!P.verifySignature(raw, req.headers['x-paystack-signature'])) return L.json(res, 401, { error: 'Bad signature' });
  let ev; try { ev = JSON.parse(raw.toString()); } catch { return L.json(res, 400, { error: 'Bad body' }); }
  if (ev.event !== 'charge.success' || !ev.data || !ev.data.reference) return L.json(res, 200, { ok: true, ignored: true });
  try {
    const out = await S.settle(String(ev.data.reference));
    if (out === 'not_successful') return L.json(res, 200, { ok: true, ignored: 'not successful' });
    if (out === 'unknown') return L.json(res, 200, { ok: true, ignored: 'not ours' });
    if (out === 'amount_mismatch') return L.json(res, 200, { ok: true, mismatch: true });
    return L.json(res, 200, { ok: true, result: out });
  } catch (e) { return L.json(res, 500, { error: 'Could not record payment' }); }  // Paystack will retry
};
handler.config = { api: { bodyParser: false } };   // we need the exact bytes Paystack signed
module.exports = handler;
