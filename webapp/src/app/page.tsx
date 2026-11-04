'use client';

// The public landing page (decision 0024) at farmtap.victorbee.com: what
// FarmTap does, live prices from the control panel's plans, how to start,
// questions and the support number. Words are edited in the control panel
// (Website); prices come from Plans.

import Link from 'next/link';
import { Fit } from '@/components/fit';
import { Icon, type IconName } from '@/components/Icon';
import { PublicShell } from '@/components/public';
import { Skel, SkelCard } from '@/components/ui';
import { ugx } from '@/lib/format';
import { monthlyValue } from '@/lib/platform';
import { loadPublicConfig, loadPublicPlans, loadSite, useOnce } from '@/lib/publicData';
import { useSession } from '@/lib/session';
import { telHref, waHref } from '@/lib/site';

const period = (m: number) => (m === 1 ? 'month' : m === 12 ? 'year' : `${m} months`);
const iconOf = (n: string): IconName => (['milk', 'health', 'calendar', 'workers', 'farmers', 'money', 'cow', 'feed', 'card', 'sms', 'chart', 'shield', 'phone', 'offline', 'receipt', 'check'].includes(n) ? (n as IconName) : 'check');

export default function Landing() {
  const { user } = useSession();
  const site = useOnce(loadSite);
  const plans = useOnce(loadPublicPlans);
  const cfg = useOnce(loadPublicConfig);
  const phone = cfg?.support.phone ?? '+256 793 128 137';
  const wa = cfg?.support.whatsapp ?? phone;
  const trial = cfg?.trialDays ?? 14;
  const start = user ? '/start/' : '/sign-in/';

  return (
    <PublicShell>
      <section className="hero">
        <div className="stack lg">
          {site ? (
            <>
              <h1>{site.heroTitle}</h1>
              <p className="lead">{site.heroText}</p>
            </>
          ) : (
            <>
              <Skel h="var(--fs-hero)" w="80%" />
              <Skel h="var(--z-skel-line)" />
              <Skel h="var(--z-skel-line)" w="70%" />
            </>
          )}
          <div className="btn-row">
            <Link className="btn" href={start}>
              <Icon name="play" /> {user ? 'Open my farm' : (site?.ctaLabel ?? 'Start your free trial')}
            </Link>
            <a className="btn outline" href={waHref(wa, 'Hello FarmTap, I want to know more.')} target="_blank" rel="noreferrer">
              <Icon name="whatsapp" /> WhatsApp us
            </a>
          </div>
          <span className="small muted">
            {trial} days free · No card needed · Works without internet on the phone
          </span>
          {site && (site.playUrl || site.appStoreUrl) && (
            <div className="store-badges">
              {site.playUrl && (
                <a className="btn outline sm" href={site.playUrl} target="_blank" rel="noreferrer">
                  <Icon name="play" /> Get it on Google Play
                </a>
              )}
              {site.appStoreUrl && (
                <a className="btn outline sm" href={site.appStoreUrl} target="_blank" rel="noreferrer">
                  <Icon name="apple" /> Download on the App Store
                </a>
              )}
            </div>
          )}
        </div>
        <div className="hero-art" aria-hidden>
          <div className="logo-mark" />
          <strong>Tap. Record. Grow.</strong>
          <ul className="hero-ticks">
            {(site?.steps ?? []).map((s) => (
              <li key={s}>
                <Icon name="check" /> {s}
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section id="features" className="sec">
        <h2>Everything your farm records, in one place</h2>
        <p>Built with farmers in Mbarara: big buttons, few words, and it keeps working when the network does not.</p>
        <Fit cols={[1, 2, 3, 3]}>
          {(site?.features ?? Array.from({ length: 6 }, () => null)).map((f, i) =>
            f ? (
              <article key={f.title} className="card feature">
                <span className="fi">
                  <Icon name={iconOf(f.icon)} />
                </span>
                <h3>{f.title}</h3>
                <p>{f.text}</p>
              </article>
            ) : (
              <SkelCard key={i} lines={3} />
            ),
          )}
        </Fit>
      </section>

      {site?.showPrices !== false && (
        <section id="prices" className="sec">
          <h2>Simple prices</h2>
          <p>{site?.priceNote ?? 'Prices in Uganda shillings.'}</p>
          <Fit kind="cards" cols={[1, 2, 3, 3]}>
            {(plans ?? [null, null, null]).map((p, i) =>
              p ? (
                <article key={p.id} className={`plan-card ${p.badge ? 'featured' : ''}`}>
                  {p.badge && <span className="plan-badge">{p.badge}</span>}
                  <h3>{p.name}</h3>
                  {p.description && <p className="small muted">{p.description}</p>}
                  <div className="plan-price">
                    <span className="amount">{ugx(p.priceUgx)}</span>
                    <span className="per">/ {period(p.months)}</span>
                  </div>
                  {p.months > 1 && <p className="small muted">That is {ugx(monthlyValue(p))} a month.</p>}
                  <ul className="plan-points">
                    {(p.highlights.length ? p.highlights : ['Every dairy feature', 'Phone and web', 'WhatsApp support']).map((h) => (
                      <li key={h}>
                        <Icon name="check" /> {h}
                      </li>
                    ))}
                  </ul>
                  <Link className={`btn ${p.badge ? '' : 'outline'} block`} href={start}>
                    Start {trial} days free
                  </Link>
                </article>
              ) : (
                <SkelCard key={i} lines={5} />
              ),
            )}
          </Fit>
          <p className="small muted">Pay with MTN Mobile Money, Airtel Money or card inside the app. You get a receipt every time.</p>
        </section>
      )}

      <section className="sec">
        <h2>Start in three steps</h2>
        <ol className="steps">
          {(site?.steps ?? []).map((s) => (
            <li key={s}>{s}</li>
          ))}
        </ol>
      </section>

      {!!site?.faq.length && (
        <section id="help" className="sec faq">
          <h2>Questions</h2>
          <div>
            {site.faq.map((f) => (
              <details key={f.q}>
                <summary>{f.q}</summary>
                <p>{f.a}</p>
              </details>
            ))}
          </div>
        </section>
      )}

      <section className="contact-band">
        <div className="stack">
          <h2>{site?.contactTitle ?? 'Talk to us'}</h2>
          <p>{site?.contactText}</p>
        </div>
        <div className="btn-row">
          <a className="btn" href={telHref(phone)}>
            <Icon name="phone" /> {phone}
          </a>
          <a className="btn outline" href={waHref(wa)} target="_blank" rel="noreferrer">
            <Icon name="whatsapp" /> WhatsApp
          </a>
        </div>
      </section>
    </PublicShell>
  );
}
