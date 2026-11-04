// sendQueuedMessage (decisions 0015, 0024): when an app queues a message in
// tenants/{t}/smsOutbox, send it through the paid provider IF
//   1. Victor switched it on (platform/config.server.autoSms or .whatsappApi),
//   2. the provider and key are set in the control panel (APIs and keys), and
//   3. the farm has paid automatic messages on (tenants/{t}.messaging.autoSend).
// Otherwise nothing happens and the farm sends it from its own phone (free).

import { FieldValue, type DocumentReference } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { routeFor, smsSender, whatsappCloud, type SendResult } from './messaging';
import { db, integrations, secret, switchOn } from './server';

/** Claims a queued message so it is sent once; returns its body or null. */
async function claim(ref: DocumentReference): Promise<{ body: Record<string, unknown>; version: number } | null> {
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const d = snap.data();
    const body = (d?.body ?? {}) as Record<string, unknown>;
    if (!d || d.isDeleted || body.status !== 'queued') return null;
    const version = (Number(d.version) || 1) + 1;
    tx.update(ref, { 'body.status': 'sending', version, updatedBy: 'server', serverUpdatedAt: FieldValue.serverTimestamp() });
    return { body, version };
  });
}

export const sendQueuedMessage = onDocumentWritten({ document: 'tenants/{t}/smsOutbox/{id}', timeoutSeconds: 60 }, async (event) => {
  const after = event.data?.after?.data();
  const body = (after?.body ?? {}) as Record<string, unknown>;
  if (!after || after.isDeleted || body.status !== 'queued') return;
  const [smsOn, waOn] = await Promise.all([switchOn('autoSms'), switchOn('whatsappApi')]);
  if (!smsOn && !waOn) return;
  const tenant = (await db().doc(`tenants/${event.params.t}`).get()).data();
  if (tenant?.messaging?.autoSend !== true) return;

  const cfg = await integrations();
  const sms = cfg.sms ?? {};
  const wa = cfg.whatsapp ?? {};
  const send = smsSender(String(sms.provider ?? ''));
  const [smsKey, waToken] = await Promise.all([secret('sms_api_key'), secret('whatsapp_token')]);
  const route = routeFor(body, smsOn && !!send && !!smsKey, waOn && !!waToken && !!wa.phoneNumberId);
  if (!route) return;

  const ref = event.data!.after.ref;
  const claimed = await claim(ref);
  if (!claimed) return;
  const to = String(claimed.body.to ?? '');
  const text = String(claimed.body.text ?? '');
  let result: SendResult;
  try {
    result =
      route === 'whatsapp'
        ? await whatsappCloud(to, text, { phoneNumberId: String(wa.phoneNumberId), token: waToken, template: String(wa.template ?? ''), language: String(wa.language ?? 'en') })
        : await send!(to, text, { username: String(sms.username ?? ''), from: String(sms.senderId ?? ''), apiKey: smsKey });
  } catch (e) {
    result = { ok: false, error: String(e) };
  }
  if (!result.ok) logger.warn('message failed', { tenant: event.params.t, id: event.params.id, route, error: result.error });
  await ref.update({
    'body.status': result.ok ? 'sent' : 'failed',
    'body.via': route,
    'body.providerId': result.providerId ?? null,
    'body.cost': result.cost ?? null,
    'body.error': result.error ?? null,
    'body.sentAt': result.ok ? new Date().toISOString() : null,
    version: claimed.version + 1,
    updatedBy: 'server',
    serverUpdatedAt: FieldValue.serverTimestamp(),
  });
});
