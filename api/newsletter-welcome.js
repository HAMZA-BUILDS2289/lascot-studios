// Sends a one-time welcome email to a new subscriber (only to an address already saved as a subscriber).
const L = require('./_lib');

module.exports = async (req, res) => {
  if (req.method !== 'POST') return L.json(res, 405, { error: 'POST only' });
  if (!L.configured()) return L.json(res, 503, { error: 'Email is not set up yet' });
  try {
    const { email } = await L.readBody(req);
    if (!email || typeof email !== 'string' || email.length > 200 || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return L.json(res, 400, { error: 'Bad email' });
    const e = email.trim().toLowerCase();
    const since = new Date(Date.now() - 30 * 60 * 1000).toISOString();
    const rows = await L.sb(`newsletter_subscribers?email=ilike.${encodeURIComponent(e)}&status=eq.subscribed&welcome_sent_at=is.null&subscribed_at=gte.${since}`,
      { method: 'PATCH', body: { welcome_sent_at: new Date().toISOString() }, prefer: 'return=representation' });
    if (!rows || !rows.length) return L.json(res, 200, { ok: true, skipped: true });
    const name = rows[0].name || '';
    const link = L.unsubLink(rows[0].email);
    try {
      await L.sendMail({
        to: rows[0].email,
        subject: 'Welcome to Lascot Studio',
        text: `Hello${name ? ' ' + name : ''},\n\nThank you for subscribing. You will be the first to see our latest photography, studio updates and offers.\n\nLascot Studio\n\nUnsubscribe: ${link}`,
        html: L.layout('Welcome' + (name ? ', ' + name : ''), `<p style="margin:0 0 14px">Thank you for subscribing to Lascot Studio. You will be the first to discover our latest photography, studio updates and exclusive offers.</p><p style="margin:0"><a href="${L.SITE()}/#portfolio" style="background:#023BE4;color:#fff;padding:12px 22px;border-radius:99px;text-decoration:none;font-weight:bold">See our work</a></p>`,
          `You are receiving this because you subscribed on our website. <a href="${link}" style="color:#667085">Unsubscribe</a>`),
        headers: { 'List-Unsubscribe': `<${link}>` }
      });
    } catch (err) {
      await L.sb(`newsletter_subscribers?email=ilike.${encodeURIComponent(e)}`, { method: 'PATCH', body: { welcome_sent_at: null } }).catch(() => {});
      return L.json(res, 502, { error: 'Could not send email' });
    }
    return L.json(res, 200, { ok: true });
  } catch (e) { console.error(e); return L.json(res, 500, { error: 'Server error' }); }
};
