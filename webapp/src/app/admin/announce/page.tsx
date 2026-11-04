'use client';

import { Timestamp, collection, doc, getDocs } from 'firebase/firestore';
import { useState, type FormEvent } from 'react';
import { Fit, MsgBanner, Need, fromDateInput, toDateInput, useAction, useLoad } from '@/components/admin';
import { Icon } from '@/components/Icon';
import { Empty, PageHead } from '@/components/ui';
import { adminChange, loadAllFarms, setOp, updateOp } from '@/lib/admin';
import { useAdmin } from '@/lib/adminSession';
import { firebase } from '@/lib/firebase';
import { date } from '@/lib/format';
import { sectorName } from '@/lib/labels';
import { announcementFromDoc, type Announcement } from '@/lib/platform';

async function loadAnnouncements(): Promise<Announcement[]> {
  const s = await getDocs(collection(firebase().db, 'announcements'));
  return s.docs.map((d) => announcementFromDoc(d.id, d.data())).sort((a, b) => (b.createdAt?.getTime() ?? 0) - (a.createdAt?.getTime() ?? 0));
}

export default function Announce() {
  const { actor, can } = useAdmin();
  const list = useLoad(loadAnnouncements);
  const farms = useLoad(() => (can('farms') || can('support') ? loadAllFarms() : Promise.resolve([])));
  const act = useAction();
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [level, setLevel] = useState<'info' | 'warn'>('info');
  const [kind, setKind] = useState<'all' | 'sector' | 'farm'>('all');
  const [sector, setSector] = useState('dairy');
  const [tenantId, setTenantId] = useState('');
  const [starts, setStarts] = useState(toDateInput(new Date()));
  const [ends, setEnds] = useState('');
  const now = new Date();

  function send(e: FormEvent) {
    e.preventDefault();
    const ref = doc(collection(firebase().db, 'announcements'));
    const end = fromDateInput(ends);
    void act
      .run(
        () =>
          adminChange(actor, { action: 'announcement.create', target: `announcements/${ref.id}`, tenantId: kind === 'farm' ? tenantId : null, details: { title, kind, sector } }, [
            setOp(
              ref,
              {
                title: title.trim(),
                body: body.trim(),
                level,
                audience: { kind, sector: kind === 'sector' ? sector : '', tenantId: kind === 'farm' ? tenantId : '' },
                startsAt: Timestamp.fromDate(fromDateInput(starts) ?? now),
                // End of the chosen day.
                endsAt: end ? Timestamp.fromDate(new Date(end.getFullYear(), end.getMonth(), end.getDate() + 1)) : null,
                active: true,
                createdAt: Timestamp.now(),
                createdByName: actor.name,
              },
              false,
            ),
          ]),
        'Sent. Web users see it now; phones see it next time they are online.',
      )
      .then((ok) => {
        if (ok) {
          setTitle('');
          setBody('');
          list.reload();
        }
      });
  }

  const stop = (a: Announcement) =>
    act.run(() => adminChange(actor, { action: 'announcement.stop', target: `announcements/${a.id}` }, [updateOp(doc(firebase().db, 'announcements', a.id), { active: false })]), 'Stopped.').then(list.reload);

  const audience = (a: Announcement) =>
    a.audience.kind === 'all' ? 'All farms' : a.audience.kind === 'sector' ? `${sectorName[a.audience.sector] ?? a.audience.sector} farms` : ((farms.data ?? []).find((f) => f.id === a.audience.tenantId)?.name ?? 'One farm');

  return (
    <Need perm="messages">
      <PageHead title="Announcements" subtitle="Notices shown at the top of the web app and the phone app" />
      <MsgBanner msg={act.msg} />
      <Fit cols={[1, 1, 2, 2]}>
        <section className="card">
          <form className="stack" onSubmit={send}>
            <div className="card-head">
              <h2>New announcement</h2>
            </div>
            <label className="field">
              <span>Title</span>
              <input className="input" value={title} onChange={(e) => setTitle(e.target.value)} maxLength={80} required placeholder="e.g. New: print ID cards" />
            </label>
            <label className="field">
              <span>Message</span>
              <textarea className="input" rows={3} value={body} onChange={(e) => setBody(e.target.value)} maxLength={400} placeholder="Short and simple. Many readers are on a small phone." />
            </label>
            <Fit cols={[1, 2, 2, 3]}>
              <label className="field">
                <span>Who sees it</span>
                <select className="input" value={kind} onChange={(e) => setKind(e.target.value as typeof kind)}>
                  <option value="all">All farms</option>
                  <option value="sector">One sector</option>
                  <option value="farm">One farm</option>
                </select>
              </label>
              {kind === 'sector' && (
                <label className="field">
                  <span>Sector</span>
                  <select className="input" value={sector} onChange={(e) => setSector(e.target.value)}>
                    {Object.entries(sectorName).map(([k, v]) => (
                      <option key={k} value={k}>
                        {v}
                      </option>
                    ))}
                  </select>
                </label>
              )}
              {kind === 'farm' && (
                <label className="field">
                  <span>Farm</span>
                  <select className="input" value={tenantId} onChange={(e) => setTenantId(e.target.value)} required>
                    <option value="">Choose…</option>
                    {(farms.data ?? []).map((f) => (
                      <option key={f.id} value={f.id}>
                        {f.name}
                      </option>
                    ))}
                  </select>
                </label>
              )}
              <label className="field">
                <span>Kind</span>
                <select className="input" value={level} onChange={(e) => setLevel(e.target.value as 'info' | 'warn')}>
                  <option value="info">News (blue)</option>
                  <option value="warn">Warning (orange)</option>
                </select>
              </label>
              <label className="field">
                <span>Show from</span>
                <input className="input" type="date" value={starts} onChange={(e) => setStarts(e.target.value)} />
              </label>
              <label className="field">
                <span>Until (optional)</span>
                <input className="input" type="date" value={ends} onChange={(e) => setEnds(e.target.value)} />
              </label>
            </Fit>
            {title && (
              <div className={`banner ${level}`}>
                <Icon name={level === 'warn' ? 'alert' : 'megaphone'} />
                <span className="grow">
                  <strong>{title}</strong> {body}
                </span>
              </div>
            )}
            <div className="row">
              <button className="btn" disabled={act.busy}>
                <Icon name="megaphone" /> Send
              </button>
            </div>
          </form>
        </section>

        <section className="card">
          <div className="card-head">
            <h2>Sent</h2>
          </div>
          <div className="list">
            {(list.data ?? []).map((a) => {
              const live = a.active && (!a.endsAt || a.endsAt > now) && (!a.startsAt || a.startsAt <= now);
              return (
                <div key={a.id} className="list-row wrap" style={{ alignItems: 'flex-start' }}>
                  <div className="stack grow-field" style={{ gap: 'var(--s-xxs)', minWidth: 0 }}>
                    <strong>{a.title}</strong>
                    {a.body && <span className="small">{a.body}</span>}
                    <span className="small muted">
                      {audience(a)} · {date(a.startsAt)}
                      {a.endsAt ? ` to ${date(a.endsAt)}` : ''}
                    </span>
                  </div>
                  <span className={`chip ${live ? 'ok' : ''}`}>{live ? 'Showing' : a.active ? 'Scheduled or ended' : 'Stopped'}</span>
                  {a.active && (
                    <button className="btn sm ghost" disabled={act.busy} onClick={() => void stop(a)}>
                      Stop
                    </button>
                  )}
                </div>
              );
            })}
            {list.data && !list.data.length && <Empty>No announcements yet.</Empty>}
          </div>
        </section>
      </Fit>
    </Need>
  );
}
