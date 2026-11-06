'use client';

import { useEffect, useState } from 'react';
import { HealthAi } from '@/components/aiPage';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { CardHead, ConfirmDialog, Empty, ExportButtons, Field, FormDialog, LoadError, PageHead, SearchBox, SkelRows, Stat, Tabs, useSave, useToast } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { addDays, dayKey, localIso, parseDate, startOfDay } from '@/lib/dates';
import { useRecords } from '@/lib/data';
import { CallButtons } from '@/components/farm';
import { expensesOf, removeWithExpenses, saveWithExpense } from '@/lib/linked';
import {
  alive,
  commonVaccines,
  manages,
  payMethodName,
  payMethods,
  type ContactBody,
  type ExpenseBody,
  type FarmRecord,
  type PayMethod,
  type VaccinationBody,
  animalLabel,
  conditions,
  drugRoutes,
  drugsFrom,
  inWithdrawal,
  isActiveAnimal,
  recordDate,
  safeFrom,
  type AnimalBody,
  type Drug,
  type StockItemBody,
  type TreatmentBody,
} from '@/lib/domain';
import { count, date, shortDate, ugx, words } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';
import { RecordTreatment } from '@/components/popups/RecordTreatment';
import { useOpenFromUrl } from '@/lib/useOpen';


function RecordVaccination({ animals, vets, onClose }: { animals: { id: string; label: string }[]; vets: FarmRecord<ContactBody>[]; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const today = dayKey(new Date());
  const [f, setF] = useState({ vaccine: commonVaccines[0] as string, custom: '', whole: true, ids: [] as string[], given: today, nextDue: dayKey(addDays(new Date(), 180)), cost: '', vetId: '', payMethod: 'cash', note: '' });
  const { busy, error, setError, run } = useSave();

  async function save() {
    if (!user) return;
    const vaccine = f.vaccine === 'other' ? f.custom.trim() : f.vaccine;
    if (!vaccine) return setError('Type the vaccine.');
    if (!f.whole && f.ids.length === 0) return setError('Choose the animals, or the whole herd.');
    const given = parseDate(f.given);
    if (!given || given > new Date()) return setError('Choose the day it was given.');
    const cost = f.cost.trim() ? Number(f.cost) : 0;
    if (cost && (!Number.isInteger(cost) || cost < 0)) return setError('Type the cost in whole shillings.');
    const at = localIso(new Date(given.getFullYear(), given.getMonth(), given.getDate(), 12));
    const vet = vets.find((v) => v.id === f.vetId);
    const ok = await run(() =>
      saveWithExpense(
        firebase().db,
        farm.id,
        user.uid,
        { collection: 'vaccinations', body: { vaccine, animalIds: f.whole ? [] : f.ids, given: at, nextDue: f.nextDue ? localIso(parseDate(f.nextDue)!) : null, cost: cost || null, vetId: vet?.id ?? null, note: f.note.trim() || null } },
        'vaccination',
        cost ? { category: 'vet', amount: cost, at, note: `${vaccine} · ${f.whole ? 'whole herd' : `${f.ids.length} animals`}`, supplierId: vet?.id ?? null, payMethod: f.payMethod as PayMethod } : null,
      ),
    );
    if (ok) {
      toast(`${vaccine} saved${f.nextDue ? `. Next due ${shortDate(parseDate(f.nextDue))}` : ''}`);
      onClose();
    }
  }

  return (
    <FormDialog title="Record vaccination" subtitle="FarmTap reminds everyone on Home when the next one is due." onClose={onClose} onSubmit={save} busy={busy} error={error} canSave={canSave} online={online} submit="Save vaccination" size="lg">
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Vaccine">
          <select className="input" value={f.vaccine} onChange={(e) => setF({ ...f, vaccine: e.target.value })}>
            {commonVaccines.map((v) => (
              <option key={v} value={v}>
                {v}
              </option>
            ))}
            <option value="other">Other…</option>
          </select>
        </Field>
        {f.vaccine === 'other' && (
          <Field label="Which vaccine">
            <input className="input" value={f.custom} onChange={(e) => setF({ ...f, custom: e.target.value })} />
          </Field>
        )}
        <Field label="Day given">
          <input className="input" type="date" max={today} value={f.given} onChange={(e) => setF({ ...f, given: e.target.value })} />
        </Field>
        <Field label="Next one due (optional)">
          <input className="input" type="date" min={today} value={f.nextDue} onChange={(e) => setF({ ...f, nextDue: e.target.value })} />
        </Field>
        {vets.length > 0 && (
          <Field label="Vet (optional)">
            <select className="input" value={f.vetId} onChange={(e) => setF({ ...f, vetId: e.target.value })}>
              <option value="">No vet</option>
              {vets.map((v) => (
                <option key={v.id} value={v.id}>
                  {v.body.name}
                </option>
              ))}
            </select>
          </Field>
        )}
        <Field label="Cost, UGX (optional)" hint="Goes to Money as a health expense.">
          <input className="input" type="number" min={0} step={500} inputMode="numeric" value={f.cost} onChange={(e) => setF({ ...f, cost: e.target.value })} />
        </Field>
        {Number(f.cost) > 0 && (
          <Field label="Paid by">
            <select className="input" value={f.payMethod} onChange={(e) => setF({ ...f, payMethod: e.target.value })}>
              {payMethods.map((m) => (
                <option key={m} value={m}>
                  {payMethodName[m]}
                </option>
              ))}
            </select>
          </Field>
        )}
      </Fit>
      <label className="check-row">
        <input type="checkbox" checked={f.whole} onChange={(e) => setF({ ...f, whole: e.target.checked })} />
        <span>The whole herd</span>
      </label>
      {!f.whole && (
        <div className="pick-grid">
          {animals.map((a) => (
            <label key={a.id} className={`pick ${f.ids.includes(a.id) ? 'on' : ''}`}>
              <input type="checkbox" checked={f.ids.includes(a.id)} onChange={(e) => setF({ ...f, ids: e.target.checked ? [...f.ids, a.id] : f.ids.filter((x) => x !== a.id) })} />
              {a.label}
            </label>
          ))}
        </div>
      )}
    </FormDialog>
  );
}

type Tab = 'withdrawal' | 'all' | 'vaccines';

export default function Health() {
  const farm = useFarm();
  const { canSave } = useSession();
  const now = new Date();
  const treatments = useRecords<TreatmentBody>(farm.id, 'treatments');
  const animals = useRecords<AnimalBody>(farm.id, 'animals');
  const stock = useRecords<StockItemBody>(farm.id, 'stockItems');
  const contacts = useRecords<ContactBody>(farm.id, 'contacts');
  const vaccinations = useRecords<VaccinationBody>(farm.id, 'vaccinations');
  const boss = manages(farm);
  const expenses = useRecords<ExpenseBody>(boss ? farm.id : null, 'expenses');
  const { user } = useSession();
  const toast = useToast();
  const [vaccinating, setVaccinating] = useState(false);
  const [removing, setRemoving] = useState<FarmRecord<TreatmentBody> | FarmRecord<VaccinationBody> | null>(null);
  const del = useSave();
  const vets = alive(contacts.data).filter((c) => c.body.kind === 'vet' && (boss || c.body.showWorkers !== false));
  const vaxList = alive(vaccinations.data).sort((a, b) => recordDate(b, 'given').getTime() - recordDate(a, 'given').getTime());
  // The latest dose of each vaccine says when the next is due.
  const nextByVaccine = new Map<string, { due: Date; rec: FarmRecord<VaccinationBody> }>();
  for (const v of vaxList) {
    const due = parseDate(v.body.nextDue);
    if (due && !nextByVaccine.has(v.body.vaccine)) nextByVaccine.set(v.body.vaccine, { due, rec: v });
  }
  const dueSoon = [...nextByVaccine.values()].filter((x) => x.due <= addDays(now, 14)).sort((a, b) => a.due.getTime() - b.due.getTime());
  const [q, setQ] = useState('');
  const [tab, setTab] = useState<Tab>('all');
  const [adding, setAdding] = useOpenFromUrl();
  const [startAnimal, setStartAnimal] = useState('');

  useEffect(() => {
    const id = new URL(window.location.href).searchParams.get('animal');
    if (id) {
      setStartAnimal(id);
      history.replaceState(null, '', window.location.pathname);
    }
  }, []);

  const drugs = drugsFrom(stock.data);
  const drugName = (id: string) => drugs.find((d) => d.id === id)?.name ?? words(id.replace(/^drug-/, ''));
  const name = (t: TreatmentBody) => {
    const a = animals.data.find((x) => x.id === t.animalId);
    return t.animalName || (a ? animalLabel(a) : t.tag || 'An animal');
  };
  const sorted = [...treatments.data].sort((a, b) => recordDate(b, 'given').getTime() - recordDate(a, 'given').getTime());
  const active = sorted.filter((t) => inWithdrawal(t.body, now));
  const month = sorted.filter((t) => recordDate(t, 'given') >= addDays(startOfDay(now), -29));
  const tally = new Map<string, number>();
  for (const t of month) tally.set(t.body.condition, (tally.get(t.body.condition) ?? 0) + 1);
  const common = [...tally.entries()].sort((a, b) => b[1] - a[1])[0];
  const list = tab === 'withdrawal' ? active : sorted;
  const shown = list.filter((t) => !q || `${name(t.body)} ${t.body.condition} ${drugName(t.body.drugId)} ${t.body.givenBy ?? ''}`.toLowerCase().includes(q.toLowerCase()));
  const herd = animals.data
    .filter(isActiveAnimal)
    .sort((a, b) => a.body.tagNumber.localeCompare(b.body.tagNumber, undefined, { numeric: true }))
    .map((a) => ({ id: a.id, label: animalLabel(a), body: a.body }));

  const csv = () =>
    downloadCsv(
      `${farm.name}-treatments-${dayKey(now)}`,
      ['Date', 'Animal', 'Tag', 'Problem', 'Drug', 'Dose', 'Route', 'Withdrawal days', 'Milk safe from', 'Given by', 'Note'],
      shown.map((t) => [
        dayKey(parseDate(t.body.given) ?? now),
        name(t.body),
        t.body.tag ?? '',
        words(t.body.condition),
        drugName(t.body.drugId),
        t.body.dose ?? '',
        words(t.body.route),
        t.body.withdrawalDays,
        safeFrom(t.body) ? dayKey(safeFrom(t.body)!) : '',
        t.body.givenBy ?? '',
        t.body.note ?? '',
      ]),
    );

  return (
    <>
      <PageHead title="Health" subtitle="Milk from a treated animal must not be sold until its safe day.">
        <SearchBox value={q} onChange={setQ} placeholder="Search animal, problem, drug" />
        <ExportButtons onCsv={csv} />
        {boss && (
          <button className="btn sm outline" onClick={() => setVaccinating(true)} disabled={!canSave}>
            <Icon name="calendar" /> Vaccination
          </button>
        )}
        <button className="btn sm" onClick={() => setAdding(true)} disabled={!canSave || herd.length === 0} title={herd.length ? undefined : 'Add animals first'}>
          <Icon name="plus" /> Record treatment
        </button>
      </PageHead>
      <HealthAi />
      {vets.length > 0 ? (
        <section className="card emergency">
          <div className="row wrap">
            <div className="icon-chip bad">
              <Icon name="phone" />
            </div>
            <div className="grow stack" style={{ gap: 0 }}>
              <strong>Vet: {vets[0].body.name}</strong>
              <span className="small muted">
                {vets[0].body.org ? `${vets[0].body.org} · ` : ''}
                {vets[0].body.phone}
                {vets.length > 1 ? ` · ${vets.length - 1} more under Contacts` : ''}
              </span>
            </div>
            <CallButtons phone={vets[0].body.phone} />
          </div>
        </section>
      ) : (
        boss && (
          <div className="banner info">
            <Icon name="phone" />
            <span className="grow">Add your vet under Contacts so workers can call them from here.</span>
            <a className="btn sm outline" href="/contacts/?new=1">
              Add vet
            </a>
          </div>
        )
      )}
      {dueSoon.length > 0 && (
        <div className="banner warn">
          <Icon name="calendar" />
          <span className="grow">
            {dueSoon.map((d) => `${d.rec.body.vaccine}: ${d.due < startOfDay(now) ? 'overdue since' : 'due'} ${shortDate(d.due)}`).join(' · ')}
          </span>
        </div>
      )}
      <LoadError code={treatments.error ?? animals.error} />

      <Fit kind="stats" cols={[2, 3, 3, 3]}>
        <Stat
          loading={treatments.loading}
          icon="health"
          label="On withdrawal now"
          value={count(new Set(active.map((t) => t.body.animalId)).size)}
          unit={new Set(active.map((t) => t.body.animalId)).size === 1 ? 'animal' : 'animals'}
          tone={active.length ? 'bad' : undefined}
          hint={active.length ? 'Keep their milk apart' : 'All milk can be sold'}
        />
        <Stat
          loading={treatments.loading}
          icon="calendar"
          label="Treatments, 30 days"
          value={count(month.length)}
          hint={common ? `Most: ${words(common[0])} (${common[1]})` : 'None'}
          tone="info"
        />
        <Stat loading={treatments.loading} icon="list" label="All treatments" value={count(sorted.length)} hint={`${drugs.length} drugs to choose from`} />
      </Fit>

      {active.length > 0 && (
        <section className="card">
          <CardHead title="Milk not for sale" />
          <Fit kind="cards" cols={[1, 2, 3, 4]}>
            {active.map((t) => (
              <div key={t.id} className="card flat stack" style={{ gap: 'var(--s-xxs)' }}>
                <strong>{name(t.body)}</strong>
                <span className="small muted">
                  {words(t.body.condition)} · {drugName(t.body.drugId)}
                </span>
                <span className="chip bad">Safe from {date(safeFrom(t.body))}</span>
              </div>
            ))}
          </Fit>
        </section>
      )}

      <Tabs
        label="Treatments"
        value={tab}
        onChange={setTab}
        items={[
          ['all', 'All treatments', sorted.length],
          ['withdrawal', 'On withdrawal', active.length],
          ['vaccines', 'Vaccinations', vaxList.length],
        ]}
      />

      {tab === 'vaccines' && (
        <div className="table-wrap">
          <table className="table rt">
            <thead>
              <tr>
                <th>Date</th>
                <th>Vaccine</th>
                <th>Animals</th>
                <th>Next due</th>
                {boss && <th className="r">Cost</th>}
                <th />
              </tr>
            </thead>
            <tbody>
              {vaxList.map((v) => {
                const due = parseDate(v.body.nextDue);
                return (
                  <tr key={v.id}>
                    <td data-label="Date">{date(parseDate(v.body.given))}</td>
                    <td data-label="Vaccine" className="lead">
                      <strong>{v.body.vaccine}</strong>
                    </td>
                    <td data-label="Animals">{v.body.animalIds?.length ? `${v.body.animalIds.length} animals` : 'Whole herd'}</td>
                    <td data-label="Next due">{due ? <span className={`chip ${due <= addDays(now, 14) ? 'warn' : ''}`}>{date(due)}</span> : '–'}</td>
                    {boss && (
                      <td data-label="Cost" className="r">
                        {v.body.cost ? ugx(v.body.cost) : '–'}
                      </td>
                    )}
                    <td className="acts r">
                      {boss && canSave && (
                        <button className="icon-btn" aria-label="Remove vaccination" onClick={() => setRemoving(v)}>
                          <Icon name="close" />
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          {!vaccinations.loading && vaxList.length === 0 && <Empty icon="calendar">No vaccinations recorded yet.</Empty>}
          {vaccinations.loading && <SkelRows rows={3} cols={4} />}
        </div>
      )}

      {tab !== 'vaccines' && (
      <div className="table-wrap">
        <table className="table rt">
          <thead>
            <tr>
              <th>Date</th>
              <th>Animal</th>
              <th>Problem</th>
              <th>Drug</th>
              <th>Given by</th>
              <th>Milk safe from</th>
              {boss && <th className="r">Cost</th>}
              {boss && <th />}
            </tr>
          </thead>
          <tbody>
            {shown.map((t) => {
              const s = safeFrom(t.body);
              const blocked = inWithdrawal(t.body, now);
              return (
                <tr key={t.id}>
                  <td data-label="Date">{date(parseDate(t.body.given))}</td>
                  <td data-label="Animal" className="lead">
                    <strong>{name(t.body)}</strong>
                    {t.body.tag && t.body.animalName !== t.body.tag ? <span className="small muted"> · {t.body.tag}</span> : null}
                  </td>
                  <td data-label="Problem">{words(t.body.condition)}</td>
                  <td data-label="Drug">
                    {drugName(t.body.drugId)}
                    {t.body.dose ? <span className="small muted"> · {t.body.dose}</span> : null}
                  </td>
                  <td data-label="Given by">{t.body.givenBy || '–'}</td>
                  <td data-label="Milk safe from">
                    {(t.body.withdrawalDays ?? 0) === 0 ? (
                      <span className="chip ok">No withdrawal</span>
                    ) : blocked ? (
                      <span className="chip bad">{date(s)}</span>
                    ) : (
                      <span className="chip ok">Safe since {shortDate(s)}</span>
                    )}
                  </td>
                  {boss && (
                    <td data-label="Cost" className="r">
                      {t.body.cost ? ugx(t.body.cost) : '–'}
                    </td>
                  )}
                  {boss && (
                    <td className="acts r">
                      {canSave && (
                        <button className="icon-btn" aria-label="Remove treatment" title="Remove a mistake (and its cost in Money)" onClick={() => setRemoving(t)}>
                          <Icon name="close" />
                        </button>
                      )}
                    </td>
                  )}
                </tr>
              );
            })}
          </tbody>
        </table>
        {treatments.loading && <SkelRows rows={5} cols={6} />}
        {!treatments.loading && shown.length === 0 && (
          <Empty
            icon="health"
            action={
              !q &&
              tab === 'all' &&
              canSave &&
              herd.length > 0 && (
                <button className="btn sm" onClick={() => setAdding(true)}>
                  <Icon name="plus" /> Record treatment
                </button>
              )
            }
          >
            {q ? 'No treatment matches.' : tab === 'withdrawal' ? 'No animal is on drug withdrawal. All milk can be sold.' : 'No treatments recorded yet.'}
          </Empty>
        )}
      </div>
      )}

      {adding && <RecordTreatment animals={herd} drugs={drugs} startAnimal={startAnimal} vets={vets} onClose={() => setAdding(false)} />}
      {vaccinating && <RecordVaccination animals={herd} vets={vets} onClose={() => setVaccinating(false)} />}
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
              toast('Removed, and its cost from Money');
              setRemoving(null);
            }
          }}
        >
          Use this only for a mistake. Its cost is removed from Money too, and the phones stop showing it.
        </ConfirmDialog>
      )}
    </>
  );
}
