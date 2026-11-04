'use client';

// Website (decision 0024): the words on the home page at
// farmtap.victorbee.com. Prices come from Plans and SMS; the support number
// from App settings.

import { doc, serverTimestamp } from 'firebase/firestore';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { MsgBanner, Need, Toggle, useAction, useLoad, Fit } from '@/components/admin';
import { Icon } from '@/components/Icon';
import { Field, PageHead, SkelCard } from '@/components/ui';
import { adminChange, setOp } from '@/lib/admin';
import { useAdmin } from '@/lib/adminSession';
import { firebase } from '@/lib/firebase';
import { loadSite } from '@/lib/publicData';
import { defaultSite, type SiteContent } from '@/lib/site';

const ICONS = ['milk', 'health', 'calendar', 'workers', 'farmers', 'money', 'feed', 'card', 'sms', 'chart', 'shield', 'phone', 'offline', 'receipt', 'check'];

export default function Website() {
  const { actor } = useAdmin();
  const site = useLoad(loadSite);
  const act = useAction();
  const [s, setS] = useState<SiteContent | null>(null);
  useEffect(() => {
    if (site.data && !s) setS(site.data);
  }, [site.data, s]);

  if (!s) {
    return (
      <Need perm="settings">
        <PageHead title="Website" subtitle="The home page at farmtap.victorbee.com" />
        <SkelCard lines={8} />
      </Need>
    );
  }
  const set = (p: Partial<SiteContent>) => setS({ ...s, ...p });

  const save = () =>
    act.run(
      () =>
        adminChange(actor, { action: 'site.update', target: 'platform/site' }, [
          setOp(doc(firebase().db, 'platform', 'site'), { ...s, updatedAt: serverTimestamp(), updatedByName: actor.name }, false),
        ]),
      'Saved. The website shows it now.',
    );

  return (
    <Need perm="settings">
      <PageHead title="Website" subtitle="The home page at farmtap.victorbee.com">
        <a className="btn outline sm" href="/" target="_blank" rel="noreferrer">
          <Icon name="eye" /> Open website
        </a>
        <button className="btn sm" onClick={() => void save()} disabled={act.busy}>
          {act.busy ? 'Saving…' : 'Save'}
        </button>
      </PageHead>
      <MsgBanner msg={act.msg} />

      <section className="card stack">
        <div className="card-head">
          <h2>Top of the page</h2>
        </div>
        <Field label="Headline">
          <input className="input" value={s.heroTitle} onChange={(e) => set({ heroTitle: e.target.value })} maxLength={90} />
        </Field>
        <Field label="Text under the headline">
          <textarea className="input" rows={3} value={s.heroText} onChange={(e) => set({ heroText: e.target.value })} maxLength={400} />
        </Field>
        <Fit kind="fields" cols={[1, 3, 3, 3]}>
          <Field label="Main button">
            <input className="input" value={s.ctaLabel} onChange={(e) => set({ ctaLabel: e.target.value })} maxLength={40} />
          </Field>
          <Field label="Google Play link" hint="Empty hides the badge until the app is published.">
            <input className="input" value={s.playUrl} onChange={(e) => set({ playUrl: e.target.value.trim() })} placeholder="https://play.google.com/store/apps/details?id=…" />
          </Field>
          <Field label="App Store link" hint="Empty hides the badge.">
            <input className="input" value={s.appStoreUrl} onChange={(e) => set({ appStoreUrl: e.target.value.trim() })} placeholder="https://apps.apple.com/…" />
          </Field>
        </Fit>
      </section>

      <section className="card stack">
        <div className="card-head">
          <h2>Features</h2>
          <button className="btn ghost sm" onClick={() => set({ features: [...s.features, { icon: 'check', title: '', text: '' }] })} disabled={s.features.length >= 12}>
            <Icon name="plus" /> Add
          </button>
        </div>
        {s.features.map((f, i) => (
          <div key={i} className="row wrap site-row">
            <label className="field site-icon">
              <span>Icon</span>
              <select className="input" value={f.icon} onChange={(e) => set({ features: s.features.map((x, j) => (j === i ? { ...x, icon: e.target.value } : x)) })}>
                {ICONS.map((n) => (
                  <option key={n}>{n}</option>
                ))}
              </select>
            </label>
            <Field label="Title">
              <input className="input" value={f.title} onChange={(e) => set({ features: s.features.map((x, j) => (j === i ? { ...x, title: e.target.value } : x)) })} />
            </Field>
            <label className="field grow">
              <span>Text</span>
              <input className="input" value={f.text} onChange={(e) => set({ features: s.features.map((x, j) => (j === i ? { ...x, text: e.target.value } : x)) })} />
            </label>
            <button className="icon-btn" aria-label="Remove feature" onClick={() => set({ features: s.features.filter((_, j) => j !== i) })}>
              <Icon name="close" />
            </button>
          </div>
        ))}
      </section>

      <Fit kind="cards" cols={[1, 2, 2, 2]}>
        <section className="card stack">
          <div className="card-head">
            <h2>Steps to start</h2>
          </div>
          <p className="small muted">{'{trialDays}'} is replaced with the free trial length from App settings.</p>
          {s.steps.map((st, i) => (
            <div key={i} className="row">
              <input className="input grow" value={st} onChange={(e) => set({ steps: s.steps.map((x, j) => (j === i ? e.target.value : x)) })} aria-label={`Step ${i + 1}`} />
              <button className="icon-btn" aria-label="Remove step" onClick={() => set({ steps: s.steps.filter((_, j) => j !== i) })}>
                <Icon name="close" />
              </button>
            </div>
          ))}
          {s.steps.length < 6 && (
            <button className="btn ghost sm" onClick={() => set({ steps: [...s.steps, ''] })}>
              <Icon name="plus" /> Add step
            </button>
          )}
        </section>

        <section className="card stack">
          <div className="card-head">
            <h2>Prices and contact</h2>
          </div>
          <Toggle label="Show prices" hint={<>Prices come from <Link href="/admin/plans/">Plans and SMS</Link>.</>} checked={s.showPrices} onChange={(v) => set({ showPrices: v })} />
          <Field label="Note under the prices">
            <input className="input" value={s.priceNote} onChange={(e) => set({ priceNote: e.target.value })} />
          </Field>
          <Field label="Contact title">
            <input className="input" value={s.contactTitle} onChange={(e) => set({ contactTitle: e.target.value })} />
          </Field>
          <Field label="Contact text" hint={<>The phone and WhatsApp number come from <Link href="/admin/settings/">App settings</Link>.</>}>
            <textarea className="input" rows={2} value={s.contactText} onChange={(e) => set({ contactText: e.target.value })} />
          </Field>
        </section>
      </Fit>

      <section className="card stack">
        <div className="card-head">
          <h2>Questions and answers</h2>
          <button className="btn ghost sm" onClick={() => set({ faq: [...s.faq, { q: '', a: '' }] })} disabled={s.faq.length >= 20}>
            <Icon name="plus" /> Add
          </button>
        </div>
        {s.faq.map((f, i) => (
          <div key={i} className="row wrap site-row">
            <label className="field grow">
              <span>Question</span>
              <input className="input" value={f.q} onChange={(e) => set({ faq: s.faq.map((x, j) => (j === i ? { ...x, q: e.target.value } : x)) })} />
            </label>
            <label className="field grow">
              <span>Answer</span>
              <input className="input" value={f.a} onChange={(e) => set({ faq: s.faq.map((x, j) => (j === i ? { ...x, a: e.target.value } : x)) })} />
            </label>
            <button className="icon-btn" aria-label="Remove question" onClick={() => set({ faq: s.faq.filter((_, j) => j !== i) })}>
              <Icon name="close" />
            </button>
          </div>
        ))}
      </section>

      <div className="row wrap">
        <button className="btn" onClick={() => void save()} disabled={act.busy}>
          {act.busy ? 'Saving…' : 'Save website'}
        </button>
        <button className="btn ghost" onClick={() => setS(defaultSite)}>
          Load standard words
        </button>
      </div>
    </Need>
  );
}
