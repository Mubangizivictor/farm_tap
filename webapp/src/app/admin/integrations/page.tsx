'use client';

import { doc, serverTimestamp, Timestamp } from 'firebase/firestore';
import { useEffect, useState, type FormEvent } from 'react';
import { MsgBanner, Need, Toggle, useAction, useLoad } from '@/components/admin';
import { Icon } from '@/components/Icon';
import { Dialog, PageHead } from '@/components/ui';
import { adminChange, loadConfig, loadIntegrations, setOp, type Integrations, type Op } from '@/lib/admin';
import { useAdmin } from '@/lib/adminSession';
import { firebase } from '@/lib/firebase';
import { date } from '@/lib/format';
import { defaultConfig, maskSecret, secretList, secretNameOk, type Gateway, type PlatformConfig } from '@/lib/platform';

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

  const cfgChanged = !!cfg.data && JSON.stringify({ p: c.payments, m: c.maps }) !== JSON.stringify({ p: cfg.data.config.payments, m: cfg.data.config.maps });
  const intChanged = !!integ.data && !!i && JSON.stringify({ s: i.sms, p: i.payments, m: i.maps }) !== JSON.stringify({ s: integ.data.sms, p: integ.data.payments, m: integ.data.maps });

  function save() {
    const { db } = firebase();
    const ops: Op[] = [];
    if (cfgChanged && can('settings')) ops.push(setOp(doc(db, 'platform', 'config'), c as unknown as Record<string, unknown>, false));
    if (intChanged && i) ops.push(setOp(doc(db, 'platform', 'integrations'), { sms: i.sms, payments: i.payments, maps: i.maps }, true));
    if (!ops.length) return;
    void act
      .run(() => adminChange(actor, { action: 'integrations.edit', target: 'platform/integrations', details: { sms: i?.sms.provider, gateways: c.payments.gateways.filter((g) => g.enabled).map((g) => g.id), maps: c.maps.provider } }, ops))
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

      {i && (
        <section className="card stack">
          <div className="card-head">
            <h2>SMS provider</h2>
            <span className={`chip ${i.sms.provider === 'none' ? '' : 'ok'}`}>{i.sms.provider === 'none' ? 'Free: farms send from their phone' : 'Automatic'}</span>
          </div>
          <div className="grid">
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
          </div>
          <div className="list">{keyRows('SMS')}</div>
          <p className="small muted">Automatic sending also needs the Firebase Blaze plan and the server job deployed, and each farm switched on (Farms, SMS).</p>
        </section>
      )}

      <section className="card stack">
        <div className="card-head">
          <h2>Payment options farmers see</h2>
          {i && (
            <select className="input" style={{ width: 'auto' }} value={i.payments.mode} onChange={(e) => setI({ ...i, payments: { ...i.payments, mode: e.target.value as 'sandbox' | 'live' } })} aria-label="Mode">
              <option value="sandbox">Test mode (sandbox)</option>
              <option value="live">Live money</option>
            </select>
          )}
        </div>
        {c.payments.gateways.map((g, idx) => (
          <div key={g.id} className="card flat stack">
            <Toggle label={g.name} hint={g.enabled ? 'Shown in the apps' : 'Hidden'} checked={g.enabled} disabled={!can('settings')} onChange={(enabled) => gw(idx, { enabled })} />
            {g.enabled && (
              <div className="grid">
                <label className="field">
                  <span>Name shown</span>
                  <input className="input" value={g.name} onChange={(e) => gw(idx, { name: e.target.value })} />
                </label>
                <label className="field">
                  <span>{g.id === 'bank' ? 'Account number' : g.id === 'card' ? 'Payment page link' : 'Pay code or number'}</span>
                  <input className="input" value={g.payCode} onChange={(e) => gw(idx, { payCode: e.target.value })} />
                </label>
                <label className="field">
                  <span>Account name</span>
                  <input className="input" value={g.accountName} onChange={(e) => gw(idx, { accountName: e.target.value })} />
                </label>
                <label className="field" style={{ gridColumn: '1 / -1' }}>
                  <span>How to pay (simple steps)</span>
                  <input className="input" value={g.instructions} onChange={(e) => gw(idx, { instructions: e.target.value })} />
                </label>
              </div>
            )}
          </div>
        ))}
        <label className="field">
          <span>After paying (shown under the options)</span>
          <input className="input" value={c.payments.manualNote} onChange={(e) => setC({ ...c, payments: { ...c.payments, manualNote: e.target.value } })} />
        </label>
        {i && (
          <label className="field">
            <span>Payment callback URL (from your Cloud Function, when you add the APIs)</span>
            <input className="input" type="url" value={i.payments.callbackUrl} onChange={(e) => setI({ ...i, payments: { ...i.payments, callbackUrl: e.target.value.trim() } })} />
          </label>
        )}
        <h3>Payment API keys</h3>
        <div className="list">
          {keyRows('MTN MoMo')}
          {keyRows('Airtel Money')}
          {keyRows('Card (Flutterwave)')}
        </div>
      </section>

      <section className="card stack">
        <div className="card-head">
          <h2>Maps and location</h2>
        </div>
        <div className="grid">
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
        </div>
        <p className="small muted">Put only a key restricted to the FarmTap app IDs and website here. Keys with billing power go below.</p>
        <div className="list">{keyRows('Maps')}</div>
      </section>

      <section className="card stack">
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

      {secret !== null && <SetSecret name={secret} onClose={() => setSecret(null)} onSaved={integ.reload} />}
    </Need>
  );
}
