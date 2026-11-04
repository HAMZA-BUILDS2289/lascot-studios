// Link at the bottom of every newsletter. Signed, so only the real link works.
const L = require('./_lib');

const page = (title, msg) => `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex"><title>${L.esc(title)}</title></head><body style="margin:0;font-family:Arial,sans-serif;background:#F5F8FF;color:#101828;display:grid;place-items:center;min-height:100vh;padding:20px"><div style="max-width:440px;background:#fff;border-radius:14px;padding:32px;text-align:center"><h1 style="font-size:22px;margin:0 0 12px">${L.esc(title)}</h1><p style="color:#667085;line-height:1.6">${L.esc(msg)}</p><a href="${L.SITE()}" style="color:#023BE4">Back to Lascot Studio</a></div></body></html>`;

module.exports = async (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  try {
    const u = new URL(req.url, 'http://x'), e = (u.searchParams.get('e') || '').trim(), t = u.searchParams.get('t') || '';
    if (!e || !L.configured() || t !== L.unsubToken(e)) { res.statusCode = 400; return res.end(page('This link is not valid', 'Please use the unsubscribe link from the latest email we sent you.')); }
    await L.sb(`newsletter_subscribers?email=ilike.${encodeURIComponent(e)}`, { method: 'PATCH', body: { status: 'unsubscribed' } });
    res.statusCode = 200; return res.end(page('You have been unsubscribed', 'You will not receive our newsletter any more.'));
  } catch (err) { console.error(err); res.statusCode = 500; return res.end(page('Something went wrong', 'Please try again in a moment.')); }
};
