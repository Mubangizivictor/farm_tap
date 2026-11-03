'use client';

import { Timestamp, collection, doc, increment } from 'firebase/firestore';
import { useState, type FormEvent } from 'react';
import { adminChange, extendPaidUntil, paymentMethods, setOp, updateOp, type AdminFarm } from '@/lib/admin';
import { useAdmin } from '@/lib/adminSession';
import { firebase } from '@/lib/firebase';
import { date, ugx } from '@/lib/format';
import type { Plan, SmsPackage } from '@/lib/platform';
import { adminError, fromDateInput, toDateInput } from './admin';
import { Dialog } from './ui';

/**
 * Records money Victorbee received (MTN, Airtel, card, bank, cash) and, in
 * the same step, extends the farm's paid-until or adds its SMS credits.
 */
export function RecordPayment({
  farms,
  farm,
  plans,
  packages,
  onClose,
  onSaved,
}: {
  farms: AdminFarm[];
  farm?: AdminFarm;
  plans: Plan[];
  packages: SmsPackage[];
  onClose: () => void;
  onSaved: () => void;
}) {
  const { actor } = useAdmin();
  const [tenantId, setTenantId] = useState(farm?.id ?? '');
  const [kind, setKind] = useState<'subscription' | 'sms'>('subscription');
  const chosen = farms.find((f) => f.id === tenantId) ?? farm;
  const activePlans = plans.filter((p) => p.active);
  const [planId, setPlanId] = useState(chosen?.planId || activePlans[0]?.id || '');
  const plan = plans.find((p) => p.id === planId);
  const [periods, setPeriods] = useState(1);
  const [pkgId, setPkgId] = useState(packages.find((p) => p.active)?.id ?? '');
  const pkg = packages.find((p) => p.id === pkgId);
  const [amount, setAmount] = useState('');
  const [method, setMethod] = useState('mtn');
  const [reference, setReference] = useState('');
  const [paidOn, setPaidOn] = useState(toDateInput(new Date()));
  const [note, setNote] = useState('');
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');

  const months = (plan?.months ?? 1) * periods;
  const suggested = kind === 'sms' ? (pkg?.priceUgx ?? 0) : (plan?.priceUgx ?? 0) * periods;
  const amountUgx = amount.trim() ? Math.round(Number(amount.replace(/[^\d]/g, ''))) : suggested;
  const now = new Date();
  const newUntil = chosen ? extendPaidUntil(chosen.paidUntil, months, now) : null;

  async function save(e: FormEvent) {
    e.preventDefault();
    if (!chosen) return setErr('Choose the farm.');
    if (!amountUgx || amountUgx <= 0) return setErr('Enter the amount received.');
    if (kind === 'sms' && !pkg) return setErr('Choose the SMS package.');
    setBusy(true);
    setErr('');
    const { db } = firebase();
    const pay = doc(collection(db, 'platformPayments'));
    const tenant = doc(db, 'tenants', chosen.id);
    try {
      await adminChange(
        actor,
        {
          action: kind === 'sms' ? 'payment.sms' : 'payment.subscription',
          target: `platformPayments/${pay.id}`,
          tenantId: chosen.id,
          details: { amountUgx, method, reference, months: kind === 'sms' ? 0 : months, credits: pkg?.credits ?? 0 },
        },
        [
          setOp(
            pay,
            {
              tenantId: chosen.id,
              farmName: chosen.name,
              kind,
              amountUgx,
              method,
              reference: reference.trim(),
              planId: kind === 'sms' ? '' : planId,
              months: kind === 'sms' ? 0 : months,
              smsCredits: kind === 'sms' ? (pkg?.credits ?? 0) : 0,
              paidAt: Timestamp.fromDate(fromDateInput(paidOn) ?? now),
              newPaidUntil: kind === 'sms' || !newUntil ? null : Timestamp.fromDate(newUntil),
              status: 'received',
              recordedBy: actor.uid,
              recordedByName: actor.name,
              note: note.trim(),
              createdAt: Timestamp.now(),
            },
            false,
          ),
          kind === 'sms'
            ? updateOp(tenant, { smsCredits: increment(pkg?.credits ?? 0) })
            : updateOp(tenant, { 'subscription.paidUntil': Timestamp.fromDate(newUntil!), planId }),
        ],
      );
      onSaved();
      onClose();
    } catch (e) {
      setErr(adminError(e));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Dialog title="Record a payment" onClose={onClose}>
      <form className="stack" onSubmit={save}>
        {!farm && (
          <label className="field">
            <span>Farm</span>
            <select className="input" value={tenantId} onChange={(e) => setTenantId(e.target.value)} required>
              <option value="">Choose…</option>
              {farms.map((f) => (
                <option key={f.id} value={f.id}>
                  {f.name} {f.owner.name ? `(${f.owner.name})` : ''}
                </option>
              ))}
            </select>
          </label>
        )}
        <div className="seg" role="group" aria-label="What was paid">
          <button type="button" aria-pressed={kind === 'subscription'} onClick={() => setKind('subscription')}>
            Subscription
          </button>
          <button type="button" aria-pressed={kind === 'sms'} onClick={() => setKind('sms')}>
            SMS credits
          </button>
        </div>
        {kind === 'subscription' ? (
          <div className="grid">
            <label className="field">
              <span>Plan</span>
              <select className="input" value={planId} onChange={(e) => setPlanId(e.target.value)}>
                {activePlans.length === 0 && <option value="">Standard (UGX 70,000 / month)</option>}
                {activePlans.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}: {ugx(p.priceUgx)} / {p.months === 1 ? 'month' : `${p.months} months`}
                  </option>
                ))}
              </select>
            </label>
            <label className="field">
              <span>Periods paid</span>
              <input className="input" type="number" min={1} max={36} value={periods} onChange={(e) => setPeriods(Math.max(1, Number(e.target.value) || 1))} />
            </label>
          </div>
        ) : (
          <label className="field">
            <span>SMS package</span>
            <select className="input" value={pkgId} onChange={(e) => setPkgId(e.target.value)}>
              {packages
                .filter((p) => p.active)
                .map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}: {p.credits} SMS for {ugx(p.priceUgx)}
                  </option>
                ))}
            </select>
          </label>
        )}
        <div className="grid">
          <label className="field">
            <span>Amount received (UGX)</span>
            <input className="input" inputMode="numeric" placeholder={String(suggested || '')} value={amount} onChange={(e) => setAmount(e.target.value)} />
          </label>
          <label className="field">
            <span>Paid with</span>
            <select className="input" value={method} onChange={(e) => setMethod(e.target.value)}>
              {Object.entries(paymentMethods).map(([k, v]) => (
                <option key={k} value={k}>
                  {v}
                </option>
              ))}
            </select>
          </label>
          <label className="field">
            <span>Transaction ID</span>
            <input className="input" value={reference} onChange={(e) => setReference(e.target.value)} placeholder="e.g. MP241103.1234.A12345" />
          </label>
          <label className="field">
            <span>Paid on</span>
            <input className="input" type="date" value={paidOn} onChange={(e) => setPaidOn(e.target.value)} />
          </label>
        </div>
        <label className="field">
          <span>Note (optional)</span>
          <input className="input" value={note} onChange={(e) => setNote(e.target.value)} />
        </label>
        {chosen && (
          <div className="banner info">
            <span className="grow">
              {kind === 'sms'
                ? `${chosen.name} gets ${pkg?.credits ?? 0} SMS credits (now ${chosen.smsCredits}).`
                : `${chosen.name} will be paid until ${date(newUntil)}${chosen.paidUntil ? ` (was ${date(chosen.paidUntil)})` : ''}.`}
            </span>
          </div>
        )}
        {err && <div className="banner bad">{err}</div>}
        <div className="actions">
          <button type="button" className="btn outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn" disabled={busy}>
            {busy ? 'Saving…' : `Save ${ugx(amountUgx || 0)}`}
          </button>
        </div>
      </form>
    </Dialog>
  );
}
