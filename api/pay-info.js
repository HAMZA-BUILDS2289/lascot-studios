// Tells the pay page what a booking costs and what has been paid. Shows only a first name and amounts.
const L = require('./_lib'), P = require('./_pay');
module.exports = async (req, res) => {
  try {
    const ref = String((req.query && req.query.reference) || new URL(req.url, 'http://x').searchParams.get('reference') || '');
    const st = await P.settings();
    if (!P.payConfigured() || !st.enabled) return L.json(res, 200, { enabled: false });
    const x = await P.loadBooking(ref);
    if (!x) return L.json(res, 404, { error: 'Booking not found' });
    const pl = P.plan(x.b, x.pkg, st);
    return L.json(res, 200, { enabled: true, first_name: String(x.b.full_name || x.b.name || '').split(' ')[0], service: x.service, package: x.pkg ? x.pkg.name : '', photo_choice: x.b.photo_choice || '',
      total_kobo: pl.total, paid_kobo: pl.paid, balance_kobo: pl.balance, status: x.b.payment_status || 'unpaid', options: pl.options, deposit_percent: st.deposit_percent });
  } catch (e) { return L.json(res, 500, { error: 'Something went wrong' }); }
};
