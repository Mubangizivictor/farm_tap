'use client';

import Link from 'next/link';
import { Icon } from '@/components/Icon';
import { Change, ExportButtons, LoadError, PageHead, Stat } from '@/components/ui';
import { MilkChart } from '@/components/MilkChart';
import { addDays, localIso, parseDate, sameDay, startOfDay } from '@/lib/dates';
import { useRecords } from '@/lib/data';
import {
  alive,
  animalLabel,
  change,
  dailyLitres,
  hasHerd,
  inWithdrawal,
  isActiveAnimal,
  isCentre,
  isMilker,
  litresBetween,
  manages,
  monthRange,
  planState,
  recordDate,
  safeFrom,
  sessionLitres,
  sumAmount,
  type AnimalBody,
  type AttendanceBody,
  type DeliveryBody,
  type ExpenseBody,
  type FarmerBody,
  type MilkBody,
  type MilkSaleBody,
  type StaffBody,
  type TreatmentBody,
} from '@/lib/domain';
import { count, firstName, greeting, litres, longDate, shortDate, time, ugx, words } from '@/lib/format';
import { useFarm, useSession } from '@/lib/session';

export default function Home() {
  const farm = useFarm();
  const { user } = useSession();
  const now = new Date();
  const today = startOfDay(now);
  const { from: monthFrom, to: monthTo, prevFrom } = monthRange(now);
  // One read window for everything: from the start of last month.
  const since = localIso(prevFrom);
  const herdFarm = hasHerd(farm);
  const centre = isCentre(farm);
  const boss = manages(farm);

  const milk = useRecords<MilkBody>(herdFarm ? farm.id : null, 'milkRecords', since);
  const animals = useRecords<AnimalBody>(herdFarm ? farm.id : null, 'animals');
  const treatments = useRecords<TreatmentBody>(herdFarm ? farm.id : null, 'treatments', localIso(addDays(today, -90)));
  const expenses = useRecords<ExpenseBody>(boss ? farm.id : null, 'expenses', since);
  const sales = useRecords<MilkSaleBody>(boss && herdFarm ? farm.id : null, 'milkSales', localIso(monthFrom));
  const staff = useRecords<StaffBody>(farm.id, 'staff');
  const attendance = useRecords<AttendanceBody>(farm.id, 'attendance', localIso(today));
  const deliveries = useRecords<DeliveryBody>(centre ? farm.id : null, 'deliveries', since);
  const farmers = useRecords<FarmerBody>(centre ? farm.id : null, 'farmers');

  const m = (() => {
    const days = dailyLitres(milk.data, now, 14);
    const todayL = litresBetween(milk.data, today, addDays(today, 1));
    const split = sessionLitres(milk.data, today);
    const monthL = litresBetween(milk.data, monthFrom, monthTo);
    // Fair comparison: last month up to the same day of the month.
    const prevSameDay = new Date(prevFrom.getFullYear(), prevFrom.getMonth(), now.getDate() + 1);
    const prevL = litresBetween(milk.data, prevFrom, prevSameDay < monthFrom ? prevSameDay : monthFrom);
    const herd = animals.data.filter(isActiveAnimal);
    const milkers = herd.filter(isMilker);
    const withdrawal = treatments.data.filter((t) => inWithdrawal(t.body, now));
    const withdrawalIds = new Set(withdrawal.map((t) => t.body.animalId));
    const spent = sumAmount(expenses.data, monthFrom, monthTo);
    const prevSpent = sumAmount(expenses.data, prevFrom, monthFrom);
    const income = alive(sales.data).reduce((t, s) => t + (Number(s.body.litres) || 0) * (Number(s.body.pricePerLitre) || 0), 0);
    const activeStaff = staff.data.filter((s) => s.body.active !== false);
    const present = new Set(
      attendance.data.filter((a) => sameDay(parseDate(a.body.inAt ?? a.body.at) ?? recordDate(a), now)).map((a) => a.body.staffId),
    );
    const todayDel = deliveries.data.filter((d) => sameDay(recordDate(d, 'at'), now));
    const accepted = todayDel.filter((d) => d.body.test !== 'failed');
    const collectedToday = accepted.reduce((t, d) => t + (Number(d.body.litres) || 0), 0);
    const rejectedToday = todayDel.filter((d) => d.body.test === 'failed');
    const collectedMonth = deliveries.data
      .filter((d) => d.body.test !== 'failed' && recordDate(d, 'at') >= monthFrom)
      .reduce((t, d) => t + (Number(d.body.litres) || 0), 0);
    const suppliersToday = new Set(accepted.map((d) => d.body.farmerId)).size;
    return {
      days, todayL, split, monthL, prevL, herd, milkers, withdrawal, withdrawalIds, spent, prevSpent, income,
      activeStaff, present, collectedToday, rejectedToday, collectedMonth, suppliersToday,
    };
  })();

  const plan = planState(farm.subscription, now);
  const animalName = (id: string) => {
    const a = animals.data.find((x) => x.id === id);
    return a ? animalLabel(a) : 'A cow';
  };
  const farmerName = (id: string) => farmers.data.find((f) => f.id === id)?.body.name ?? 'A farmer';

  // Things the owner should act on, most urgent first.
  const alerts: { tone: 'bad' | 'warn' | 'info'; icon: 'alert' | 'health' | 'clock' | 'lock' | 'drop'; text: string; href?: string }[] = [];
  if (plan.kind === 'trial' && plan.daysLeft <= 2)
    alerts.push({ tone: 'warn', icon: 'clock', text: `Free trial ends ${plan.daysLeft <= 0 ? 'today' : `in ${plan.daysLeft} day${plan.daysLeft === 1 ? '' : 's'}`}. Pay to keep recording.`, href: '/settings/' });
  for (const t of m.withdrawal.slice(0, 5)) {
    alerts.push({
      tone: 'bad',
      icon: 'health',
      text: `${t.body.animalName || animalName(t.body.animalId)}: milk not for sale until ${shortDate(safeFrom(t.body))} (${words(t.body.condition)}).`,
      href: '/health/',
    });
  }
  if (herdFarm && !milk.loading && m.todayL === 0 && now.getHours() >= 10)
    alerts.push({ tone: 'warn', icon: 'drop', text: 'No milk recorded yet today.', href: '/milk/' });
  if (m.rejectedToday.length)
    alerts.push({ tone: 'warn', icon: 'alert', text: `${m.rejectedToday.length} delivery${m.rejectedToday.length === 1 ? '' : 'ies'} rejected today.`, href: '/farmers/' });
  if (farm.reviewStatus === 'pending')
    alerts.push({ tone: 'info', icon: 'alert', text: 'FarmTap is checking your new farm. Everything works while you wait.' });

  const absent = m.activeStaff.filter((s) => !m.present.has(s.id));

  return (
    <>
      <PageHead
        title={`${greeting(now)}${firstName(user?.displayName) ? `, ${firstName(user?.displayName)}` : ''}`}
        subtitle={`${longDate(now)} · ${farm.name}`}
      >
        <ExportButtons />
      </PageHead>

      <LoadError code={milk.error ?? animals.error ?? deliveries.error ?? staff.error} />

      <div className="grid">
        {herdFarm && (
          <Stat
            icon="drop"
            label="Milk today"
            value={litres(m.todayL)}
            hint={`Morning ${litres(m.split.morning)} · Evening ${litres(m.split.evening)}`}
          />
        )}
        {herdFarm && (
          <Stat
            icon="calendar"
            label="Milk this month"
            value={litres(m.monthL)}
            hint={
              <>
                <Change pct={change(m.monthL, m.prevL)} /> {m.prevL > 0 ? 'vs same days last month' : 'First month on FarmTap'}
              </>
            }
          />
        )}
        {centre && (
          <Stat
            icon="truck"
            label="Collected today"
            value={litres(m.collectedToday)}
            hint={`${count(m.suppliersToday)} supplier${m.suppliersToday === 1 ? '' : 's'} · ${m.rejectedToday.length} rejected`}
            tone="info"
          />
        )}
        {centre && <Stat icon="calendar" label="Collected this month" value={litres(m.collectedMonth)} hint={`${count(farmers.data.length)} suppliers registered`} tone="info" />}
        {herdFarm && (
          <Stat
            icon="cow"
            label="Herd"
            value={count(m.herd.length)}
            unit="animals"
            hint={`${count(m.milkers.length)} milking · ${count(m.herd.filter((a) => a.body.dairyStatus === 'dry').length)} dry · ${count(m.herd.filter((a) => a.body.dairyStatus === 'calf').length)} calves`}
          />
        )}
        {herdFarm && (
          <Stat
            icon="health"
            label="Not for sale"
            value={count(m.withdrawalIds.size)}
            unit={m.withdrawalIds.size === 1 ? 'cow' : 'cows'}
            hint={m.withdrawalIds.size ? 'Drug withdrawal: keep their milk apart' : 'All milk can be sold'}
            tone={m.withdrawalIds.size ? 'bad' : undefined}
          />
        )}
        <Stat
          icon="workers"
          label="Workers today"
          value={`${count(m.present.size)} / ${count(m.activeStaff.length)}`}
          hint={m.activeStaff.length ? (absent.length ? `${absent.length} not in yet` : 'Everyone is in') : 'No workers added yet'}
          tone="gold"
        />
        {boss && (
          <Stat
            icon="money"
            label="Spent this month"
            value={ugx(m.spent)}
            hint={
              <>
                <Change pct={change(m.spent, m.prevSpent)} goodWhenUp={false} /> {m.income > 0 ? `Milk sales ${ugx(m.income)}` : 'vs last month'}
              </>
            }
            tone="warn"
          />
        )}
      </div>

      <div className="grid cols">
        {herdFarm && (
          <section className="card">
            <div className="card-head">
              <h2>Milk, last 14 days</h2>
              <Link href="/milk/" className="small no-print">
                All milk records
              </Link>
            </div>
            <MilkChart days={m.days} />
          </section>
        )}

        <section className="card">
          <div className="card-head">
            <h2>Needs your attention</h2>
          </div>
          {alerts.length === 0 ? (
            <div className="row muted">
              <Icon name="check" /> Nothing needs you right now.
            </div>
          ) : (
            <div className="list">
              {alerts.map((a, i) => (
                <div key={i} className="list-row">
                  <span className={`chip ${a.tone === 'info' ? 'brand' : a.tone}`}>
                    <Icon name={a.icon} className="icon" />
                  </span>
                  <span className="grow">{a.text}</span>
                  {a.href && (
                    <Link href={a.href} className="no-print" aria-label="Open">
                      <Icon name="chevron" />
                    </Link>
                  )}
                </div>
              ))}
            </div>
          )}
        </section>

        <section className="card">
          <div className="card-head">
            <h2>Workers today</h2>
            <Link href="/workers/" className="small no-print">
              All workers
            </Link>
          </div>
          {m.activeStaff.length === 0 ? (
            <p className="muted">Add workers on the farm phone (Settings → Staff). They appear here.</p>
          ) : (
            <div className="list">
              {m.activeStaff.slice(0, 8).map((s) => {
                const a = attendance.data.find((x) => x.body.staffId === s.id);
                const inAt = a ? parseDate(a.body.inAt ?? a.body.at) ?? recordDate(a) : null;
                return (
                  <div key={s.id} className="list-row">
                    <span className="avatar">{s.body.name.slice(0, 1).toUpperCase()}</span>
                    <div className="grow">
                      <div>{s.body.name}</div>
                      <div className="small muted">{s.body.title || words(s.body.role)}</div>
                    </div>
                    {inAt ? <span className="chip ok">In {time(inAt)}</span> : <span className="chip">Not in</span>}
                  </div>
                );
              })}
            </div>
          )}
        </section>

        {centre && (
          <section className="card">
            <div className="card-head">
              <h2>Latest deliveries</h2>
              <Link href="/farmers/" className="small no-print">
                All suppliers
              </Link>
            </div>
            {deliveries.data.length === 0 ? (
              <p className="muted">No deliveries yet. They appear here as the centre phone records them.</p>
            ) : (
              <div className="list">
                {[...deliveries.data]
                  .sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime())
                  .slice(0, 8)
                  .map((d) => (
                    <div key={d.id} className="list-row">
                      <span className="avatar">{farmerName(d.body.farmerId).slice(0, 1)}</span>
                      <div className="grow">
                        <div>{farmerName(d.body.farmerId)}</div>
                        <div className="small muted">
                          {shortDate(recordDate(d, 'at'))} {time(recordDate(d, 'at'))} · {words(d.body.session)}
                        </div>
                      </div>
                      <span className="num">{litres(d.body.litres)}</span>
                      {d.body.test === 'failed' && <span className="chip bad">Rejected</span>}
                    </div>
                  ))}
              </div>
            )}
          </section>
        )}
      </div>
    </>
  );
}
