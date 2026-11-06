'use client';

// Milk Quality and Expiry (decision 0025): milk batches kept on the farm,
// cooler temperatures, use-by times from the farm's own shelf-life rule,
// and the centre's rejections. A use-by is never a safety test.

import { useMemo, useState } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { AiTable, MethodBadge, ModuleHead } from '@/components/ai';
import { AiGate, ModuleFindings, useAiPage } from '@/components/aiPage';
import { CardHead, Empty, Field, Stat, useToast } from '@/components/ui';
import { fmtL, kampalaNow } from '@/shared/aiCore';
import { batchViews, qualitySummary, temperatureBreaches, type BatchView } from '@/shared/aiMilk';
import type { ShelfRule } from '@/shared/aiData';
import { addRecord, putRecord, upsertRecord } from '@/lib/data';
import { isCentre, manages, type FarmRecord } from '@/lib/domain';
import { firebase } from '@/lib/firebase';
import { useSession } from '@/lib/session';

const stateText: Record<BatchView['state'], string> = { fresh: 'Within use-by', useSoon: 'Use soon', expired: 'Past use-by', closed: 'Gone' };
const stateTone: Record<BatchView['state'], string> = { fresh: 'ok', useSoon: 'warn', expired: 'bad', closed: '' };
const nowLocal = () => kampalaNow(new Date()).iso.slice(0, 16);

export default function Quality() {
  const page = useAiPage('quality', ['herd', 'centre', 'quality', 'states']);
  const { farm, ai } = page;
  const { user, canSave } = useSession();
  const toast = useToast();
  const db = () => firebase().db;
  const views = useMemo(() => batchViews(ai.data), [ai.data]);
  const stored = views.filter((v) => v.state !== 'closed').sort((a, b) => a.hoursLeft - b.hoursLeft);
  const breaches = useMemo(() => temperatureBreaches(ai.data), [ai.data]);
  const q = useMemo(() => qualitySummary(ai.data), [ai.data]);
  const [batch, setBatch] = useState({ litres: '', collectedAt: nowLocal(), cooled: true, place: '' });
  const [reading, setReading] = useState({ place: '', tempC: '', at: nowLocal() });
  const [rule, setRule] = useState<ShelfRule | null>(null);
  const [err, setErr] = useState('');
  const r0 = ai.shelfRules[0];
  const places = [...new Set(views.map((v) => v.place).filter((p) => p !== 'Not named'))];

  const wrap = async (fn: () => Promise<void>, done: string) => {
    setErr('');
    try {
      await fn();
      toast(done);
    } catch {
      setErr('Could not save. Check the internet and try again.');
    }
  };
  const addBatch = () => {
    const litres = Number(batch.litres.replace(',', '.'));
    if (!(litres > 0 && litres < 20000)) return setErr('Type the litres in the batch.');
    void wrap(
      () => addRecord(db(), farm.id, 'milkBatches', user!.uid, { litres, collectedAt: `${batch.collectedAt}:00`, cooled: batch.cooled, place: batch.place.trim() || null, product: 'rawMilk', status: 'stored', closedAt: null, note: null }).then(() => setBatch({ litres: '', collectedAt: nowLocal(), cooled: true, place: batch.place })),
      'Batch added',
    );
  };
  const addReading = () => {
    const t = Number(reading.tempC.replace(',', '.'));
    if (!Number.isFinite(t) || t < -10 || t > 60 || !reading.tempC.trim()) return setErr('Type the temperature in °C.');
    if (!reading.place.trim()) return setErr('Say which cooler or can.');
    void wrap(() => addRecord(db(), farm.id, 'storageReadings', user!.uid, { place: reading.place.trim(), tempC: t, at: `${reading.at}:00`, batchId: null }).then(() => setReading({ ...reading, tempC: '' })), 'Temperature saved');
  };
  const close = (v: BatchView, status: 'sold' | 'used' | 'discarded') => {
    const rec = ai.records.milkBatches?.find((r) => r.id === v.id) as FarmRecord<Record<string, unknown>> | undefined;
    if (!rec) return;
    void wrap(() => putRecord(db(), farm.id, rec, user!.uid, { ...rec.body, status, closedAt: kampalaNow(new Date()).iso }), status === 'discarded' ? 'Marked as thrown away' : 'Marked as gone');
  };
  const saveRule = (r: ShelfRule) => void wrap(() => upsertRecord(db(), farm.id, 'settings', 'aiMilk', user!.uid, { rules: [r] }).then(() => setRule(null)), 'Rule saved');

  return (
    <>
      <ModuleHead module="quality" title="Milk Quality and Expiry" subtitle="Milk kept on the farm, cooler temperatures and use-by times" />
      <AiGate page={page}>
        <div className="banner info small" role="note">
          <Icon name="shield" />
          <span className="grow">
            Use-by times follow your rule: {r0.label.toLowerCase()} keeps {r0.cooledHours} hours at {r0.maxTempC} °C or colder, {r0.warmHours} hours when warm. They are a
            reminder, not a safety test; FarmTap cannot tell if milk is safe. Check the rule with your buyer.
          </span>
        </div>
        {err && <div className="banner bad small">{err}</div>}
        <Fit kind="stats">
          <Stat icon="drop" label="In storage" value={fmtL(stored.reduce((t, v) => t + v.litres, 0))} hint={`${stored.length} batches`} />
          <Stat icon="clock" label="Use soon" value={String(stored.filter((v) => v.state === 'useSoon').length)} tone={stored.some((v) => v.state === 'useSoon') ? 'warn' : undefined} />
          <Stat icon="alert" label="Past use-by" value={String(stored.filter((v) => v.state === 'expired').length)} tone={stored.some((v) => v.state === 'expired') ? 'bad' : undefined} />
          <Stat icon="thermo" label="Too warm (7 days)" value={String(breaches.length)} tone={breaches.length ? 'warn' : undefined} />
        </Fit>
        <ModuleFindings page={page} module="quality" empty="No milk is near its use-by and every temperature is within the limit." />
        <section className="card stack">
          <CardHead title="Milk in storage">
            <MethodBadge method="calculated" />
          </CardHead>
          {stored.length ? (
            <AiTable
              label="Batches"
              columns={['Where', 'Litres', 'Collected', 'Use by', 'State', '']}
              rows={stored.map((v) => [
                v.place,
                fmtL(v.litres),
                v.collectedAt.replace('T', ' ').slice(0, 16),
                <span key="u">
                  {v.useBy.replace('T', ' ')}
                  {v.unverified ? <span className="small muted"> (no temperature)</span> : null}
                </span>,
                <span key="s" className={`chip ${stateTone[v.state]}`}>
                  {stateText[v.state]}
                  {v.warm && v.state !== 'closed' ? ' · warm' : ''}
                </span>,
                <span key="a" className="row wrap">
                  <button className="btn sm outline" disabled={!canSave} onClick={() => close(v, 'sold')}>
                    Sold
                  </button>
                  <button className="btn sm ghost" disabled={!canSave} onClick={() => close(v, 'used')}>
                    Used
                  </button>
                  <button className="btn sm ghost" disabled={!canSave} onClick={() => close(v, 'discarded')}>
                    Thrown away
                  </button>
                </span>,
              ])}
            />
          ) : (
            <Empty icon="drop">No milk batch in storage. Add one when milk goes into a can or cooler.</Empty>
          )}
        </section>
        <Fit kind="cards" cols={[1, 2, 2, 2]}>
          <section className="card stack">
            <h2>Add a batch</h2>
            <Field label="Litres">
              <input className="input" inputMode="decimal" value={batch.litres} onChange={(e) => setBatch({ ...batch, litres: e.target.value })} />
            </Field>
            <Field label="Milked at">
              <input className="input" type="datetime-local" value={batch.collectedAt} onChange={(e) => setBatch({ ...batch, collectedAt: e.target.value })} />
            </Field>
            <Field label="Kept in (cooler or can)">
              <input className="input" list="ai-places" value={batch.place} onChange={(e) => setBatch({ ...batch, place: e.target.value })} placeholder="Cooler 1" maxLength={40} />
            </Field>
            <label className="row">
              <input type="checkbox" checked={batch.cooled} onChange={(e) => setBatch({ ...batch, cooled: e.target.checked })} /> Cooled (in a cooler or cooling tank)
            </label>
            <button className="btn" disabled={!canSave} onClick={addBatch}>
              <Icon name="plus" /> Add batch
            </button>
          </section>
          <section className="card stack">
            <h2>Record a temperature</h2>
            <Field label="Cooler or can">
              <input className="input" list="ai-places" value={reading.place} onChange={(e) => setReading({ ...reading, place: e.target.value })} placeholder="Cooler 1" maxLength={40} />
            </Field>
            <Field label="Temperature (°C)">
              <input className="input" inputMode="decimal" value={reading.tempC} onChange={(e) => setReading({ ...reading, tempC: e.target.value })} />
            </Field>
            <Field label="Read at">
              <input className="input" type="datetime-local" value={reading.at} onChange={(e) => setReading({ ...reading, at: e.target.value })} />
            </Field>
            <button className="btn" disabled={!canSave} onClick={addReading}>
              <Icon name="thermo" /> Save temperature
            </button>
            <p className="small muted">Later, a cooler sensor can send these by itself.</p>
          </section>
        </Fit>
        <datalist id="ai-places">
          {places.map((p) => (
            <option key={p} value={p} />
          ))}
        </datalist>
        {manages(farm) && (
          <section className="card stack">
            <CardHead title="Your shelf-life rule">
              {!rule && (
                <button className="btn sm outline" onClick={() => setRule(r0)}>
                  <Icon name="edit" /> Change
                </button>
              )}
            </CardHead>
            {rule ? (
              <div className="row wrap">
                <Field label="Hours when cooled">
                  <input className="input" inputMode="decimal" value={rule.cooledHours} onChange={(e) => setRule({ ...rule, cooledHours: Number(e.target.value) || 0 })} />
                </Field>
                <Field label="Coldest allowed (°C)">
                  <input className="input" inputMode="decimal" value={rule.maxTempC} onChange={(e) => setRule({ ...rule, maxTempC: Number(e.target.value) || 0 })} />
                </Field>
                <Field label="Hours when warm">
                  <input className="input" inputMode="decimal" value={rule.warmHours} onChange={(e) => setRule({ ...rule, warmHours: Number(e.target.value) || 0 })} />
                </Field>
                <button className="btn" disabled={!canSave || rule.cooledHours <= 0 || rule.warmHours <= 0} onClick={() => saveRule(rule)}>
                  Save rule
                </button>
                <button className="btn ghost" onClick={() => setRule(null)}>
                  Cancel
                </button>
              </div>
            ) : (
              <p className="small">
                {r0.label}: {r0.cooledHours} hours at {r0.maxTempC} °C or colder; {r0.warmHours} hours otherwise.
              </p>
            )}
          </section>
        )}
        {isCentre(farm) && (
          <section className="card stack">
            <CardHead title="Centre quality (last 30 days)">
              <MethodBadge method="calculated" />
            </CardHead>
            <Fit kind="stats">
              <Stat icon="truck" label="Deliveries" value={String(q.deliveries)} hint={fmtL(q.litres)} />
              <Stat icon="alert" label="Rejected" value={String(q.rejected)} hint={fmtL(q.rejectedLitres)} tone={q.rejected ? 'warn' : undefined} />
              <Stat icon="flag" label="Not tested" value={String(q.notTested)} tone={q.notTested ? 'warn' : undefined} />
            </Fit>
          </section>
        )}
      </AiGate>
    </>
  );
}
