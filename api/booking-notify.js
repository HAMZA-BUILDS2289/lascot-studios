// Called by the website right after a booking is saved. Emails the studio and the customer.
// Safe by design: it only reads the booking from the database and only emails the address saved on it,
// only once, and only for bookings made in the last 30 minutes.
const L = require('./_lib');

module.exports = async (req, res) => {
  if (req.method !== 'POST') return L.json(res, 405, { error: 'POST only' });
  if (!L.configured()) return L.json(res, 503, { error: 'Email is not set up yet' });
  try {
    const { reference } = await L.readBody(req);
    if (!reference || typeof reference !== 'string' || reference.length > 60) return L.json(res, 400, { error: 'Missing reference' });

    const since = new Date(Date.now() - 30 * 60 * 1000).toISOString();
    // claim the booking so the emails are sent only once
    const claimed = await L.sb(`bookings?reference=eq.${encodeURIComponent(reference)}&notified_at=is.null&created_at=gte.${since}`,
      { method: 'PATCH', body: { notified_at: new Date().toISOString() }, prefer: 'return=representation' });
    if (!claimed || !claimed.length) return L.json(res, 200, { ok: true, skipped: true });
    const b = claimed[0];

    const [svc, pkg] = await Promise.all([
      b.service_id ? L.sb(`services?id=eq.${b.service_id}&select=name`).catch(() => []) : [],
      b.package_id ? L.sb(`service_packages?id=eq.${b.package_id}&select=name`).catch(() => []) : []
    ]);
    const service = svc && svc[0] ? svc[0].name : '';
    const pack = pkg && pkg[0] ? pkg[0].name : '';
    const name = b.full_name || b.name || 'there';
    const rows = [['Reference', b.reference], ['Name', name], ['Email', b.email], ['Phone', b.phone], ['Service', service], ['Package', pack], ['Photos chosen', b.photo_choice]].filter(r => r[1]);
    const table = `<table role="presentation" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-size:15px">${rows.map(r => `<tr><td style="color:#667085;padding-right:18px">${L.esc(r[0])}</td><td><b>${L.esc(r[1])}</b></td></tr>`).join('')}</table>`;
    const textRows = rows.map(r => `${r[0]}: ${r[1]}`).join('\n');
    const owner = L.env('OWNER_NOTIFY_EMAIL', L.env('GMAIL_USER'));
    const results = { owner: false, customer: false };

    try {
      await L.sendMail({
        to: owner, replyTo: b.email || undefined,
        subject: `New booking request: ${name}${service ? ' · ' + service : ''}`,
        text: `You have a new booking request on the website.\n\n${textRows}\n\nOpen the dashboard to confirm it: ${L.SITE()}/admin.html`,
        html: L.layout('New booking request', `<p style="margin:0 0 16px">Someone just booked on your website.</p>${table}<p style="margin:20px 0 0"><a href="${L.SITE()}/admin.html" style="background:#023BE4;color:#fff;padding:12px 22px;border-radius:99px;text-decoration:none;font-weight:bold">Open dashboard</a></p><p style="margin:16px 0 0;color:#667085;font-size:14px">Reply to this email to answer the customer directly.</p>`)
      });
      results.owner = true;
    } catch (e) { console.error('owner email failed', e.message); }

    if (b.email) {
      try {
        await L.sendMail({
          to: b.email,
          subject: 'We received your booking request · Lascot Studio',
          text: `Hello ${name},\n\nThank you for your booking request. It is not confirmed yet. We will contact you shortly to agree the details.\n\n${textRows}\n\nLascot Studio`,
          html: L.layout('Thank you, ' + name, `<p style="margin:0 0 14px">We have received your booking request. <b>It is not confirmed yet.</b> We will get in touch shortly to agree the details with you.</p>${table}<p style="margin:20px 0 0;color:#667085;font-size:14px">If anything above is wrong, just reply to this email.</p>`, 'Lascot Studio · Monday to Saturday, 8:00 AM – 5:00 PM')
        });
        results.customer = true;
      } catch (e) { console.error('customer email failed', e.message); }
    }

    if (!results.owner && !results.customer) { // nothing went out: allow a retry
      await L.sb(`bookings?reference=eq.${encodeURIComponent(reference)}`, { method: 'PATCH', body: { notified_at: null } }).catch(() => {});
      return L.json(res, 502, { error: 'Could not send email' });
    }
    return L.json(res, 200, { ok: true, ...results });
  } catch (e) {
    console.error(e);
    return L.json(res, 500, { error: 'Server error' });
  }
};
