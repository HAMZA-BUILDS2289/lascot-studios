// Records a Paystack payment against its booking, exactly once, and sends the emails.
// Used by the Paystack webhook AND by pay-verify (so a payment is never missed if the webhook did not arrive).
// Always re-checks with Paystack: nothing here trusts the browser or the message alone.
const L = require('./_lib'), P = require('./_pay');

const fmtDate = d => { try { return new Date(d + 'T00:00:00Z').toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' }); } catch { return d; } };

// returns 'ok' | 'already' | 'unknown' | 'amount_mismatch' | 'not_successful'
async function settle(ref) {
  const v = await P.paystack('/transaction/verify/' + encodeURIComponent(ref));
  if (!v.ok || !v.j || !v.j.data || v.j.data.status !== 'success' || v.j.data.currency !== 'NGN') return 'not_successful';
  const d = v.j.data;
  const out = await L.sb('rpc/record_booking_payment', { method: 'POST', body: { p_reference: ref, p_provider_ref: String(d.id || ''), p_amount: Number(d.amount), p_fees: Number(d.fees) || 0, p_paid_at: d.paid_at || null } });
  if (out === 'amount_mismatch') {
    L.sendMail({ to: L.env('OWNER_NOTIFY_EMAIL', L.env('GMAIL_USER')), subject: 'A payment needs your attention', text: `Paystack payment ${ref} for ${d.amount / 100} NGN did not match the amount we expected. Please check your Paystack dashboard.` }).catch(() => {});
  }
  if (out !== 'ok') return out;
  try { await afterPayment(d); } catch (e) { console.error('after-payment step failed', e && e.message); }   // the money is recorded; emails must never undo that
  return 'ok';
}

async function afterPayment(d) {
  const x = await P.loadBooking(d.metadata && d.metadata.booking_ref).catch(() => null);
  if (!x || !L.configured()) return;
  let b = x.b;
  const name = b.full_name || b.name || 'there', first = String(name).split(' ')[0], paid = P.naira(d.amount), total = x.pkg ? P.bookingTotalKobo(b, x.pkg) : null;
  const left = total ? Math.max(total - (Number(b.paid_kobo) || 0), 0) : null;
  const line = left ? `Balance still to pay: ${P.naira(left)}, due once your photos are delivered. We will email you the link.` : 'Your booking is fully paid.';
  const owner = L.env('OWNER_NOTIFY_EMAIL', L.env('GMAIL_USER'));
  // Optional: confirm the booking by itself once it is paid (switch in Dashboard → Payments). Only for a booking still waiting, with a date.
  let auto = false;
  const open = !b.status || b.status === 'pending' || b.status === 'new';
  if (open && b.preferred_date && (await P.settings()).auto_confirm) {
    const patch = { status: 'confirmed', confirmed_date: b.preferred_date, confirmed_time: b.preferred_time || null, confirmed_at: new Date().toISOString() };
    const done = await L.sb(`bookings?reference=eq.${encodeURIComponent(b.reference)}&or=(status.is.null,status.in.(pending,new))`, { method: 'PATCH', body: patch, prefer: 'return=representation' }).catch(() => null);
    if (done && done.length) { auto = true; b = { ...b, ...patch }; }
  }
  const what = [x.service, x.pkg ? x.pkg.name : ''].filter(Boolean).join(' · ') || 'your session';
  const when = auto ? fmtDate(b.confirmed_date) + (b.confirmed_time ? ' · ' + b.confirmed_time : '') : (b.preferred_date ? fmtDate(b.preferred_date) + (b.preferred_time ? ' · ' + b.preferred_time : '') : '');
  const status = auto ? 'Confirmed' : 'Waiting for confirmation';
  const statusLine = auto ? `Your booking is confirmed for ${when}.` : `Your booking is waiting for confirmation${when ? ' (you asked for ' + when + ')' : ''}. We will email you as soon as it is confirmed.`;
  const rows = [['Booking', b.reference], ['Session', what], [auto ? 'Confirmed for' : 'Date you asked for', when], ['Paid now', paid], ['Status', status]].filter(r => r[1]);
  const table = `<table role="presentation" cellpadding="6" cellspacing="0" style="font-size:15px">${rows.map(r => `<tr><td style="color:#667085;padding-right:18px">${L.esc(r[0])}</td><td><b>${L.esc(r[1])}</b></td></tr>`).join('')}</table>`;
  L.sendMail({ to: owner, replyTo: b.email || undefined, subject: `Payment received: ${paid} from ${name}${auto ? ' (booking confirmed automatically)' : ''}`,
    text: `${name} paid ${paid} for booking ${b.reference} (${what}).\n${line}\n${auto ? `The booking was confirmed automatically for ${when}.\n` : 'The booking is waiting for you to confirm it.\n'}\nOpen the dashboard: ${L.SITE()}/admin.html`,
    html: L.layout('Payment received', `<p>${L.esc(name)} paid <b>${L.esc(paid)}</b> for booking <b>${L.esc(b.reference)}</b> (${L.esc(what)}).</p><p>${L.esc(line)}</p><p>${auto ? 'The booking was confirmed automatically for ' + L.esc(when) + '.' : 'The booking is waiting for you to confirm it.'}</p>`) }).catch(() => {});
  if (b.email) L.sendMail({ to: b.email, replyTo: owner, subject: auto ? 'Payment received and your booking is confirmed · Lascot Studio' : 'Payment received, booking waiting for confirmation · Lascot Studio',
    text: `Hello ${first},\n\nThank you. We received your payment of ${paid}.\n\n${rows.map(r => r[0] + ': ' + r[1]).join('\n')}\n\n${statusLine}\n${line}\n\nLascot Studio`,
    html: L.layout('Payment received', `<p style="margin:0 0 14px">Hello ${L.esc(first)}, thank you. We received your payment of <b>${L.esc(paid)}</b>.</p>${table}<p style="margin:16px 0 0"><b>${L.esc(statusLine)}</b></p><p style="margin:10px 0 0;color:#667085;font-size:14px">${L.esc(line)}</p>`) }).catch(() => {});
}

module.exports = { settle };
