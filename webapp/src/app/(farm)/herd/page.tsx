'use client';

import { useState, type FormEvent } from 'react';
import { Icon } from '@/components/Icon';
import { Dialog, Empty, ExportButtons, LoadError, PageHead, SaveHint, SearchBox } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { addDays, dayKey, localIso, parseDate, startOfDay } from '@/lib/dates';
import { addRecord, saveError, useRecords } from '@/lib/data';
import {
  ageText,
  alive,
  animalLabel,
  dairyStatuses,
  inWithdrawal,
  isActiveAnimal,
  recordDate,
  safeFrom,
  type AnimalBody,
  type FarmRecord,
  type MilkBody,
  type TreatmentBody,
} from '@/lib/domain';
import { count, date, litres, shortDate, words } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';

function AddAnimal({ onClose }: { onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const [f, setF] = useState({ tagNumber: '', name: '', sex: 'female', breed: '', dateOfBirth: '', dairyStatus: 'milking', group: '', motherTag: '' });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const set = (k: keyof typeof f) => (e: { target: { value: string } }) => setF({ ...f, [k]: e.target.value });

  async function save(ev: FormEvent) {
    ev.preventDefault();
    if (!user) return;
    setBusy(true);
    try {
      const dob = parseDate(f.dateOfBirth) ?? new Date();
      await addRecord(firebase().db, farm.id, 'animals', user.uid, {
        tagNumber: f.tagNumber.trim(),
        name: f.name.trim(),
        sex: f.sex,
        breed: f.breed.trim(),
        dateOfBirth: localIso(dob),
        status: 'active',
        govIdTag: null,
        dairyStatus: f.sex === 'male' && f.dairyStatus !== 'calf' ? 'bull' : f.dairyStatus,
        avatarIndex: 1 + Math.floor(Math.random() * 6),
        group: f.group.trim() || null,
        motherTag: f.motherTag.trim() || null,
      });
      onClose();
    } catch (e) {
      setError(saveError((e as { code?: string }).code));
      setBusy(false);
    }
  }

  return (
    <Dialog title="Add animal" onClose={onClose}>
      <form className="stack" onSubmit={save}>
        <div className="grid">
          <label className="field">
            <span>Ear tag number</span>
            <input className="input" required value={f.tagNumber} onChange={set('tagNumber')} autoFocus />
          </label>
          <label className="field">
            <span>Name (optional)</span>
            <input className="input" value={f.name} onChange={set('name')} />
          </label>
          <label className="field">
            <span>Sex</span>
            <select className="input" value={f.sex} onChange={set('sex')}>
              <option value="female">Female</option>
              <option value="male">Male</option>
            </select>
          </label>
          <label className="field">
            <span>Status</span>
            <select className="input" value={f.dairyStatus} onChange={set('dairyStatus')}>
              {dairyStatuses.map((s) => (
                <option key={s} value={s}>
                  {words(s)}
                </option>
              ))}
            </select>
          </label>
          <label className="field">
            <span>Breed</span>
            <input className="input" list="breeds" value={f.breed} onChange={set('breed')} placeholder="e.g. Friesian" />
            <datalist id="breeds">
              {['Friesian', 'Ankole', 'Jersey', 'Guernsey', 'Ayrshire', 'Cross', 'Boran', 'Sahiwal'].map((b) => (
                <option key={b} value={b} />
              ))}
            </datalist>
          </label>
          <label className="field">
            <span>Date of birth</span>
            <input className="input" type="date" max={dayKey(new Date())} value={f.dateOfBirth} onChange={set('dateOfBirth')} required />
          </label>
          <label className="field">
            <span>Group (optional)</span>
            <input className="input" value={f.group} onChange={set('group')} placeholder="e.g. Paddock A" />
          </label>
          <label className="field">
            <span>Mother’s tag (optional)</span>
            <input className="input" value={f.motherTag} onChange={set('motherTag')} />
          </label>
        </div>
        {error && <p className="error-text">{error}</p>}
        <SaveHint canSave={canSave} online={online} />
        <div className="actions">
          <button type="button" className="btn outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn" disabled={busy || !canSave}>
            {busy ? 'Saving…' : 'Add animal'}
          </button>
        </div>
      </form>
    </Dialog>
  );
}

function AnimalDetail({
  a,
  milk,
  treatments,
  onClose,
}: {
  a: FarmRecord<AnimalBody>;
  milk: FarmRecord<MilkBody>[];
  treatments: FarmRecord<TreatmentBody>[];
  onClose: () => void;
}) {
  const now = new Date();
  const mine = milk.filter((m) => m.body.animalId === a.id).sort((x, y) => recordDate(y).getTime() - recordDate(x).getTime());
  const health = treatments.filter((t) => t.body.animalId === a.id).sort((x, y) => recordDate(y, 'given').getTime() - recordDate(x, 'given').getTime());
  const last30 = mine.filter((m) => recordDate(m) >= addDays(startOfDay(now), -29)).reduce((t, m) => t + (Number(m.body.litres) || 0), 0);
  return (
    <Dialog title={animalLabel(a)} onClose={onClose}>
      <div className="row">
        <span className="avatar lg">{(a.body.name || a.body.tagNumber).slice(0, 1).toUpperCase()}</span>
        <div className="stack" style={{ gap: 'var(--s-xxs)' }}>
          <strong>Tag {a.body.tagNumber}</strong>
          <span className="small muted">
            {words(a.body.sex)} · {a.body.breed || 'Breed not set'} · {ageText(a.body.dateOfBirth, now)}
          </span>
          <div className="row wrap">
            <span className="chip brand">{words(a.body.dairyStatus)}</span>
            {a.body.group && <span className="chip">{a.body.group}</span>}
          </div>
        </div>
      </div>
      <div className="grid">
        <div className="card flat stat">
          <span className="label">Milk, 30 days</span>
          <span className="value">{litres(last30)}</span>
        </div>
        <div className="card flat stat">
          <span className="label">Born</span>
          <span className="value small">{date(parseDate(a.body.dateOfBirth))}</span>
        </div>
      </div>
      <h3>Health</h3>
      {health.length === 0 ? (
        <p className="muted small">No treatments recorded.</p>
      ) : (
        <div className="list">
          {health.slice(0, 6).map((t) => (
            <div key={t.id} className="list-row small">
              <span className="grow">
                {shortDate(parseDate(t.body.given))} · {words(t.body.condition)}
              </span>
              {inWithdrawal(t.body, now) ? <span className="chip bad">Safe from {shortDate(safeFrom(t.body))}</span> : <span className="chip ok">Done</span>}
            </div>
          ))}
        </div>
      )}
      <h3>Last milk records</h3>
      {mine.length === 0 ? (
        <p className="muted small">No milk recorded for this cow alone.</p>
      ) : (
        <div className="list">
          {mine.slice(0, 8).map((m) => (
            <div key={m.id} className="list-row small">
              <span className="grow">
                {shortDate(recordDate(m))} · {words(m.body.session)}
              </span>
              <span className="num">{litres(m.body.litres)}</span>
            </div>
          ))}
        </div>
      )}
    </Dialog>
  );
}

export default function Herd() {
  const farm = useFarm();
  const { canSave } = useSession();
  const now = new Date();
  const animals = useRecords<AnimalBody>(farm.id, 'animals');
  const milk = useRecords<MilkBody>(farm.id, 'milkRecords', localIso(addDays(startOfDay(now), -30)));
  const treatments = useRecords<TreatmentBody>(farm.id, 'treatments');
  const [q, setQ] = useState('');
  const [status, setStatus] = useState<string>('all');
  const [adding, setAdding] = useState(false);
  const [open, setOpen] = useState<FarmRecord<AnimalBody> | null>(null);

  const herd = animals.data.filter(isActiveAnimal);
  const blocked = new Set(alive(treatments.data).filter((t) => inWithdrawal(t.body, now)).map((t) => t.body.animalId));
  const counts = new Map<string, number>();
  for (const a of herd) counts.set(a.body.dairyStatus, (counts.get(a.body.dairyStatus) ?? 0) + 1);
  const shown = herd
    .filter((a) => status === 'all' || a.body.dairyStatus === status)
    .filter((a) => !q || `${a.body.tagNumber} ${a.body.name} ${a.body.breed} ${a.body.group ?? ''}`.toLowerCase().includes(q.toLowerCase()))
    .sort((a, b) => a.body.tagNumber.localeCompare(b.body.tagNumber, undefined, { numeric: true }));
  const week = addDays(startOfDay(now), -6);
  const weekLitres = (id: string) =>
    milk.data.filter((m) => m.body.animalId === id && recordDate(m) >= week).reduce((t, m) => t + (Number(m.body.litres) || 0), 0);

  const csv = () =>
    downloadCsv(
      `${farm.name}-herd-${dayKey(now)}`,
      ['Tag', 'Name', 'Sex', 'Breed', 'Born', 'Age', 'Status', 'Group', 'Mother tag', 'Milk 7 days (L)', 'Drug withdrawal'],
      shown.map((a) => [
        a.body.tagNumber,
        a.body.name,
        words(a.body.sex),
        a.body.breed,
        dayKey(parseDate(a.body.dateOfBirth) ?? now),
        ageText(a.body.dateOfBirth, now),
        words(a.body.dairyStatus),
        a.body.group ?? '',
        a.body.motherTag ?? '',
        weekLitres(a.id),
        blocked.has(a.id) ? 'Yes' : '',
      ]),
    );

  return (
    <>
      <PageHead title="Herd" subtitle={`${count(herd.length)} animals on the farm`}>
        <SearchBox value={q} onChange={setQ} placeholder="Search tag, name, breed" />
        <ExportButtons onCsv={csv} />
        <button className="btn sm" onClick={() => setAdding(true)} disabled={!canSave}>
          <Icon name="plus" /> Add animal
        </button>
      </PageHead>
      <LoadError code={animals.error} />

      <div className="row wrap no-print">
        {['all', ...dairyStatuses].map((s) => (
          <button key={s} className={`chip ${status === s ? 'brand' : ''}`} style={{ border: 0, cursor: 'pointer' }} onClick={() => setStatus(s)}>
            {s === 'all' ? 'All' : words(s)} {s === 'all' ? herd.length : (counts.get(s) ?? 0)}
          </button>
        ))}
      </div>

      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr>
              <th>Tag</th>
              <th>Name</th>
              <th>Breed</th>
              <th>Age</th>
              <th>Status</th>
              <th>Group</th>
              <th className="r">Milk 7 days</th>
            </tr>
          </thead>
          <tbody>
            {shown.map((a) => (
              <tr key={a.id} onClick={() => setOpen(a)} style={{ cursor: 'pointer' }}>
                <td>
                  <strong>{a.body.tagNumber}</strong>
                </td>
                <td>{a.body.name || '–'}</td>
                <td>{a.body.breed || '–'}</td>
                <td>{ageText(a.body.dateOfBirth, now)}</td>
                <td>
                  <span className="row" style={{ gap: 'var(--s-xs)' }}>
                    <span className="chip brand">{words(a.body.dairyStatus)}</span>
                    {blocked.has(a.id) && <span className="chip bad">Withdrawal</span>}
                  </span>
                </td>
                <td>{a.body.group || '–'}</td>
                <td className="r">{weekLitres(a.id) ? litres(weekLitres(a.id)) : '–'}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {!animals.loading && shown.length === 0 && <Empty>{herd.length ? 'No animal matches.' : 'No animals yet. Add your first animal here or on the phone.'}</Empty>}
      </div>

      {adding && <AddAnimal onClose={() => setAdding(false)} />}
      {open && <AnimalDetail a={open} milk={milk.data} treatments={treatments.data} onClose={() => setOpen(null)} />}
    </>
  );
}
