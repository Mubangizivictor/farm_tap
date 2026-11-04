'use client';

import { useEffect, useState } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { CardHead, Empty, ExportButtons, Field, FormDialog, LoadError, PageHead, SearchBox, SkelRows, Stat, Tabs, useSave, useToast } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { addDays, dayKey, localIso, parseDate, startOfDay } from '@/lib/dates';
import { addRecord, useRecords } from '@/lib/data';
import {
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
import { count, date, shortDate, words } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';
import { useOpenFromUrl } from '@/lib/useOpen';

function RecordTreatment({
  animals,
  drugs,
  startAnimal,
  onClose,
}: {
  animals: { id: string; label: string; body: AnimalBody }[];
  drugs: Drug[];
  startAnimal: string;
  onClose: () => void;
}) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const today = dayKey(new Date());
  const [f, setF] = useState({
    animalId: animals.some((a) => a.id === startAnimal) ? startAnimal : '',
    condition: 'mastitis',
    drugId: drugs[0]?.id ?? '',
    given: today,
    dose: '',
    route: 'injection',
    givenBy: user?.displayName ?? '',
    note: '',
  });
  const { busy, error, setError, run } = useSave();
  // The herd may still be loading when the dialog opens from an animal's page.
  useEffect(() => {
    if (startAnimal && animals.some((a) => a.id === startAnimal)) setF((x) => (x.animalId ? x : { ...x, animalId: startAnimal }));
  }, [startAnimal, animals]);
  const set = (k: keyof typeof f) => (e: { target: { value: string } }) => setF({ ...f, [k]: e.target.value });
  const drug = drugs.find((d) => d.id === f.drugId);
  const givenDay = parseDate(f.given);
  const safe = givenDay && drug ? addDays(startOfDay(givenDay), drug.withdrawalDays) : null;

  async function save() {
    if (!user) return;
    const a = animals.find((x) => x.id === f.animalId);
    if (!a) return setError('Choose the animal that was treated.');
    if (!drug) return setError('Choose the drug that was given.');
    if (!givenDay) return setError('Choose the day it was given.');
    if (givenDay > new Date()) return setError('The day given cannot be in the future.');
    // Given today: now. Given earlier: that day at noon, like a typed date on the phone.
    const at = f.given === today ? new Date() : new Date(givenDay.getFullYear(), givenDay.getMonth(), givenDay.getDate(), 12);
    const ok = await run(() =>
      addRecord(firebase().db, farm.id, 'treatments', user.uid, {
        animalId: a.id,
        animalName: a.body.name?.trim() || a.body.tagNumber,
        tag: a.body.tagNumber,
        avatarIndex: a.body.avatarIndex ?? 1,
        animalDry: a.body.dairyStatus === 'dry',
        condition: f.condition,
        drugId: drug.id,
        withdrawalDays: drug.withdrawalDays,
        given: localIso(at),
        courseDays: 3,
        dose: f.dose.trim() || null,
        route: f.route,
        givenBy: f.givenBy.trim() || null,
        photo: null,
        note: f.note.trim() || null,
      }),
    );
    if (ok) {
      toast(drug.withdrawalDays ? `Saved. ${a.label}: milk not for sale until ${shortDate(safe)}` : `Treatment saved for ${a.label}`);
      onClose();
    }
  }

  return (
    <FormDialog
      title="Record treatment"
      subtitle="The phones block this animal’s milk until the safe day."
      onClose={onClose}
      onSubmit={save}
      busy={busy}
      error={error}
      canSave={canSave}
      online={online}
      submit="Save treatment"
      size="lg"
    >
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Animal">
          <select className="input" required value={f.animalId} onChange={set('animalId')} autoFocus>
            <option value="">Choose…</option>
            {animals.map((a) => (
              <option key={a.id} value={a.id}>
                {a.label}
                {a.body.name ? ` (${a.body.tagNumber})` : ''}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Problem">
          <select className="input" value={f.condition} onChange={set('condition')}>
            {conditions.map((c) => (
              <option key={c} value={c}>
                {words(c)}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Drug" hint={drug ? (drug.withdrawalDays ? `Milk not for sale for ${drug.withdrawalDays} days.` : 'No milk withdrawal.') : undefined}>
          <select className="input" required value={f.drugId} onChange={set('drugId')}>
            {drugs.map((d) => (
              <option key={d.id} value={d.id}>
                {d.name}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Day given" hint={safe && drug?.withdrawalDays ? `Milk safe from ${date(safe)}.` : undefined}>
          <input className="input" type="date" required max={today} min={dayKey(addDays(new Date(), -60))} value={f.given} onChange={set('given')} />
        </Field>
        <Field label="Dose (optional)">
          <input className="input" value={f.dose} onChange={set('dose')} placeholder="e.g. 20 ml" />
        </Field>
        <Field label="How it was given">
          <select className="input" value={f.route} onChange={set('route')}>
            {drugRoutes.map((r) => (
              <option key={r} value={r}>
                {words(r)}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Given by (optional)">
          <input className="input" value={f.givenBy} onChange={set('givenBy')} placeholder="e.g. the vet’s name" />
        </Field>
        <Field label="Note (optional)">
          <input className="input" value={f.note} onChange={set('note')} />
        </Field>
      </Fit>
    </FormDialog>
  );
}

type Tab = 'withdrawal' | 'all';

export default function Health() {
  const farm = useFarm();
  const { canSave } = useSession();
  const now = new Date();
  const treatments = useRecords<TreatmentBody>(farm.id, 'treatments');
  const animals = useRecords<AnimalBody>(farm.id, 'animals');
  const stock = useRecords<StockItemBody>(farm.id, 'stockItems');
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
        <button className="btn sm" onClick={() => setAdding(true)} disabled={!canSave || herd.length === 0} title={herd.length ? undefined : 'Add animals first'}>
          <Icon name="plus" /> Record treatment
        </button>
      </PageHead>
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

      <Tabs label="Treatments" value={tab} onChange={setTab} items={[['all', 'All treatments', sorted.length], ['withdrawal', 'On withdrawal', active.length]]} />

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

      {adding && <RecordTreatment animals={herd} drugs={drugs} startAnimal={startAnimal} onClose={() => setAdding(false)} />}
    </>
  );
}
