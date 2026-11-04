'use client';

import { doc } from 'firebase/firestore';
import { useEffect, useState, type ReactNode } from 'react';
import { Anchor, Fit, JumpNav, MsgBanner, Need, Toggle, useAction, useLoad } from '@/components/admin';
import { Icon } from '@/components/Icon';
import { PageHead } from '@/components/ui';
import { adminChange, loadConfig, setOp } from '@/lib/admin';
import { useAdmin } from '@/lib/adminSession';
import { firebase } from '@/lib/firebase';
import { sectorName } from '@/lib/labels';
import { WEB_BUILD, defaultConfig, featureList, type AppVersion, type PlatformConfig } from '@/lib/platform';

function Section({ title, hint, children }: { title: string; hint?: string; children: ReactNode }) {
  return (
    <section className="card stack">
      <div className="card-head">
        <h2>{title}</h2>
        {hint && <span className="small muted">{hint}</span>}
      </div>
      {children}
    </section>
  );
}

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <label className="field">
      <span>{label}</span>
      {children}
    </label>
  );
}

const sections = [
  ['status', 'Open or closed'],
  ['versions', 'App versions'],
  ['signup', 'Sign-up and support'],
  ['features', 'Features'],
  ['sms', 'SMS and legal'],
] as const;

function VersionFields({ v, onChange, store }: { v: AppVersion; onChange: (v: AppVersion) => void; store: string }) {
  return (
    <Fit cols={[1, 2, 3, 3]}>
      <Field label="Oldest version allowed">
        <input className="input" value={v.minVersion} onChange={(e) => onChange({ ...v, minVersion: e.target.value.trim() })} placeholder="1.0.0" />
      </Field>
      <Field label="Newest version">
        <input className="input" value={v.latestVersion} onChange={(e) => onChange({ ...v, latestVersion: e.target.value.trim() })} placeholder="1.2.0" />
      </Field>
      <Field label={`${store} link`}>
        <input className="input" type="url" value={v.storeUrl} onChange={(e) => onChange({ ...v, storeUrl: e.target.value.trim() })} />
      </Field>
    </Fit>
  );
}

export default function Settings() {
  const { actor, can } = useAdmin();
  const loaded = useLoad(loadConfig);
  const [c, setC] = useState<PlatformConfig>(defaultConfig);
  const act = useAction();
  useEffect(() => {
    if (loaded.data) setC(loaded.data.config);
  }, [loaded.data]);
  const saved = loaded.data?.config;
  const changed = !!saved && JSON.stringify(saved) !== JSON.stringify(c);
  const set = <K extends keyof PlatformConfig>(k: K, v: PlatformConfig[K]) => setC((x) => ({ ...x, [k]: v }));

  const save = (next = c, what = 'settings') =>
    act
      .run(
        () =>
          adminChange(actor, { action: `config.${what}`, target: 'platform/config', details: { changed: Object.keys(next).filter((k) => JSON.stringify(next[k as keyof PlatformConfig]) !== JSON.stringify(saved?.[k as keyof PlatformConfig])) } }, [
            setOp(doc(firebase().db, 'platform', 'config'), next as unknown as Record<string, unknown>, false),
          ]),
        'Saved. Web users get it now; phones the next time they are online.',
      )
      .then(loaded.reload);

  const disabled = !can('settings');

  return (
    <Need perm="settings">
      <PageHead title="App settings" subtitle="Change how both apps behave, with no new build">
        <button className="btn sm" disabled={!changed || act.busy} onClick={() => void save()}>
          <Icon name="check" /> Save changes
        </button>
      </PageHead>
      <MsgBanner msg={act.msg} />
      {loaded.data && !loaded.data.exists && <div className="banner info">These are the built-in defaults. Press Save once to store them.</div>}

      <JumpNav items={sections} />

      <Anchor id="status" title="Open or closed" hint="Maintenance and the web version">
        <Fit cols={[1, 1, 2, 2]}>
          <Section title="Maintenance mode" hint="Admins can still sign in">
            <Toggle
              label={c.maintenance.on ? 'FarmTap is closed for maintenance' : 'FarmTap is open'}
              hint="When on, both apps show your message instead of the farm. Phones that are offline keep working with their saved records."
              checked={c.maintenance.on}
              disabled={disabled}
              onChange={(on) => set('maintenance', { ...c.maintenance, on })}
            />
            <Field label="Message">
              <input className="input" value={c.maintenance.message} onChange={(e) => set('maintenance', { ...c.maintenance, message: e.target.value })} />
            </Field>
          </Section>

          <Section title="Web app version" hint={`This build: ${WEB_BUILD || 'dev'}`}>
            <p className="small muted">After you deploy a new web version, ask every open browser to refresh. Browsers on an older build see a Refresh button.</p>
            <div className="inline-form">
              <Field label="Oldest build allowed">
                <input className="input" inputMode="numeric" value={c.web.minBuild || ''} onChange={(e) => set('web', { ...c.web, minBuild: Number(e.target.value.replace(/\D/g, '')) || 0 })} />
              </Field>
              <button className="btn outline" disabled={disabled || !WEB_BUILD} onClick={() => set('web', { ...c.web, minBuild: WEB_BUILD })}>
                Use this build
              </button>
            </div>
            <Field label="Refresh message">
              <input className="input" value={c.web.message} onChange={(e) => set('web', { ...c.web, message: e.target.value })} />
            </Field>
          </Section>
        </Fit>
      </Anchor>

      <Anchor id="versions" title="App versions" hint="Phones older than the oldest allowed must update">
        <Fit cols={[1, 1, 2, 2]}>
          <Section title="Android app">
            <VersionFields v={c.app.android} store="Play Store" onChange={(v) => set('app', { ...c.app, android: v })} />
          </Section>
          <Section title="iPhone app">
            <VersionFields v={c.app.ios} store="App Store" onChange={(v) => set('app', { ...c.app, ios: v })} />
          </Section>
        </Fit>
        <Section title="Update message" hint="Shown when a phone is too old, or a newer version exists">
          <input className="input" value={c.app.updateMessage} onChange={(e) => set('app', { ...c.app, updateMessage: e.target.value })} aria-label="Update message" />
        </Section>
      </Anchor>

      <Anchor id="signup" title="Sign-up and support">
        <Fit cols={[1, 1, 2, 2]}>
          <Section title="Sign-up and trial">
            <Toggle label="New farms can sign up" checked={c.signup.open} disabled={disabled} onChange={(open) => set('signup', { ...c.signup, open })} />
            <Field label="Free trial (days)">
              <input className="input" type="number" min={1} max={60} value={c.trialDays} onChange={(e) => set('trialDays', Math.max(1, Math.min(60, Math.round(Number(e.target.value) || 7))))} />
            </Field>
            <div className="stack" style={{ gap: 'var(--s-xs)' }}>
              <span className="small muted">Sectors open for sign-up (the others join the waiting list)</span>
              <div className="row wrap">
                {Object.entries(sectorName).map(([k, v]) => {
                  const on = c.signup.sectors.includes(k);
                  return (
                    <button
                      key={k}
                      type="button"
                      className={`chip ${on ? 'ok' : ''}`}
                      style={{ border: 0, cursor: 'pointer' }}
                      aria-pressed={on}
                      onClick={() => set('signup', { ...c.signup, sectors: on ? c.signup.sectors.filter((s) => s !== k) : [...c.signup.sectors, k] })}
                    >
                      {on ? '✓ ' : ''}
                      {v}
                    </button>
                  );
                })}
              </div>
            </div>
            <Field label="Message when sign-up is closed">
              <input className="input" value={c.signup.closedMessage} onChange={(e) => set('signup', { ...c.signup, closedMessage: e.target.value })} />
            </Field>
          </Section>

          <Section title="Support contacts" hint="Shown on every Help page">
            <Fit cols={[1, 2, 2, 2]}>
              <Field label="Phone">
                <input className="input" type="tel" value={c.support.phone} onChange={(e) => set('support', { ...c.support, phone: e.target.value })} />
              </Field>
              <Field label="WhatsApp">
                <input className="input" type="tel" value={c.support.whatsapp} onChange={(e) => set('support', { ...c.support, whatsapp: e.target.value })} />
              </Field>
              <Field label="Email">
                <input className="input" type="email" value={c.support.email} onChange={(e) => set('support', { ...c.support, email: e.target.value })} />
              </Field>
              <Field label="Hours">
                <input className="input" value={c.support.hours} onChange={(e) => set('support', { ...c.support, hours: e.target.value })} />
              </Field>
            </Fit>
          </Section>
        </Fit>
      </Anchor>

      <Anchor id="features" title="Features" hint="For every farm. Plans and single farms can override these">
        <section className="card">
          <div className="split-c">
            <div className="list">
              {featureList.map((f) => (
                <Toggle key={f.key} label={f.label} hint={f.hint} checked={c.features[f.key] ?? false} disabled={disabled} onChange={(on) => set('features', { ...c.features, [f.key]: on })} />
              ))}
            </div>
          </div>
        </section>
      </Anchor>

      <Anchor id="sms" title="SMS and legal">
        <Fit cols={[1, 1, 2, 2]}>
          <Section title="Automatic SMS">
            <Toggle
              label="Offer automatic SMS"
              hint="Farms can buy SMS packages. Needs a provider and key under APIs and keys."
              checked={c.sms.autoSendAvailable}
              disabled={disabled}
              onChange={(on) => set('sms', { ...c.sms, autoSendAvailable: on })}
            />
            <Field label="Cost to you per SMS (UGX, for the reports)">
              <input className="input" inputMode="numeric" value={c.sms.pricePerSmsUgx} onChange={(e) => set('sms', { ...c.sms, pricePerSmsUgx: Number(e.target.value.replace(/\D/g, '')) || 0 })} />
            </Field>
          </Section>
          <Section title="Legal links">
            <Field label="Terms of use">
              <input className="input" type="url" value={c.legal.termsUrl} onChange={(e) => set('legal', { ...c.legal, termsUrl: e.target.value })} />
            </Field>
            <Field label="Privacy policy">
              <input className="input" type="url" value={c.legal.privacyUrl} onChange={(e) => set('legal', { ...c.legal, privacyUrl: e.target.value })} />
            </Field>
          </Section>
        </Fit>
      </Anchor>

      {changed && (
        <div className="sticky-actions">
          <button className="btn outline" onClick={() => saved && setC(saved)}>
            Undo changes
          </button>
          <button className="btn" disabled={act.busy} onClick={() => void save()}>
            Save changes
          </button>
        </div>
      )}
    </Need>
  );
}
