// Paid automatic messages (decisions 0015 and 0024). The app saves every
// message in tenants/{t}/smsOutbox as `queued`; for free the user sends it
// from their own phone. These providers send it automatically instead, once
// Victor has pasted the keys and switched it on. `fetch` is injectable for tests.

export type Fetch = typeof fetch;

export interface SendResult {
  ok: boolean;
  providerId?: string | null;
  cost?: string | null;
  error?: string | null;
}

export interface SmsConfig {
  username: string;
  from: string;
  apiKey: string;
}

/** Africa's Talking (Uganda: about UGX 25-35 per SMS, Nov 2026). username 'sandbox' uses their test system. */
export async function africasTalking(to: string, text: string, cfg: SmsConfig, f: Fetch = fetch): Promise<SendResult> {
  const host = cfg.username === 'sandbox' ? 'api.sandbox.africastalking.com' : 'api.africastalking.com';
  const form = new URLSearchParams({ username: cfg.username, to, message: text });
  if (cfg.from) form.set('from', cfg.from);
  const res = await f(`https://${host}/version1/messaging`, {
    method: 'POST',
    headers: { apiKey: cfg.apiKey, Accept: 'application/json', 'Content-Type': 'application/x-www-form-urlencoded' },
    body: form.toString(),
  });
  if (!res.ok) return { ok: false, error: `http ${res.status}` };
  const data = (await res.json().catch(() => ({}))) as { SMSMessageData?: { Message?: string; Recipients?: { status?: string; messageId?: string; cost?: string }[] } };
  const r = data.SMSMessageData?.Recipients?.[0];
  if (!r) return { ok: false, error: data.SMSMessageData?.Message ?? 'no recipient' };
  return r.status === 'Success' ? { ok: true, providerId: r.messageId ?? null, cost: r.cost ?? null } : { ok: false, error: r.status ?? 'failed' };
}

/** Twilio (much dearer to Uganda). username = Account SID, apiKey = auth token, from = number or MG service id. */
export async function twilio(to: string, text: string, cfg: SmsConfig, f: Fetch = fetch): Promise<SendResult> {
  const form = new URLSearchParams({ To: to, Body: text });
  if (cfg.from.startsWith('MG')) form.set('MessagingServiceSid', cfg.from);
  else form.set('From', cfg.from);
  const auth = Buffer.from(`${cfg.username}:${cfg.apiKey}`).toString('base64');
  const res = await f(`https://api.twilio.com/2010-04-01/Accounts/${cfg.username}/Messages.json`, {
    method: 'POST',
    headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/x-www-form-urlencoded' },
    body: form.toString(),
  });
  const data = (await res.json().catch(() => ({}))) as { sid?: string; price?: string; message?: string };
  return res.ok ? { ok: true, providerId: data.sid ?? null, cost: data.price ?? null } : { ok: false, error: data.message ?? `http ${res.status}` };
}

export interface WhatsAppConfig {
  /** WhatsApp Business phone number id (Meta). */
  phoneNumberId: string;
  /** Permanent access token. */
  token: string;
  /** Approved utility template for messages outside a 24-hour chat (one {{1}} body variable). */
  template: string;
  language: string;
}

/**
 * WhatsApp Cloud API (Meta). Business-started messages must use an approved
 * template; the text goes in as its one variable. Meta charges per message.
 */
export async function whatsappCloud(to: string, text: string, cfg: WhatsAppConfig, f: Fetch = fetch): Promise<SendResult> {
  const digits = to.replace(/\D/g, '');
  const body = cfg.template
    ? {
        messaging_product: 'whatsapp',
        to: digits,
        type: 'template',
        template: { name: cfg.template, language: { code: cfg.language || 'en' }, components: [{ type: 'body', parameters: [{ type: 'text', text: text.slice(0, 1000) }] }] },
      }
    : { messaging_product: 'whatsapp', to: digits, type: 'text', text: { body: text.slice(0, 4000) } };
  const res = await f(`https://graph.facebook.com/v21.0/${encodeURIComponent(cfg.phoneNumberId)}/messages`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${cfg.token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const data = (await res.json().catch(() => ({}))) as { messages?: { id?: string }[]; error?: { message?: string } };
  return res.ok && data.messages?.[0]?.id ? { ok: true, providerId: data.messages[0].id } : { ok: false, error: data.error?.message ?? `http ${res.status}` };
}

export type SmsProvider = 'africastalking' | 'twilio';
export const smsSender = (name: string | undefined) => (name === 'africastalking' ? africasTalking : name === 'twilio' ? twilio : null);

/** How a queued message should go: 'whatsapp' when it asks for it and WhatsApp is on, else SMS. */
export function routeFor(body: Record<string, unknown>, smsOn: boolean, whatsappOn: boolean): 'sms' | 'whatsapp' | null {
  const want = body.via === 'whatsapp' || body.channel === 'whatsapp' ? 'whatsapp' : 'sms';
  if (want === 'whatsapp' && whatsappOn) return 'whatsapp';
  if (smsOn) return 'sms';
  if (whatsappOn) return 'whatsapp';
  return null;
}
