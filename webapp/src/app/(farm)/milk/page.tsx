'use client';

import { useState, type FormEvent } from 'react';
import { Icon } from '@/components/Icon';
import { MilkChart } from '@/components/MilkChart';
import { Dialog, Empty, ExportButtons, LoadError, PageHead, SaveHint, Stat } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { addDays, dayKey, localIso, sameDay, startOfDay, startOfMonth } from '@/lib/dates';
import { addRecord, saveError, useRecords } from '@/lib/data';
import {
  alive,
  animalLabel,
  dailyLitres,
  inWithdrawal,
  isMilker,
  recordDate,
  type AnimalBody,
  type MilkBody,
  type TreatmentBody,
} from '@/lib/domain';
import { date, litres, num1, shortDate, time, weekday, words } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';

type Range = '7' | '30' | 'month';

function RecordMilk({ onClose, cows, blocked }: { onClose: () => void; cows: { id: string; label: string }[]; blocked: Set<string> }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const [session, setSession] = useState<'morning' | 'evening'>(new Date().getHours() < 12 ? 'morning' : 'evening');
  const [mode, setMode] = useState<'total' | 'cow'>('total');
  const [total, setTotal] = useState('');
  const [perCow, setPerCow] = useState<Record<string, string>>({});
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function save(ev: FormEvent) {
    ev.preventDefault();
    if (!user) return;
    setBusy(true);
    setError('');
    const { db } = firebase();
    const by = user.displayName || user.email || user.uid;
    try {
      if (mode === 'total') {
        await addRecord(db, farm.id, 'milkRecords', user.uid, { animalId: null, session, litres: Number(total), recordedBy: by });
      } else {
        for (const [cowId, v] of Object.entries(perCow)) {
          if (!v || Number(v) <= 0) continue;
          await addRecord(db, farm.id, 'milkRecords', user.uid, {
            animalId: cowId,
            session,
            litres: Number(v),
            notForSale: blocked.has(cowId),
            recordedBy: by,
          });
        }
      }
      onClose();
    } catch (e) {
      setError(saveError((e as { code?: string }).code));
      setBusy(false);
    }
  }

  return (
    <Dialog title="Record milk" onClose={onClose}>
      <form className="stack" onSubmit={save}>
        <div className="seg" role="group" aria-label="Session">
          <button type="button" aria-pressed={session === 'morning'} onClick={() => setSession('morning')}>
            Morning
          </button>
          <button type="button" aria-pressed={session === 'evening'} onClick={() => setSession('evening')}>
            Evening
          </button>
        </div>
        <div className="seg" role="group" aria-label="How">
          <button type="button" aria-pressed={mode === 'total'} onClick={() => setMode('total')}>
            Herd total
          </button>
          <button type="button" aria-pressed={mode === 'cow'} onClick={() => setMode('cow')} disabled={!cows.length}>
            Each cow
          </button>
        </div>
        {mode === 'total' ? (
          <label className="field">
            <span>Litres for the whole herd</span>
            <input className="input" type="number" min={0.1} step={0.1} inputMode="decimal" required value={total} onChange={(e) => setTotal(e.target.value)} autoFocus />
          </label>
        ) : (
          <div className="list">
            {cows.map((c) => (
              <label key={c.id} className="list-row">
                <span className="grow">
                  {c.label}
                  {blocked.has(c.id) && <span className="chip bad"> Not for sale</span>}
                </span>
                <input
                  className="input"
                  style={{ maxWidth: 'var(--z-col-min)', width: '40%' }}
                  type="number"
                  min={0}
                  step={0.1}
                  inputMode="decimal"
                  placeholder="L"
                  value={perCow[c.id] ?? ''}
                  onChange={(e) => setPerCow({ ...perCow, [c.id]: e.target.value })}
                />
              </label>
            ))}
          </div>
        )}
        {error && <p className="error-text">{error}</p>}
        <SaveHint canSave={canSave} online={online} />
        <div className="actions">
          <button type="button" className="btn outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn" disabled={busy || !canSave}>
            {busy ? 'Saving…' : 'Save'}
          </button>
        </div>
      </form>
    </Dialog>
  );
}

export default function Milk() {
  const farm = useFarm();
  const { canSave } = useSession();
  const [range, setRange] = useState<Range>('7');
  const [adding, setAdding] = useState(false);
  const now = new Date();
  const today = startOfDay(now);
  const from = range === 'month' ? startOfMonth(now) : addDays(today, -(Number(range) - 1));
  const milk = useRecords<MilkBody>(farm.id, 'milkRecords', localIso(addDays(today, -60)));
  const animals = useRecords<AnimalBody>(farm.id, 'animals');
  const treatments = useRecords<TreatmentBody>(farm.id, 'treatments', localIso(addDays(today, -90)));

  const inRange = alive(milk.data).filter((r) => recordDate(r) >= from);
  const days = dailyLitres(milk.data, now, Math.max(1, Math.round((today.getTime() - from.getTime()) / 86_400_000) + 1));
  const total = inRange.reduce((t, r) => t + (Number(r.body.litres) || 0), 0);
  const notForSale = inRange.filter((r) => r.body.notForSale).reduce((t, r) => t + (Number(r.body.litres) || 0), 0);
  const recordedDays = days.filter((d) => d.litres > 0).length;
  const best = days.reduce((b, d) => (d.litres > b.litres ? d : b), { day: today, litres: 0 });

  const name = (id: string | null) => {
    if (!id) return 'Herd total';
    const a = animals.data.find((x) => x.id === id);
    return a ? animalLabel(a) : 'Cow';
  };

  // Top cows in the range.
  const perCow = new Map<string, number>();
  for (const r of inRange) if (r.body.animalId) perCow.set(r.body.animalId, (perCow.get(r.body.animalId) ?? 0) + (Number(r.body.litres) || 0));
  const top = [...perCow.entries()].sort((a, b) => b[1] - a[1]).slice(0, 8);

  const byDay = [...days].reverse().map((d) => {
    const rs = inRange.filter((r) => sameDay(recordDate(r), d.day));
    const m = rs.filter((r) => r.body.session !== 'evening').reduce((t, r) => t + (Number(r.body.litres) || 0), 0);
    const e = rs.filter((r) => r.body.session === 'evening').reduce((t, r) => t + (Number(r.body.litres) || 0), 0);
    return { day: d.day, m, e, total: m + e, n: rs.length };
  });

  const blocked = new Set(treatments.data.filter((t) => inWithdrawal(t.body, now)).map((t) => t.body.animalId));
  const cows = animals.data.filter(isMilker).map((a) => ({ id: a.id, label: animalLabel(a) }));

  const csv = () =>
    downloadCsv(
      `${farm.name}-milk-${dayKey(from)}-to-${dayKey(today)}`,
      ['Date', 'Time', 'Session', 'Cow', 'Litres', 'Not for sale', 'Recorded by'],
      [...inRange]
        .sort((a, b) => recordDate(a).getTime() - recordDate(b).getTime())
        .map((r) => [dayKey(recordDate(r)), time(recordDate(r)), words(r.body.session), name(r.body.animalId), r.body.litres, r.body.notForSale ? 'Yes' : '', r.body.recordedBy ?? '']),
    );

  return (
    <>
      <PageHead title="Milk" subtitle={`${shortDate(from)} to ${shortDate(today)}`}>
        <div className="seg" role="group" aria-label="Period">
          {(
            [
              ['7', '7 days'],
              ['30', '30 days'],
              ['month', 'This month'],
            ] as const
          ).map(([v, l]) => (
            <button key={v} aria-pressed={range === v} onClick={() => setRange(v)}>
              {l}
            </button>
          ))}
        </div>
        <ExportButtons onCsv={csv} />
        <button className="btn sm" onClick={() => setAdding(true)} disabled={!canSave}>
          <Icon name="plus" /> Record milk
        </button>
      </PageHead>
      <LoadError code={milk.error} />

      <div className="grid">
        <Stat icon="drop" label="Total" value={litres(total)} hint={`${inRange.length} records`} />
        <Stat icon="calendar" label="Average a day" value={litres(recordedDays ? total / recordedDays : 0)} hint={`${recordedDays} of ${days.length} days recorded`} />
        <Stat icon="check" label="Best day" value={litres(best.litres)} hint={best.litres ? `${weekday(best.day)} ${date(best.day)}` : 'None yet'} tone="gold" />
        <Stat icon="health" label="Not for sale" value={litres(notForSale)} hint="From cows on drug withdrawal" tone={notForSale ? 'bad' : undefined} />
      </div>

      <div className="grid cols">
        <section className="card">
          <div className="card-head">
            <h2>Litres per day</h2>
          </div>
          <MilkChart days={days.slice(-31)} />
        </section>
        <section className="card">
          <div className="card-head">
            <h2>Top cows</h2>
            <span className="small muted">this period</span>
          </div>
          {top.length === 0 ? (
            <p className="muted">Milk is recorded as a herd total. Record each cow on the phone to see who gives the most.</p>
          ) : (
            <div className="list">
              {top.map(([id, l], i) => (
                <div key={id} className="list-row">
                  <span className="avatar">{i + 1}</span>
                  <span className="grow">{name(id)}</span>
                  <span className="num">{litres(l)}</span>
                  <span className="small muted num">{num1(l / Math.max(1, recordedDays))} L/day</span>
                </div>
              ))}
            </div>
          )}
        </section>
      </div>

      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr>
              <th>Day</th>
              <th className="r">Morning</th>
              <th className="r">Evening</th>
              <th className="r">Total</th>
              <th className="r">Records</th>
            </tr>
          </thead>
          <tbody>
            {byDay.map((d) => (
              <tr key={d.day.toISOString()}>
                <td>
                  {weekday(d.day)} {date(d.day)}
                </td>
                <td className="r">{d.m ? litres(d.m) : '–'}</td>
                <td className="r">{d.e ? litres(d.e) : '–'}</td>
                <td className="r">
                  <strong>{d.total ? litres(d.total) : '–'}</strong>
                </td>
                <td className="r">{d.n || '–'}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {!milk.loading && inRange.length === 0 && <Empty>No milk recorded in this period.</Empty>}
      </div>

      {adding && <RecordMilk onClose={() => setAdding(false)} cows={cows} blocked={blocked} />}
    </>
  );
}
