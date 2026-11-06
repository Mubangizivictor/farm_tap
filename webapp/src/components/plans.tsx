'use client';

// Plans and paying (decision 0023): the plan cards a farm sees in Settings,
// and the pay dialog. Plans, prices and which ways to pay come from the
// control panel, so Victor changes them without a new app.

import { collection, doc, getDocs, onSnapshot } from 'firebase/firestore';
import { useEffect, useMemo, useState } from 'react';
import { Icon } from '@/components/Icon';
import { Dialog, Empty, Field, SkelCard, useSave, useToast } from '@/components/ui';
import { addRecord } from '@/lib/data';
import { manages, planState, type Farm } from '@/lib/domain';
import { firebase } from '@/lib/firebase';
import { date, ugx } from '@/lib/format';
import { planText } from '@/lib/labels';
import { checkPayment, msisdn, networkOf, payError, startPayment, type PayStatus, type SubscriptionPayment } from '@/lib/payments';
import { farmGateways, monthlyValue, offeredPlans, planFromDoc, planPrice, starterPlan, type Gateway, type Plan } from '@/lib/platform';
import { useSession } from '@/lib/session';
import { supportWhatsAppLink } from '@/lib/support';
import { usePlatform } from '@/lib/usePlatform';

const period = (m: number) => (m === 1 ? 'month' : m === 12 ? 'year' : `${m} months`);

export function usePlans(): { plans: Plan[]; loading: boolean } {
  const [state, setState] = useState<{ plans: Plan[]; loading: boolean }>({ plans: [], loading: true });
  useEffect(() => {
    let live = true;
    getDocs(collection(firebase().db, 'plans'))
      .then((s) => live && setState({ plans: s.docs.map((d) => planFromDoc(d.id, d.data())), loading: false }))
      .catch(() => live && setState({ plans: [], loading: false }));
    return () => {
      live = false;
    };
  }, []);
  return state;
}

function PlanCard({ plan, current, onPick, canPay }: { plan: Plan; current: boolean; onPick: () => void; canPay: boolean }) {
  return (
    <article className={`plan-card ${plan.badge ? 'featured' : ''} ${current ? 'current' : ''}`}>
      {plan.badge && <span className="plan-badge">{plan.badge}</span>}
      <h3>{plan.name}</h3>
      {plan.description && <p className="small muted">{plan.description}</p>}
      <div className="plan-price">
        <span className="amount">{ugx(plan.priceUgx)}</span>
        <span className="per">/ {period(plan.months)}</span>
      </div>
      {plan.months > 1 && <p className="small muted">That is {ugx(monthlyValue(plan))} a month.</p>}
      <ul className="plan-points">
        {(plan.highlights.length ? plan.highlights : ['Every dairy feature', 'Phone and web', 'WhatsApp support']).map((h) => (
          <li key={h}>
            <Icon name="check" /> {h}
          </li>
        ))}
        {plan.maxWorkers > 0 && (
          <li>
            <Icon name="workers" /> Up to {plan.maxWorkers} workers
          </li>
        )}
        {plan.smsCreditsPerMonth > 0 && (
          <li>
            <Icon name="sms" /> {plan.smsCreditsPerMonth} SMS a month
          </li>
        )}
      </ul>
      <button className={`btn block ${plan.badge ? '' : 'outline'}`} onClick={onPick} disabled={!canPay}>
        {current ? 'Pay again to extend' : `Choose ${plan.name}`}
      </button>
    </article>
  );
}

/** The plans screen (Settings > Plan and payment; the trial chip opens it). */
export function PlansSection({ farm }: { farm: Farm }) {
  const { config } = usePlatform();
  const { plans: all, loading } = usePlans();
  const { online } = useSession();
  const [picked, setPicked] = useState<Plan | null>(null);
  const now = new Date();
  const state = planState(farm.subscription, now);
  const pt = planText(state);
  const plans = useMemo(() => {
    const offered = offeredPlans(all);
    return offered.length ? offered : [starterPlan];
  }, [all]);
  const boss = manages(farm);
  const payments = usePayments(boss ? farm.id : null);
  const gateways = farmGateways(config);

  // Back from the card payment page: ?paid=<id> asks the server to check it.
  const toast = useToast();
  const { reloadFarms } = useSession();
  useEffect(() => {
    const url = new URL(window.location.href);
    const id = url.searchParams.get('paid');
    if (!id) return;
    url.searchParams.delete('paid');
    history.replaceState(null, '', url.pathname + url.search + url.hash);
    void checkPayment({ tenantId: farm.id, paymentId: id })
      .then((r) => {
        if (r.status === 'paid') {
          toast('Payment received. Thank you!');
          void reloadFarms();
        } else toast(r.status === 'pending' ? 'Payment is still being confirmed.' : 'The card payment did not go through.');
      })
      .catch(() => undefined);
  }, [farm.id, toast, reloadFarms]);

  return (
    <div className="stack">
      <section className={`card plan-status ${state.kind === 'readOnly' ? 'bad' : ''}`}>
        <div className="row wrap between">
          <div className="stack" style={{ gap: 'var(--s-xxs)' }}>
            <span className="small muted">Your plan</span>
            <strong className="plan-status-text">{pt.text}</strong>
            <span className="small muted">
              {state.kind === 'trial' && `Free trial of ${config.trialDays} days, ends ${date(state.endsAt)}. After that nothing can be recorded until you pay.`}
              {state.kind === 'paid' && `Recording is on until ${date(state.until)}. Paying again adds time after that date.`}
              {state.kind === 'readOnly' && 'Recording, cards and changes are off. Your records are safe. Choose a plan below to start again.'}
            </span>
          </div>
          <span className={`chip ${pt.tone}`}>{state.kind === 'readOnly' ? 'Locked' : state.kind === 'trial' ? 'Trial' : 'Active'}</span>
        </div>
      </section>

      {!boss && <div className="banner info">Only the farm owner or a manager can pay for FarmTap.</div>}

      <div className="plan-grid">
        {loading
          ? [0, 1, 2].map((i) => <SkelCard key={i} lines={5} />)
          : plans.map((p) => <PlanCard key={p.id} plan={p} current={farm.planId === p.id && state.kind === 'paid'} canPay={boss && online} onPick={() => setPicked(p)} />)}
      </div>

      <section className="card stack">
        <h2>Ways to pay</h2>
        <div className="pay-methods">
          {gateways.map((g) => (
            <div key={g.id} className={`pay-method ${g.enabled ? '' : 'soon'}`}>
              <span className={`pay-logo ${g.id}`} aria-hidden>
                {g.id === 'mtn' ? 'MTN' : g.id === 'airtel' ? 'Airtel' : g.id === 'card' ? 'Card' : g.name.slice(0, 4)}
              </span>
              <span className="grow">{g.name}</span>
              {g.enabled ? <span className="chip ok">Available</span> : <span className="chip">Coming soon</span>}
            </div>
          ))}
        </div>
        <p className="small muted">
          Mobile Money asks you to approve with your PIN on your phone. Card payments open a secure page. Problems?{' '}
          <a href={supportWhatsAppLink(`Hello FarmTap, I need help paying for ${farm.name}.`)} target="_blank" rel="noreferrer">
            WhatsApp support
          </a>
          .
        </p>
      </section>

      {boss && (
        <section className="card">
          <h2>Payments</h2>
          {payments.loading ? (
            <SkelCard lines={2} />
          ) : payments.list.length === 0 ? (
            <Empty icon="receipt">No payments yet.</Empty>
          ) : (
            <div className="list">
              {payments.list.map((p) => (
                <div key={p.id} className="list-row wrap">
                  <div className="grow stack" style={{ gap: 0 }}>
                    <strong>
                      {p.planName} · {ugx(p.amountUgx)}
                    </strong>
                    <span className="small muted">
                      {date(p.createdAt?.toDate() ?? null)} · {methodName(p.method)}
                      {p.reason ? ` · ${p.reason}` : ''}
                    </span>
                  </div>
                  <span className={`chip ${statusTone(p.status)}`}>{statusText(p.status)}</span>
                </div>
              ))}
            </div>
          )}
        </section>
      )}

      {picked && <PayDialog farm={farm} plan={picked} gateways={gateways} onClose={() => setPicked(null)} />}
    </div>
  );
}

const methodName = (m: string) => (m === 'mtn' ? 'MTN MoMo' : m === 'airtel' ? 'Airtel Money' : m === 'card' ? 'Card' : m);
const statusText = (s: PayStatus) => ({ pending: 'Waiting', paid: 'Paid', failed: 'Failed', cancelled: 'Cancelled', expired: 'Timed out' })[s] ?? s;
const statusTone = (s: PayStatus) => (s === 'paid' ? 'ok' : s === 'pending' ? 'warn' : 'bad');

function usePayments(tenantId: string | null) {
  const [state, setState] = useState<{ list: SubscriptionPayment[]; loading: boolean }>({ list: [], loading: true });
  useEffect(() => {
    if (!tenantId) return;
    return onSnapshot(
      collection(firebase().db, 'tenants', tenantId, 'subscriptionPayments'),
      (s) =>
        setState({
          list: s.docs
            .map((d) => ({ ...(d.data() as SubscriptionPayment), id: d.id }))
            .sort((a, b) => (b.createdAt?.toDate().getTime() ?? 0) - (a.createdAt?.toDate().getTime() ?? 0))
            .slice(0, 12),
          loading: false,
        }),
      () => setState({ list: [], loading: false }),
    );
  }, [tenantId]);
  return state;
}

function PayDialog({ farm, plan, gateways, onClose }: { farm: Farm; plan: Plan; gateways: Gateway[]; onClose: () => void }) {
  const { user, reloadFarms, online } = useSession();
  const toast = useToast();
  const live = gateways.filter((g) => g.enabled);
  const [method, setMethod] = useState(live[0]?.id ?? '');
  const [periods, setPeriods] = useState(1);
  const [phone, setPhone] = useState(farm.whatsapp || '');
  const [reference, setReference] = useState('');
  const [payment, setPayment] = useState<{ id: string; status: PayStatus; message?: string | null } | null>(null);
  const { busy, error, setError, run } = useSave();
  const gw = gateways.find((g) => g.id === method);
  const amount = planPrice(plan, periods);
  const mobile = method === 'mtn' || method === 'airtel';

  // Watch the payment the server keeps up to date, and ask it to check now and then.
  useEffect(() => {
    if (!payment || payment.status !== 'pending') return;
    const ref = doc(firebase().db, 'tenants', farm.id, 'subscriptionPayments', payment.id);
    const unsub = onSnapshot(ref, (s) => {
      const st = (s.data()?.status as PayStatus | undefined) ?? 'pending';
      if (st !== 'pending') setPayment((p) => (p ? { ...p, status: st, message: (s.data()?.reason as string) ?? null } : p));
    });
    let tries = 0;
    const timer = setInterval(() => {
      tries += 1;
      if (tries > 36) return clearInterval(timer);
      void checkPayment({ tenantId: farm.id, paymentId: payment.id }).catch(() => undefined);
    }, 5000);
    return () => {
      unsub();
      clearInterval(timer);
    };
  }, [payment, farm.id]);

  useEffect(() => {
    if (payment?.status === 'paid') {
      toast('Payment received. Recording is on.');
      void reloadFarms();
    }
  }, [payment?.status, toast, reloadFarms]);

  async function pay() {
    if (!gw) return setError('Choose how to pay.');
    if (!gw.api) {
      // Paid by hand: send the claim; support confirms it in the panel.
      if (!reference.trim()) return setError('Type the transaction ID from the payment message.');
      if (!user) return;
      const ok = await run(() =>
        addRecord(firebase().db, farm.id, 'payments', user.uid, {
          status: 'submitted',
          amount,
          method: gw.id,
          reference: reference.trim(),
          planId: plan.id,
          periods,
        }),
      );
      if (ok) {
        toast('Sent. FarmTap confirms it within working hours.');
        onClose();
      }
      return;
    }
    if (mobile) {
      const m = msisdn(phone);
      if (!m) return setError('Type the Mobile Money number, e.g. 0772 123 456.');
      const net = networkOf(phone);
      if (net && net !== method) return setError(`That looks like an ${net === 'mtn' ? 'MTN' : 'Airtel'} number. Choose ${net === 'mtn' ? 'MTN MoMo' : 'Airtel Money'} or use another number.`);
    }
    setError('');
    await run(async () => {
      try {
        const r = await startPayment({
          tenantId: farm.id,
          planId: plan.id,
          periods,
          method,
          phone: mobile ? (msisdn(phone) ?? undefined) : undefined,
          returnUrl: `${window.location.origin}/settings/?paid={id}#plan`,
        });
        if (r.redirectUrl) {
          window.location.assign(r.redirectUrl);
          return;
        }
        setPayment({ id: r.paymentId, status: r.status, message: r.message });
      } catch (e) {
        throw new Error(payError(e));
      }
    });
  }

  if (payment) {
    return (
      <Dialog title={payment.status === 'paid' ? 'Paid. Thank you!' : 'Approve on your phone'} onClose={onClose}>
        <div className="stack pay-wait">
          {payment.status === 'pending' && (
            <>
              <div className="pay-phone" aria-hidden>
                <Icon name="phone" />
              </div>
              <p>
                A request for <strong>{ugx(amount)}</strong> was sent to <strong>{phone}</strong>. Enter your {method === 'mtn' ? 'MTN MoMo' : 'Airtel Money'} PIN on that phone to
                approve.
              </p>
              <p className="small muted">This page updates by itself. No prompt? Dial {method === 'mtn' ? '*165#, then My approvals' : '*185#, then My approvals'}.</p>
              <span className="spinner" aria-label="Waiting" />
            </>
          )}
          {payment.status === 'paid' && (
            <p>
              {plan.name} is paid. Recording is on for {farm.name}.
            </p>
          )}
          {['failed', 'cancelled', 'expired'].includes(payment.status) && (
            <div className="banner bad">
              <Icon name="alert" />
              <span className="grow">{payment.message || 'The payment did not go through. Nothing was taken. Try again.'}</span>
            </div>
          )}
          <div className="actions">
            {payment.status !== 'pending' && payment.status !== 'paid' && (
              <button className="btn outline" onClick={() => setPayment(null)}>
                Try again
              </button>
            )}
            <button className="btn" onClick={onClose}>
              {payment.status === 'paid' ? 'Done' : 'Close'}
            </button>
          </div>
        </div>
      </Dialog>
    );
  }

  return (
    <Dialog title={`Pay for ${plan.name}`} subtitle={`${farm.name} · ${ugx(plan.priceUgx)} every ${period(plan.months)}`} onClose={onClose}>
      <form
        className="stack"
        onSubmit={(e) => {
          e.preventDefault();
          if (!busy) void pay();
        }}
      >
        <Field label="How long">
          <select className="input" value={periods} onChange={(e) => setPeriods(Number(e.target.value))}>
            {[1, 2, 3, 6, 12].map((n) => (
              <option key={n} value={n}>
                {n === 1 ? `${period(plan.months)}` : `${n} × ${period(plan.months)}`} · {ugx(planPrice(plan, n))}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Pay with">
          <div className="pay-choice">
            {gateways.map((g) => (
              <button
                type="button"
                key={g.id}
                className={`pay-option ${method === g.id ? 'on' : ''}`}
                aria-pressed={method === g.id}
                disabled={!g.enabled}
                onClick={() => setMethod(g.id)}
              >
                <span className={`pay-logo ${g.id}`}>{g.id === 'mtn' ? 'MTN' : g.id === 'airtel' ? 'Airtel' : g.id === 'card' ? 'Card' : g.name.slice(0, 4)}</span>
                <span>{g.name}</span>
                {!g.enabled && <small>Coming soon</small>}
              </button>
            ))}
          </div>
        </Field>
        {live.length === 0 && (
          <div className="banner info">
            <Icon name="whatsapp" />
            <span className="grow">Paying in the app is coming soon. Pay through FarmTap support on WhatsApp for now.</span>
            <a className="btn sm" href={supportWhatsAppLink(`Hello FarmTap, I want to pay ${ugx(amount)} for ${plan.name} for ${farm.name}.`)} target="_blank" rel="noreferrer">
              WhatsApp
            </a>
          </div>
        )}
        {gw && gw.api && mobile && (
          <Field label="Mobile Money number" hint="The phone that will approve the payment with its PIN.">
            <input className="input" type="tel" inputMode="tel" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="0772 123 456" required />
          </Field>
        )}
        {gw && !gw.api && (
          <>
            <div className="banner info stack" style={{ alignItems: 'flex-start' }}>
              <strong>{gw.name}</strong>
              {gw.payCode && <span className="mono">{gw.payCode}</span>}
              {gw.accountName && <span className="small">{gw.accountName}</span>}
              {gw.instructions && <span className="small">{gw.instructions}</span>}
            </div>
            <Field label="Transaction ID" hint="From the payment message, so FarmTap can confirm it.">
              <input className="input" value={reference} onChange={(e) => setReference(e.target.value)} />
            </Field>
          </>
        )}
        {error && (
          <div className="banner bad small" role="alert">
            <Icon name="alert" />
            <span className="grow">{error}</span>
          </div>
        )}
        <div className="actions">
          <button type="button" className="btn outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn" disabled={busy || !gw || !gw.enabled || !online}>
            {busy ? 'Starting…' : gw?.api === false ? 'Send for confirming' : `Pay ${ugx(amount)}`}
          </button>
        </div>
      </form>
    </Dialog>
  );
}
