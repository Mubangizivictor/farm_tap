'use client';

// Deleted accounts (decision 0024). A person who deletes their account is
// closed at once; their records are kept 90 days, then erased. Within the
// 90 days this page brings an account back. Requests sent from the public
// form (people who cannot sign in) are checked here first.

import { useMemo, useState } from 'react';
import { MsgBanner, Need, useAction, useLoad } from '@/components/admin';
import { Icon } from '@/components/Icon';
import { Dialog, Empty, Field, LoadError, PageHead, SearchBox, SkelRows, Tabs } from '@/components/ui';
import { HOLD_DAYS, loadDeletions, markDeletion, restoreAccount, type Deletion } from '@/lib/adminLaunch';
import { useAdmin } from '@/lib/adminSession';
import { date } from '@/lib/format';

type View = 'closed' | 'requests' | 'done';
const VIEWS = [
  ['closed', 'Closed, can restore'],
  ['requests', 'Requests to check'],
  ['done', 'History'],
] as const;

const statusText: Record<string, string> = {
  closed: 'Closed',
  requested: 'Waiting to be checked',
  verified: 'Checked',
  restored: 'Restored',
  rejected: 'Turned down',
  erased: 'Erased',
};

export default function Deletions() {
  const { actor, can } = useAdmin();
  const list = useLoad(loadDeletions);
  const act = useAction();
  const [view, setView] = useState<View>('closed');
  const [q, setQ] = useState('');
  const [restoring, setRestoring] = useState<Deletion | null>(null);
  const [checking, setChecking] = useState<Deletion | null>(null);
  const [note, setNote] = useState('');

  const rows = useMemo(() => {
    const t = q.trim().toLowerCase();
    return (list.data ?? [])
      .filter((d) => (view === 'closed' ? d.status === 'closed' : view === 'requests' ? d.status === 'requested' : !['closed', 'requested'].includes(d.status)))
      .filter((d) => !t || [d.name, d.email, d.phone, d.farmName, d.uid ?? ''].some((v) => v.toLowerCase().includes(t)));
  }, [list.data, view, q]);
  const count = (v: View) =>
    (list.data ?? []).filter((d) => (v === 'closed' ? d.status === 'closed' : v === 'requests' ? d.status === 'requested' : !['closed', 'requested'].includes(d.status))).length;

  const restore = () =>
    restoring &&
    act
      .run(() => restoreAccount(actor, restoring, note.trim()), 'Restored. The person can sign in again and their farms are open.')
      .then((ok) => {
        if (ok) {
          setRestoring(null);
          setNote('');
          list.reload();
        }
      });

  const mark = (status: 'verified' | 'rejected') =>
    checking &&
    act.run(() => markDeletion(actor, checking, status, note.trim()), status === 'verified' ? 'Marked as checked.' : 'Turned down.').then((ok) => {
      if (ok) {
        setChecking(null);
        setNote('');
        list.reload();
      }
    });

  return (
    <Need perm={['users', 'support']}>
      <PageHead title="Deleted accounts" subtitle={`Closed accounts are kept ${HOLD_DAYS} days, then erased for good`}>
        <SearchBox value={q} onChange={setQ} placeholder="Name, email, phone, farm" />
      </PageHead>
      <MsgBanner msg={act.msg} />
      <LoadError code={list.error} />

      <section className="card stack">
        <div className="card-head">
          <h2>How to bring an account back</h2>
        </div>
        <ol className="how-list small">
          <li>Check it is really the account owner: ask them to call or WhatsApp from the phone number on the account, or reply from its email.</li>
          <li>
            Find the account below under <strong>Closed, can restore</strong> (search by name, email or phone). It shows how many days are left.
          </li>
          <li>
            Press <strong>Restore</strong> and write a short note (who asked and how you checked). The account and every farm it owned open again with all
            their records, workers and cards.
          </li>
          <li>Tell the person to sign in again as before. Workers can use their cards and PINs again at once.</li>
          <li>
            After {HOLD_DAYS} days the records are erased for good and cannot be restored. If the daily server job is not switched on yet, erase by hand
            with <code>node functions/scripts/accounts.mjs erase &lt;uid&gt;</code> (see the Blaze guide).
          </li>
        </ol>
      </section>

      <Tabs label="Show" value={view} onChange={setView} items={VIEWS.map(([k, l]) => [k, l, count(k)] as const)} />

      <section className="card">
        {!list.data ? (
          <SkelRows rows={4} cols={4} />
        ) : rows.length === 0 ? (
          <Empty icon="check">{view === 'closed' ? 'No closed accounts.' : view === 'requests' ? 'No requests waiting.' : 'Nothing here yet.'}</Empty>
        ) : (
          <div className="list">
            {rows.map((d) => (
              <div key={d.id} className="list-row wrap">
                <span className="grow stack tight">
                  <strong>{d.name || d.email || d.phone || d.uid}</strong>
                  <small className="muted">
                    {[d.email, d.phone, d.farmName, d.farms.length ? `${d.farms.length} farm${d.farms.length > 1 ? 's' : ''}` : ''].filter(Boolean).join(' · ')}
                  </small>
                  <small className="muted">
                    {d.status === 'closed'
                      ? `Closed ${date(d.closedAt)} · restore by ${date(d.restoreBy)} (${d.daysLeft} day${d.daysLeft === 1 ? '' : 's'} left)`
                      : `${statusText[d.status] ?? d.status} · ${date(d.createdAt)}${d.handledByName ? ` · by ${d.handledByName}` : ''}`}
                  </small>
                  {d.reason && <small>Reason: {d.reason}</small>}
                  {d.note && <small className="muted">Note: {d.note}</small>}
                </span>
                <span className="acts">
                  {d.status === 'closed' && can('users') && (d.daysLeft ?? 0) > 0 && (
                    <button className="btn sm" onClick={() => setRestoring(d)}>
                      <Icon name="refresh" /> Restore
                    </button>
                  )}
                  {d.status === 'requested' && can('users') && (
                    <button className="btn outline sm" onClick={() => setChecking(d)}>
                      Check
                    </button>
                  )}
                </span>
              </div>
            ))}
          </div>
        )}
      </section>

      {restoring && (
        <Dialog title="Restore this account?" subtitle={restoring.name || restoring.email} onClose={() => setRestoring(null)}>
          <div className="dialog-body stack">
            <p>
              The account signs in again and {restoring.farms.length ? `its ${restoring.farms.length} farm${restoring.farms.length > 1 ? 's open' : ' opens'}` : 'opens'}{' '}
              with every record kept. This is logged in the audit log.
            </p>
            <Field label="Note" hint="Who asked and how you checked it was them.">
              <input className="input" value={note} onChange={(e) => setNote(e.target.value)} required />
            </Field>
          </div>
          <div className="actions">
            <button className="btn outline" onClick={() => setRestoring(null)}>
              Cancel
            </button>
            <button className="btn" onClick={() => void restore()} disabled={act.busy || !note.trim()}>
              {act.busy ? 'Restoring…' : 'Restore account'}
            </button>
          </div>
        </Dialog>
      )}

      {checking && (
        <Dialog title="Deletion request" subtitle={checking.name} onClose={() => setChecking(null)}>
          <div className="dialog-body stack">
            <p className="small">
              {[checking.phone, checking.email, checking.farmName].filter(Boolean).join(' · ')}
              {checking.reason ? ` · “${checking.reason}”` : ''}
            </p>
            <p className="small muted">
              Contact the person on the phone or email they gave. When it is really them, find their account under Users and turn it off, then mark
              this request as checked. Their records are erased after {HOLD_DAYS} days.
            </p>
            <Field label="Note">
              <input className="input" value={note} onChange={(e) => setNote(e.target.value)} />
            </Field>
          </div>
          <div className="actions">
            <button className="btn outline" onClick={() => void mark('rejected')} disabled={act.busy}>
              Turn down
            </button>
            <button className="btn" onClick={() => void mark('verified')} disabled={act.busy}>
              Mark as checked
            </button>
          </div>
        </Dialog>
      )}
    </Need>
  );
}
