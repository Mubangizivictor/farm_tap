'use client';

import { collection, doc } from 'firebase/firestore';
import { useState, type FormEvent } from 'react';
import { Anchor, Fit, MsgBanner, Need, Toggle, Tri, adminError, useAction, useLoad } from '@/components/admin';
import { Icon } from '@/components/Icon';
import { Dialog, Empty, PageHead } from '@/components/ui';
import { adminChange, loadConfig, loadPlans, loadSmsPackages, setOp } from '@/lib/admin';
import { useAdmin } from '@/lib/adminSession';
import { firebase } from '@/lib/firebase';
import { ugx } from '@/lib/format';
import { featureList, featureOn, monthlyValue, starterPlan, type FeatureKey, type Plan, type SmsPackage } from '@/lib/platform';

const period = (m: number) => (m === 1 ? 'month' : m === 12 ? 'year' : `${m} months`);
const toInt = (s: string) => Math.max(0, Math.round(Number(s.replace(/[^\d.]/g, '')) || 0));

function PlanEditor({ plan, onClose, onSaved }: { plan: Plan | null; onClose: () => void; onSaved: () => void }) {
  const { actor } = useAdmin();
  const cfg = useLoad(loadConfig);
  const [p, setP] = useState<Plan>(plan ?? { ...starterPlan, id: '', name: '', priceUgx: 0 });
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');
  const set = <K extends keyof Plan>(k: K, v: Plan[K]) => setP((x) => ({ ...x, [k]: v }));

  async function save(e: FormEvent) {
    e.preventDefault();
    if (!p.name.trim()) return setErr('Give the plan a name.');
    setBusy(true);
    setErr('');
    const { db } = firebase();
    const ref = plan?.id ? doc(db, 'plans', plan.id) : doc(collection(db, 'plans'));
    const { id: _id, ...data } = { ...p, name: p.name.trim(), description: p.description.trim() };
    try {
      await adminChange(actor, { action: plan?.id ? 'plan.edit' : 'plan.create', target: `plans/${ref.id}`, details: { name: data.name, priceUgx: data.priceUgx, months: data.months } }, [setOp(ref, data, false)]);
      onSaved();
      onClose();
    } catch (e) {
      setErr(adminError(e));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Dialog title={plan?.id ? `Edit ${plan.name}` : 'New plan'} onClose={onClose}>
      <form className="stack" onSubmit={save}>
        <label className="field">
          <span>Name farmers see</span>
          <input className="input" value={p.name} onChange={(e) => set('name', e.target.value)} placeholder="e.g. Standard, Centre, Yearly" required />
        </label>
        <Fit cols={[2, 2, 3, 3]}>
          <label className="field">
            <span>Price (UGX)</span>
            <input className="input" inputMode="numeric" value={p.priceUgx || ''} onChange={(e) => set('priceUgx', toInt(e.target.value))} />
          </label>
          <label className="field">
            <span>Every</span>
            <select className="input" value={p.months} onChange={(e) => set('months', Number(e.target.value))}>
              {[1, 3, 6, 12].map((m) => (
                <option key={m} value={m}>
                  {period(m)}
                </option>
              ))}
            </select>
          </label>
          <label className="field">
            <span>SMS included each month</span>
            <input className="input" inputMode="numeric" value={p.smsCreditsPerMonth || ''} onChange={(e) => set('smsCreditsPerMonth', toInt(e.target.value))} placeholder="0" />
          </label>
          <label className="field">
            <span>Most workers (0 = no limit)</span>
            <input className="input" inputMode="numeric" value={p.maxWorkers || ''} onChange={(e) => set('maxWorkers', toInt(e.target.value))} placeholder="0" />
          </label>
          <label className="field">
            <span>Farms per account</span>
            <input className="input" type="number" min={1} max={50} value={p.farmLimit} onChange={(e) => set('farmLimit', Math.max(1, toInt(e.target.value)))} />
          </label>
          <label className="field">
            <span>Order in the list</span>
            <input className="input" type="number" value={p.sort} onChange={(e) => set('sort', Number(e.target.value) || 0)} />
          </label>
        </Fit>
        <label className="field">
          <span>Short description</span>
          <input className="input" value={p.description} onChange={(e) => set('description', e.target.value)} placeholder="What the farmer gets" />
        </label>
        <Toggle label="Offered to farmers" hint="Hidden plans stay on the farms already using them" checked={p.active} onChange={(v) => set('active', v)} />
        <h3>Features on this plan</h3>
        <div className="list">
          {featureList.map((f) => (
            <div key={f.key} className="list-row wrap">
              <span className="grow">{f.label}</span>
              <Tri
                value={p.features[f.key]}
                inherited={featureOn(f.key, cfg.data?.config.features ?? {}, null, null)}
                onChange={(v) => {
                  const next = { ...p.features };
                  if (v === undefined) delete next[f.key as FeatureKey];
                  else next[f.key as FeatureKey] = v;
                  set('features', next);
                }}
              />
            </div>
          ))}
        </div>
        {err && <div className="banner bad">{err}</div>}
        <div className="actions">
          <button type="button" className="btn outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn" disabled={busy}>
            {busy ? 'Saving…' : 'Save plan'}
          </button>
        </div>
      </form>
    </Dialog>
  );
}

function PackageEditor({ pkg, onClose, onSaved }: { pkg: SmsPackage | null; onClose: () => void; onSaved: () => void }) {
  const { actor } = useAdmin();
  const [p, setP] = useState<SmsPackage>(pkg ?? { id: '', name: '', credits: 100, priceUgx: 5000, active: true });
  const act = useAction();
  return (
    <Dialog title={pkg ? `Edit ${pkg.name}` : 'New SMS package'} onClose={onClose}>
      <form
        className="stack"
        onSubmit={(e) => {
          e.preventDefault();
          const { db } = firebase();
          const ref = pkg ? doc(db, 'smsPackages', pkg.id) : doc(collection(db, 'smsPackages'));
          const { id: _id, ...data } = { ...p, name: p.name.trim() || `${p.credits} SMS` };
          void act.run(() => adminChange(actor, { action: pkg ? 'smsPackage.edit' : 'smsPackage.create', target: `smsPackages/${ref.id}`, details: data }, [setOp(ref, data, false)])).then((ok) => ok && (onSaved(), onClose()));
        }}
      >
        <label className="field">
          <span>Name</span>
          <input className="input" value={p.name} onChange={(e) => setP({ ...p, name: e.target.value })} placeholder="e.g. Starter 100" />
        </label>
        <Fit cols={[2, 2, 2, 2]}>
          <label className="field">
            <span>SMS credits</span>
            <input className="input" inputMode="numeric" value={p.credits || ''} onChange={(e) => setP({ ...p, credits: toInt(e.target.value) })} />
          </label>
          <label className="field">
            <span>Price (UGX)</span>
            <input className="input" inputMode="numeric" value={p.priceUgx || ''} onChange={(e) => setP({ ...p, priceUgx: toInt(e.target.value) })} />
          </label>
        </Fit>
        <p className="small muted">{p.credits ? `${ugx(p.priceUgx / p.credits)} per SMS to the farmer.` : ''}</p>
        <Toggle label="Offered to farmers" checked={p.active} onChange={(v) => setP({ ...p, active: v })} />
        <MsgBanner msg={act.msg?.ok ? null : act.msg} />
        <div className="actions">
          <button type="button" className="btn outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn" disabled={act.busy}>
            Save package
          </button>
        </div>
      </form>
    </Dialog>
  );
}

export default function Plans() {
  const plans = useLoad(loadPlans);
  const pkgs = useLoad(loadSmsPackages);
  const [edit, setEdit] = useState<Plan | null | 'new'>(null);
  const [editPkg, setEditPkg] = useState<SmsPackage | null | 'new'>(null);

  return (
    <Need perm="finance">
      <PageHead title="Plans and SMS packages" subtitle="Names and prices farmers see. Change them any time; no new app needed.">
        <button className="btn sm" onClick={() => setEdit('new')}>
          <Icon name="plus" /> New plan
        </button>
      </PageHead>

      {plans.data && plans.data.length === 0 && (
        <div className="banner info">
          <span className="grow">No plans yet. Farms use the standard UGX 70,000 a month until you add one.</span>
          <button className="btn sm" onClick={() => setEdit({ ...starterPlan, id: '' })}>
            Start with Standard
          </button>
        </div>
      )}

      <Anchor id="plans" title="Plans" hint="What a farm pays for FarmTap">
      <Fit>
        {(plans.data ?? []).map((p) => (
          <section key={p.id} className="card stack" style={p.active ? undefined : { opacity: 0.6 }}>
            <div className="card-head">
              <h2>{p.name}</h2>
              <span className={`chip ${p.active ? 'ok' : ''}`}>{p.active ? 'Offered' : 'Hidden'}</span>
            </div>
            <div className="stat">
              <div className="value money">{ugx(p.priceUgx)}</div>
              <div className="hint">
                per {period(p.months)}
                {p.months > 1 ? ` (${ugx(monthlyValue(p))} a month)` : ''}
              </div>
            </div>
            {p.description && <p className="small">{p.description}</p>}
            <div className="row wrap">
              {p.smsCreditsPerMonth > 0 && <span className="chip brand">{p.smsCreditsPerMonth} SMS a month</span>}
              {p.maxWorkers > 0 && <span className="chip">Up to {p.maxWorkers} workers</span>}
              {p.farmLimit > 1 && <span className="chip gold">{p.farmLimit} farms</span>}
              {Object.entries(p.features).map(([k, v]) => (
                <span key={k} className={`chip ${v ? 'ok' : 'bad'}`}>
                  {featureList.find((f) => f.key === k)?.label ?? k}: {v ? 'on' : 'off'}
                </span>
              ))}
            </div>
            <div className="row between" style={{ marginTop: 'auto' }}>
              <button className="btn sm outline" onClick={() => setEdit(p)}>
                Edit
              </button>
              <span className="small muted mono">{p.id}</span>
            </div>
          </section>
        ))}
      </Fit>
      </Anchor>

      <Anchor
        id="sms-packages"
        title="SMS packages"
        hint={
          <button className="btn sm outline" onClick={() => setEditPkg('new')}>
            <Icon name="plus" /> New package
          </button>
        }
      >
      <div className="table-wrap">
        <table className="table rt">
          <thead>
            <tr>
              <th>Package</th>
              <th className="r">SMS</th>
              <th className="r">Price</th>
              <th className="r">Per SMS</th>
              <th>Status</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {(pkgs.data ?? []).map((p) => (
              <tr key={p.id}>
                <td className="lead">
                  <strong>{p.name}</strong>
                </td>
                <td className="r" data-label="SMS">{p.credits}</td>
                <td className="r" data-label="Price">{ugx(p.priceUgx)}</td>
                <td className="r" data-label="Per SMS">{p.credits ? ugx(p.priceUgx / p.credits) : '—'}</td>
                <td data-label="Status">
                  <span className={`chip ${p.active ? 'ok' : ''}`}>{p.active ? 'Offered' : 'Hidden'}</span>
                </td>
                <td className="r acts">
                  <button className="btn sm ghost" onClick={() => setEditPkg(p)}>
                    Edit
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {pkgs.data && !pkgs.data.length && <Empty>No SMS packages yet. Add one so farms can buy automatic SMS.</Empty>}
      </div>
      </Anchor>

      {edit && <PlanEditor plan={edit === 'new' ? null : edit} onClose={() => setEdit(null)} onSaved={plans.reload} />}
      {editPkg && <PackageEditor pkg={editPkg === 'new' ? null : editPkg} onClose={() => setEditPkg(null)} onSaved={pkgs.reload} />}
    </Need>
  );
}
