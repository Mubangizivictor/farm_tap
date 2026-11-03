'use client';

import { useState } from 'react';
import { Empty, ExportButtons, LoadError, PageHead, SearchBox, Stat } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { addDays, dayKey, daysBetween, parseDate, startOfDay } from '@/lib/dates';
import { useRecords } from '@/lib/data';
import { animalLabel, inWithdrawal, recordDate, safeFrom, type AnimalBody, type TreatmentBody } from '@/lib/domain';
import { count, date, shortDate, words } from '@/lib/format';
import { useFarm } from '@/lib/session';

/** Treatments and drug withdrawal (Section F). Treatments are recorded on the phone. */
export default function Health() {
  const farm = useFarm();
  const now = new Date();
  const treatments = useRecords<TreatmentBody>(farm.id, 'treatments');
  const animals = useRecords<AnimalBody>(farm.id, 'animals');
  const [q, setQ] = useState('');

  const name = (t: TreatmentBody) => {
    const a = animals.data.find((x) => x.id === t.animalId);
    return t.animalName || (a ? animalLabel(a) : t.tag || 'Cow');
  };
  const sorted = [...treatments.data].sort((a, b) => recordDate(b, 'given').getTime() - recordDate(a, 'given').getTime());
  const active = sorted.filter((t) => inWithdrawal(t.body, now));
  const month = sorted.filter((t) => recordDate(t, 'given') >= addDays(startOfDay(now), -29));
  const conditions = new Map<string, number>();
  for (const t of month) conditions.set(t.body.condition, (conditions.get(t.body.condition) ?? 0) + 1);
  const common = [...conditions.entries()].sort((a, b) => b[1] - a[1])[0];
  const shown = sorted.filter((t) => !q || `${name(t.body)} ${t.body.condition} ${t.body.drugId} ${t.body.givenBy ?? ''}`.toLowerCase().includes(q.toLowerCase()));

  const csv = () =>
    downloadCsv(
      `${farm.name}-treatments-${dayKey(now)}`,
      ['Date', 'Animal', 'Tag', 'Condition', 'Drug', 'Dose', 'Route', 'Withdrawal days', 'Milk safe from', 'Given by'],
      shown.map((t) => [
        dayKey(parseDate(t.body.given) ?? now),
        name(t.body),
        t.body.tag ?? '',
        words(t.body.condition),
        words(t.body.drugId),
        t.body.dose ?? '',
        words(t.body.route),
        t.body.withdrawalDays,
        safeFrom(t.body) ? dayKey(safeFrom(t.body)!) : '',
        t.body.givenBy ?? '',
      ]),
    );

  return (
    <>
      <PageHead title="Health" subtitle="Treatments are recorded on the farm phone. Milk from treated cows must not be sold until the safe day.">
        <SearchBox value={q} onChange={setQ} placeholder="Search cow, condition, drug" />
        <ExportButtons onCsv={csv} />
      </PageHead>
      <LoadError code={treatments.error} />

      <div className="grid">
        <Stat icon="health" label="On withdrawal now" value={count(new Set(active.map((t) => t.body.animalId)).size)} unit="cows" tone={active.length ? 'bad' : undefined} hint={active.length ? 'Keep their milk apart' : 'All milk can be sold'} />
        <Stat icon="calendar" label="Treatments, 30 days" value={count(month.length)} hint={common ? `Most: ${words(common[0])} (${common[1]})` : 'None'} tone="info" />
      </div>

      {active.length > 0 && (
        <section className="card">
          <div className="card-head">
            <h2>Milk not for sale</h2>
          </div>
          <div className="list">
            {active.map((t) => {
              const safe = safeFrom(t.body);
              const left = safe ? daysBetween(now, safe) : 0;
              return (
                <div key={t.id} className="list-row">
                  <span className="avatar">{name(t.body).slice(0, 1)}</span>
                  <div className="grow">
                    <div>{name(t.body)}</div>
                    <div className="small muted">
                      {words(t.body.condition)} · {words(t.body.drugId)} · given {shortDate(parseDate(t.body.given))}
                    </div>
                  </div>
                  <span className="chip bad">
                    Safe {date(safe)} ({left} day{left === 1 ? '' : 's'})
                  </span>
                </div>
              );
            })}
          </div>
        </section>
      )}

      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr>
              <th>Date</th>
              <th>Animal</th>
              <th>Condition</th>
              <th>Drug</th>
              <th>Given by</th>
              <th>Milk safe from</th>
            </tr>
          </thead>
          <tbody>
            {shown.map((t) => (
              <tr key={t.id}>
                <td>{date(parseDate(t.body.given))}</td>
                <td>{name(t.body)}</td>
                <td>{words(t.body.condition)}</td>
                <td>{words(t.body.drugId)}</td>
                <td>{t.body.givenBy || '–'}</td>
                <td>{inWithdrawal(t.body, now) ? <span className="chip bad">{date(safeFrom(t.body))}</span> : <span className="chip ok">Safe</span>}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {!treatments.loading && shown.length === 0 && <Empty>No treatments recorded.</Empty>}
      </div>
    </>
  );
}
