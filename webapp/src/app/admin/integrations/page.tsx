'use client';

import { doc, serverTimestamp, Timestamp } from 'firebase/firestore';
import { useEffect, useState, type FormEvent } from 'react';
import { Anchor, Fit, JumpNav, MsgBanner, Need, Toggle, useAction, useLoad } from '@/components/admin';
import { Icon } from '@/components/Icon';
import { Dialog, PageHead } from '@/components/ui';
import { adminChange, loadConfig, loadIntegrations, setOp, type Integrations, type Op } from '@/lib/admin';
import { useAdmin } from '@/lib/adminSession';
import { firebase } from '@/lib/firebase';
import { date } from '@/lib/format';
import { defaultConfig, maskSecret, secretList, secretNameOk, serverSwitchList, type Gateway, type PlatformConfig } from '@/lib/platform';
import { SheetsSendButton } from '@/components/SheetsSend';
import { sheetsUrlOk } from '@/lib/sheets';

/** Keys each in-app gateway needs (names in platformSecrets, read only by functions/). */
const gatewayKeys: Record<string, string[]> = {
  mtn: ['mtn_subscription_key', 'mtn_api_user', 'mtn_api_key'],
  airtel: ['airtel_client_id', 'airtel_client_secret'],
  card: ['flutterwave_secret_key', 'flutterwave_webhook_hash'],
};
const DEFAULT_WEBHOOK_BASE = 'https://europe-west1-farm-tap-1dd15.cloudfunctions.net/paymentWebhook';
const webhookUrl = (base: string, provider: string) => `${(base || DEFAULT_WEBHOOK_BASE).replace(/\/+$/, '')}/${provider}`;

const sections = [
  ['server-jobs', 'Server jobs'],
  ['sms-provider', 'SMS'],
  ['whatsapp', 'WhatsApp'],
  ['google-sheets', 'Google Sheets'],
  ['payments', 'Payments'],
  ['payment-keys', 'Payment keys'],
  ['maps', 'Maps'],
  ['refund-keys', 'Refunds'],
  ['other-keys', 'Other keys'],
] as const;

function SetSecret({ name, onClose, onSaved }: { name: string; onClose: () => void; onSaved: () => void }) {
  const { actor } = useAdmin();
  const [key, setKey] = useState(name);
  const [value, setValue] = useState('');
  const [show, setShow] = useState(false);
  const act = useAction();
  const known = secretList.find((s) => s.key === name);

  function save(e: FormEvent) {
    e.preventDefault();
    const k = key.trim();
    if (!secretNameOk(k)) return act.setMsg({ ok: false, text: 'Use small letters, numbers and _ only, like my_api_key.' });
    if (!value.trim()) return act.setMsg({ ok: false, text: 'Paste the key.' });
    const { db } = firebase();
    void act
      .run(() =>
        // The value goes only to platformSecrets, which no app can read.
        // The audit log and the panel keep just the last 4 characters.
        adminChange(actor, { action: 'secret.set', target: `platformSecrets/${k}`, details: { name: k } }, [
          setOp(doc(db, 'platformSecrets', k), { value: value.trim(), updatedAt: serverTimestamp() }, false),
          setOp(doc(db, 'platform', 'integrations'), { secrets: { [k]: { last4: maskSecret(value), setAt: Timestamp.now(), setByName: actor.name } } }, true),
        ]),
      )
      .then((ok) => ok && (onSaved(), onClose()));
  }

  return (
    <Dialog title={name ? `Set ${known?.label ?? name}` : 'Add an API key'} onClose={onClose}>
      <form className="stack" onSubmit={save} autoComplete="off">
        {!name && (
          <label className="field">
            <span>Name (small letters and _)</span>
            <input className="input mono" value={key} onChange={(e) => setKey(e.target.value.toLowerCase())} placeholder="e.g. yo_uganda_api_key" />
          </label>
        )}
        <label className="field">
          <span>Key</span>
          <div className="row">
            <input className="input mono" type={show ? 'text' : 'password'} value={value} onChange={(e) => setValue(e.target.value)} autoComplete="new-password" spellCheck={false} />
            <button type="button" className="icon-btn" aria-label={show ? 'Hide' : 'Show'} onClick={() => setShow(!show)}>
              <Icon name="eye" />
            </button>
          </div>
        </label>
        <div className="banner info">
          <Icon name="lock" />
          <span className="grow small">Once saved, nobody can read this key back, not even you. Only FarmTap&apos;s server code uses it. To change it, paste a new one.</span>
        </div>
        <MsgBanner msg={act.msg?.ok ? null : act.msg} />
        <div className="actions">
          <button type="button" className="btn outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn" disabled={act.busy}>
            Save key
          </button>
        </div>
      </form>
    </Dialog>
  );
}

function KeyRow({ name, label, info, onSet, canSet }: { name: string; label: string; info?: Integrations['secrets'][string]; onSet: () => void; canSet: boolean }) {
  const set = !!info?.last4;
  return (
    <div className="list-row wrap">
      <div className="stack grow" style={{ gap: 0 }}>
        <strong>{label}</strong>
        <span className="small muted mono">{name}</span>
      </div>
      {set ? (
        <span className="stack" style={{ gap: 0, alignItems: 'flex-end' }}>
          <span className="mono">{info!.last4}</span>
          <span className="small muted">
            {info!.setByName} · {date(info!.setAt)}
          </span>
        </span>
      ) : (
        <span className="chip warn">Not set</span>
      )}
      {canSet && (
        <button className="btn sm outline" onClick={onSet}>
          {set ? 'Replace' : 'Set'}
        </button>
      )}
    </div>
  );
}

export default function IntegrationsPage() {
  const { actor, can } = useAdmin();
  const cfg = useLoad(loadConfig);
  const integ = useLoad(loadIntegrations);
  const act = useAction();
  const [c, setC] = useState<PlatformConfig>(defaultConfig);
  const [i, setI] = useState<Integrations | null>(null);
  const [secret, setSecret] = useState<string | null>(null);
  useEffect(() => cfg.data && setC(cfg.data.config), [cfg.data]);
  useEffect(() => integ.data && setI(integ.data), [integ.data]);

  const cfgChanged = !!cfg.data && JSON.stringify({ p: c.payments, m: c.maps, s: c.server }) !== JSON.stringify({ p: cfg.data.config.payments, m: cfg.data.config.maps, s: cfg.data.config.server });
  const intChanged = !!integ.data && !!i && JSON.stringify({ s: i.sms, p: i.payments, m: i.maps, w: i.whatsapp, g: i.sheets }) !== JSON.stringify({ s: integ.data.sms, p: integ.data.payments, m: integ.data.maps, w: integ.data.whatsapp, g: integ.data.sheets });

  function save() {
    const { db } = firebase();
    const ops: Op[] = [];
    if (cfgChanged && can('settings')) ops.push(setOp(doc(db, 'platform', 'config'), c as unknown as Record<string, unknown>, false));
    if (intChanged && i) ops.push(setOp(doc(db, 'platform', 'integrations'), { sms: i.sms, payments: i.payments, maps: i.maps, whatsapp: i.whatsapp, sheets: { url: i.sheets.url.trim(), secret: i.sheets.secret.trim(), auto: i.sheets.auto } }, true));
    if (!ops.length) return;
    void act
      .run(() => adminChange(actor, { action: 'integrations.edit', target: 'platform/integrations', details: { server: c.server, sms: i?.sms.provider, gateways: c.payments.gateways.filter((g) => g.enabled).map((g) => g.id), maps: c.maps.provider } }, ops))
      .then(() => (cfg.reload(), integ.reload()));
  }

  const gw = (idx: number, g: Partial<Gateway>) => setC((x) => ({ ...x, payments: { ...x.payments, gateways: x.payments.gateways.map((o, j) => (j === idx ? { ...o, ...g } : o)) } }));
  const secrets = integ.data?.secrets ?? {};
  const custom = Object.keys(secrets).filter((k) => !secretList.some((s) => s.key === k));
  const keyRows = (group: string) =>
    secretList
      .filter((s) => s.group === group)
      .map((s) => <KeyRow key={s.key} name={s.key} label={s.label} info={secrets[s.key]} canSet={can('secrets')} onSet={() => setSecret(s.key)} />);

  return (
    <Need perm={['settings', 'secrets']}>
      <PageHead title="APIs and keys" subtitle="SMS, payment and map providers. Keys are write-only.">
        <button className="btn sm" disabled={(!cfgChanged && !intChanged) || act.busy} onClick={save}>
          <Icon name="check" /> Save changes
        </button>
      </PageHead>
      <MsgBanner msg={act.msg} />
      <JumpNav items={sections} />

      <section id="server-jobs" className="card stack anchor">
        <div className="card-head">
          <h2>Server jobs</h2>
          <span className="chip warn">Needs the paid server plan</span>
        </div>
        <p className="small muted">
          These run on FarmTap&apos;s server, which needs the paid (Blaze) plan. Everything is ready: after upgrading, run the one setup command from the
          Blaze guide (it switches these on for you), or switch them on here one by one. Off means FarmTap works as today: phones remind and send
          messages themselves, and receipts are made in the browser.
        </p>
        {serverSwitchList.map((x) => (
          <Toggle key={x.key} label={x.label} hint={x.hint} checked={c.server[x.key]} disabled={!can('settings')} onChange={(v) => setC({ ...c, server: { ...c.server, [x.key]: v } })} />
        ))}
      </section>

      {i && (
        <section id="sms-provider" className="card stack anchor">
          <div className="card-head">
            <h2>SMS provider</h2>
            <span className={`chip ${i.sms.provider === 'none' ? '' : 'ok'}`}>{i.sms.provider === 'none' ? 'Free: farms send from their phone' : 'Automatic'}</span>
          </div>
          <Fit cols={[1, 3, 3, 3]}>
            <label className="field">
              <span>Provider</span>
              <select className="input" value={i.sms.provider} onChange={(e) => setI({ ...i, sms: { ...i.sms, provider: e.target.value as Integrations['sms']['provider'] } })}>
                <option value="none">None (free, from the phone)</option>
                <option value="africastalking">Africa&apos;s Talking</option>
                <option value="twilio">Twilio</option>
              </select>
            </label>
            <label className="field">
              <span>{i.sms.provider === 'twilio' ? 'Account SID' : 'Username'}</span>
              <input className="input" value={i.sms.username} onChange={(e) => setI({ ...i, sms: { ...i.sms, username: e.target.value.trim() } })} />
            </label>
            <label className="field">
              <span>{i.sms.provider === 'twilio' ? 'From number' : 'Sender ID'}</span>
              <input className="input" value={i.sms.senderId} onChange={(e) => setI({ ...i, sms: { ...i.sms, senderId: e.target.value.trim() } })} placeholder="FARMTAP" />
            </label>
          </Fit>
          <div className="list">{keyRows('SMS')}</div>
          <p className="small muted">Automatic sending also needs the paid server plan and the sending job switched on, and each farm switched on (Farms, SMS).</p>
        </section>
      )}

      {i && (
        <section id="whatsapp" className="card stack anchor">
          <div className="card-head">
            <h2>WhatsApp Business API</h2>
            <span className={`chip ${i.whatsapp.phoneNumberId && secrets.whatsapp_token?.last4 ? 'ok' : ''}`}>
              {i.whatsapp.phoneNumberId && secrets.whatsapp_token?.last4 ? 'Ready' : 'Free: farms send from their phone'}
            </span>
          </div>
          <p className="small muted">
            From Meta Business (WhatsApp Manager): the phone number ID, and a message template approved for reminders with one text field. Without a
            template WhatsApp only delivers to people who wrote to you in the last 24 hours.
          </p>
          <Fit cols={[1, 3, 3, 3]}>
            <label className="field">
              <span>Phone number ID</span>
              <input className="input" value={i.whatsapp.phoneNumberId} onChange={(e) => setI({ ...i, whatsapp: { ...i.whatsapp, phoneNumberId: e.target.value.trim() } })} />
            </label>
            <label className="field">
              <span>Template name</span>
              <input className="input" value={i.whatsapp.template} onChange={(e) => setI({ ...i, whatsapp: { ...i.whatsapp, template: e.target.value.trim() } })} placeholder="farm_reminder" />
            </label>
            <label className="field">
              <span>Template language</span>
              <input className="input" value={i.whatsapp.language} onChange={(e) => setI({ ...i, whatsapp: { ...i.whatsapp, language: e.target.value.trim() } })} placeholder="en" />
            </label>
          </Fit>
          <div className="list">{keyRows('WhatsApp')}</div>
        </section>
      )}

      {i && (
        <section id="google-sheets" className="card stack anchor">
          <div className="card-head">
            <h2>Google Sheets</h2>
            <span className={`chip ${sheetsUrlOk(i.sheets.url) && i.sheets.secret ? 'ok' : ''}`}>{sheetsUrlOk(i.sheets.url) && i.sheets.secret ? 'Ready' : 'Not set up'}</span>
          </div>
          <p className="small muted">
            A copy of Farms, Payments, Users and the Audit log in your own Google Sheet, one tab each. Free: it uses a small Apps Script in the sheet (steps in
            docs/GOOGLE_SHEETS.md). Each send replaces the old rows.
          </p>
          <Fit cols={[1, 2, 2, 2]}>
            <label className="field">
              <span>Web app link</span>
              <input className="input" value={i.sheets.url} onChange={(e) => setI({ ...i, sheets: { ...i.sheets, url: e.target.value } })} placeholder="https://script.google.com/macros/s/…/exec" />
              {i.sheets.url && !sheetsUrlOk(i.sheets.url) && <small className="error-text">Use the Web app URL from Deploy, ending in /exec.</small>}
            </label>
            <label className="field">
              <span>Secret word (the SECRET line in the script)</span>
              <input className="input" value={i.sheets.secret} onChange={(e) => setI({ ...i, sheets: { ...i.sheets, secret: e.target.value } })} />
            </label>
          </Fit>
          <label className="row">
            <input type="checkbox" checked={i.sheets.auto} onChange={(e) => setI({ ...i, sheets: { ...i.sheets, auto: e.target.checked } })} />
            <span>Send by itself when an admin opens the Overview (at most once an hour)</span>
          </label>
          <SheetsSendButton settings={i.sheets} disabled={intChanged} />
          {intChanged && <small className="muted">Save changes first, then send.</small>}
        </section>
      )}

      <Anchor
        id="payments"
        title="Payment options farmers see"
        hint={
          i && (
            <select className="input" style={{ width: 'auto' }} value={i.payments.mode} onChange={(e) => setI({ ...i, payments: { ...i.payments, mode: e.target.value as 'sandbox' | 'live' } })} aria-label="Mode">
              <option value="sandbox">Test mode (sandbox, no real money)</option>
              <option value="live">Live money</option>
            </select>
          )
        }
      >
        <Fit cols={[1, 2, 2, 3]}>
          {c.payments.gateways.map((g, idx) => {
            const needs = gatewayKeys[g.id] ?? [];
            const missing = needs.filter((k) => !secrets[k]?.last4);
            return (
              <section key={g.id} className="card stack">
                <div className="card-head">
                  <h2>{g.name}</h2>
                  <span className={`chip ${g.hidden ? '' : g.enabled ? 'ok' : 'warn'}`}>{g.hidden ? 'Hidden' : g.enabled ? 'Live for farms' : 'Coming soon'}</span>
                </div>
                <Toggle
                  label="Farms can pay this way"
                  hint={g.enabled ? 'On: farms can choose it' : 'Muted: farms see it as Coming soon'}
                  checked={g.enabled}
                  disabled={!can('settings')}
                  onChange={(enabled) => gw(idx, { enabled })}
                />
                <Toggle label="Hide it completely" hint="Not even Coming soon" checked={g.hidden} disabled={!can('settings')} onChange={(hidden) => gw(idx, { hidden })} />
                {needs.length > 0 && (
                  <Toggle
                    label="Pay inside the app"
                    hint={g.api ? 'The server asks the network and starts the plan by itself' : 'By hand: farms follow the steps and send the transaction ID'}
                    checked={g.api}
                    disabled={!can('settings')}
                    onChange={(api) => gw(idx, { api })}
                  />
                )}
                {g.api && needs.length > 0 && missing.length > 0 && (
                  <div className="banner warn small">
                    <Icon name="key" />
                    <span className="grow">Paste its keys below before switching it on ({missing.length} missing). Until then farms get an error.</span>
                  </div>
                )}
                <label className="field">
                  <span>Name shown</span>
                  <input className="input" value={g.name} onChange={(e) => gw(idx, { name: e.target.value })} />
                </label>
                {!g.api && (
                  <>
                    <label className="field">
                      <span>{g.id === 'bank' ? 'Account number' : g.id === 'card' ? 'Payment page link' : 'Pay code or number'}</span>
                      <input className="input" value={g.payCode} onChange={(e) => gw(idx, { payCode: e.target.value })} />
                    </label>
                    <label className="field">
                      <span>Account name</span>
                      <input className="input" value={g.accountName} onChange={(e) => gw(idx, { accountName: e.target.value })} />
                    </label>
                    <label className="field">
                      <span>How to pay (simple steps)</span>
                      <input className="input" value={g.instructions} onChange={(e) => gw(idx, { instructions: e.target.value })} />
                    </label>
                  </>
                )}
              </section>
            );
          })}
        </Fit>
        <section className="card">
          <Fit cols={[1, 2, 2, 2]}>
            <label className="field">
              <span>After paying (shown under the options)</span>
              <input className="input" value={c.payments.manualNote} onChange={(e) => setC({ ...c, payments: { ...c.payments, manualNote: e.target.value } })} />
            </label>
            {i && (
              <label className="field">
                <span>MTN target environment (from MTN: sandbox, or mtnuganda when live)</span>
                <input className="input mono" value={i.payments.mtnEnvironment} onChange={(e) => setI({ ...i, payments: { ...i.payments, mtnEnvironment: e.target.value.trim() } })} />
              </label>
            )}
          </Fit>
          {i && (
            <div className="stack small" style={{ marginTop: 'var(--s-md)' }}>
              <strong>Callback addresses to give the providers</strong>
              <span className="muted">Paste these in the MTN, Airtel and Flutterwave portals. FarmTap always re-checks a payment with the provider before starting a plan.</span>
              {(['mtn', 'airtel', 'flutterwave'] as const).map((p) => (
                <code key={p} className="mono" style={{ wordBreak: 'break-all' }}>
                  {webhookUrl(i.payments.callbackUrl, p)}
                </code>
              ))}
              <label className="field">
                <span>Server address (leave empty unless you moved the server code)</span>
                <input className="input mono" type="url" value={i.payments.callbackUrl} placeholder={DEFAULT_WEBHOOK_BASE} onChange={(e) => setI({ ...i, payments: { ...i.payments, callbackUrl: e.target.value.trim() } })} />
              </label>
            </div>
          )}
        </section>
      </Anchor>

      <section id="payment-keys" className="card anchor">
        <div className="card-head">
          <h2>Payment API keys</h2>
          <span className="small muted">MTN MoMo, Airtel Money and card</span>
        </div>
        <div className="split-c">
          <div className="list">
            {keyRows('MTN MoMo')}
            {keyRows('Airtel Money')}
            {keyRows('Card (Flutterwave)')}
          </div>
        </div>
      </section>

      <Fit cols={[1, 1, 2, 2]}>
      <section id="maps" className="card stack anchor">
        <div className="card-head">
          <h2>Maps and location</h2>
        </div>
        <Fit cols={[1, 2, 2, 2]}>
          <label className="field">
            <span>Map provider</span>
            <select className="input" value={c.maps.provider} onChange={(e) => setC({ ...c, maps: { ...c.maps, provider: e.target.value as PlatformConfig['maps']['provider'] } })}>
              <option value="none">None (district list only)</option>
              <option value="openstreetmap">OpenStreetMap (free)</option>
              <option value="google">Google Maps</option>
              <option value="mapbox">Mapbox</option>
            </select>
          </label>
          <label className="field">
            <span>App key (restricted to the FarmTap apps; the phones can read it)</span>
            <input className="input mono" value={c.maps.appKey} onChange={(e) => setC({ ...c, maps: { ...c.maps, appKey: e.target.value.trim() } })} />
          </label>
        </Fit>
        <p className="small muted">Put only a key restricted to the FarmTap app IDs and website here. Keys with billing power go below.</p>
        <div className="list">{keyRows('Maps')}</div>
      </section>

      <section id="refund-keys" className="card stack anchor">
        <div className="card-head">
          <h2>Refund keys</h2>
        </div>
        <p className="small muted">MTN refunds use the MoMo Disbursement product (a separate subscription). Airtel and card refunds use the payment keys above.</p>
        <div className="list">{keyRows('Refunds')}</div>
      </section>

      <section id="other-keys" className="card stack anchor">
        <div className="card-head">
          <h2>Other API keys</h2>
          {can('secrets') && (
            <button className="btn sm outline" onClick={() => setSecret('')}>
              <Icon name="plus" /> Add key
            </button>
          )}
        </div>
        <div className="list">
          {custom.map((k) => (
            <KeyRow key={k} name={k} label={k} info={secrets[k]} canSet={can('secrets')} onSet={() => setSecret(k)} />
          ))}
          {!custom.length && <p className="small muted">Any other provider you add later (for example a new SMS or payment company).</p>}
        </div>
      </section>
      </Fit>

      {secret !== null && <SetSecret name={secret} onClose={() => setSecret(null)} onSaved={integ.reload} />}
    </Need>
  );
}
