// Owner only. Confirm / decline / mark delivered, and email the customer about it.
// "Delivered" also sends the customer a private link to write a review.
const crypto = require('crypto');
const L = require('./_lib');

const fmtDate = d => { try { return new Date(d + 'T00:00:00Z').toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' }); } catch { return d; } };
const clean = (s, n) => String(s || '').trim().slice(0, n);

module.exports = async (req, res) => {
  if (req.method !== 'POST') return L.json(res, 405, { error: 'POST only' });
  if (!L.configured()) return L.json(res, 503, { error: 'Email is not set up yet' });
  try {
    const owner = await L.requireOwner(req);
    if (!owner) return L.json(res, 401, { error: 'Please sign in to the dashboard again' });
    const body = await L.readBody(req);
    const { id, action } = body;
    if (!id || typeof id !== 'string' || !['confirm', 'decline', 'delivered', 'resend_review'].includes(action)) return L.json(res, 400, { error: 'Bad request' });
    const rows = await L.sb(`bookings?id=eq.${encodeURIComponent(id)}&select=*`);
    const b = rows && rows[0];
    if (!b) return L.json(res, 404, { error: 'Booking not found' });

    const svc = b.service_id ? await L.sb(`services?id=eq.${b.service_id}&select=name`).catch(() => []) : [];
    const service = svc && svc[0] ? svc[0].name : 'your session';
    const name = (b.full_name || b.name || 'there').split(' ')[0];
    const note = clean(body.message, 1000);
    const contact = L.env('OWNER_NOTIFY_EMAIL', L.env('GMAIL_USER'));
    const patch = {};
    let mail = null;

    if (action === 'confirm') {
      const date = clean(body.date, 10), time = clean(body.time, 60);
      if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return L.json(res, 400, { error: 'Choose the date for this booking first' });
      Object.assign(patch, { status: 'confirmed', confirmed_date: date, confirmed_time: time || null, owner_message: note || null, confirmed_at: new Date().toISOString() });
      const when = fmtDate(date) + (time ? ' · ' + time : '');
      mail = {
        subject: 'Your booking is confirmed · Lascot Studio',
        text: `Hello ${name},\n\nGood news: your ${service} booking is confirmed.\n\nWhen: ${when}\nReference: ${b.reference}\n${note ? '\n' + note + '\n' : ''}\nIf you need to change anything, just reply to this email.\n\nLascot Studio`,
        html: L.layout('Your booking is confirmed', `<p style="margin:0 0 14px">Hello ${L.esc(name)}, good news: your <b>${L.esc(service)}</b> booking is confirmed.</p><table role="presentation" cellpadding="6" cellspacing="0" style="font-size:15px"><tr><td style="color:#667085;padding-right:18px">When</td><td><b>${L.esc(when)}</b></td></tr><tr><td style="color:#667085;padding-right:18px">Reference</td><td><b>${L.esc(b.reference)}</b></td></tr></table>${note ? L.textToHtml(note) : ''}<p style="margin:18px 0 0;color:#667085;font-size:14px">If you need to change anything, just reply to this email.</p>`)
      };
    } else if (action === 'decline') {
      Object.assign(patch, { status: 'rejected', owner_message: note || null });
      mail = {
        subject: 'About your booking request · Lascot Studio',
        text: `Hello ${name},\n\nThank you for your interest. Unfortunately we are not able to take this booking as requested.\n${note ? '\n' + note + '\n' : ''}\nYou are welcome to reply to this email or send a new request for another date.\n\nLascot Studio`,
        html: L.layout('About your booking request', `<p style="margin:0 0 14px">Hello ${L.esc(name)}, thank you for your interest. Unfortunately we are not able to take this booking as requested.</p>${note ? L.textToHtml(note) : ''}<p style="margin:0">You are welcome to reply to this email or send a new request for another date.</p>`)
      };
    } else { // delivered, or resend the review link
      if (action === 'delivered') {
        if (b.status !== 'confirmed' && b.status !== 'completed') return L.json(res, 409, { error: 'Confirm the booking before marking it as delivered' });
        patch.status = 'completed';
        if (!b.delivered_at) patch.delivered_at = new Date().toISOString();
      } else if (b.status !== 'completed') return L.json(res, 409, { error: 'Only delivered bookings can get a review request' });
      const token = b.review_token || crypto.randomBytes(24).toString('hex');
      if (!b.review_token) patch.review_token = token;
      patch.review_sent_at = new Date().toISOString();
      const link = `${L.SITE()}/#reviews/${token}`;
      mail = {
        subject: 'How was your session? · Lascot Studio',
        text: `Hello ${name},\n\nYour ${service} is complete. Thank you for choosing Lascot Studio.\n\nWe would be grateful if you could share a short review. It takes a minute:\n${link}\n\nLascot Studio`,
        html: L.layout('Thank you, ' + name, `<p style="margin:0 0 14px">Your <b>${L.esc(service)}</b> is complete. Thank you for choosing Lascot Studio.</p><p style="margin:0 0 18px">We would be grateful if you could share a short review. It takes about a minute.</p><p style="margin:0 0 18px"><a href="${link}" style="background:#023BE4;color:#fff;padding:12px 22px;border-radius:99px;text-decoration:none;font-weight:bold">Write a review</a></p><p style="margin:0;color:#667085;font-size:13px">Or open this link: ${L.esc(link)}</p>`)
      };
    }

    await L.sb(`bookings?id=eq.${encodeURIComponent(id)}`, { method: 'PATCH', body: patch });
    let emailed = false, emailError = '';
    if (!b.email) emailError = 'This booking has no email address.';
    else {
      try { await L.sendMail({ to: b.email, replyTo: contact, ...mail }); emailed = true; }
      catch (e) { emailError = 'Saved, but the email could not be sent.'; console.error('booking-update email failed', e.message); }
    }
    return L.json(res, 200, { ok: true, emailed, emailError, status: patch.status || b.status });
  } catch (e) { console.error(e); return L.json(res, 500, { error: 'Server error' }); }
};
