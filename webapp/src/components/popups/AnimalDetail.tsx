'use client';

import Link from 'next/link';
import { AnimalAi } from '@/components/aiPage';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { Dialog } from '@/components/ui';
import { addDays, parseDate, startOfDay } from '@/lib/dates';
import { ageText, animalLabel, inWithdrawal, isActiveAnimal, recordDate, safeFrom, type AnimalBody, type FarmRecord, type MilkBody, type TreatmentBody } from '@/lib/domain';
import { date, litres, shortDate, words } from '@/lib/format';
import { useSession } from '@/lib/session';

export function AnimalDetail({
  a,
  milk,
  treatments,
  onEdit,
  onLeave,
  onTreat,
  onClose,
}: {
  a: FarmRecord<AnimalBody>;
  milk: FarmRecord<MilkBody>[];
  treatments: FarmRecord<TreatmentBody>[];
  /** Left out inside the AI chat pop-up, where the animal is only looked at. */
  onEdit?: () => void;
  onLeave?: () => void;
  /** Opens the treatment form over this one instead of going to the Health page. */
  onTreat?: () => void;
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
          {onEdit && (
            <button className="btn sm" onClick={onEdit}>
              <Icon name="edit" /> Edit
            </button>
          )}
          {onTreat ? (
            <button className="btn sm outline" onClick={onTreat}>
              <Icon name="health" /> Record treatment
            </button>
          ) : (
            <Link className="btn sm outline" href={`/health/?new=1&animal=${a.id}`}>
              <Icon name="health" /> Record treatment
            </Link>
          )}
          {onLeave && (
            <button className="btn sm outline" onClick={onLeave}>
              <Icon name="logout" /> Sold or died
            </button>
          )}
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
