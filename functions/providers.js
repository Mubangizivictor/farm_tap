// Paid SMS providers for automatic sending (decision 0015). The app never
// holds these keys; they live in Firebase secrets / params.
//
// Each provider is `async send({to, text}) -> {ok, providerId?, cost?, error?}`.
// Add a provider by adding a function to `providers` below.

/** Africa's Talking (Uganda: about UGX 25-27 per SMS on MTN/Airtel, Nov 2026). */
async function africasTalking({ to, text }, cfg, fetchFn = fetch) {
  const host = cfg.username === 'sandbox' ? 'api.sandbox.africastalking.com' : 'api.africastalking.com';
  const form = new URLSearchParams({ username: cfg.username, to, message: text });
  if (cfg.from) form.set('from', cfg.from);
  const res = await fetchFn(`https://${host}/version1/messaging`, {
    method: 'POST',
    headers: { apiKey: cfg.apiKey, Accept: 'application/json', 'Content-Type': 'application/x-www-form-urlencoded' },
    body: form.toString(),
  });
  if (!res.ok) return { ok: false, error: `http ${res.status}` };
  const data = await res.json();
  const r = data?.SMSMessageData?.Recipients?.[0];
  if (!r) return { ok: false, error: data?.SMSMessageData?.Message ?? 'no recipient' };
  return r.status === 'Success'
    ? { ok: true, providerId: r.messageId, cost: r.cost }
    : { ok: false, error: r.status };
}

/** Twilio (much dearer to Uganda: about USD 0.26 per SMS, Nov 2026). */
async function twilio({ to, text }, cfg, fetchFn = fetch) {
  const form = new URLSearchParams({ To: to, Body: text });
  if (cfg.from.startsWith('MG')) form.set('MessagingServiceSid', cfg.from);
  else form.set('From', cfg.from);
  const auth = Buffer.from(`${cfg.username}:${cfg.apiKey}`).toString('base64');
  const res = await fetchFn(`https://api.twilio.com/2010-04-01/Accounts/${cfg.username}/Messages.json`, {
    method: 'POST',
    headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/x-www-form-urlencoded' },
    body: form.toString(),
  });
  const data = await res.json().catch(() => ({}));
  return res.ok ? { ok: true, providerId: data.sid, cost: data.price } : { ok: false, error: data.message ?? `http ${res.status}` };
}

const providers = { africastalking: africasTalking, twilio };

/** The provider named [name], or null for 'none' / unknown (nothing is sent). */
function providerFor(name) {
  return providers[(name || 'none').toLowerCase()] ?? null;
}

module.exports = { providerFor, africasTalking, twilio };
