// Owner only. Sends a newsletter to subscribers, a batch at a time (the dashboard calls this repeatedly).
const L = require('./_lib');
const BATCH = 40;

module.exports = async (req, res) => {
  if (req.method !== 'POST') return L.json(res, 405, { error: 'POST only' });
  if (!L.configured()) return L.json(res, 503, { error: 'Email is not set up yet' });
  try {
    const owner = await L.requireOwner(req);
    if (!owner) return L.json(res, 401, { error: 'Please sign in to the dashboard again' });
    const { subject, message, test, offset = 0, count } = await L.readBody(req);
    if (!subject || !message || String(subject).length > 200 || String(message).length > 20000) return L.json(res, 400, { error: 'Subject and message are required' });

    const build = email => {
      const link = L.unsubLink(email);
      return {
        to: email, subject: String(subject),
        text: `${message}\n\n--\nLascot Studio\nUnsubscribe: ${link}`,
        html: L.layout(String(subject), L.textToHtml(message), `You are receiving this because you subscribed on our website. <a href="${link}" style="color:#667085">Unsubscribe</a>`),
        headers: { 'List-Unsubscribe': `<${link}>` }
      };
    };

    if (test) {
      await L.sendMail(build(L.env('OWNER_NOTIFY_EMAIL', L.env('GMAIL_USER'))));
      return L.json(res, 200, { ok: true, sent: 1, done: true });
    }

    const all = await L.sb(`newsletter_subscribers?status=eq.subscribed&select=email&order=subscribed_at.asc&limit=${BATCH}&offset=${Number(offset) || 0}`);
    let sent = 0, failed = 0;
    for (const r of all || []) {
      try { await L.sendMail(build(r.email)); sent++; } catch (e) { failed++; console.error('newsletter send failed', e.message); }
    }
    return L.json(res, 200, { ok: true, sent, failed, next: (Number(offset) || 0) + (all || []).length, done: !all || all.length < BATCH });
  } catch (e) { console.error(e); return L.json(res, 500, { error: 'Server error' }); }
};
