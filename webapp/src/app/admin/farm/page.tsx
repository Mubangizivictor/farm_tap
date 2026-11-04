'use client';

import { Timestamp, collection, deleteField, doc, getDocs, query, where } from 'firebase/firestore';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Suspense, useState } from 'react';
import { Confirm, Fit, MsgBanner, Need, Tri, useAction, useLoad } from '@/components/admin';
import { RecordPayment } from '@/components/adminPayment';
import { Icon } from '@/components/Icon';
import { Loading } from '@/components/Loading';
import { Empty, PageHead, Stat } from '@/components/ui';
import {
  adminChange,
  farmCollection,
  farmMembers,
  hashPin,
  loadConfig,
  loadFarm,
  loadPlans,
  loadSmsPackages,
  randomPin,
  recordNextVersion,
  setOp,
  updateOp,
  type AdminFarm,
} from '@/lib/admin';
import { useAdmin } from '@/lib/adminSession';
import { farmPlan, farmStatus, planOf } from '@/lib/adminView';
import { addDays, parseDate } from '@/lib/dates';
import { firebase } from '@/lib/firebase';
import { date, shortDate, time, ugx, words } from '@/lib/format';
import { sectorName } from '@/lib/labels';
import { featureList, featureOn, type FeatureKey, type FeatureMap } from '@/lib/platform';

const tabs = ['Summary', 'Features', 'SMS', 'People', 'Records', 'Notes'] as const;
type Tab = (typeof tabs)[number];

const wa = (n: string) => `https://wa.me/${n.replace(/\D/g, '').replace(/^0/, '256')}`;

function Summary({ f, reload }: { f: AdminFarm; reload: () => void }) {
  const { actor, can } = useAdmin();
  const plans = useLoad(loadPlans);
  const packages = useLoad(loadSmsPackages);
  const owner = useLoad(async () => {
    if (!f.owner.uid) return null;
    const { getDoc } = await import('firebase/firestore');
    const s = await getDoc(doc(firebase().db, 'users', f.owner.uid)).catch(() => null);
    return s?.data() ?? null;
  }, [f.owner.uid]);
  const act = useAction();
  const [ask, setAsk] = useState<null | 'suspend' | 'reject'>(null);
  const [reason, setReason] = useState('');
  const [extend, setExtend] = useState(7);
  const [pay, setPay] = useState(false);
  const now = new Date();
  const st = farmStatus(f, now);
  const plan = planOf(f, plans.data ?? []);
  const ref = doc(firebase().db, 'tenants', f.id);
  const p = farmPlan(f, now);

  const change = (action: string, data: Record<string, unknown>, details: Record<string, unknown> = {}, ok = 'Saved.') =>
    act.run(() => adminChange(actor, { action, target: `tenants/${f.id}`, tenantId: f.id, details }, [updateOp(ref, data)]).then(reload), ok);

  return (
    <>
      <MsgBanner msg={act.msg} />
      <Fit kind="stats" cols={[2, 4, 4, 4]}>
        <Stat icon="shield" label="Status" value={<span className={`chip ${st.tone}`}>{st.text}</span>} hint={f.review ? `Review: ${f.review}` : 'Reviewed before the panel'} />
        <Stat icon="tag" label="Plan" value={plan.name} hint={`${ugx(plan.priceUgx)} / ${plan.months === 1 ? 'month' : `${plan.months} months`}`} tone="gold" />
        <Stat icon="calendar" label={f.paidUntil ? 'Paid until' : 'Trial ends'} value={date(f.paidUntil ?? f.trialEndsAt) || '—'} hint={p.kind === 'trial' ? `${p.daysLeft} days left` : p.kind === 'grace' ? `${p.daysLeft} days of grace left` : ''} tone="info" />
        <Stat icon="sms" label="SMS credits" value={String(f.smsCredits)} hint={f.autoSend ? 'Automatic SMS on' : 'Sends from the phone (free)'} />
      </Fit>

      <Fit>
        <section className="card stack">
          <div className="card-head">
            <h2>Farm</h2>
            <span className="chip brand">{sectorName[f.sector] ?? f.sector}</span>
          </div>
          <dl className="kv">
            <dt>Type</dt>
            <dd>{f.type === 'centre' ? 'Milk collection centre' : f.type === 'both' ? 'Farm and collection centre' : 'Farm'}</dd>
            <dt>Place</dt>
            <dd>{[f.village, f.district].filter(Boolean).join(', ') || '—'}</dd>
            {f.cows != null && (
              <>
                <dt>Herd size</dt>
                <dd>{f.cows}</dd>
              </>
            )}
            <dt>Created</dt>
            <dd>{date(f.createdAt) || '—'}</dd>
            <dt>Last seen</dt>
            <dd>{f.lastSeenAt ? `${date(f.lastSeenAt)} ${time(f.lastSeenAt)}` : '—'}</dd>
            <dt>Farm ID</dt>
            <dd className="mono">{f.id}</dd>
          </dl>
        </section>

        <section className="card stack">
          <div className="card-head">
            <h2>Owner</h2>
          </div>
          <dl className="kv">
            <dt>Name</dt>
            <dd>{f.owner.name || '—'}</dd>
            <dt>Email</dt>
            <dd>{f.owner.email ? <a href={`mailto:${f.owner.email}`}>{f.owner.email}</a> : '—'}</dd>
            <dt>WhatsApp</dt>
            <dd>{f.whatsapp ? <a href={wa(f.whatsapp)} target="_blank" rel="noreferrer">{f.whatsapp}</a> : '—'}</dd>
            <dt>SMS</dt>
            <dd>{f.sms ? <a href={`sms:${f.sms}`}>{f.sms}</a> : '—'}</dd>
            <dt>Farm limit</dt>
            <dd>{Number(owner.data?.farmLimit ?? 1)} farm(s)</dd>
          </dl>
          <div className="btn-row" style={{ marginTop: 'auto' }}>
            {f.whatsapp && (
              <a className="btn sm outline" href={wa(f.whatsapp)} target="_blank" rel="noreferrer">
                <Icon name="whatsapp" /> WhatsApp
              </a>
            )}
            {f.whatsapp && (
              <a className="btn sm outline" href={`tel:${f.whatsapp}`}>
                <Icon name="phone" /> Call
              </a>
            )}
            {can('farms') && f.owner.uid && (
              <button
                className="btn sm outline"
                disabled={act.busy}
                onClick={() => {
                  const n = Number(prompt('How many farms may this account own? (1 is normal; more is the multi-farm plan)', String(owner.data?.farmLimit ?? 1)));
                  if (!Number.isInteger(n) || n < 1 || n > 50) return;
                  void act
                    .run(() => adminChange(actor, { action: 'user.farmLimit', target: `users/${f.owner.uid}`, tenantId: f.id, details: { farmLimit: n } }, [updateOp(doc(firebase().db, 'users', f.owner.uid), { farmLimit: n })]))
                    .then(owner.reload);
                }}
              >
                Farm limit
              </button>
            )}
          </div>
        </section>

        <section className="card stack">
          <div className="card-head">
            <h2>Actions</h2>
          </div>
          <div className="btn-row">
          {can('farms') && f.review !== 'approved' && (
            <button className="btn" disabled={act.busy} onClick={() => void change('farm.approve', { review: { status: 'approved', at: Timestamp.now(), by: actor.name } }, {}, 'Farm approved.')}>
              <Icon name="check" /> Approve
            </button>
          )}
          {can('farms') && f.review !== 'rejected' && (
            <button className="btn outline" disabled={act.busy} onClick={() => setAsk('reject')}>
              Reject
            </button>
          )}
          {can('finance') && (
            <button className="btn outline" onClick={() => setPay(true)}>
              <Icon name="receipt" /> Record payment
            </button>
          )}
          {can('farms') &&
            (f.status === 'suspended' ? (
              <button className="btn" disabled={act.busy} onClick={() => void change('farm.reactivate', { status: 'active', suspendedReason: deleteField() }, {}, 'Farm reactivated. It can record again.')}>
                <Icon name="play" /> Reactivate
              </button>
            ) : (
              <button className="btn danger" disabled={act.busy} onClick={() => setAsk('suspend')}>
                <Icon name="pause" /> Suspend
              </button>
            ))}
        </div>

        {(can('farms') || can('finance')) && (
          <div className="inline-form divide">
            <label className="field">
              <span>Extend the trial by (days)</span>
              <input className="input" type="number" min={1} max={90} value={extend} onChange={(e) => setExtend(Number(e.target.value) || 1)} />
            </label>
            <button
              className="btn outline"
              disabled={act.busy}
              onClick={() => {
                const base = f.trialEndsAt && f.trialEndsAt > now ? f.trialEndsAt : now;
                const until = addDays(base, extend);
                void change('farm.extendTrial', { 'subscription.trialEndsAt': Timestamp.fromDate(until) }, { days: extend, until: until.toISOString() }, `Trial now ends ${date(until)}.`);
              }}
            >
              Extend trial
            </button>
          </div>
        )}
        {(can('farms') || can('finance')) && (
          <div className="inline-form">
              <label className="field">
                <span>Plan</span>
                <select className="input" value={f.planId} onChange={(e) => void change('farm.plan', { planId: e.target.value }, { planId: e.target.value }, 'Plan changed.')}>
                  <option value="">Default</option>
                  {(plans.data ?? []).map((pl) => (
                    <option key={pl.id} value={pl.id}>
                      {pl.name}
                      {pl.active ? '' : ' (hidden)'}
                    </option>
                  ))}
                </select>
              </label>
          </div>
        )}
        {f.status === 'suspended' && f.suspendedReason && <p className="small muted">Suspended because: {f.suspendedReason}</p>}
        </section>
      </Fit>

      {ask && (
        <Confirm
          title={ask === 'suspend' ? `Suspend ${f.name}?` : `Reject ${f.name}?`}
          confirm={ask === 'suspend' ? 'Suspend' : 'Reject'}
          danger
          busy={act.busy}
          onClose={() => setAsk(null)}
          onConfirm={() =>
            void (ask === 'suspend'
              ? change('farm.suspend', { status: 'suspended', suspendedReason: reason.trim() }, { reason }, 'Farm suspended. It can see its records but not save new ones.')
              : change('farm.reject', { review: { status: 'rejected', note: reason.trim(), at: Timestamp.now(), by: actor.name } }, { reason }, 'Farm marked rejected.')
            ).then(() => setAsk(null))
          }
        >
          <p className="muted">
            {ask === 'suspend'
              ? 'The farm keeps every record and can still look at them, but nothing new saves until you reactivate it.'
              : 'Rejecting marks the review. Suspend as well if the farm should stop recording.'}
          </p>
          <label className="field">
            <span>Reason (kept in the audit log)</span>
            <input className="input" value={reason} onChange={(e) => setReason(e.target.value)} />
          </label>
        </Confirm>
      )}

      {pay && (
        <RecordPayment farms={[f]} farm={f} plans={plans.data ?? []} packages={packages.data ?? []} onClose={() => setPay(false)} onSaved={reload} />
      )}
    </>
  );
}

function Features({ f, reload }: { f: AdminFarm; reload: () => void }) {
  const { actor, can } = useAdmin();
  const cfg = useLoad(loadConfig);
  const plans = useLoad(loadPlans);
  const act = useAction();
  const [draft, setDraft] = useState<FeatureMap>(f.features);
  const plan = planOf(f, plans.data ?? []);
  const defaults = cfg.data?.config.features ?? {};
  const changed = JSON.stringify(draft) !== JSON.stringify(f.features);

  return (
    <section className="card stack">
      <div className="card-head">
        <h2>Features for this farm</h2>
        <span className="small muted">Default comes from the {plan.name} plan, then the app settings</span>
      </div>
      <MsgBanner msg={act.msg} />
      <div className="split-c">
      <div className="list">
        {featureList.map((ft) => (
          <div key={ft.key} className="list-row wrap">
            <div className="stack grow" style={{ gap: 0 }}>
              <strong>{ft.label}</strong>
              <span className="small muted">{ft.hint}</span>
            </div>
            <Tri
              value={draft[ft.key]}
              inherited={featureOn(ft.key, defaults, plan.features, null)}
              disabled={!can('farms')}
              onChange={(v) => {
                const next = { ...draft };
                if (v === undefined) delete next[ft.key as FeatureKey];
                else next[ft.key as FeatureKey] = v;
                setDraft(next);
              }}
            />
          </div>
        ))}
      </div>
      </div>
      {can('farms') && (
        <div className="row">
          <button
            className="btn"
            disabled={!changed || act.busy}
            onClick={() =>
              void act.run(
                () => adminChange(actor, { action: 'farm.features', target: `tenants/${f.id}`, tenantId: f.id, details: { features: draft } }, [updateOp(doc(firebase().db, 'tenants', f.id), { features: draft })]).then(reload),
                'Saved. Phones pick it up the next time they are online.',
              )
            }
          >
            Save features
          </button>
          {changed && (
            <button className="btn ghost" onClick={() => setDraft(f.features)}>
              Undo changes
            </button>
          )}
        </div>
      )}
    </section>
  );
}

function Sms({ f, reload }: { f: AdminFarm; reload: () => void }) {
  const { actor, can } = useAdmin();
  const act = useAction();
  const [add, setAdd] = useState(100);
  const outbox = useLoad(() => farmCollection(f.id, 'smsOutbox', 30), [f.id]);
  const ref = doc(firebase().db, 'tenants', f.id);
  const sent = (outbox.data ?? []).filter((r) => r.body.status === 'sent').length;

  return (
    <>
      <MsgBanner msg={act.msg} />
      <Fit cols={[1, 1, 2, 2]}>
      <section className="card stack">
        <div className="card-head">
          <h2>SMS for this farm</h2>
          <span className="chip brand">{f.smsCredits} credits</span>
        </div>
        <label className="toggle">
          <span className="t-text">
            <strong>Automatic SMS</strong>
            <span className="small muted">The server sends this farm&apos;s messages and uses its credits. Off: the farm sends from its own phone for free.</span>
          </span>
          <input
            type="checkbox"
            role="switch"
            checked={f.autoSend}
            disabled={!can('farms') || act.busy}
            onChange={(e) =>
              void act.run(() => adminChange(actor, { action: 'farm.autoSend', target: `tenants/${f.id}`, tenantId: f.id, details: { on: e.target.checked } }, [updateOp(ref, { 'messaging.autoSend': e.target.checked })]).then(reload))
            }
          />
        </label>
        {(can('farms') || can('finance')) && (
          <div className="inline-form">
            <label className="field">
              <span>Add or remove credits (free top-up or correction)</span>
              <input className="input" type="number" value={add} onChange={(e) => setAdd(Math.round(Number(e.target.value) || 0))} />
            </label>
            <button
              className="btn outline"
              disabled={act.busy || !add}
              onClick={() =>
                void act.run(
                  () => adminChange(actor, { action: 'farm.smsCredits', target: `tenants/${f.id}`, tenantId: f.id, details: { change: add, before: f.smsCredits } }, [updateOp(ref, { smsCredits: Math.max(0, f.smsCredits + add) })]).then(reload),
                  'Credits updated.',
                )
              }
            >
              Apply
            </button>
          </div>
        )}
        <p className="small muted">Paid packages: use Record payment on the Summary tab and choose SMS credits.</p>
      </section>
      <section className="card">
        <div className="card-head">
          <h2>Latest messages</h2>
          <span className="small muted">{sent} sent by the server of the last {outbox.data?.length ?? 0}</span>
        </div>
        <div className="list">
          {(outbox.data ?? []).map((r) => (
            <div key={r.id} className="list-row">
              <span className={`chip ${r.body.status === 'sent' ? 'ok' : r.body.status === 'failed' ? 'bad' : ''}`}>{words(String(r.body.status ?? ''))}</span>
              <span className="grow small">{String(r.body.text ?? '').slice(0, 90)}</span>
              <span className="small muted">{String(r.body.to ?? '')}</span>
            </div>
          ))}
          {outbox.data && !outbox.data.length && <Empty>No messages yet.</Empty>}
        </div>
      </section>
      </Fit>
    </>
  );
}

function People({ f }: { f: AdminFarm }) {
  const { actor, can } = useAdmin();
  const members = useLoad(() => farmMembers(f.id), [f.id]);
  const staff = useLoad(() => farmCollection(f.id, 'staff', 200), [f.id]);
  const pins = useLoad(() => farmCollection(f.id, 'staffPins', 200), [f.id]);
  const cards = useLoad(() => farmCollection(f.id, 'nfcCards', 300), [f.id]);
  const act = useAction();
  const [shown, setShown] = useState<{ name: string; pin: string } | null>(null);

  async function resetPin(staffId: string, name: string) {
    const rec = (pins.data ?? []).find((p) => p.id === staffId);
    if (!rec) throw Object.assign(new Error('no pin'), { code: 'not-found' });
    const pin = randomPin();
    const hash = await hashPin(pin);
    await adminChange(actor, { action: 'staff.resetPin', target: `tenants/${f.id}/staffPins/${staffId}`, tenantId: f.id, details: { name } }, [
      recordNextVersion(f.id, 'staffPins', rec, { pinHash: hash, mustChange: true }, actor.uid),
    ]);
    setShown({ name, pin });
    pins.reload();
  }

  async function revoke(number: string) {
    const rec = (cards.data ?? []).find((c) => c.id === number);
    if (!rec) return;
    await adminChange(actor, { action: 'card.revoke', target: `tenants/${f.id}/nfcCards/${number}`, tenantId: f.id, details: { holder: rec.body.personName } }, [
      recordNextVersion(f.id, 'nfcCards', rec, { status: 'lost', endedAt: new Date().toISOString() }, actor.uid),
    ]);
    cards.reload();
  }

  return (
    <>
      <MsgBanner msg={act.msg} />
      {shown && (
        <div className="banner ok">
          <Icon name="key" />
          <span className="grow">
            New temporary card PIN for {shown.name}: <strong className="mono">{shown.pin}</strong>. Tell them by phone; they must choose their own PIN after unlocking. It reaches the farm&apos;s phones on their next sync.
          </span>
          <button className="btn sm outline" onClick={() => setShown(null)}>
            Done
          </button>
        </div>
      )}
      <section className="card">
        <div className="card-head">
          <h2>Accounts on this farm</h2>
          <span className="small muted">{members.data?.length ?? 0}</span>
        </div>
        <div className="list">
          {(members.data ?? []).map((m) => (
            <div key={m.uid} className="list-row">
              <span className="chip brand">{words(m.role ?? '')}</span>
              <span className="grow">{m.name || m.title || (m.uid === f.owner.uid ? f.owner.name : '') || m.uid}</span>
              {m.staffId && <span className="small muted">Phone sign-in</span>}
              <Link href={`/admin/users/?q=${m.uid}`} className="small">
                Account
              </Link>
            </div>
          ))}
        </div>
      </section>
      <section className="card">
        <div className="card-head">
          <h2>Staff and cards</h2>
          <span className="small muted">Read from the farm&apos;s records</span>
        </div>
        <div className="table-wrap">
          <table className="table rt">
            <thead>
              <tr>
                <th>Name</th>
                <th>Role</th>
                <th>Phone</th>
                <th>Card</th>
                <th>PIN</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {(staff.data ?? [])
                .filter((s) => !s.isDeleted)
                .map((s) => {
                  const card = (cards.data ?? []).find((c) => c.body.personId === s.id && c.body.status === 'active');
                  const pin = (pins.data ?? []).find((p) => p.id === s.id);
                  const name = String(s.body.name ?? '');
                  return (
                    <tr key={s.id}>
                      <td className="lead">
                        <strong>{name}</strong>
                      </td>
                      <td data-label="Role">{String(s.body.title || s.body.role || '')}</td>
                      <td data-label="Phone">{String(s.body.phone ?? '') || '—'}</td>
                      <td data-label="Card">{card ? <span className="mono">{card.id}</span> : <span className="muted">—</span>}</td>
                      <td data-label="PIN">{pin ? (pin.body.mustChange ? <span className="chip warn">Temporary</span> : <span className="chip ok">Own PIN</span>) : '—'}</td>
                      <td className="r acts">
                        {can('users') && (
                          <div className="row" style={{ justifyContent: 'flex-end' }}>
                            {pin && (
                              <button className="btn sm outline" disabled={act.busy} onClick={() => void act.run(() => resetPin(s.id, name), 'PIN reset.')}>
                                Reset PIN
                              </button>
                            )}
                            {card && (
                              <button
                                className="btn sm outline"
                                disabled={act.busy}
                                onClick={() => confirm(`Revoke card ${card.id} for ${name} as lost? It can never be used again.`) && void act.run(() => revoke(card.id), 'Card revoked.')}
                              >
                                Revoke card
                              </button>
                            )}
                          </div>
                        )}
                      </td>
                    </tr>
                  );
                })}
            </tbody>
          </table>
          {staff.data && !staff.data.length && <Empty>No staff recorded.</Empty>}
        </div>
        <p className="small muted">Reset PIN changes the card-unlock PIN. A worker who signs in on their own phone resets that sign-in from the farm owner&apos;s phone (Workers, Reset PIN).</p>
      </section>
    </>
  );
}

const lookCollections = [
  ['milkRecords', 'Milk records'],
  ['animals', 'Animals'],
  ['treatments', 'Treatments'],
  ['deliveries', 'Deliveries (centre)'],
  ['farmers', 'Suppliers (centre)'],
  ['expenses', 'Expenses'],
  ['income', 'Income'],
  ['milkSales', 'Milk sales'],
  ['attendance', 'Attendance'],
  ['payments', 'Payment claims'],
] as const;

function Records({ f }: { f: AdminFarm }) {
  const [c, setC] = useState<string>('milkRecords');
  const recs = useLoad(() => farmCollection(f.id, c, 50), [f.id, c]);
  return (
    <section className="card stack">
      <div className="card-head">
        <h2>Records (read only)</h2>
        <select className="input" style={{ width: 'auto', maxWidth: '100%' }} value={c} onChange={(e) => setC(e.target.value)} aria-label="Kind of record">
          {lookCollections.map(([k, v]) => (
            <option key={k} value={k}>
              {v}
            </option>
          ))}
        </select>
      </div>
      <p className="small muted">The latest 50, newest first. You can look; you cannot change a farm&apos;s records.</p>
      <div className="table-wrap">
        <table className="table rt">
          <thead>
            <tr>
              <th>When</th>
              <th>Details</th>
              <th>By</th>
            </tr>
          </thead>
          <tbody>
            {(recs.data ?? []).map((r) => (
              <tr key={r.id}>
                <td data-label="When">{shortDate(parseDate(r.createdAt))} {time(parseDate(r.createdAt))}</td>
                <td className="small wide" data-label="Details" style={{ whiteSpace: 'normal' }}>
                  {Object.entries(r.body)
                    .filter(([k, v]) => v != null && v !== '' && !/hash|photo|url/i.test(k))
                    .slice(0, 6)
                    .map(([k, v]) => `${words(k)}: ${typeof v === 'object' ? '…' : String(v)}`)
                    .join(' · ')}
                  {r.isDeleted && <span className="chip bad">Deleted</span>}
                </td>
                <td className="small muted" data-label="By">{r.createdBy}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {recs.data && !recs.data.length && <Empty>Nothing here.</Empty>}
        {recs.error && <Empty>Could not load ({recs.error}).</Empty>}
      </div>
    </section>
  );
}

function Notes({ f }: { f: AdminFarm }) {
  const { actor, can } = useAdmin();
  const act = useAction();
  const [text, setText] = useState('');
  const notes = useLoad(async () => {
    const s = await getDocs(query(collection(firebase().db, 'adminNotes'), where('tenantId', '==', f.id)));
    return s.docs.map((d) => ({ id: d.id, ...(d.data() as { text: string; byName: string; at?: unknown }) })).sort((a, b) => (parseDate(b.at)?.getTime() ?? 0) - (parseDate(a.at)?.getTime() ?? 0));
  }, [f.id]);
  const history = useLoad(async () => {
    if (!can('audit')) return [];
    const s = await getDocs(query(collection(firebase().db, 'adminAudit'), where('tenantId', '==', f.id)));
    return s.docs.map((d) => ({ id: d.id, ...(d.data() as { action: string; byName: string; at?: unknown }) })).sort((a, b) => (parseDate(b.at)?.getTime() ?? 0) - (parseDate(a.at)?.getTime() ?? 0));
  }, [f.id]);

  return (
    <Fit cols={[1, 1, 2, 2]}>
      <section className="card stack">
        <div className="card-head">
          <h2>Support notes</h2>
          <span className="small muted">Only the FarmTap team sees these</span>
        </div>
        <MsgBanner msg={act.msg} />
        <form
          className="stack"
          onSubmit={(e) => {
            e.preventDefault();
            if (!text.trim()) return;
            const ref = doc(collection(firebase().db, 'adminNotes'));
            void act
              .run(() => adminChange(actor, { action: 'farm.note', target: `adminNotes/${ref.id}`, tenantId: f.id }, [setOp(ref, { tenantId: f.id, text: text.trim(), by: actor.uid, byName: actor.name, at: Timestamp.now() }, false)]), 'Note saved.')
              .then((ok) => {
                if (ok) {
                  setText('');
                  notes.reload();
                }
              });
          }}
        >
          <textarea className="input" rows={3} value={text} onChange={(e) => setText(e.target.value)} placeholder="e.g. Called the owner, will pay on Friday" />
          <div className="row">
            <button className="btn sm" disabled={act.busy || !text.trim()}>
              Add note
            </button>
          </div>
        </form>
        <div className="list">
          {(notes.data ?? []).map((n) => (
            <div key={n.id} className="list-row" style={{ alignItems: 'flex-start' }}>
              <div className="stack grow" style={{ gap: 0 }}>
                <span>{n.text}</span>
                <span className="small muted">
                  {n.byName} · {date(parseDate(n.at))}
                </span>
              </div>
            </div>
          ))}
        </div>
      </section>
      {can('audit') && (
        <section className="card">
          <div className="card-head">
            <h2>Changes made here</h2>
          </div>
          <div className="list">
            {(history.data ?? []).map((h) => (
              <div key={h.id} className="list-row">
                <span className="grow">{words(h.action.replace('.', ' '))}</span>
                <span className="small muted">
                  {h.byName} · {shortDate(parseDate(h.at))}
                </span>
              </div>
            ))}
            {history.data && !history.data.length && <Empty>No changes yet.</Empty>}
          </div>
        </section>
      )}
    </Fit>
  );
}

function FarmView() {
  const id = useSearchParams().get('id') ?? '';
  const farm = useLoad(() => loadFarm(id), [id]);
  const [tab, setTab] = useState<Tab>('Summary');
  if (farm.data === undefined && !farm.error) return <Loading />;
  const f = farm.data;
  if (!f) return <Empty>Farm not found.</Empty>;
  return (
    <>
      <PageHead title={f.name} subtitle={`${f.owner.name || 'No owner name'}${f.district ? ` · ${f.district}` : ''}`}>
        <Link className="btn outline sm" href="/admin/farms/">
          All farms
        </Link>
      </PageHead>
      <div className="tabs sticky" role="tablist">
        {tabs.map((t) => (
          <button key={t} role="tab" aria-selected={tab === t} onClick={() => setTab(t)}>
            {t}
          </button>
        ))}
      </div>
      {tab === 'Summary' && <Summary f={f} reload={farm.reload} />}
      {tab === 'Features' && <Features key={JSON.stringify(f.features)} f={f} reload={farm.reload} />}
      {tab === 'SMS' && <Sms f={f} reload={farm.reload} />}
      {tab === 'People' && <People f={f} />}
      {tab === 'Records' && <Records f={f} />}
      {tab === 'Notes' && <Notes f={f} />}
    </>
  );
}

export default function AdminFarm() {
  return (
    <Need perm={['farms', 'support', 'finance', 'users']}>
      <Suspense fallback={<Loading />}>
        <FarmView />
      </Suspense>
    </Need>
  );
}
