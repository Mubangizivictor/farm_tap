'use client';

import { useState } from 'react';
import { BreedingAi } from '@/components/aiPage';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { ConfirmDialog, Empty, ExportButtons, Field, FormDialog, LoadError, PageHead, Seg, SkelRows, Stat, Tabs, useSave, useToast } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { addDays, dayKey, localIso, parseDate } from '@/lib/dates';
import { addRecord, useRecords } from '@/lib/data';
import {
  alive,
  animalLabel,
  breedingView,
  isActiveAnimal,
  manages,
  payMethodName,
  payMethods,
  recordDate,
  type AnimalBody,
  type BreedingBody,
  type ContactBody,
  type ExpenseBody,
  type FarmRecord,
  type PayMethod,
} from '@/lib/domain';
import { firebase } from '@/lib/firebase';
import { date, shortDate, ugx } from '@/lib/format';
import { expensesOf, removeWithExpenses, saveWithExpense } from '@/lib/linked';
import { useFarm, useSession } from '@/lib/session';

type Action = 'heat' | 'service' | 'check' | 'calving';

function atOf(day: string) {
  const d = parseDate(day) ?? new Date();
  return localIso(new Date(d.getFullYear(), d.getMonth(), d.getDate(), 9));
}

function BreedingForm({
  action,
  cows,
  startCow,
  events,
  techs,
  onClose,
}: {
  action: Action;
  cows: FarmRecord<AnimalBody>[];
  startCow: string;
  events: FarmRecord<BreedingBody>[];
  techs: FarmRecord<ContactBody>[];
  onClose: () => void;
}) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const boss = manages(farm);
  const today = dayKey(new Date());
  const [f, setF] = useState({
    cow: startCow || cows[0]?.id || '',
    day: today,
    kind: 'ai' as 'ai' | 'natural',
    straw: '',
    bull: '',
    techId: '',
    technician: user?.displayName ?? '',
    cost: '',
    method: 'cash',
    pregnant: 'yes' as 'yes' | 'no',
  });
  const { busy, error, setError, run } = useSave();
  const cow = cows.find((c) => c.id === f.cow);
  const v = cow ? breedingView(cow.id, events, new Date()) : null;

  async function save() {
    if (!user || !cow) return setError('Choose the cow.');
    const day = parseDate(f.day);
    if (!day || day > new Date()) return setError('Choose the day; it cannot be in the future.');
    const at = atOf(f.day);
    const { db } = firebase();
    const tech = techs.find((t) => t.id === f.techId);
    const by = tech?.body.name ?? (f.technician.trim() || null);
    let ok = false;
    if (action === 'heat') {
      ok = await run(() => addRecord(db, farm.id, 'breedingEvents', user.uid, { type: 'service', kind: 'heat', animalId: cow.id, at, straw: null, bull: null, technician: by, cost: null }));
    } else if (action === 'service') {
      const cost = boss && f.cost.trim() ? Number(f.cost) : 0;
      if (cost && (!Number.isInteger(cost) || cost < 0)) return setError('Type the cost in whole shillings.');
      ok = await run(() =>
        saveWithExpense(
          db,
          farm.id,
          user.uid,
          // The phone's recordService shape (fake_breeding_repository).
          { collection: 'breedingEvents', body: { type: f.kind === 'ai' ? 'ai' : 'service', kind: f.kind, animalId: cow.id, at, straw: f.kind === 'ai' ? f.straw.trim() || null : null, bull: f.kind === 'natural' ? f.bull.trim() || null : null, technician: by, cost: cost || null } },
          'service',
          cost ? { category: 'breeding', amount: cost, at, note: `${animalLabel(cow)} · ${f.kind === 'ai' ? f.straw.trim() || 'AI' : f.bull.trim() || 'bull'}`, supplierId: tech?.id ?? null, payMethod: f.method as PayMethod } : null,
        ),
      );
    } else if (action === 'check') {
      if (!v?.service) return setError('This cow has no service waiting for a check.');
      ok = await run(() => addRecord(db, farm.id, 'breedingEvents', user.uid, { type: 'pregnancyCheck', serviceId: v.service!.id, pregnant: f.pregnant === 'yes', by, at }));
    } else {
      ok = await run(() => addRecord(db, farm.id, 'breedingEvents', user.uid, { type: 'calving', animalId: cow.id, at }));
    }
    if (ok) {
      toast(
        action === 'service'
          ? `Served. Check for pregnancy around ${shortDate(addDays(day, 60))}.`
          : action === 'check'
            ? f.pregnant === 'yes'
              ? `In calf. Due about ${shortDate(addDays(v!.servedAt!, 283))}.`
              : 'Not in calf. Watch for heat.'
            : action === 'calving'
              ? 'Calving saved. Add the calf on the Herd page.'
              : 'Heat saved.',
      );
      onClose();
    }
  }

  const titles: Record<Action, string> = { heat: 'Cow on heat', service: 'Served (AI or bull)', check: 'Pregnancy check', calving: 'Calved' };
  return (
    <FormDialog title={titles[action]} onClose={onClose} onSubmit={save} busy={busy} error={error} canSave={canSave} online={online} submit="Save">
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Cow">
          <select className="input" value={f.cow} onChange={(e) => setF({ ...f, cow: e.target.value })}>
            {cows.map((c) => (
              <option key={c.id} value={c.id}>
                {animalLabel(c)}
                {c.body.name ? ` (${c.body.tagNumber})` : ''}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Day">
          <input className="input" type="date" max={today} value={f.day} onChange={(e) => setF({ ...f, day: e.target.value })} />
        </Field>
        {action === 'service' && <Seg label="How" value={f.kind} onChange={(k) => setF({ ...f, kind: k })} items={[['ai', 'AI'], ['natural', 'Bull']]} />}
        {action === 'service' && f.kind === 'ai' && (
          <Field label="Straw (optional)">
            <input className="input" value={f.straw} onChange={(e) => setF({ ...f, straw: e.target.value })} placeholder="e.g. Friesian 4421" />
          </Field>
        )}
        {action === 'service' && f.kind === 'natural' && (
          <Field label="Bull (optional)">
            <input className="input" value={f.bull} onChange={(e) => setF({ ...f, bull: e.target.value })} />
          </Field>
        )}
        {action !== 'calving' && techs.length > 0 && (
          <Field label={action === 'service' ? 'AI technician or vet' : 'Checked by'}>
            <select className="input" value={f.techId} onChange={(e) => setF({ ...f, techId: e.target.value })}>
              <option value="">Someone else (type below)</option>
              {techs.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.body.name}
                </option>
              ))}
            </select>
          </Field>
        )}
        {action !== 'calving' && !f.techId && (
          <Field label="Name (optional)">
            <input className="input" value={f.technician} onChange={(e) => setF({ ...f, technician: e.target.value })} />
          </Field>
        )}
        {action === 'service' && boss && (
          <Field label="Cost, UGX (optional)" hint="Goes to Money as a breeding expense.">
            <input className="input" type="number" min={0} step={500} value={f.cost} onChange={(e) => setF({ ...f, cost: e.target.value })} />
          </Field>
        )}
        {action === 'service' && boss && Number(f.cost) > 0 && (
          <Field label="Paid by">
            <select className="input" value={f.method} onChange={(e) => setF({ ...f, method: e.target.value })}>
              {payMethods.map((m) => (
                <option key={m} value={m}>
                  {payMethodName[m]}
                </option>
              ))}
            </select>
          </Field>
        )}
        {action === 'check' && <Seg label="Result" value={f.pregnant} onChange={(p) => setF({ ...f, pregnant: p })} items={[['yes', 'In calf'], ['no', 'Not in calf']]} />}
      </Fit>
      {action === 'check' && v && (v.servedAt ? <p className="small muted">Served {date(v.servedAt)}.</p> : <p className="small bad-text">No open service for this cow.</p>)}
    </FormDialog>
  );
}

type Tab = 'cows' | 'events';

export default function Breeding() {
  const farm = useFarm();
  const { user, canSave } = useSession();
  const toast = useToast();
  const boss = manages(farm);
  const now = new Date();
  const animals = useRecords<AnimalBody>(farm.id, 'animals');
  const events = useRecords<BreedingBody>(farm.id, 'breedingEvents');
  const contacts = useRecords<ContactBody>(farm.id, 'contacts');
  const expenses = useRecords<ExpenseBody>(boss ? farm.id : null, 'expenses');
  const [tab, setTab] = useState<Tab>('cows');
  const [form, setForm] = useState<{ action: Action; cow: string } | null>(null);
  const [removing, setRemoving] = useState<FarmRecord<BreedingBody> | null>(null);
  const del = useSave();

  const cows = animals.data
    .filter((a) => isActiveAnimal(a) && a.body.sex === 'female' && a.body.dairyStatus !== 'calf')
    .sort((a, b) => a.body.tagNumber.localeCompare(b.body.tagNumber, undefined, { numeric: true }));
  const techs = alive(contacts.data).filter((c) => c.body.kind === 'aiTechnician' || c.body.kind === 'vet');
  const ev = alive(events.data);
  const views = cows.map((c) => ({ cow: c, v: breedingView(c.id, ev, now) }));
  const soon = (d: Date | null, days: number) => !!d && d <= addDays(now, days);
  const inCalf = views.filter((x) => x.v.pregnant);
  const due30 = views.filter((x) => x.v.due && soon(x.v.due, 30)).sort((a, b) => a.v.due!.getTime() - b.v.due!.getTime());
  const checks = views.filter((x) => x.v.checkDue && soon(x.v.checkDue, 7));
  const heats = views.filter((x) => x.v.nextHeat && soon(x.v.nextHeat, 3));
  const open = views.filter((x) => !x.v.pregnant);
  const nameOf = (id?: string) => {
    const a = animals.data.find((x) => x.id === id);
    return a ? animalLabel(a) : 'A cow';
  };
  const serviceOf = (id?: string) => ev.find((e) => e.id === id);
  const sorted = [...ev].sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime());
  const eventText = (e: BreedingBody) =>
    e.type === 'pregnancyCheck'
      ? `Pregnancy check: ${e.pregnant ? 'in calf' : 'not in calf'}`
      : e.type === 'calving'
        ? 'Calved'
        : e.kind === 'heat'
          ? 'On heat'
          : e.kind === 'ai'
            ? `AI${e.straw ? ` · ${e.straw}` : ''}`
            : `Bull${e.bull ? ` · ${e.bull}` : ''}`;

  const csv = () =>
    downloadCsv(
      `${farm.name}-breeding`,
      ['Cow', 'Tag', 'Status', 'Served', 'Due', 'Next heat'],
      views.map((x) => [animalLabel(x.cow), x.cow.body.tagNumber, x.v.pregnant ? (x.v.confirmed ? 'In calf' : 'Served') : 'Open', x.v.servedAt ? dayKey(x.v.servedAt) : '', x.v.due ? dayKey(x.v.due) : '', x.v.nextHeat ? dayKey(x.v.nextHeat) : '']),
    );

  return (
    <>
      <PageHead title="Breeding" subtitle="Heat, AI or bull, pregnancy checks and calving dates. Same records as the farm phones.">
        <ExportButtons onCsv={csv} />
        <button className="btn sm outline" onClick={() => setForm({ action: 'heat', cow: '' })} disabled={!canSave || !cows.length}>
          Heat
        </button>
        <button className="btn sm outline" onClick={() => setForm({ action: 'calving', cow: '' })} disabled={!canSave || !cows.length}>
          Calved
        </button>
        <button className="btn sm" onClick={() => setForm({ action: 'service', cow: '' })} disabled={!canSave || !cows.length}>
          <Icon name="plus" /> Served
        </button>
      </PageHead>
      <BreedingAi />
      <LoadError code={events.error ?? animals.error} />

      <Fit kind="stats" cols={[2, 2, 4, 4]}>
        <Stat loading={events.loading} icon="cow" label="In calf" value={String(inCalf.length)} hint={`${open.length} open`} />
        <Stat loading={events.loading} icon="calendar" label="Calving in 30 days" value={String(due30.length)} hint={due30[0] ? `${animalLabel(due30[0].cow)} on ${shortDate(due30[0].v.due)}` : 'None'} tone={due30.length ? 'gold' : undefined} />
        <Stat loading={events.loading} icon="check" label="Pregnancy checks due" value={String(checks.length)} hint="About 60 days after service" tone={checks.length ? 'warn' : undefined} />
        <Stat loading={events.loading} icon="clock" label="Heat expected" value={String(heats.length)} hint="In the next 3 days" tone="info" />
      </Fit>

      <Tabs
        label="Breeding"
        value={tab}
        onChange={setTab}
        items={[
          ['cows', 'Cows', cows.length],
          ['events', 'All records', sorted.length],
        ]}
      />

      {tab === 'cows' && (
        <div className="table-wrap">
          <table className="table rt">
            <thead>
              <tr>
                <th>Cow</th>
                <th>Status</th>
                <th>Served</th>
                <th>Due</th>
                <th>Next</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {views.map(({ cow, v }) => (
                <tr key={cow.id}>
                  <td data-label="Cow" className="lead">
                    <strong>{animalLabel(cow)}</strong>
                    {cow.body.name ? <span className="small muted"> · {cow.body.tagNumber}</span> : null}
                  </td>
                  <td data-label="Status">{v.pregnant ? <span className={`chip ${v.confirmed ? 'ok' : 'warn'}`}>{v.confirmed ? 'In calf' : 'Served, not checked'}</span> : <span className="chip">Open</span>}</td>
                  <td data-label="Served">{v.servedAt ? shortDate(v.servedAt) : '–'}</td>
                  <td data-label="Due">{v.due ? <span className={soon(v.due, 30) ? 'chip gold' : ''}>{date(v.due)}</span> : '–'}</td>
                  <td data-label="Next">
                    {v.checkDue ? `Check from ${shortDate(v.checkDue)}` : v.nextHeat ? `Heat about ${shortDate(v.nextHeat)}` : v.pregnant ? 'Dry off 60 days before due' : 'Watch for heat'}
                  </td>
                  <td className="acts r">
                    {canSave && (
                      <select
                        className="input sm"
                        aria-label={`Record for ${animalLabel(cow)}`}
                        value=""
                        onChange={(e) => e.target.value && setForm({ action: e.target.value as Action, cow: cow.id })}
                      >
                        <option value="">Record…</option>
                        <option value="heat">On heat</option>
                        <option value="service">Served</option>
                        {v.service && <option value="check">Pregnancy check</option>}
                        <option value="calving">Calved</option>
                      </select>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {animals.loading && <SkelRows rows={5} cols={5} />}
          {!animals.loading && cows.length === 0 && <Empty icon="cow">No cows or heifers in the herd yet. Add them on the Herd page.</Empty>}
        </div>
      )}

      {tab === 'events' && (
        <div className="table-wrap">
          <table className="table rt">
            <thead>
              <tr>
                <th>Date</th>
                <th>Cow</th>
                <th>What</th>
                <th>By</th>
                {boss && <th className="r">Cost</th>}
                <th />
              </tr>
            </thead>
            <tbody>
              {sorted.map((e) => (
                <tr key={e.id}>
                  <td data-label="Date">{shortDate(recordDate(e, 'at'))}</td>
                  <td data-label="Cow" className="lead">
                    <strong>{nameOf(e.body.animalId ?? serviceOf(e.body.serviceId)?.body.animalId)}</strong>
                  </td>
                  <td data-label="What">{eventText(e.body)}</td>
                  <td data-label="By">{e.body.technician || e.body.by || '–'}</td>
                  {boss && (
                    <td data-label="Cost" className="r">
                      {e.body.cost ? ugx(e.body.cost) : '–'}
                    </td>
                  )}
                  <td className="acts r">
                    {boss && canSave && (
                      <button className="icon-btn" aria-label="Remove" onClick={() => setRemoving(e)}>
                        <Icon name="close" />
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!events.loading && sorted.length === 0 && <Empty icon="cow">No breeding records yet.</Empty>}
        </div>
      )}

      {form && <BreedingForm action={form.action} cows={cows} startCow={form.cow} events={ev} techs={techs} onClose={() => setForm(null)} />}
      {removing && (
        <ConfirmDialog
          title="Remove this record?"
          confirm="Remove"
          danger
          busy={del.busy}
          error={del.error}
          onClose={() => setRemoving(null)}
          onConfirm={async () => {
            if (!user) return;
            if (await del.run(() => removeWithExpenses(firebase().db, farm.id, user.uid, removing, expensesOf(removing.id, expenses.data)))) {
              toast('Removed, with its cost in Money');
              setRemoving(null);
            }
          }}
        >
          Use this only for a mistake. Its cost is removed from Money too.
        </ConfirmDialog>
      )}
    </>
  );
}

