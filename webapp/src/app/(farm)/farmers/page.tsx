'use client';

import { useState, type FormEvent } from 'react';
import { Icon } from '@/components/Icon';
import { Dialog, Empty, ExportButtons, LoadError, PageHead, SaveHint, SearchBox, Stat } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { dayKey, localIso, sameDay, startOfMonth } from '@/lib/dates';
import { nextFreeCard } from '@/lib/cards';
import { addRecord, saveError, useRecords } from '@/lib/data';
import { recordDate, type DeliveryBody, type FarmRecord, type FarmerBody, type StaffBody } from '@/lib/domain';
import { count, date, initials, litres, shortDate, time, words } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';


function AddSupplier({ onClose, taken }: { onClose: () => void; taken: Set<string> }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [village, setVillage] = useState('');
  const [card, setCard] = useState(nextFreeCard(taken));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function save(ev: FormEvent) {
    ev.preventDefault();
    if (!user) return;
    const c = card.trim() ? card.trim().padStart(4, '0') : null;
    if (c && !/^\d{4}$/.test(c)) return setError('A card number is 4 digits, e.g. 0012.');
    if (c && taken.has(c)) return setError(`Card ${c} already belongs to someone. Use ${nextFreeCard(taken)}.`);
    setBusy(true);
    try {
      await addRecord(firebase().db, farm.id, 'farmers', user.uid, { name: name.trim(), phone: phone.trim(), village: village.trim(), card: c });
      onClose();
    } catch (e) {
      setError(saveError((e as { code?: string }).code));
      setBusy(false);
    }
  }

  return (
    <Dialog title="Add supplier" onClose={onClose}>
      <form className="stack" onSubmit={save}>
        <label className="field">
          <span>Farmer’s name</span>
          <input className="input" required value={name} onChange={(e) => setName(e.target.value)} autoFocus />
        </label>
        <label className="field">
          <span>Phone (for SMS receipts)</span>
          <input className="input" type="tel" required value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+256 7XX XXX XXX" />
        </label>
        <label className="field">
          <span>Village</span>
          <input className="input" value={village} onChange={(e) => setVillage(e.target.value)} />
        </label>
        <label className="field">
          <span>Card number (4 digits)</span>
          <input className="input" inputMode="numeric" maxLength={4} value={card} onChange={(e) => setCard(e.target.value.replace(/\D/g, ''))} />
          <span className="small muted">Easy to remember. Each card number belongs to one person only.</span>
        </label>
        {error && <p className="error-text">{error}</p>}
        <SaveHint canSave={canSave} online={online} />
        <div className="actions">
          <button type="button" className="btn outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn" disabled={busy || !canSave}>
            {busy ? 'Saving…' : 'Add supplier'}
          </button>
        </div>
      </form>
    </Dialog>
  );
}

function SupplierDetail({ f, deliveries, onClose }: { f: FarmRecord<FarmerBody>; deliveries: FarmRecord<DeliveryBody>[]; onClose: () => void }) {
  const mine = deliveries.filter((d) => d.body.farmerId === f.id).sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime());
  const ok = mine.filter((d) => d.body.test !== 'failed');
  const total = ok.reduce((t, d) => t + (Number(d.body.litres) || 0), 0);
  return (
    <Dialog title={f.body.name} onClose={onClose}>
      <div className="row">
        <span className="avatar lg">{initials(f.body.name)}</span>
        <div className="stack" style={{ gap: 'var(--s-xxs)' }}>
          <span>{f.body.phone}</span>
          <span className="small muted">{f.body.village || 'Village not set'}</span>
          {f.body.card && <span className="chip brand">Card {f.body.card}</span>}
        </div>
      </div>
      <div className="grid">
        <div className="card flat stat">
          <span className="label">Brought this month</span>
          <span className="value">{litres(total)}</span>
          <span className="hint">{ok.length} deliveries</span>
        </div>
        <div className="card flat stat">
          <span className="label">Rejected</span>
          <span className="value">{mine.length - ok.length}</span>
        </div>
      </div>
      <h3>Deliveries</h3>
      {mine.length === 0 ? (
        <p className="small muted">No deliveries this month.</p>
      ) : (
        <div className="list">
          {mine.slice(0, 20).map((d) => (
            <div key={d.id} className="list-row small">
              <span className="grow">
                {shortDate(recordDate(d, 'at'))} {time(recordDate(d, 'at'))} · {words(d.body.session)}
              </span>
              <span className="num">{litres(d.body.litres)}</span>
              {d.body.test === 'failed' && <span className="chip bad">{words(d.body.rejectReason) || 'Rejected'}</span>}
            </div>
          ))}
        </div>
      )}
    </Dialog>
  );
}

/** Milk suppliers of a collection centre (Section E). */
export default function Farmers() {
  const farm = useFarm();
  const { canSave } = useSession();
  const now = new Date();
  const monthFrom = startOfMonth(now);
  const farmers = useRecords<FarmerBody>(farm.id, 'farmers');
  const staff = useRecords<StaffBody>(farm.id, 'staff');
  const deliveries = useRecords<DeliveryBody>(farm.id, 'deliveries', localIso(monthFrom));
  const [q, setQ] = useState('');
  const [adding, setAdding] = useState(false);
  const [open, setOpen] = useState<FarmRecord<FarmerBody> | null>(null);

  const taken = new Set<string>([
    ...farmers.data.map((f) => f.body.card ?? '').filter(Boolean),
    ...staff.data.map((s) => s.body.cardNumber ?? '').filter(Boolean),
  ]);
  const accepted = (id: string) => deliveries.data.filter((d) => d.body.farmerId === id && d.body.test !== 'failed');
  const monthL = (id: string) => accepted(id).reduce((t, d) => t + (Number(d.body.litres) || 0), 0);
  const todayL = (id: string) => accepted(id).filter((d) => sameDay(recordDate(d, 'at'), now)).reduce((t, d) => t + (Number(d.body.litres) || 0), 0);
  const rejected = (id: string) => deliveries.data.filter((d) => d.body.farmerId === id && d.body.test === 'failed').length;
  const list = [...farmers.data].sort((a, b) => monthL(b.id) - monthL(a.id));
  const shown = list.filter((f) => !q || `${f.body.name} ${f.body.phone} ${f.body.village ?? ''} ${f.body.card ?? ''}`.toLowerCase().includes(q.toLowerCase()));
  const totalToday = farmers.data.reduce((t, f) => t + todayL(f.id), 0);
  const totalMonth = farmers.data.reduce((t, f) => t + monthL(f.id), 0);
  const broughtToday = farmers.data.filter((f) => todayL(f.id) > 0).length;

  const csv = () =>
    downloadCsv(
      `${farm.name}-suppliers-${dayKey(now)}`,
      ['Name', 'Phone', 'Village', 'Card', 'Litres today', 'Litres this month', 'Rejected this month'],
      shown.map((f) => [f.body.name, f.body.phone, f.body.village ?? '', f.body.card ?? '', todayL(f.id), monthL(f.id), rejected(f.id)]),
    );

  return (
    <>
      <PageHead title="Suppliers" subtitle={`Farmers who bring milk · ${date(monthFrom)} to today`}>
        <SearchBox value={q} onChange={setQ} placeholder="Search name, phone, card" />
        <ExportButtons onCsv={csv} />
        <button className="btn sm" onClick={() => setAdding(true)} disabled={!canSave}>
          <Icon name="plus" /> Add supplier
        </button>
      </PageHead>
      <LoadError code={farmers.error ?? deliveries.error} />

      <div className="grid">
        <Stat icon="truck" label="Collected today" value={litres(totalToday)} hint={`${broughtToday} of ${farmers.data.length} suppliers`} tone="info" />
        <Stat icon="calendar" label="This month" value={litres(totalMonth)} />
        <Stat icon="farmers" label="Suppliers" value={count(farmers.data.length)} tone="gold" />
      </div>

      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Phone</th>
              <th>Village</th>
              <th>Card</th>
              <th className="r">Today</th>
              <th className="r">This month</th>
              <th className="r">Rejected</th>
            </tr>
          </thead>
          <tbody>
            {shown.map((f) => (
              <tr key={f.id} onClick={() => setOpen(f)} style={{ cursor: 'pointer' }}>
                <td>
                  <strong>{f.body.name}</strong>
                </td>
                <td>{f.body.phone}</td>
                <td>{f.body.village || '–'}</td>
                <td>{f.body.card || '–'}</td>
                <td className="r">{todayL(f.id) ? litres(todayL(f.id)) : '–'}</td>
                <td className="r">{litres(monthL(f.id))}</td>
                <td className="r">{rejected(f.id) || '–'}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {!farmers.loading && shown.length === 0 && <Empty>{farmers.data.length ? 'No supplier matches.' : 'No suppliers yet. Add the farmers who bring you milk.'}</Empty>}
      </div>

      {adding && <AddSupplier onClose={() => setAdding(false)} taken={taken} />}
      {open && <SupplierDetail f={open} deliveries={deliveries.data} onClose={() => setOpen(null)} />}
    </>
  );
}
