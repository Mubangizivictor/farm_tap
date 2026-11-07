'use client';

import { Timestamp, collection, deleteField, doc, getDocs, query, serverTimestamp, where } from 'firebase/firestore';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Suspense, useEffect, useState } from 'react';
import { Confirm, Fit, MsgBanner, Need, Tri, fromDateInput, toDateInput, useAction, useLoad } from '@/components/admin';
import { RecordPayment } from '@/components/adminPayment';
import { Icon } from '@/components/Icon';
import { Loading } from '@/components/Loading';
import { Empty, PageHead, PrintButton, Stat } from '@/components/ui';
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
import { farmPlan, farmStatus, planOf, trialLength } from '@/lib/adminView';
import { addDays, parseDate, startOfDay } from '@/lib/dates';
import { firebase } from '@/lib/firebase';
import { date, shortDate, time, ugx, words } from '@/lib/format';
import { sectorName } from '@/lib/labels';
import { featureList, featureOn, type FeatureKey, type FeatureMap } from '@/lib/platform';

const tabs = ['Summary', 'Features', 'SMS', 'People', 'Records', 'Notes'] as const;
type Tab = (typeof tabs)[number];

const wa = (n: string) => `https://wa.me/${n.replace(/\D/g, '').replace(/^0/, '256')}`;

type Ask = null | 'suspend' | 'reject' | 'remove' | 'endTrial' | 'unpay' | 'details';

function Summary({ f, reload }: { f: AdminFarm; reload: () => void }) {
  const { actor, can } = useAdmin();
  const plans = useLoad(loadPlans);
  const packages = useLoad(loadSmsPackages);
  const cfg = useLoad(loadConfig);
  const owner = useLoad(async () => {
    if (!f.owner.uid) return null;
    const { getDoc } = await import('firebase/firestore');
    const s = await getDoc(doc(firebase().db, 'users', f.owner.uid)).catch(() => null);
    return s?.data() ?? null;
  }, [f.owner.uid]);
  const act = useAction();
  const [ask, setAsk] = useState<Ask>(null);
  const [reason, setReason] = useState('');
  const [pay, setPay] = useState(false);
  const now = new Date();
  const st = farmStatus(f, now);
  const plan = planOf(f, plans.data ?? []);
  const ref = doc(firebase().db, 'tenants', f.id);
  const p = farmPlan(f, now);
  const farms = can('farms');
  const money = farms || can('finance');

  // Free trial: the whole length from sign-up, not extra days on top.
  const defaultDays = cfg.data?.config.trialDays ?? 14;
  const trialStart = startOfDay(f.trialStartedAt ?? f.createdAt ?? now);
  const [days, setDays] = useState(() => trialLength(f, defaultDays));
  const newEnd = addDays(trialStart, days);
  const lengthChanged = !f.trialEndsAt || newEnd.getTime() !== f.trialEndsAt.getTime();

  const [paidUntil, setPaidUntil] = useState(toDateInput(f.paidUntil));
  const [credits, setCredits] = useState(String(f.smsCredits));
  const [limit, setLimit] = useState('');
  const farmLimit = Number(owner.data?.farmLimit ?? 1);
  const [d, setD] = useState({ name: f.name, district: f.district, village: f.village, type: f.type, cows: f.cows == null ? '' : String(f.cows), whatsapp: f.whatsapp, sms: f.sms });

  // After a save the farm reloads; show its new values in the boxes.
  const trialKey = `${f.trialStartedAt?.getTime()}-${f.trialEndsAt?.getTime()}-${defaultDays}`;
  useEffect(() => setDays(trialLength(f, defaultDays)), [trialKey]); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(() => setPaidUntil(toDateInput(f.paidUntil)), [f.paidUntil?.getTime()]); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(() => setCredits(String(f.smsCredits)), [f.smsCredits]);

  const change = (action: string, data: Record<string, unknown>, details: Record<string, unknown> = {}, ok = 'Saved.') =>
    act.run(() => adminChange(actor, { action, target: `tenants/${f.id}`, tenantId: f.id, details }, [updateOp(ref, data)]).then(reload), ok);
  const close = () => {
    setAsk(null);
    setReason('');
  };
  const aiNow = f.features.ai;

  return (
    <>
      <MsgBanner msg={act.msg} />
      <Fit kind="stats" cols={[2, 4, 4, 4]}>
        <Stat icon="shield" label="Status" value={<span className={`chip ${st.tone}`}>{st.text}</span>} hint={f.review ? `Review: ${f.review}` : 'Reviewed before the panel'} />
        <Stat icon="tag" label="Plan" value={plan.name} hint={`${ugx(plan.priceUgx)} / ${plan.months === 1 ? 'month' : `${plan.months} months`}`} tone="gold" />
        <Stat icon="calendar" label={f.paidUntil ? 'Paid until' : 'Trial ends'} value={date(f.paidUntil ?? f.trialEndsAt) || '—'} hint={p.kind === 'trial' ? `${p.daysLeft} days left` : p.kind === 'grace' ? `${p.daysLeft} days until it locks` : ''} tone="info" />
        <Stat icon="sms" label="SMS credits" value={String(f.smsCredits)} hint={f.autoSend ? 'Automatic SMS on' : 'Sends from the phone (free)'} />
      </Fit>

      <h2 className="section-title">Actions</h2>
      <Fit cols={[1, 2, 2, 4]}>
        {/* 1. Review and access */}
        <section className="card stack act-card">
          <div className="card-head">
            <h3>
              <Icon name="shield" /> Review and access
            </h3>
            <span className={`chip ${st.tone}`}>{st.text}</span>
          </div>
          <p className="small muted">Review: {f.review || 'none'}{f.reviewNote ? ` (${f.reviewNote})` : ''}</p>
          {farms ? (
            <div className="act-list">
              {f.review !== 'approved' && (
                <button className="btn sm" disabled={act.busy} onClick={() => void change('farm.approve', { review: { status: 'approved', at: Timestamp.now(), by: actor.name } }, {}, 'Farm approved.')}>
                  <Icon name="check" /> Approve
                </button>
              )}
              {f.review !== 'rejected' && (
                <button className="btn sm outline" disabled={act.busy} onClick={() => setAsk('reject')}>
                  <Icon name="thumbDown" /> Reject
                </button>
              )}
              {f.review && f.review !== 'pending' && (
                <button className="btn sm outline" disabled={act.busy} onClick={() => void change('farm.reviewAgain', { review: { status: 'pending' } }, {}, 'Back in the review list.')}>
                  <Icon name="clock" /> Review again
                </button>
              )}
              {f.status === 'suspended' ? (
                <button className="btn sm" disabled={act.busy} onClick={() => void change('farm.reactivate', { status: 'active', suspendedReason: deleteField() }, {}, 'Farm reactivated. It can record again.')}>
                  <Icon name="play" /> Reactivate
                </button>
              ) : (
                <button className="btn sm danger outline" disabled={act.busy} onClick={() => setAsk('suspend')}>
                  <Icon name="pause" /> Suspend
                </button>
              )}
              {f.closed ? (
                <button className="btn sm outline" disabled={act.busy} onClick={() => void change('farm.restore', { closure: deleteField() }, {}, 'Farm brought back. It shows in the lists and Google Sheets again.')}>
                  <Icon name="refresh" /> Bring back
                </button>
              ) : (
                <button className="btn sm danger outline" disabled={act.busy} onClick={() => setAsk('remove')}>
                  <Icon name="trash" /> Remove farm
                </button>
              )}
            </div>
          ) : (
            <p className="small muted">Needs the Farms permission.</p>
          )}
          {f.status === 'suspended' && f.suspendedReason && <p className="small muted">Suspended because: {f.suspendedReason}</p>}
        </section>

        {/* 2. Free trial */}
        <section className="card stack act-card">
          <div className="card-head">
            <h3>
              <Icon name="clock" /> Free trial
            </h3>
            <span className="small muted">New farms: {defaultDays} days</span>
          </div>
          {money ? (
            <>
              <label className="field">
                <span>Free trial length, in days from sign-up</span>
                <input className="input" type="number" min={0} max={365} value={days} onChange={(e) => setDays(Math.max(0, Math.min(365, Math.round(Number(e.target.value) || 0))))} />
              </label>
              <p className="small muted">
                Signed up {date(trialStart)}. With {days} {days === 1 ? 'day' : 'days'} the trial {newEnd <= now ? 'ended' : 'ends'} <strong>{date(newEnd)}</strong>
                {f.trialEndsAt && lengthChanged ? ` (now ${date(f.trialEndsAt)})` : ''}.
              </p>
              {lengthChanged && newEnd <= now && !f.paidUntil && <p className="small bad-text">This date is already past, so the farm locks as soon as you save, until it pays.</p>}
              <div className="act-list">
                <button
                  className="btn sm"
                  disabled={act.busy || !lengthChanged}
                  onClick={() =>
                    void change(
                      'farm.trialLength',
                      { 'subscription.trialStartedAt': Timestamp.fromDate(trialStart), 'subscription.trialEndsAt': Timestamp.fromDate(newEnd) },
                      { days, from: trialStart.toISOString(), until: newEnd.toISOString() },
                      `Free trial is now ${days} days: it ${newEnd <= now ? 'ended' : 'ends'} ${date(newEnd)}.`,
                    )
                  }
                >
                  <Icon name="check" /> Save trial
                </button>
                {p.kind === 'trial' && (
                  <button className="btn sm danger outline" disabled={act.busy} onClick={() => setAsk('endTrial')}>
                    <Icon name="stop" /> End trial now
                  </button>
                )}
              </div>
              {f.paidUntil && <p className="small muted">This farm has paid, so the trial no longer decides when it locks.</p>}
            </>
          ) : (
            <p className="small muted">Needs the Farms or Money permission.</p>
          )}
        </section>

        {/* 3. Plan and payment */}
        <section className="card stack act-card">
          <div className="card-head">
            <h3>
              <Icon name="money" /> Plan and payment
            </h3>
          </div>
          {money ? (
            <>
              <label className="field">
                <span>Plan</span>
                <select className="input" value={f.planId} disabled={act.busy} onChange={(e) => void change('farm.plan', { planId: e.target.value }, { planId: e.target.value }, 'Plan changed.')}>
                  <option value="">Default</option>
                  {(plans.data ?? []).map((pl) => (
                    <option key={pl.id} value={pl.id}>
                      {pl.name}
                      {pl.active ? '' : ' (hidden)'}
                    </option>
                  ))}
                </select>
              </label>
              <div className="inline-form">
                <label className="field">
                  <span>Paid until (set by hand)</span>
                  <input className="input" type="date" value={paidUntil} onChange={(e) => setPaidUntil(e.target.value)} />
                </label>
                <button
                  className="btn sm outline"
                  disabled={act.busy || !paidUntil || paidUntil === toDateInput(f.paidUntil)}
                  onClick={() => {
                    const until = fromDateInput(paidUntil)!;
                    void change('farm.paidUntil', { 'subscription.paidUntil': Timestamp.fromDate(until) }, { until: until.toISOString(), before: f.paidUntil?.toISOString() ?? null }, `Paid until ${date(until)}.`);
                  }}
                >
                  Set
                </button>
              </div>
              <div className="act-list">
                <button className="btn sm" onClick={() => setPay(true)} disabled={!can('finance')}>
                  <Icon name="receipt" /> Record payment
                </button>
                {f.paidUntil && (
                  <button className="btn sm danger outline" disabled={act.busy} onClick={() => setAsk('unpay')}>
                    <Icon name="close" /> Clear paid date
                  </button>
                )}
                <Link className="btn sm ghost" href="/admin/money/">
                  <Icon name="list" /> All payments
                </Link>
              </div>
            </>
          ) : (
            <p className="small muted">Needs the Farms or Money permission.</p>
          )}
        </section>

        {/* 4. SMS and features */}
        <section className="card stack act-card">
          <div className="card-head">
            <h3>
              <Icon name="sms" /> SMS and features
            </h3>
          </div>
          {money && (
            <div className="inline-form">
              <label className="field">
                <span>SMS credits (set the exact number)</span>
                <input className="input" type="number" min={0} value={credits} onChange={(e) => setCredits(e.target.value)} />
              </label>
              <button
                className="btn sm outline"
                disabled={act.busy || credits === '' || Number(credits) === f.smsCredits || Number(credits) < 0}
                onClick={() => {
                  const n = Math.max(0, Math.round(Number(credits)));
                  void change('farm.smsCredits', { smsCredits: n }, { change: n - f.smsCredits, before: f.smsCredits }, `SMS credits set to ${n}.`);
                }}
              >
                Set
              </button>
            </div>
          )}
          <label className="toggle">
            <span className="t-text">
              <strong>Automatic SMS</strong>
              <span className="small muted">Off: the farm sends from its own phone, free.</span>
            </span>
            <input
              type="checkbox"
              role="switch"
              checked={f.autoSend}
              disabled={!farms || act.busy}
              onChange={(e) => void change('farm.autoSend', { 'messaging.autoSend': e.target.checked }, { on: e.target.checked }, e.target.checked ? 'Automatic SMS on.' : 'Automatic SMS off.')}
            />
          </label>
          <label className="field">
            <span>AI Intelligence</span>
            <select
              className="input"
              value={aiNow === true ? 'on' : aiNow === false ? 'off' : ''}
              disabled={!farms || act.busy}
              onChange={(e) => {
                const v = e.target.value;
                void change('farm.features', { 'features.ai': v === '' ? deleteField() : v === 'on' }, { ai: v || 'default' }, 'AI setting saved. Phones pick it up the next time they are online.');
              }}
            >
              <option value="">Plan default</option>
              <option value="on">On for this farm</option>
              <option value="off">Off for this farm</option>
            </select>
          </label>
          <p className="small muted">Every other switch is on the Features tab; messages sent are on the SMS tab.</p>
        </section>
      </Fit>

      <Fit>
        <section className="card stack">
          <div className="card-head">
            <h2>Farm</h2>
            <div className="row">
              <span className="chip brand">{sectorName[f.sector] ?? f.sector}</span>
              {farms && (
                <button
                  className="btn sm outline"
                  onClick={() => {
                    setD({ name: f.name, district: f.district, village: f.village, type: f.type, cows: f.cows == null ? '' : String(f.cows), whatsapp: f.whatsapp, sms: f.sms });
                    setAsk('details');
                  }}
                >
                  <Icon name="edit" /> Edit details
                </button>
              )}
            </div>
          </div>
          <dl className="kv">
            <dt>Name</dt>
            <dd>{f.name}</dd>
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
            <dd className="mono">
              {f.id}{' '}
              <button className="btn xs ghost" title="Copy the farm ID" onClick={() => void navigator.clipboard?.writeText(f.id)}>
                <Icon name="copy" />
              </button>
            </dd>
          </dl>
          {f.closed && (
            <div className="banner bad small">
              <Icon name="trash" />
              <span className="grow">
                Removed{f.closedAt ? ` on ${date(f.closedAt)}` : ''}. It no longer shows in the farm lists, the Overview or Google Sheets, and nobody can record on it. Its records are
                kept for 90 days in case it was a mistake, then erased for good.
              </span>
            </div>
          )}
        </section>

        <section className="card stack">
          <div className="card-head">
            <h2>Owner</h2>
            {can('users') && (f.owner.email || f.owner.name) && (
              <Link className="btn sm ghost" href={`/admin/users/?q=${encodeURIComponent(f.owner.email || f.owner.name)}`}>
                <Icon name="eye" /> Account
              </Link>
            )}
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
            <dd>{farmLimit} farm(s)</dd>
          </dl>
          {farms && f.owner.uid && (
            <div className="inline-form">
              <label className="field">
                <span>Farms this account may own (1 is normal)</span>
                <input className="input" type="number" min={1} max={50} placeholder={String(farmLimit)} value={limit} onChange={(e) => setLimit(e.target.value)} />
              </label>
              <button
                className="btn sm outline"
                disabled={act.busy || !limit || !Number.isInteger(Number(limit)) || Number(limit) < 1 || Number(limit) > 50 || Number(limit) === farmLimit}
                onClick={() => {
                  const n = Number(limit);
                  void act
                    .run(() => adminChange(actor, { action: 'user.farmLimit', target: `users/${f.owner.uid}`, tenantId: f.id, details: { farmLimit: n } }, [updateOp(doc(firebase().db, 'users', f.owner.uid), { farmLimit: n })]), `This account may now own ${n} farm(s).`)
                    .then(() => {
                      setLimit('');
                      owner.reload();
                    });
                }}
              >
                Set
              </button>
            </div>
          )}
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
            {f.sms && (
              <a className="btn sm outline" href={`sms:${f.sms}`}>
                <Icon name="sms" /> SMS
              </a>
            )}
            {f.owner.email && (
              <a className="btn sm outline" href={`mailto:${f.owner.email}`}>
                <Icon name="mail" /> Email
              </a>
            )}
          </div>
        </section>
      </Fit>

      {ask === 'details' && (
        <Confirm
          title={`Edit ${f.name}`}
          confirm="Save details"
          busy={act.busy}
          onClose={close}
          onConfirm={() => {
            if (!d.name.trim()) return;
            const cows = d.type === 'centre' || d.cows === '' ? null : Math.max(0, Math.round(Number(d.cows) || 0));
            void change(
              'farm.details',
              { name: d.name.trim(), district: d.district.trim(), place: d.district.trim(), village: d.village.trim(), type: d.type, cows, 'contacts.whatsapp': d.whatsapp.trim(), 'contacts.sms': d.sms.trim() },
              { before: { name: f.name, district: f.district, village: f.village, type: f.type, cows: f.cows, whatsapp: f.whatsapp, sms: f.sms } },
              'Farm details saved. Phones show them the next time they open the farm.',
            ).then(close);
          }}
        >
          <div className="form-grid">
            <label className="field">
              <span>Farm name</span>
              <input className="input" value={d.name} onChange={(e) => setD({ ...d, name: e.target.value })} />
            </label>
            <label className="field">
              <span>Type</span>
              <select className="input" value={d.type} onChange={(e) => setD({ ...d, type: e.target.value })}>
                <option value="farm">Farm</option>
                <option value="centre">Milk collection centre</option>
                <option value="both">Farm and collection centre</option>
              </select>
            </label>
            <label className="field">
              <span>District</span>
              <input className="input" value={d.district} onChange={(e) => setD({ ...d, district: e.target.value })} />
            </label>
            <label className="field">
              <span>Village</span>
              <input className="input" value={d.village} onChange={(e) => setD({ ...d, village: e.target.value })} />
            </label>
            {d.type !== 'centre' && (
              <label className="field">
                <span>Herd size</span>
                <input className="input" type="number" min={0} value={d.cows} onChange={(e) => setD({ ...d, cows: e.target.value })} />
              </label>
            )}
            <label className="field">
              <span>WhatsApp</span>
              <input className="input" inputMode="tel" value={d.whatsapp} onChange={(e) => setD({ ...d, whatsapp: e.target.value })} />
            </label>
            <label className="field">
              <span>SMS number</span>
              <input className="input" inputMode="tel" value={d.sms} onChange={(e) => setD({ ...d, sms: e.target.value })} />
            </label>
          </div>
          <p className="small muted">The change is kept in the audit log with the old values.</p>
        </Confirm>
      )}

      {ask && ask !== 'details' && (
        <Confirm
          title={
            ask === 'suspend' ? `Suspend ${f.name}?` : ask === 'remove' ? `Remove ${f.name}?` : ask === 'endTrial' ? `End the free trial of ${f.name} now?` : ask === 'unpay' ? `Clear the paid date of ${f.name}?` : `Reject ${f.name}?`
          }
          confirm={ask === 'suspend' ? 'Suspend' : ask === 'remove' ? 'Remove farm' : ask === 'endTrial' ? 'End trial' : ask === 'unpay' ? 'Clear paid date' : 'Reject'}
          danger
          busy={act.busy}
          onClose={close}
          onConfirm={() =>
            void (ask === 'remove'
              ? change('farm.remove', { closure: { at: serverTimestamp(), by: actor.uid, requestId: 'admin', reason: reason.trim() } }, { reason }, 'Farm removed. It is gone from the lists and from Google Sheets.')
              : ask === 'suspend'
              ? change('farm.suspend', { status: 'suspended', suspendedReason: reason.trim() }, { reason }, 'Farm suspended. It can see its records but not save new ones.')
              : ask === 'endTrial'
              ? change('farm.endTrial', { 'subscription.trialEndsAt': Timestamp.now() }, { reason, before: f.trialEndsAt?.toISOString() ?? null }, 'Trial ended. The farm is locked until it pays.')
              : ask === 'unpay'
              ? change('farm.clearPaid', { 'subscription.paidUntil': deleteField() }, { reason, before: f.paidUntil?.toISOString() ?? null }, 'Paid date cleared.')
              : change('farm.reject', { review: { status: 'rejected', note: reason.trim(), at: Timestamp.now(), by: actor.name } }, { reason }, 'Farm marked rejected.')
            ).then(close)
          }
        >
          <p className="muted">
            {ask === 'remove'
              ? 'Use this for demo or fake farms, or a farm that asked to leave. It disappears at once from the farm lists, the Overview and Google Sheets, and its people can no longer record on it. You can bring it back for 90 days.'
              : ask === 'suspend'
              ? 'The farm keeps every record and can still look at them, but nothing new saves until you reactivate it.'
              : ask === 'endTrial'
              ? 'The farm keeps its records and can look at them, but nothing new saves until a payment is recorded. Set a longer trial length to undo.'
              : ask === 'unpay'
              ? 'Use this to undo a paid date entered by mistake. The farm falls back to its trial date, and locks if that has passed.'
              : 'Rejecting marks the review. Suspend as well if the farm should stop recording.'}
          </p>
          <label className="field">
            <span>Reason (kept in the audit log)</span>
            <input className="input" value={reason} onChange={(e) => setReason(e.target.value)} />
          </label>
        </Confirm>
      )}

      {pay && <RecordPayment farms={[f]} farm={f} plans={plans.data ?? []} packages={packages.data ?? []} onClose={() => setPay(false)} onSaved={reload} />}
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
        <PrintButton />
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
