'use client';

import { personPhotoSrc } from '@/lib/images';
import { HomeAi } from '@/components/aiPage';
import Link from 'next/link';
import { Fit } from '@/components/fit';
import { Icon, type IconName } from '@/components/Icon';
import { CardHead, Change, Empty, ExportButtons, LoadError, PageHead, SkelCard, SkelRows, Stat } from '@/components/ui';
import { MilkChart } from '@/components/MilkChart';
import { TodayOnFarm } from '@/components/farm';
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
  isClockIn,
  isMilker,
  litresBetween,
  manages,
  monthRange,
  planState,
  recordDate,
  safeFrom,
  saleValue,
  sessionLitres,
  sumAmount,
  taskView,
  type AnimalBody,
  type AttendanceBody,
  type DeliveryBody,
  type ExpenseBody,
  type FarmerBody,
  type IncomeBody,
  type MilkBody,
  type MilkSaleBody,
  type StaffBody,
  type TaskBody,
  type TreatmentBody,
} from '@/lib/domain';
import { count, firstName, greeting, litres, longDate, shortDate, time, ugx, words } from '@/lib/format';
import { useFarm, useSession } from '@/lib/session';
import { Avatar } from '@/components/Avatar';

export default function Home() {
  const farm = useFarm();
  const { user, canSave } = useSession();
  const now = new Date();
  const today = startOfDay(now);
  const { from: monthFrom, to: monthTo, prevFrom } = monthRange(now);
  // One read window for everything: from the start of last month.
  const since = localIso(prevFrom);
  const herdFarm = hasHerd(farm);
  const centre = isCentre(farm);
  const boss = manages(farm);

  const tasks = useRecords<TaskBody>(farm.id, 'tasks');
  const milk = useRecords<MilkBody>(herdFarm ? farm.id : null, 'milkRecords', since);
  const animals = useRecords<AnimalBody>(herdFarm ? farm.id : null, 'animals');
  const treatments = useRecords<TreatmentBody>(herdFarm ? farm.id : null, 'treatments', localIso(addDays(today, -90)));
  const expenses = useRecords<ExpenseBody>(boss ? farm.id : null, 'expenses', since);
  const sales = useRecords<MilkSaleBody>(boss && herdFarm ? farm.id : null, 'milkSales', localIso(monthFrom));
  const income = useRecords<IncomeBody>(boss ? farm.id : null, 'income', localIso(monthFrom));
  const staff = useRecords<StaffBody>(farm.id, 'staff');
  const attendance = useRecords<AttendanceBody>(farm.id, 'attendance', localIso(today));
  const deliveries = useRecords<DeliveryBody>(centre ? farm.id : null, 'deliveries', since);
  const farmers = useRecords<FarmerBody>(centre ? farm.id : null, 'farmers');

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
  const earned =
    alive(sales.data).reduce((t, s) => t + saleValue(s.body), 0) + sumAmount(income.data, monthFrom, monthTo);
  const activeStaff = staff.data.filter((s) => s.body.active !== false).sort((a, b) => a.body.name.localeCompare(b.body.name));
  const clockIns = attendance.data.filter(isClockIn).filter((a) => sameDay(parseDate(a.body.inAt ?? a.body.at) ?? recordDate(a), now));
  const present = new Set(clockIns.map((a) => a.body.staffId));
  const todayDel = deliveries.data.filter((d) => sameDay(recordDate(d, 'at'), now));
  const accepted = todayDel.filter((d) => d.body.test !== 'failed');
  const collectedToday = accepted.reduce((t, d) => t + (Number(d.body.litres) || 0), 0);
  const rejectedToday = todayDel.filter((d) => d.body.test === 'failed');
  const collectedMonth = deliveries.data
    .filter((d) => d.body.test !== 'failed' && recordDate(d, 'at') >= monthFrom)
    .reduce((t, d) => t + (Number(d.body.litres) || 0), 0);
  const suppliersToday = new Set(accepted.map((d) => d.body.farmerId)).size;

  const plan = planState(farm.subscription, now);
  const staffName = (id: string) => staff.data.find((s) => s.id === id)?.body.name ?? '';
  const openTasks = tasks.data
    .map((t) => ({ r: t, v: taskView(t.body) }))
    .filter((t) => !t.v.done)
    .sort((a, b) => (a.v.priority === b.v.priority ? (a.v.due?.getTime() ?? 0) - (b.v.due?.getTime() ?? 0) : a.v.priority === 'high' ? -1 : 1));
  const overdueTasks = openTasks.filter((t) => t.v.due && t.v.due < today);
  const animalName = (id: string) => {
    const a = animals.data.find((x) => x.id === id);
    return a ? animalLabel(a) : 'An animal';
  };
  const farmerName = (id: string) => farmers.data.find((f) => f.id === id)?.body.name ?? 'A supplier';

  // Things the owner should act on, most urgent first.
  const alerts: { tone: 'bad' | 'warn' | 'info'; icon: IconName; text: string; href?: string }[] = [];
  if (plan.kind === 'trial' && plan.daysLeft <= 2)
    alerts.push({
      tone: 'warn',
      icon: 'clock',
      text: `Free trial ends ${plan.daysLeft <= 0 ? 'today' : `in ${plan.daysLeft} day${plan.daysLeft === 1 ? '' : 's'}`}. Pay to keep recording.`,
      href: '/settings/#plan',
    });
  for (const t of withdrawal.slice(0, 5)) {
    alerts.push({
      tone: 'bad',
      icon: 'health',
      text: `${t.body.animalName || animalName(t.body.animalId)}: milk not for sale until ${shortDate(safeFrom(t.body))} (${words(t.body.condition)}).`,
      href: '/health/',
    });
  }
  if (herdFarm && !milk.loading && todayL === 0 && now.getHours() >= 10)
    alerts.push({ tone: 'warn', icon: 'drop', text: 'No milk recorded yet today.', href: '/milk/?new=1' });
  if (rejectedToday.length)
    alerts.push({
      tone: 'warn',
      icon: 'alert',
      text: `${rejectedToday.length} ${rejectedToday.length === 1 ? 'delivery' : 'deliveries'} rejected today.`,
      href: '/farmers/',
    });
  if (overdueTasks.length)
    alerts.push({ tone: 'warn', icon: 'check', text: `${overdueTasks.length} task${overdueTasks.length === 1 ? ' is' : 's are'} overdue.`, href: '/tasks/' });
  if (farm.reviewStatus === 'pending')
    alerts.push({ tone: 'info', icon: 'shield', text: 'FarmTap is checking your new farm. Everything works while you wait.' });

  const absent = activeStaff.filter((s) => !present.has(s.id));

  // Shortcuts to the things people record most.
  const quick: { href: string; icon: IconName; label: string }[] = [
    ...(herdFarm ? [{ href: '/milk/?new=1', icon: 'drop' as const, label: 'Record milk' }] : []),
    ...(herdFarm ? [{ href: '/herd/?new=1', icon: 'tag' as const, label: 'Add animal' }] : []),
    ...(herdFarm ? [{ href: '/health/?new=1', icon: 'health' as const, label: 'Record treatment' }] : []),
    ...(centre ? [{ href: '/farmers/?new=1', icon: 'truck' as const, label: 'Add supplier' }] : []),
    { href: '/tasks/?new=1', icon: 'check' as const, label: 'Add task' },
    ...(boss ? [{ href: '/money/?new=1', icon: 'money' as const, label: 'Add expense' }] : []),
  ];

  const stats = [
    herdFarm && (
      <Stat
        key="milk"
        loading={milk.loading}
        href="/milk/"
        icon="drop"
        label="Milk today"
        value={litres(todayL)}
        hint={`Morning ${litres(split.morning)} · Evening ${litres(split.evening)}`}
      />
    ),
    herdFarm && (
      <Stat
        key="month"
        loading={milk.loading}
        href="/milk/"
        icon="calendar"
        label="Milk this month"
        value={litres(monthL)}
        hint={
          <>
            <Change pct={change(monthL, prevL)} /> {prevL > 0 ? 'vs same days last month' : 'First month on FarmTap'}
          </>
        }
      />
    ),
    centre && (
      <Stat
        key="collected"
        loading={deliveries.loading}
        href="/farmers/"
        icon="truck"
        label="Collected today"
        value={litres(collectedToday)}
        hint={`${count(suppliersToday)} supplier${suppliersToday === 1 ? '' : 's'} · ${rejectedToday.length} rejected`}
        tone="info"
      />
    ),
    centre && (
      <Stat
        key="collectedMonth"
        loading={deliveries.loading || farmers.loading}
        href="/farmers/"
        icon="calendar"
        label="Collected this month"
        value={litres(collectedMonth)}
        hint={`${count(farmers.data.length)} suppliers registered`}
        tone="info"
      />
    ),
    herdFarm && (
      <Stat
        key="herd"
        loading={animals.loading}
        href="/herd/"
        icon="tag"
        label="Herd"
        value={count(herd.length)}
        unit={herd.length === 1 ? 'animal' : 'animals'}
        hint={`${count(milkers.length)} milking · ${count(herd.filter((a) => a.body.dairyStatus === 'dry').length)} dry · ${count(herd.filter((a) => a.body.dairyStatus === 'calf').length)} calves`}
      />
    ),
    herdFarm && (
      <Stat
        key="withdrawal"
        loading={treatments.loading}
        href="/health/"
        icon="health"
        label="Milk not for sale"
        value={count(withdrawalIds.size)}
        unit={withdrawalIds.size === 1 ? 'animal' : 'animals'}
        hint={withdrawalIds.size ? 'Drug withdrawal: keep their milk apart' : 'All milk can be sold'}
        tone={withdrawalIds.size ? 'bad' : undefined}
      />
    ),
    <Stat
      key="workers"
      loading={staff.loading || attendance.loading}
      href="/workers/"
      icon="workers"
      label="Workers today"
      value={`${count(present.size)} / ${count(activeStaff.length)}`}
      hint={activeStaff.length ? (absent.length ? `${absent.length} not in yet` : 'Everyone is in') : 'No workers added yet'}
      tone="gold"
    />,
    boss && (
      <Stat
        key="spent"
        loading={expenses.loading}
        href="/money/"
        icon="money"
        label="Spent this month"
        value={ugx(spent)}
        hint={
          <>
            <Change pct={change(spent, prevSpent)} goodWhenUp={false} /> {earned > 0 ? `Earned ${ugx(earned)}` : 'vs last month'}
          </>
        }
        tone="warn"
      />
    ),
  ].filter(Boolean);

  const cards = [
    herdFarm && (
      <section key="chart" className="card">
        <CardHead title="Milk, last 14 days">
          <Link href="/milk/" className="small no-print">
            All milk records
          </Link>
        </CardHead>
        {milk.loading ? <SkelRows rows={4} cols={3} /> : <MilkChart days={days} />}
      </section>
    ),
    <section key="attention" className="card">
      <CardHead title="Needs your attention" />
      {alerts.length === 0 ? (
        <Empty icon="check">Nothing needs you right now.</Empty>
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
    </section>,
    <section key="tasks" className="card">
      <CardHead title="Open tasks">
        <Link href="/tasks/" className="small no-print">
          All tasks
        </Link>
      </CardHead>
      {tasks.loading ? (
        <SkelRows rows={3} cols={2} />
      ) : openTasks.length === 0 ? (
        <Empty icon="check" action={canSave && <Link href="/tasks/?new=1" className="btn sm outline">Add a task</Link>}>
          No open tasks.
        </Empty>
      ) : (
        <div className="list">
          {openTasks.slice(0, 6).map(({ r, v }) => {
            const late = v.due && v.due < today;
            return (
              <div key={r.id} className="list-row">
                <div className="stack grow" style={{ gap: 'var(--s-xxs)' }}>
                  <span>{v.title}</span>
                  <span className={`small ${late ? 'down' : 'muted'}`}>
                    {staffName(v.staffId) || 'Anyone'} · {late ? 'Overdue, was due ' : 'Due '}
                    {v.due ? shortDate(v.due) : 'any day'}
                    {v.when ? ` · ${v.when}` : ''}
                  </span>
                </div>
                {v.priority === 'high' && <span className="chip bad">Urgent</span>}
              </div>
            );
          })}
        </div>
      )}
    </section>,
    <TodayOnFarm key="duty" />,
    <section key="staff" className="card">
      <CardHead title="Workers today">
        <Link href="/workers/" className="small no-print">
          All workers
        </Link>
      </CardHead>
      {staff.loading ? (
        <SkelRows rows={3} cols={2} />
      ) : activeStaff.length === 0 ? (
        <Empty icon="workers" action={boss && canSave && <Link href="/workers/?new=1" className="btn sm outline">Add a worker</Link>}>
          No workers yet.
        </Empty>
      ) : (
        <div className="list">
          {activeStaff.slice(0, 8).map((s) => {
            const a = clockIns.find((x) => x.body.staffId === s.id);
            const inAt = a ? (parseDate(a.body.inAt ?? a.body.at) ?? recordDate(a)) : null;
            return (
              <div key={s.id} className="list-row">
                <Avatar photo={personPhotoSrc(s.body)} name={s.body.name} />
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
    </section>,
    centre && (
      <section key="deliveries" className="card">
        <CardHead title="Latest deliveries">
          <Link href="/farmers/" className="small no-print">
            All suppliers
          </Link>
        </CardHead>
        {deliveries.loading ? (
          <SkelRows rows={3} cols={3} />
        ) : deliveries.data.length === 0 ? (
          <Empty icon="truck">No deliveries yet. They show here as soon as the centre phone records them.</Empty>
        ) : (
          <div className="list">
            {[...deliveries.data]
              .sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime())
              .slice(0, 6)
              .map((d) => (
                <div key={d.id} className="list-row">
                  <Avatar name={farmerName(d.body.farmerId)} />
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
    ),
  ].filter(Boolean);

  const anyLoading = staff.loading && tasks.loading;

  return (
    <>
      <PageHead
        title={`${greeting(now)}${firstName(user?.displayName) ? `, ${firstName(user?.displayName)}` : ''}`}
        subtitle={`${longDate(now)} · ${farm.name}`}
      >
        <ExportButtons />
      </PageHead>

      <LoadError code={milk.error ?? animals.error ?? deliveries.error ?? staff.error ?? tasks.error} />

      {canSave && (
        <nav className="quick no-print" aria-label="Record">
          <Fit cols={[2, 3, 3, 6]}>
            {quick.map((q) => (
              <Link key={q.href} href={q.href} className="btn outline">
                <Icon name={q.icon} /> {q.label}
              </Link>
            ))}
          </Fit>
        </nav>
      )}

      <Fit kind="stats">{stats}</Fit>

      <HomeAi />

      {anyLoading ? (
        <Fit kind="cards">
          <SkelCard />
          <SkelCard />
          <SkelCard />
        </Fit>
      ) : (
        <Fit kind="cards" cols={[1, 2, 2, 3]}>
          {cards}
        </Fit>
      )}
    </>
  );
}
