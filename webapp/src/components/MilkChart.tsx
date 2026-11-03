import { sameDay } from '@/lib/dates';
import { litres, num1, weekday } from '@/lib/format';

/** Daily milk bars; today in gold. Heights are a share of the best day. */
export function MilkChart({ days }: { days: { day: Date; litres: number }[] }) {
  const max = Math.max(...days.map((d) => d.litres), 1);
  const total = days.reduce((t, d) => t + d.litres, 0);
  const recorded = days.filter((d) => d.litres > 0).length;
  const today = new Date();
  return (
    <div className="stack">
      <div className="bars" role="img" aria-label={`Milk per day for ${days.length} days, total ${litres(total)}`}>
        {days.map((d) => {
          const isToday = sameDay(d.day, today);
          return (
            <div className="bar-col" key={d.day.toISOString()} title={`${weekday(d.day)} ${d.day.getDate()}: ${litres(d.litres)}`}>
              <div
                className={`bar ${isToday ? 'today' : ''} ${d.litres === 0 ? 'zero' : ''}`}
                style={{ height: `${(d.litres / max) * 100}%` }}
              />
              <span className="bar-label">{d.day.getDate()}</span>
            </div>
          );
        })}
      </div>
      <div className="row between small muted">
        <span>Total {litres(total)}</span>
        <span>Average {recorded ? `${num1(total / recorded)} L a day` : 'none yet'}</span>
      </div>
    </div>
  );
}
