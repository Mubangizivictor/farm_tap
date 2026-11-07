'use client';

import { useState } from 'react';
import { CallButtons } from '@/components/farm';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { CardHead, ConfirmDialog, Empty, Field, FormDialog, LoadError, PageHead, SkelCard, Tabs, useSave, useToast } from '@/components/ui';
import { addDays, dayKey, localIso, parseDate, startOfDay } from '@/lib/dates';
import { addRecord, mergeBody, putRecord, removeRecord, useRecords } from '@/lib/data';
import {
  alive,
  awayOn,
  contactKindName,
  dutyActivities,
  dutyLabel,
  dutyName,
  manages,
  onDay,
  shiftName,
  weekDays,
  whoIsOn,
  type AbsenceBody,
  type ContactBody,
  type DutyBody,
  type FarmRecord,
  type StaffBody,
} from '@/lib/domain';
import { firebase } from '@/lib/firebase';
import { personPhotoSrc } from '@/lib/images';
import { shortDate, weekday } from '@/lib/format';
import { useFarm, useSession } from '@/lib/session';
import { useOpenFromUrl } from '@/lib/useOpen';
import { Avatar } from '@/components/Avatar';

const shifts = ['morning', 'afternoon', 'evening', 'night', 'allDay'] as const;
/** The contact a job usually needs: the vet for health, the feed supplier for feeding. */
const jobContact: Record<string, string> = { health: 'vet', feeding: 'feedSupplier', collection: 'milkBuyer' };

function DutyForm({ d, staff, contacts, onClose }: { d?: FarmRecord<DutyBody>; staff: FarmRecord<StaffBody>[]; contacts: FarmRecord<ContactBody>[]; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const b = d?.body;
  const [f, setF] = useState({
    activity: b?.activity ?? 'milking',
    label: b?.label ?? '',
    staffId: b?.staffId ?? staff[0]?.id ?? '',
    standInId: b?.standInId ?? '',
    days: b?.days ?? ([] as number[]),
    shift: b?.shift ?? 'morning',
    note: b?.note ?? '',
    contactId: b?.contactId ?? '',
  });
  const { busy, error, setError, run } = useSave();

  async function save() {
    if (!user) return;
    if (!f.staffId) return setError('Choose who is on duty.');
    if (f.standInId && f.standInId === f.staffId) return setError('The stand-in must be someone else.');
    if (f.activity === 'other' && !f.label.trim()) return setError('Type the job.');
    const body = {
      activity: f.activity,
      label: f.activity === 'other' ? f.label.trim() : null,
      staffId: f.staffId,
      standInId: f.standInId || null,
      days: [...f.days].sort(),
      shift: f.shift,
      note: f.note.trim() || null,
      contactId: f.contactId || null,
    };
    const { db } = firebase();
    const ok = await run(() => (d ? putRecord(db, farm.id, d, user.uid, mergeBody(d, body)) : addRecord(db, farm.id, 'duties', user.uid, body)));
    if (ok) {
      toast('Duty saved. Workers see it on their roster.');
      onClose();
    }
  }

  const dayToggle = (i: number) => setF({ ...f, days: f.days.includes(i) ? f.days.filter((x) => x !== i) : [...f.days, i] });

  return (
    <FormDialog title={d ? 'Change duty' : 'Add duty'} subtitle="Who does a job, when, and who covers when they are away." onClose={onClose} onSubmit={save} busy={busy} error={error} canSave={canSave} online={online} submit="Save duty" size="lg">
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Job">
          <select className="input" value={f.activity} onChange={(e) => setF({ ...f, activity: e.target.value })}>
            {dutyActivities.map((a) => (
              <option key={a} value={a}>
                {dutyName[a]}
              </option>
            ))}
            <option value="other">Other…</option>
          </select>
        </Field>
        {f.activity === 'other' && (
          <Field label="Which job">
            <input className="input" value={f.label} onChange={(e) => setF({ ...f, label: e.target.value })} placeholder="e.g. Spraying, fencing" />
          </Field>
        )}
        <Field label="Shift">
          <select className="input" value={f.shift} onChange={(e) => setF({ ...f, shift: e.target.value as DutyBody['shift'] })}>
            {shifts.map((s) => (
              <option key={s} value={s}>
                {shiftName[s]}
              </option>
            ))}
          </select>
        </Field>
        <Field label={f.activity === 'manager' ? 'In charge' : 'On duty'}>
          <select className="input" value={f.staffId} onChange={(e) => setF({ ...f, staffId: e.target.value })}>
            {staff.map((s) => (
              <option key={s.id} value={s.id}>
                {s.body.name}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Stand-in when away" hint="Takes over by themselves when the person is marked away.">
          <select className="input" value={f.standInId} onChange={(e) => setF({ ...f, standInId: e.target.value })}>
            <option value="">Nobody</option>
            {staff
              .filter((s) => s.id !== f.staffId)
              .map((s) => (
                <option key={s.id} value={s.id}>
                  {s.body.name}
                </option>
              ))}
          </select>
        </Field>
        {contacts.length > 0 && (
          <Field label="Who to call for this job (optional)">
            <select className="input" value={f.contactId} onChange={(e) => setF({ ...f, contactId: e.target.value })}>
              <option value="">Nobody</option>
              {contacts.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.body.name} · {contactKindName[c.body.kind as keyof typeof contactKindName] ?? c.body.kind}
                </option>
              ))}
            </select>
          </Field>
        )}
      </Fit>
      <Field label="Days" hint="None ticked = every day.">
        <div className="chips" role="group">
          {weekDays.map((w, i) => (
            <button type="button" key={w} className={`chip ${f.days.includes(i) ? 'brand' : ''}`} aria-pressed={f.days.includes(i)} onClick={() => dayToggle(i)}>
              {w}
            </button>
          ))}
        </div>
      </Field>
      <Field label="Note (optional)">
        <input className="input" value={f.note} onChange={(e) => setF({ ...f, note: e.target.value })} placeholder="e.g. Milking at 5 am and 4 pm; wash the cans" maxLength={200} />
      </Field>
    </FormDialog>
  );
}

function AwayForm({ staff, onClose }: { staff: FarmRecord<StaffBody>[]; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const today = dayKey(new Date());
  const [f, setF] = useState({ staffId: staff[0]?.id ?? '', from: today, to: today, reason: 'leave' });
  const { busy, error, setError, run } = useSave();
  async function save() {
    if (!user) return;
    const from = parseDate(f.from);
    const to = parseDate(f.to);
    if (!f.staffId) return setError('Choose who is away.');
    if (!from || !to || to < from) return setError('The last day must be on or after the first day.');
    const ok = await run(() => addRecord(firebase().db, farm.id, 'absences', user.uid, { staffId: f.staffId, from: localIso(from), to: localIso(to), reason: f.reason }));
    if (ok) {
      toast('Saved. Their stand-ins take over on those days.');
      onClose();
    }
  }
  return (
    <FormDialog title="Mark someone away" subtitle="Their stand-in covers their duties on these days." onClose={onClose} onSubmit={save} busy={busy} error={error} canSave={canSave} online={online} submit="Save">
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Who">
          <select className="input" value={f.staffId} onChange={(e) => setF({ ...f, staffId: e.target.value })}>
            {staff.map((s) => (
              <option key={s.id} value={s.id}>
                {s.body.name}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Why">
          <select className="input" value={f.reason} onChange={(e) => setF({ ...f, reason: e.target.value })}>
            <option value="leave">Leave</option>
            <option value="sick">Sick</option>
            <option value="off">Day off</option>
            <option value="other">Other</option>
          </select>
        </Field>
        <Field label="From">
          <input className="input" type="date" value={f.from} onChange={(e) => setF({ ...f, from: e.target.value, to: e.target.value > f.to ? e.target.value : f.to })} />
        </Field>
        <Field label="To (last day away)">
          <input className="input" type="date" min={f.from} value={f.to} onChange={(e) => setF({ ...f, to: e.target.value })} />
        </Field>
      </Fit>
    </FormDialog>
  );
}

type Tab = 'today' | 'week' | 'away';

/** Duty roster (decision 0023): everyone on the farm sees who does what, and who covers. */
export default function Roster() {
  const farm = useFarm();
  const { user, canSave } = useSession();
  const toast = useToast();
  const boss = manages(farm);
  const now = new Date();
  const duties = useRecords<DutyBody>(farm.id, 'duties');
  const staff = useRecords<StaffBody>(farm.id, 'staff');
  const contacts = useRecords<ContactBody>(farm.id, 'contacts');
  const absences = useRecords<AbsenceBody>(farm.id, 'absences');
  const [tab, setTab] = useState<Tab>('today');
  const [adding, setAdding] = useOpenFromUrl();
  const [editing, setEditing] = useState<FarmRecord<DutyBody> | null>(null);
  const [marking, setMarking] = useState(false);
  const [removing, setRemoving] = useState<FarmRecord<DutyBody> | FarmRecord<AbsenceBody> | null>(null);
  const del = useSave();

  const people = alive(staff.data)
    .filter((s) => s.body.active !== false)
    .sort((a, b) => a.body.name.localeCompare(b.body.name));
  const person = (id: string | null | undefined) => people.find((s) => s.id === id);
  const shared = alive(contacts.data).filter((c) => boss || c.body.showWorkers !== false);
  const list = alive(duties.data);
  const away = awayOn(absences.data, now);
  const today = list.filter((d) => onDay(d.body, now)).sort((a, b) => shifts.indexOf(a.body.shift) - shifts.indexOf(b.body.shift));
  const boss1 = today.find((d) => d.body.activity === 'manager');
  const inCharge = boss1 ? whoIsOn(boss1.body, away) : null;
  const managers = people.filter((s) => s.body.role === 'manager');
  const contactFor = (d: DutyBody) => shared.find((c) => c.id === d.contactId) ?? shared.find((c) => c.body.kind === jobContact[d.activity]);
  const upcoming = alive(absences.data)
    .filter((a) => (parseDate(a.body.to) ?? new Date(0)) >= startOfDay(now))
    .sort((a, b) => (parseDate(a.body.from)?.getTime() ?? 0) - (parseDate(b.body.from)?.getTime() ?? 0));
  const loading = duties.loading || staff.loading;
  const vet = shared.find((c) => c.body.kind === 'vet');
  const feedSup = shared.find((c) => c.body.kind === 'feedSupplier');
  const week = Array.from({ length: 7 }, (_, i) => addDays(startOfDay(now), i));

  return (
    <>
      <PageHead title="Duty roster" subtitle="Who does what today, and who covers when someone is away. Every worker sees this.">
        {boss && (
          <button className="btn sm outline" onClick={() => setMarking(true)} disabled={!canSave || people.length === 0}>
            <Icon name="calendar" /> Mark away
          </button>
        )}
        {boss && (
          <button className="btn sm" onClick={() => setAdding(true)} disabled={!canSave || people.length === 0} title={people.length ? undefined : 'Add workers first'}>
            <Icon name="plus" /> Add duty
          </button>
        )}
      </PageHead>
      <LoadError code={duties.error ?? staff.error} />

      <section className="card in-charge">
        <div className="row wrap">
          <div className="icon-chip">
            <Icon name="shield" />
          </div>
          <div className="grow stack" style={{ gap: 0 }}>
            <span className="small muted">In charge today</span>
            <strong>
              {inCharge?.staffId
                ? person(inCharge.staffId)?.body.name
                : managers.filter((m) => !away.has(m.id))[0]?.body.name ?? (boss1 ? 'Nobody: the manager and stand-in are away' : 'The owner')}
            </strong>
            {inCharge?.covering && <span className="small">Covering for {person(boss1?.body.staffId)?.body.name} (away)</span>}
          </div>
          {(() => {
            const p = inCharge?.staffId ? person(inCharge.staffId) : managers.find((m) => !away.has(m.id));
            const phone = p?.body.phone || (!p ? farm.whatsapp : '');
            return phone ? <CallButtons phone={phone} /> : null;
          })()}
        </div>
      </section>

      <Fit kind="cards" cols={[1, 2, 3, 3]}>
        {[
          vet && { label: 'Vet', c: vet },
          feedSup && { label: 'Feed supplier', c: feedSup },
          ...managers.slice(0, 1).map((m) => ({ label: 'Manager', c: { id: m.id, body: { name: m.body.name, phone: m.body.phone ?? '', kind: 'manager' } } })),
        ]
          .filter(Boolean)
          .map((x) => {
            const k = x as { label: string; c: { id: string; body: { name: string; phone: string } } };
            return (
              <section key={k.c.id} className="card row wrap key-contact">
                <div className="grow stack" style={{ gap: 0 }}>
                  <span className="small muted">{k.label}</span>
                  <strong>{k.c.body.name}</strong>
                  <span className="small mono">{k.c.body.phone || 'No phone'}</span>
                </div>
                {k.c.body.phone && <CallButtons phone={k.c.body.phone} compact />}
              </section>
            );
          })}
      </Fit>

      <Tabs
        label="Roster"
        value={tab}
        onChange={setTab}
        items={[
          ['today', `Today, ${weekday(now)}`, today.length],
          ['week', 'This week'],
          ['away', 'Away', upcoming.length],
        ]}
      />

      {tab === 'today' &&
        (loading ? (
          <SkelCard lines={4} />
        ) : today.length === 0 ? (
          <Empty
            icon="calendar"
            action={
              boss &&
              canSave &&
              people.length > 0 && (
                <button className="btn sm" onClick={() => setAdding(true)}>
                  <Icon name="plus" /> Add the first duty
                </button>
              )
            }
          >
            {list.length ? 'No duties for today.' : 'No duties yet. Add who milks, who feeds and who looks after animal health, with a stand-in for each.'}
          </Empty>
        ) : (
          <div className="duty-grid">
            {today.map((d) => {
              const on = whoIsOn(d.body, away);
              const p = person(on.staffId);
              const c = contactFor(d.body);
              const mine = !!p && !!user && (p.body.phone ?? '').replace(/\D/g, '').slice(-9) === (user.phoneNumber ?? '-').replace(/\D/g, '').slice(-9);
              return (
                <article key={d.id} className={`card duty-card stack ${on.covering ? 'covering' : ''} ${!p ? 'gap' : ''} ${mine ? 'mine' : ''}`}>
                  <div className="row between">
                    <strong>{dutyLabel(d.body)}</strong>
                    <span className="chip">{shiftName[d.body.shift]}</span>
                  </div>
                  <div className="row">
                    <Avatar photo={p ? personPhotoSrc(p.body) : null} name={p?.body.name} />
                    <div className="grow stack" style={{ gap: 0 }}>
                      <strong>{p?.body.name ?? 'Nobody'}</strong>
                      <span className="small muted">
                        {on.covering
                          ? `Standing in for ${person(d.body.staffId)?.body.name ?? 'someone'} (away)`
                          : !p
                            ? 'Everyone on this duty is away. Find cover.'
                            : d.body.standInId
                              ? `Stand-in: ${person(d.body.standInId)?.body.name ?? '–'}`
                              : 'No stand-in set'}
                      </span>
                    </div>
                    {p?.body.phone && <CallButtons phone={p.body.phone} compact />}
                  </div>
                  {d.body.note && <p className="small">{d.body.note}</p>}
                  {c && (
                    <div className="row small call-line">
                      <span className="grow muted">
                        Call: {c.body.name}
                        {c.body.org ? ` · ${c.body.org}` : ''}
                      </span>
                      <CallButtons phone={c.body.phone} compact />
                    </div>
                  )}
                  {boss && canSave && (
                    <div className="row">
                      <span className="grow" />
                      <button className="icon-btn" aria-label="Change duty" onClick={() => setEditing(d)}>
                        <Icon name="edit" />
                      </button>
                      <button className="icon-btn" aria-label="Remove duty" onClick={() => setRemoving(d)}>
                        <Icon name="close" />
                      </button>
                    </div>
                  )}
                </article>
              );
            })}
          </div>
        ))}

      {tab === 'week' && (
        <div className="table-wrap">
          <table className="table roster-week">
            <thead>
              <tr>
                <th>Job</th>
                {week.map((d) => (
                  <th key={d.toISOString()}>{weekday(d).slice(0, 3)}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {list.map((d) => (
                <tr key={d.id}>
                  <td className="lead">
                    <strong>{dutyLabel(d.body)}</strong>
                    <div className="small muted">{shiftName[d.body.shift]}</div>
                  </td>
                  {week.map((day) => {
                    if (!onDay(d.body, day)) return <td key={day.toISOString()} className="muted">–</td>;
                    const on = whoIsOn(d.body, awayOn(absences.data, day));
                    return (
                      <td key={day.toISOString()} className={on.covering ? 'covering' : !on.staffId ? 'gap' : ''}>
                        {person(on.staffId)?.body.name.split(' ')[0] ?? 'Nobody'}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
          {list.length === 0 && <Empty icon="calendar">No duties yet.</Empty>}
        </div>
      )}

      {tab === 'away' && (
        <section className="card">
          <CardHead title="Away now and coming up" />
          {upcoming.length === 0 ? (
            <Empty icon="workers">Nobody is marked away.</Empty>
          ) : (
            <div className="list">
              {upcoming.map((a) => (
                <div key={a.id} className="list-row wrap">
                  <strong className="grow">{person(a.body.staffId)?.body.name ?? 'Removed worker'}</strong>
                  <span className="small">
                    {shortDate(parseDate(a.body.from))} to {shortDate(parseDate(a.body.to))} · {a.body.reason ?? 'away'}
                  </span>
                  {boss && canSave && (
                    <button className="icon-btn" aria-label="Remove" onClick={() => setRemoving(a)}>
                      <Icon name="close" />
                    </button>
                  )}
                </div>
              ))}
            </div>
          )}
        </section>
      )}

      {adding && <DutyForm staff={people} contacts={shared} onClose={() => setAdding(false)} />}
      {editing && <DutyForm d={editing} staff={people} contacts={shared} onClose={() => setEditing(null)} />}
      {marking && <AwayForm staff={people} onClose={() => setMarking(false)} />}
      {removing && (
        <ConfirmDialog
          title="Remove this?"
          confirm="Remove"
          danger
          busy={del.busy}
          error={del.error}
          onClose={() => setRemoving(null)}
          onConfirm={async () => {
            if (!user) return;
            if (await del.run(() => removeRecord(firebase().db, farm.id, removing, user.uid))) {
              toast('Removed');
              setRemoving(null);
            }
          }}
        >
          Workers stop seeing it on their roster.
        </ConfirmDialog>
      )}
    </>
  );
}
