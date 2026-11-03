'use client';

import { useState } from 'react';
import { Dialog, Empty, ExportButtons, LoadError, PageHead, SearchBox, Stat } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { dayKey, localIso, parseDate, sameDay, startOfMonth } from '@/lib/dates';
import { useRecords } from '@/lib/data';
import { alive, manages, recordDate, type AttendanceBody, type FarmRecord, type StaffBody, type WageBody } from '@/lib/domain';
import { count, date, initials, shortDate, time, ugx, words } from '@/lib/format';
import { useFarm } from '@/lib/session';

const inTime = (a: FarmRecord<AttendanceBody>) => parseDate(a.body.inAt ?? a.body.at) ?? recordDate(a);

function Profile({
  s,
  attendance,
  wages,
  showPay,
  onClose,
}: {
  s: FarmRecord<StaffBody>;
  attendance: FarmRecord<AttendanceBody>[];
  wages: FarmRecord<WageBody>[];
  showPay: boolean;
  onClose: () => void;
}) {
  const days = new Set(attendance.filter((a) => a.body.staffId === s.id).map((a) => dayKey(inTime(a))));
  const paid = wages.filter((w) => w.body.staffId === s.id);
  const paidTotal = paid.reduce((t, w) => t + (Number(w.body.amount) || 0), 0);
  const wage = Number(s.body.monthlyWage) || 0;
  return (
    <Dialog title={s.body.name} onClose={onClose}>
      <div className="row">
        <span className="avatar lg">{s.body.photoUrl ? <img src={s.body.photoUrl} alt="" /> : initials(s.body.name)}</span>
        <div className="stack" style={{ gap: 'var(--s-xxs)' }}>
          <strong>{s.body.title || words(s.body.role)}</strong>
          <span className="small muted">{s.body.phone || 'No phone'}</span>
          <div className="row wrap">
            {s.body.cardNumber && <span className="chip brand">Card {s.body.cardNumber}</span>}
            {s.body.since && <span className="chip">Since {date(parseDate(s.body.since))}</span>}
          </div>
        </div>
      </div>
      <div className="grid">
        <div className="card flat stat">
          <span className="label">Days in, this month</span>
          <span className="value">{days.size}</span>
        </div>
        {showPay && (
          <div className="card flat stat">
            <span className="label">Paid this month</span>
            <span className="value small">{ugx(paidTotal)}</span>
            <span className="hint">{wage ? (paidTotal >= wage ? 'Fully paid' : `${ugx(wage - paidTotal)} still to pay`) : 'No monthly wage set'}</span>
          </div>
        )}
      </div>
      {showPay && (
        <>
          <h3>Payments this month</h3>
          {paid.length === 0 ? (
            <p className="small muted">No payments yet this month.</p>
          ) : (
            <div className="list">
              {paid.map((w) => (
                <div key={w.id} className="list-row small">
                  <span className="grow">
                    {shortDate(recordDate(w, 'at'))} · {words(w.body.kind)}
                  </span>
                  <span className="num">{ugx(w.body.amount)}</span>
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </Dialog>
  );
}

/** Workers, attendance and payroll status (Section I). Workers are added on the farm phone. */
export default function Workers() {
  const farm = useFarm();
  const now = new Date();
  const monthFrom = startOfMonth(now);
  const staff = useRecords<StaffBody>(farm.id, 'staff');
  const attendance = useRecords<AttendanceBody>(farm.id, 'attendance', localIso(monthFrom));
  const boss = manages(farm);
  const wages = useRecords<WageBody>(boss ? farm.id : null, 'wages', localIso(monthFrom));
  const [q, setQ] = useState('');
  const [open, setOpen] = useState<FarmRecord<StaffBody> | null>(null);

  const active = staff.data.filter((s) => s.body.active !== false).sort((a, b) => a.body.name.localeCompare(b.body.name));
  const shown = active.filter((s) => !q || `${s.body.name} ${s.body.role} ${s.body.title ?? ''} ${s.body.phone ?? ''} ${s.body.cardNumber ?? ''}`.toLowerCase().includes(q.toLowerCase()));
  const todayIn = (id: string) => alive(attendance.data).find((a) => a.body.staffId === id && sameDay(inTime(a), now));
  const daysIn = (id: string) => new Set(attendance.data.filter((a) => a.body.staffId === id).map((a) => dayKey(inTime(a)))).size;
  const paidTo = (id: string) => wages.data.filter((w) => w.body.staffId === id).reduce((t, w) => t + (Number(w.body.amount) || 0), 0);
  const payroll = active.reduce((t, s) => t + (Number(s.body.monthlyWage) || 0), 0);
  const paidAll = active.reduce((t, s) => t + paidTo(s.id), 0);
  const presentToday = active.filter((s) => todayIn(s.id)).length;

  const csv = () =>
    downloadCsv(
      `${farm.name}-workers-${dayKey(now)}`,
      ['Name', 'Role', 'Phone', 'Card', 'Since', 'In today', 'Days in this month', ...(boss ? ['Monthly wage', 'Paid this month', 'Still to pay'] : [])],
      shown.map((s) => {
        const wage = Number(s.body.monthlyWage) || 0;
        const t = todayIn(s.id);
        return [
          s.body.name,
          s.body.title || words(s.body.role),
          s.body.phone ?? '',
          s.body.cardNumber ?? '',
          s.body.since ? dayKey(parseDate(s.body.since) ?? now) : '',
          t ? time(inTime(t)) : 'No',
          daysIn(s.id),
          ...(boss ? [wage, paidTo(s.id), Math.max(0, wage - paidTo(s.id))] : []),
        ];
      }),
    );

  return (
    <>
      <PageHead title="Workers" subtitle="Workers are added on the farm phone and sign in there with their card and PIN.">
        <SearchBox value={q} onChange={setQ} placeholder="Search name, role, card" />
        <ExportButtons onCsv={csv} />
      </PageHead>
      <LoadError code={staff.error} />

      <div className="grid">
        <Stat icon="workers" label="Workers" value={count(active.length)} tone="gold" />
        <Stat icon="clock" label="In today" value={`${presentToday} / ${active.length}`} hint={active.length - presentToday ? `${active.length - presentToday} not in yet` : 'Everyone is in'} />
        {boss && (
          <Stat
            icon="money"
            label="Payroll this month"
            value={ugx(payroll)}
            hint={payroll ? `${ugx(paidAll)} paid · ${ugx(Math.max(0, payroll - paidAll))} to pay` : 'Set wages on the phone'}
            tone="warn"
          />
        )}
      </div>

      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Role</th>
              <th>Phone</th>
              <th>Card</th>
              <th>Today</th>
              <th className="r">Days this month</th>
              {boss && <th className="r">Wage</th>}
              {boss && <th>Pay status</th>}
            </tr>
          </thead>
          <tbody>
            {shown.map((s) => {
              const t = todayIn(s.id);
              const wage = Number(s.body.monthlyWage) || 0;
              const paid = paidTo(s.id);
              return (
                <tr key={s.id} onClick={() => setOpen(s)} style={{ cursor: 'pointer' }}>
                  <td>
                    <span className="row">
                      <span className="avatar">{s.body.photoUrl ? <img src={s.body.photoUrl} alt="" /> : initials(s.body.name)}</span>
                      <strong>{s.body.name}</strong>
                    </span>
                  </td>
                  <td>{s.body.title || words(s.body.role)}</td>
                  <td>{s.body.phone || '–'}</td>
                  <td>{s.body.cardNumber || '–'}</td>
                  <td>{t ? <span className="chip ok">In {time(inTime(t))}</span> : <span className="chip">Not in</span>}</td>
                  <td className="r">{daysIn(s.id)}</td>
                  {boss && <td className="r">{wage ? ugx(wage) : '–'}</td>}
                  {boss && (
                    <td>
                      {!wage ? (
                        <span className="chip">No wage set</span>
                      ) : paid >= wage ? (
                        <span className="chip ok">Paid</span>
                      ) : paid > 0 ? (
                        <span className="chip warn">{ugx(wage - paid)} left</span>
                      ) : (
                        <span className="chip bad">Not paid</span>
                      )}
                    </td>
                  )}
                </tr>
              );
            })}
          </tbody>
        </table>
        {!staff.loading && shown.length === 0 && <Empty>{active.length ? 'No worker matches.' : 'No workers yet. Add them on the farm phone (Settings → Staff).'}</Empty>}
      </div>

      {open && <Profile s={open} attendance={attendance.data} wages={wages.data} showPay={boss} onClose={() => setOpen(null)} />}
    </>
  );
}
