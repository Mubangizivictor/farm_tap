'use client';

// Legal documents (decision 0024): edit the Privacy Policy and Terms of Use,
// preview them exactly as the public pages show them, and publish a new
// version. Every version is kept; the public pages show the latest.

import { useEffect, useState } from 'react';
import { Fit, MsgBanner, Need, useAction, useLoad } from '@/components/admin';
import { Icon } from '@/components/Icon';
import { LegalView } from '@/components/public';
import { Dialog, Field, LoadError, PageHead, SkelCard, Tabs } from '@/components/ui';
import { loadLegalAdmin, publishLegal, saveLegalDraft } from '@/lib/adminLaunch';
import { useAdmin } from '@/lib/adminSession';
import { date } from '@/lib/format';
import { DEFAULT_LEGAL, longDate, type LegalDoc, type LegalKind } from '@/shared/legal';

const KINDS = [
  ['privacy', 'Privacy Policy'],
  ['terms', 'Terms of Use'],
] as const;

const today = () => new Date().toISOString().slice(0, 10);

export default function Legal() {
  const [kind, setKind] = useState<LegalKind>('privacy');
  return (
    <Need perm="settings">
      <PageHead title="Legal documents" subtitle="Privacy Policy and Terms of Use on the website and in the apps">
        <a className="btn outline sm" href={kind === 'privacy' ? '/privacy/' : '/terms/'} target="_blank" rel="noreferrer">
          <Icon name="eye" /> Open public page
        </a>
      </PageHead>
      <Tabs label="Document" value={kind} onChange={setKind} items={KINDS} />
      <Editor key={kind} kind={kind} />
    </Need>
  );
}

function Editor({ kind }: { kind: LegalKind }) {
  const { actor } = useAdmin();
  const data = useLoad(() => loadLegalAdmin(kind), [kind]);
  const act = useAction();
  const [doc, setDoc] = useState<LegalDoc | null>(null);
  const [preview, setPreview] = useState(false);
  const [viewing, setViewing] = useState<LegalDoc | null>(null);
  const [confirm, setConfirm] = useState(false);

  useEffect(() => {
    if (data.data && !doc) setDoc(data.data.draft ?? { ...data.data.published, summary: '', effectiveDate: data.data.published.effectiveDate });
  }, [data.data, doc]);

  if (data.error) return <LoadError code={data.error} />;
  if (!data.data || !doc) return <SkelCard lines={8} />;
  const cur = data.data;
  const set = (patch: Partial<LegalDoc>) => setDoc({ ...doc, ...patch });
  const nextVersion = cur.isPublished ? cur.published.version + 1 : Math.max(1, (cur.versions[0]?.version ?? 0) + 1);

  const saveDraft = () => act.run(() => saveLegalDraft(actor, doc), 'Draft saved. Only the control panel sees it.');
  const publish = () =>
    act
      .run(() => publishLegal(actor, doc, cur), `Version ${nextVersion} is live on the website and in the apps.`)
      .then((ok) => {
        setConfirm(false);
        if (ok) {
          setDoc(null);
          data.reload();
        }
      });

  return (
    <>
      <MsgBanner msg={act.msg} />
      <div className="split-2-1">
        <section className="card stack">
          <div className="card-head">
            <h2>Edit</h2>
            <span className="chip">{cur.isPublished ? `Live: version ${cur.published.version}` : 'Live: built-in text'}</span>
          </div>
          <Fit kind="fields" cols={[1, 2, 2, 2]}>
            <Field label="Title">
              <input className="input" value={doc.title} onChange={(e) => set({ title: e.target.value })} />
            </Field>
            <Field label="Effective date" hint={longDate(doc.effectiveDate)}>
              <input className="input" type="date" value={doc.effectiveDate} onChange={(e) => set({ effectiveDate: e.target.value || today() })} />
            </Field>
            <Field label="Signed by">
              <input className="input" value={doc.signatory.name} onChange={(e) => set({ signatory: { ...doc.signatory, name: e.target.value } })} />
            </Field>
            <Field label="Title of signer">
              <input className="input" value={doc.signatory.title} onChange={(e) => set({ signatory: { ...doc.signatory, title: e.target.value } })} />
            </Field>
          </Fit>
          <Field
            label="Text"
            hint="## starts a section, ### a sub-section, - a bullet, **bold** for bold. {company}, {product}, {phone}, {email}, {website}, {address} fill in your details."
          >
            <textarea className="input editor" rows={24} value={doc.body} onChange={(e) => set({ body: e.target.value })} spellCheck />
          </Field>
          <Field label="What changed in this version" hint="Shown in the version history, for example: Added the 90-day hold after deleting an account.">
            <input className="input" value={doc.summary} onChange={(e) => set({ summary: e.target.value })} maxLength={200} />
          </Field>
          <div className="btn-row">
            <button className="btn outline" onClick={() => setPreview(true)}>
              <Icon name="eye" /> Preview
            </button>
            <button className="btn outline" onClick={() => void saveDraft()} disabled={act.busy}>
              Save draft
            </button>
            <button className="btn" onClick={() => setConfirm(true)} disabled={act.busy || !doc.body.trim() || !doc.title.trim()}>
              Publish version {nextVersion}
            </button>
            <button
              className="btn ghost"
              onClick={() => setDoc({ ...DEFAULT_LEGAL[kind], effectiveDate: today(), summary: 'Back to the FarmTap standard text' })}
              title="Load the standard text that ships with FarmTap"
            >
              Load standard text
            </button>
          </div>
        </section>

        <section className="card stack">
          <div className="card-head">
            <h2>Versions</h2>
          </div>
          {cur.versions.length === 0 ? (
            <p className="small muted">
              Nothing published yet. The website shows the standard FarmTap text (effective {longDate(DEFAULT_LEGAL[kind].effectiveDate)}) until you publish.
            </p>
          ) : (
            <div className="list">
              {cur.versions.map((v) => (
                <div key={v.version} className="list-row">
                  <span className="grow stack tight">
                    <strong>
                      Version {v.version}
                      {v.version === cur.published.version && cur.isPublished ? ' · live' : ''}
                    </strong>
                    <small className="muted">
                      Effective {longDate(v.effectiveDate)} · published {date(v.publishedAt)} by {v.publishedByName || 'admin'}
                    </small>
                    {v.summary && <small>{v.summary}</small>}
                  </span>
                  <span className="acts">
                    <button className="btn ghost sm" onClick={() => setViewing(v)}>
                      View
                    </button>
                    <button className="btn ghost sm" onClick={() => setDoc({ ...v, summary: '', effectiveDate: today() })} title="Start a new version from this one">
                      Copy
                    </button>
                  </span>
                </div>
              ))}
            </div>
          )}
          <p className="small muted">Old versions are never changed or removed, so you can always show what a farmer agreed to.</p>
        </section>
      </div>

      {preview && (
        <Dialog title="Preview" subtitle="Exactly as the public page will show it" onClose={() => setPreview(false)} size="lg">
          <div className="dialog-body">
            <LegalView doc={{ ...doc, version: nextVersion }} preview />
          </div>
        </Dialog>
      )}
      {viewing && (
        <Dialog title={`${viewing.title}, version ${viewing.version}`} onClose={() => setViewing(null)} size="lg">
          <div className="dialog-body">
            <LegalView doc={viewing} />
          </div>
        </Dialog>
      )}
      {confirm && (
        <Dialog title={`Publish version ${nextVersion}?`} onClose={() => setConfirm(false)}>
          <div className="dialog-body stack">
            <p>
              The {doc.title} on the website and in the apps changes to this text, effective {longDate(doc.effectiveDate)}. Version{' '}
              {cur.isPublished ? cur.published.version : 'built-in'} stays in the history.
            </p>
            {!doc.summary.trim() && <p className="banner warn small">Add a line on what changed, so the history makes sense later.</p>}
          </div>
          <div className="actions">
            <button className="btn outline" onClick={() => setConfirm(false)}>
              Cancel
            </button>
            <button className="btn" onClick={() => void publish()} disabled={act.busy}>
              {act.busy ? 'Publishing…' : 'Publish'}
            </button>
          </div>
        </Dialog>
      )}
    </>
  );
}
