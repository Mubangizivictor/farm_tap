'use client';

import Link from 'next/link';
import { AnimalAi } from '@/components/aiPage';
import { useEffect, useState } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { Dialog, Empty, ExportButtons, Field, FormDialog, LoadError, PageHead, SearchBox, Seg, SkelRows, useSave, useToast } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { addDays, dayKey, localIso, parseDate, startOfDay } from '@/lib/dates';
import { addRecord, mergeBody, putRecord, useRecords } from '@/lib/data';
import {
  ageText,
  alive,
  animalLabel,
  dairyStatuses,
  inWithdrawal,
  isActiveAnimal,
  manages,
  nextTag,
  recordDate,
  safeFrom,
  tagTaken,
  type AnimalBody,
  type FarmRecord,
  type MilkBody,
  type TreatmentBody,
} from '@/lib/domain';
import { count, date, litres, shortDate, words } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';
import { useOpenFromUrl } from '@/lib/useOpen';

const BREEDS = ['Friesian', 'Ankole', 'Jersey', 'Guernsey', 'Ayrshire', 'Cross', 'Boran', 'Sahiwal'];

/** Add a new animal, or edit one ([a] set). Same fields and checks as the phone (C02). */
function AnimalForm({ a, animals, onClose }: { a?: FarmRecord<AnimalBody>; animals: FarmRecord<AnimalBody>[]; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const b = a?.body;
  const [f, setF] = useState({
    tagNumber: b?.tagNumber ?? nextTag(animals),
    name: b?.name ?? '',
    sex: b?.sex ?? 'female',
    breed: b?.breed ?? '',
    dateOfBirth: b?.dateOfBirth ? dayKey(parseDate(b.dateOfBirth) ?? new Date()) : '',
    dairyStatus: b?.dairyStatus && b.dairyStatus !== 'treated' ? b.dairyStatus : 'milking',
    group: b?.group ?? '',
    motherTag: b?.motherTag ?? '',
    govIdTag: b?.govIdTag ?? '',
  });
  const { busy, error, setError, run } = useSave();
  const [tagTouched, setTagTouched] = useState(false);
  const set = (k: keyof typeof f) => (e: { target: { value: string } }) => {
    if (k === 'tagNumber') setTagTouched(true);
    setF({ ...f, [k]: e.target.value });
  };
  // Opened before the herd finished loading: keep the suggested tag up to date until they type one.
  const suggested = nextTag(animals);
  useEffect(() => {
    if (!a && !tagTouched) setF((x) => (x.tagNumber === suggested ? x : { ...x, tagNumber: suggested }));
  }, [a, tagTouched, suggested]);
  const groups = [...new Set(animals.map((x) => x.body.group ?? '').filter(Boolean))];
  const breeds = [...new Set([...BREEDS, ...animals.map((x) => x.body.breed).filter(Boolean)])];
  const tagClash = f.tagNumber.trim() !== '' && tagTaken(animals, f.tagNumber, a?.id);
  const statuses = f.sex === 'male' ? (['calf', 'bull'] as const) : dairyStatuses.filter((s) => s !== 'bull');

  async function save() {
    if (!user) return;
    if (!f.tagNumber.trim()) return setError('Every animal needs an ear tag number.');
    if (tagClash) return setError(`Tag ${f.tagNumber.trim()} is already on another animal.`);
    const dob = parseDate(f.dateOfBirth);
    if (!dob) return setError('Choose the date of birth (a guess is fine).');
    if (dob > new Date()) return setError('The date of birth cannot be in the future.');
    const dairyStatus = f.sex === 'male' && f.dairyStatus !== 'calf' ? 'bull' : f.dairyStatus;
    const body = {
      tagNumber: f.tagNumber.trim(),
      name: f.name.trim(),
      sex: f.sex,
      breed: f.breed.trim(),
      dateOfBirth: localIso(dob),
      govIdTag: f.govIdTag.trim() || null,
      dairyStatus,
      group: f.group.trim() || null,
      motherTag: f.motherTag.trim() || null,
    };
    const { db } = firebase();
    const ok = await run(() =>
      a
        ? putRecord(db, farm.id, a, user.uid, mergeBody(a, body))
        : addRecord(db, farm.id, 'animals', user.uid, {
            ...body,
            status: 'active',
            avatarIndex: 1 + Math.floor(Math.random() * 6),
            photo: null,
          }),
    );
    if (ok) {
      toast(a ? `${body.name || body.tagNumber} saved` : `${body.name || body.tagNumber} added to the herd`);
      onClose();
    }
  }

  return (
    <FormDialog
      title={a ? `Edit ${animalLabel(a)}` : 'Add animal'}
      onClose={onClose}
      onSubmit={save}
      busy={busy}
      error={error}
      canSave={canSave}
      online={online}
      submit={a ? 'Save changes' : 'Add animal'}
      size="lg"
    >
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Ear tag number" error={tagClash ? 'Another animal has this tag.' : null}>
          <input className="input" required value={f.tagNumber} onChange={set('tagNumber')} autoFocus />
        </Field>
        <Field label="Name (optional)">
          <input className="input" value={f.name} onChange={set('name')} />
        </Field>
        <Field label="Sex">
          <Seg
            label="Sex"
            value={f.sex}
            onChange={(v) => setF({ ...f, sex: v, dairyStatus: v === 'male' ? (f.dairyStatus === 'calf' ? 'calf' : 'bull') : f.dairyStatus === 'bull' ? 'milking' : f.dairyStatus })}
            items={[['female', 'Female'], ['male', 'Male']]}
          />
        </Field>
        <Field label="Status">
          <select className="input" value={f.dairyStatus} onChange={set('dairyStatus')}>
            {statuses.map((s) => (
              <option key={s} value={s}>
                {words(s)}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Breed">
          <input className="input" list="breeds" value={f.breed} onChange={set('breed')} placeholder="e.g. Friesian" />
          <datalist id="breeds">
            {breeds.map((x) => (
              <option key={x} value={x} />
            ))}
          </datalist>
        </Field>
        <Field label="Date of birth" hint="A guess is fine.">
          <input className="input" type="date" max={dayKey(new Date())} value={f.dateOfBirth} onChange={set('dateOfBirth')} required />
        </Field>
        <Field label="Group (optional)">
          <input className="input" list="groups" value={f.group} onChange={set('group')} placeholder="e.g. Paddock A" />
          <datalist id="groups">
            {groups.map((x) => (
              <option key={x} value={x} />
            ))}
          </datalist>
        </Field>
        <Field label="Mother’s tag (optional)">
          <input className="input" list="tags" value={f.motherTag} onChange={set('motherTag')} />
          <datalist id="tags">
            {animals.filter((x) => isActiveAnimal(x) && x.body.sex === 'female').map((x) => (
              <option key={x.id} value={x.body.tagNumber} />
            ))}
          </datalist>
        </Field>
      </Fit>
      <Field label="Government ID tag (optional)">
        <input className="input" value={f.govIdTag} onChange={set('govIdTag')} />
      </Field>
    </FormDialog>
  );
}

/** Sold or died: the animal leaves the herd (phone: recordSale / recordDeath). */
function LeaveHerd({ a, onClose, onDone }: { a: FarmRecord<AnimalBody>; onClose: () => void; onDone: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const boss = manages(farm);
  const [why, setWhy] = useState<'sold' | 'died'>('sold');
  const [price, setPrice] = useState('');
  const [buyer, setBuyer] = useState('');
  const [cause, setCause] = useState('');
  const { busy, error, setError, run } = useSave();

  async function save() {
    if (!user) return;
    const amount = Number(price || 0);
    if (why === 'sold' && (!Number.isInteger(amount) || amount < 0)) return setError('Type the price in whole shillings, or leave it empty.');
    const { db } = firebase();
    const ok = await run(async () => {
      await putRecord(db, farm.id, a, user.uid, mergeBody(a, { status: why === 'sold' ? 'sold' : 'deceased' }));
      if (why === 'sold') {
        const eventId = await addRecord(db, farm.id, 'animalEvents', user.uid, { type: 'sold', animalId: a.id, price: amount, buyer: buyer.trim() || null });
        if (amount > 0 && boss) {
          const label = [a.body.tagNumber, a.body.name].filter(Boolean).join(' ');
          await addRecord(db, farm.id, 'income', user.uid, {
            source: 'animalSale',
            amount,
            at: localIso(new Date()),
            note: [label, buyer.trim()].filter(Boolean).join(' · '),
            sourceId: eventId,
          });
        }
      } else {
        await addRecord(db, farm.id, 'animalEvents', user.uid, { type: 'death', animalId: a.id, cause: cause.trim() || null });
      }
    });
    if (ok) {
      toast(why === 'sold' ? `${animalLabel(a)} recorded as sold` : `${animalLabel(a)} recorded as dead`);
      onDone();
    }
  }

  return (
    <FormDialog
      title={`${animalLabel(a)} leaves the herd`}
      subtitle="It moves to past animals. Its milk and health records stay."
      onClose={onClose}
      onSubmit={save}
      busy={busy}
      error={error}
      canSave={canSave}
      online={online}
      submit={why === 'sold' ? 'Record sale' : 'Record death'}
      danger={why === 'died'}
    >
      <Seg label="Why" value={why} onChange={setWhy} items={[['sold', 'Sold'], ['died', 'Died']]} />
      {why === 'sold' ? (
        <Fit kind="fields" cols={[1, 2, 2, 2]}>
          <Field label="Price (UGX, optional)" hint={boss ? 'Saved as farm income.' : undefined}>
            <input className="input" type="number" min={0} step={1} inputMode="numeric" value={price} onChange={(e) => setPrice(e.target.value)} autoFocus />
          </Field>
          <Field label="Buyer (optional)">
            <input className="input" value={buyer} onChange={(e) => setBuyer(e.target.value)} />
          </Field>
        </Fit>
      ) : (
        <Field label="Cause (optional)">
          <input className="input" value={cause} onChange={(e) => setCause(e.target.value)} autoFocus />
        </Field>
      )}
    </FormDialog>
  );
}

function AnimalDetail({
  a,
  milk,
  treatments,
  onEdit,
  onLeave,
  onClose,
}: {
  a: FarmRecord<AnimalBody>;
  milk: FarmRecord<MilkBody>[];
  treatments: FarmRecord<TreatmentBody>[];
  onEdit: () => void;
  onLeave: () => void;
  onClose: () => void;
}) {
  const { canSave } = useSession();
  const now = new Date();
  const mine = milk.filter((m) => m.body.animalId === a.id).sort((x, y) => recordDate(y).getTime() - recordDate(x).getTime());
  const health = treatments.filter((t) => t.body.animalId === a.id).sort((x, y) => recordDate(y, 'given').getTime() - recordDate(x, 'given').getTime());
  const last30 = mine.filter((m) => recordDate(m) >= addDays(startOfDay(now), -29)).reduce((t, m) => t + (Number(m.body.litres) || 0), 0);
  const active = isActiveAnimal(a);
  return (
    <Dialog title={animalLabel(a)} subtitle={`Tag ${a.body.tagNumber}`} onClose={onClose} size="lg">
      <div className="row wrap">
        <span className="avatar lg">{(a.body.name || a.body.tagNumber).slice(0, 1).toUpperCase()}</span>
        <div className="stack grow" style={{ gap: 'var(--s-xxs)' }}>
          <span className="small muted">
            {words(a.body.sex)} · {a.body.breed || 'Breed not set'} · {ageText(a.body.dateOfBirth, now) || 'Age not set'}
          </span>
          <div className="chips">
            <span className="chip brand">{active ? words(a.body.dairyStatus) : words(a.body.status)}</span>
            {a.body.group && <span className="chip">{a.body.group}</span>}
            {a.body.motherTag && <span className="chip">Mother {a.body.motherTag}</span>}
            {a.body.govIdTag && <span className="chip">ID {a.body.govIdTag}</span>}
          </div>
        </div>
      </div>
      {canSave && active && (
        <div className="btn-row">
          <button className="btn sm" onClick={onEdit}>
            <Icon name="edit" /> Edit
          </button>
          <Link className="btn sm outline" href={`/health/?new=1&animal=${a.id}`}>
            <Icon name="health" /> Record treatment
          </Link>
          <button className="btn sm outline" onClick={onLeave}>
            <Icon name="logout" /> Sold or died
          </button>
        </div>
      )}
      <AnimalAi animalId={a.id} />
      <Fit kind="stats" cols={[2, 3, 3, 3]}>
        <div className="card flat stat">
          <span className="label">Milk, 30 days</span>
          <span className="value">{litres(last30)}</span>
        </div>
        <div className="card flat stat">
          <span className="label">Born</span>
          <span className="value money">{date(parseDate(a.body.dateOfBirth)) || '–'}</span>
        </div>
        <div className="card flat stat">
          <span className="label">Treatments</span>
          <span className="value">{health.length}</span>
        </div>
      </Fit>
      <Fit kind="cards" cols={[1, 2, 2, 2]}>
        <div className="stack">
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
        </div>
        <div className="stack">
          <h3>Last milk records</h3>
          {mine.length === 0 ? (
            <p className="muted small">No milk recorded for this animal alone.</p>
          ) : (
            <div className="list">
              {mine.slice(0, 6).map((m) => (
                <div key={m.id} className="list-row small">
                  <span className="grow">
                    {shortDate(recordDate(m))} · {words(m.body.session)}
                  </span>
                  <span className="num">{litres(m.body.litres)}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </Fit>
    </Dialog>
  );
}

type View = 'herd' | 'past';

export default function Herd() {
  const farm = useFarm();
  const { canSave } = useSession();
  const now = new Date();
  const animals = useRecords<AnimalBody>(farm.id, 'animals');
  const milk = useRecords<MilkBody>(farm.id, 'milkRecords', localIso(addDays(startOfDay(now), -30)));
  const treatments = useRecords<TreatmentBody>(farm.id, 'treatments');
  const [q, setQ] = useState('');
  const [status, setStatus] = useState<string>('all');
  const [view, setView] = useState<View>('herd');
  const [adding, setAdding] = useOpenFromUrl();
  const [openId, setOpenId] = useState<string | null>(null);
  // /herd/?animal=<id> opens that animal (links from AI Intelligence, decision 0025).
  useEffect(() => {
    const url = new URL(window.location.href);
    const id = url.searchParams.get('animal');
    if (!id) return;
    setOpenId(id);
    url.searchParams.delete('animal');
    history.replaceState(null, '', url.pathname + url.search + url.hash);
  }, []);
  const [editing, setEditing] = useState<FarmRecord<AnimalBody> | null>(null);
  const [leaving, setLeaving] = useState<FarmRecord<AnimalBody> | null>(null);

  const herd = animals.data.filter(isActiveAnimal);
  const past = animals.data.filter((a) => !isActiveAnimal(a)).sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
  const open = animals.data.find((a) => a.id === openId) ?? null;
  const blocked = new Set(alive(treatments.data).filter((t) => inWithdrawal(t.body, now)).map((t) => t.body.animalId));
  const counts = new Map<string, number>();
  for (const a of herd) counts.set(a.body.dairyStatus, (counts.get(a.body.dairyStatus) ?? 0) + 1);
  const shown = (view === 'herd' ? herd : past)
    .filter((a) => view === 'past' || status === 'all' || a.body.dairyStatus === status)
    .filter((a) => !q || `${a.body.tagNumber} ${a.body.name} ${a.body.breed} ${a.body.group ?? ''}`.toLowerCase().includes(q.toLowerCase()))
    .sort((a, b) => (view === 'past' ? 0 : a.body.tagNumber.localeCompare(b.body.tagNumber, undefined, { numeric: true })));
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
        isActiveAnimal(a) ? words(a.body.dairyStatus) : words(a.body.status),
        a.body.group ?? '',
        a.body.motherTag ?? '',
        weekLitres(a.id),
        blocked.has(a.id) ? 'Yes' : '',
      ]),
    );

  return (
    <>
      <PageHead title="Herd" subtitle={animals.loading ? 'Loading the herd…' : `${count(herd.length)} animals on the farm`}>
        <SearchBox value={q} onChange={setQ} placeholder="Search tag, name, breed" />
        <ExportButtons onCsv={csv} />
        <button className="btn sm" onClick={() => setAdding(true)} disabled={!canSave}>
          <Icon name="plus" /> Add animal
        </button>
      </PageHead>
      <LoadError code={animals.error} />

      <div className="row wrap between no-print">
        <Seg label="Show" value={view} onChange={setView} items={[['herd', `On the farm (${herd.length})`], ['past', `Sold or died (${past.length})`]]} />
        {view === 'herd' && (
          <div className="chips">
            {['all', ...dairyStatuses].map((s) => (
              <button key={s} className={`chip ${status === s ? 'brand' : ''}`} onClick={() => setStatus(s)} aria-pressed={status === s}>
                {s === 'all' ? 'All' : words(s)} {s === 'all' ? herd.length : (counts.get(s) ?? 0)}
              </button>
            ))}
          </div>
        )}
      </div>

      <div className="table-wrap">
        <table className="table rt">
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
              <tr key={a.id} className="clickable" tabIndex={0} onClick={() => setOpenId(a.id)} onKeyDown={(e) => e.key === 'Enter' && setOpenId(a.id)}>
                <td data-label="Tag" className="lead">
                  <strong>{a.body.tagNumber}</strong>
                  {a.body.name ? <span className="muted"> · {a.body.name}</span> : null}
                </td>
                <td data-label="Name" className="hide-rt">
                  {a.body.name || '–'}
                </td>
                <td data-label="Breed">{a.body.breed || '–'}</td>
                <td data-label="Age">{ageText(a.body.dateOfBirth, now) || '–'}</td>
                <td data-label="Status">
                  <span className="chips">
                    <span className="chip brand">{isActiveAnimal(a) ? words(a.body.dairyStatus) : words(a.body.status)}</span>
                    {blocked.has(a.id) && <span className="chip bad">Withdrawal</span>}
                  </span>
                </td>
                <td data-label="Group">{a.body.group || '–'}</td>
                <td data-label="Milk 7 days" className="r">
                  {weekLitres(a.id) ? litres(weekLitres(a.id)) : '–'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {animals.loading && <SkelRows rows={6} cols={6} />}
        {!animals.loading && shown.length === 0 && (
          <Empty
            icon="tag"
            action={
              !q && view === 'herd' && canSave && (
                <button className="btn sm" onClick={() => setAdding(true)}>
                  <Icon name="plus" /> Add animal
                </button>
              )
            }
          >
            {q || status !== 'all' ? 'No animal matches.' : view === 'past' ? 'No animals sold or dead.' : 'No animals yet. Add your first animal here or on the phone.'}
          </Empty>
        )}
      </div>

      {adding && <AnimalForm animals={animals.data} onClose={() => setAdding(false)} />}
      {editing && <AnimalForm a={editing} animals={animals.data} onClose={() => setEditing(null)} />}
      {leaving && <LeaveHerd a={leaving} onClose={() => setLeaving(null)} onDone={() => { setLeaving(null); setOpenId(null); }} />}
      {open && !editing && !leaving && (
        <AnimalDetail
          a={open}
          milk={milk.data}
          treatments={treatments.data}
          onEdit={() => setEditing(open)}
          onLeave={() => setLeaving(open)}
          onClose={() => setOpenId(null)}
        />
      )}
    </>
  );
}

