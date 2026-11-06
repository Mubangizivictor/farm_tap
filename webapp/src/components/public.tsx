'use client';

// The public website's frame (decision 0024): header, footer, and the
// signed legal document view. Same brand, tokens and dark mode as the app.

import Link from 'next/link';
import { Fragment, type ReactNode } from 'react';
import { Icon } from '@/components/Icon';
import { Skel } from '@/components/ui';
import { loadAsset, loadPublicInfo, useOnce, type Asset } from '@/lib/publicData';
import { telHref, waHref } from '@/lib/site';
import { useSession } from '@/lib/session';
import { contents, fillOperator, longDate, parseMarkdown, OPERATOR, type Inline, type LegalDoc } from '@/shared/legal';

export function Rich({ parts }: { parts: Inline }) {
  return (
    <>
      {parts.map((p, i) => (p.bold ? <strong key={i}>{p.text}</strong> : <Fragment key={i}>{p.text}</Fragment>))}
    </>
  );
}

export function PublicShell({ children, wide = true }: { children: ReactNode; wide?: boolean }) {
  const { user } = useSession();
  const info = useOnce(loadPublicInfo);
  const phone = info?.config.support.phone ?? OPERATOR.phone;
  const wa = info?.config.support.whatsapp ?? phone;
  const year = new Date().getFullYear();
  return (
    <div className="pub">
      <header className="pub-head">
        <div className={`pub-in ${wide ? '' : 'narrow'}`}>
          <Link href="/" className="pub-brand" aria-label="FarmTap home">
            <span className="logo-full" role="img" aria-label="FarmTap" />
          </Link>
          <nav className="pub-nav" aria-label="Site">
            <Link href="/#features" className="hide-sm">
              Features
            </Link>
            <Link href="/#prices" className="hide-sm">
              Prices
            </Link>
            <Link href="/#help" className="hide-sm">
              Help
            </Link>
            {user ? (
              <Link className="btn sm" href="/start/">
                Open my farm
              </Link>
            ) : (
              <>
                <Link className="btn sm outline" href="/sign-in/">
                  Sign in
                </Link>
              </>
            )}
          </nav>
        </div>
      </header>
      <main className={`pub-main ${wide ? '' : 'narrow'}`}>{children}</main>
      <footer className="pub-foot">
        <div className="pub-in">
          <div className="stack">
            <span className="logo-full" role="img" aria-label="FarmTap" />
            <span className="small muted">Farm records for Uganda. Made in Mbarara by {info?.company.company ?? OPERATOR.company}.</span>
          </div>
          <div className="stack">
            <strong>Help</strong>
            <a href={telHref(phone)}>
              <Icon name="phone" /> {phone}
            </a>
            <a href={waHref(wa)} target="_blank" rel="noreferrer">
              <Icon name="whatsapp" /> WhatsApp us
            </a>
            {info?.config.support.email && (
              <a href={`mailto:${info.config.support.email}`}>
                <Icon name="mail" /> {info.config.support.email}
              </a>
            )}
          </div>
          <div className="stack">
            <strong>Legal</strong>
            <Link href="/privacy/">Privacy Policy</Link>
            <Link href="/terms/">Terms of Use</Link>
            <Link href="/delete-account/">Delete my account</Link>
          </div>
        </div>
        <div className="pub-in small muted pub-copy">
          © {year} {info?.company.company ?? OPERATOR.company}. All rights reserved.
        </div>
      </footer>
    </div>
  );
}

/** A picture uploaded in the control panel (logo, stamp, signature). */
export function AssetImg({ asset, alt, className }: { asset: Asset | null | undefined; alt: string; className: string }) {
  const src = asset?.url || asset?.dataUrl;
  if (!src) return null;
  // eslint-disable-next-line @next/next/no-img-element
  return <img src={src} alt={alt} className={className} />;
}

/** A Privacy Policy or Terms of Use page: logo, title, version, contents, text, signature. */
export function LegalView({ doc, preview = false }: { doc: LegalDoc | undefined; preview?: boolean }) {
  const info = useOnce(loadPublicInfo);
  const signature = useOnce(() => loadAsset('signature'));
  const stamp = useOnce(() => loadAsset('stamp'));
  if (!doc) {
    return (
      <article className="legal card">
        <Skel h="var(--fs-hero-sm)" w="60%" />
        <Skel h="var(--z-skel-line)" w="40%" />
        {Array.from({ length: 10 }, (_, i) => (
          <Skel key={i} h="var(--z-skel-line)" />
        ))}
      </article>
    );
  }
  const op = {
    ...OPERATOR,
    company: info?.company.company ?? OPERATOR.company,
    address: info?.company.address ?? OPERATOR.address,
    website: info?.company.website ?? OPERATOR.website,
    phone: info?.config.support.phone ?? OPERATOR.phone,
    email: info?.config.support.email || OPERATOR.email,
  };
  const blocks = parseMarkdown(fillOperator(doc.body, op));
  const toc = contents(blocks);
  return (
    <article className="legal card">
      <header className="legal-head">
        {info?.logo ? <AssetImg asset={info.logo} alt={op.company} className="legal-logo" /> : <span className="logo-full lg" role="img" aria-label="FarmTap" />}
        <div className="stack">
          <h1>{doc.title}</h1>
          <p className="muted small">
            Version {doc.version} · Effective {longDate(doc.effectiveDate)} · {op.company}
            {preview && <span className="chip warn">Preview, not published</span>}
          </p>
        </div>
      </header>
      {toc.length > 2 && (
        <nav className="legal-toc" aria-label="Contents">
          <strong className="small">Contents</strong>
          <ol>
            {toc.map((h) => (
              <li key={h.id}>
                <a href={`#${h.id}`}>{h.text.replace(/^\d+\.\s*/, '')}</a>
              </li>
            ))}
          </ol>
        </nav>
      )}
      <div className="legal-body">
        {blocks.map((b, i) => {
          if (b.type === 'p')
            return (
              <p key={i}>
                {b.lines.map((l, j) => (
                  <Fragment key={j}>
                    {j > 0 && <br />}
                    <Rich parts={l} />
                  </Fragment>
                ))}
              </p>
            );
          if (b.type === 'ul')
            return (
              <ul key={i}>
                {b.items.map((it, j) => (
                  <li key={j}>
                    <Rich parts={it} />
                  </li>
                ))}
              </ul>
            );
          if (b.type === 'h3') return <h3 key={i} id={b.id}>{b.text}</h3>;
          return <h2 key={i} id={b.id}>{b.text}</h2>;
        })}
      </div>
      <footer className="legal-sign">
        <div className="legal-sign-art">
          <AssetImg asset={stamp} alt="Company stamp" className="legal-stamp" />
          <AssetImg asset={signature} alt={`Signature of ${doc.signatory.name}`} className="legal-signature" />
        </div>
        <div className="legal-sign-line" />
        <strong>{doc.signatory.name}</strong>
        <span className="small muted">{doc.signatory.title}</span>
        <span className="small muted">
          For {op.company} · Signed {longDate(doc.effectiveDate)}
        </span>
      </footer>
    </article>
  );
}
