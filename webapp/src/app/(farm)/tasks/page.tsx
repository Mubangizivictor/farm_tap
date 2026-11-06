'use client';

import Link from 'next/link';
import { useState } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { ConfirmDialog, Empty, Field, FormDialog, LoadError, PageHead, SearchBox, Seg, SkelRows, Stat, Tabs, useSave, useToast } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { addDays, dayKey, localIso, parseDate, sameDay, startOfDay } from '@/lib/dates';
import { addRecord, mergeBody, putRecord, removeRecord, useRecords } from '@/lib/data';
import { manages, taskBody, taskView, type FarmRecord, type StaffBody, type TaskBody, type TaskView } from '@/lib/domain';
import { count, date, shortDate, time } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';
import { useOpenFromUrl } from '@/lib/useOpen';

/** The phone saves a task as due at 18:00 on its day (workers_pages.dart). */
/** A value the AI chat put in the link, e.g. /tasks/?new=1&title=Recheck%20Bella&due=2026-11-07. */
const fromUrl = (k: string) => (typeof window === 'undefined' ? null : new URL(window.location.href).searchParams.get(k));

const dueAt = (day: Date) => new Date(day.getFullYear(), day.getMonth(), day.getDate(), 18);

function TaskForm({ t, staff, onClose }: { t?: FarmRecord<TaskBody>; staff: FarmRecord<StaffBody>[]; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const v = t ? taskView(t.body) : null;
  const [f, setF] = useState({
    title: v?.title ?? fromUrl('title') ?? '',
    staffId: v?.staffId && staff.some((s) => s.id === v.staffId) ? v.staffId : staff.length === 1 ? staff[0].id : '',
    due: dayKey(v?.due ?? (/^\d{4}-\d{2}-\d{2}$/.test(fromUrl('due') ?? '') ? new Date(`${fromUrl('due')}T12:00:00`) : new Date())),
    when: v?.when ?? '',
    priority: v?.priority ?? 'normal',
    note: v?.note ?? '',
  });
  const { busy, error, setError, run } = useSave();
  const set = (k: keyof typeof f) => (e: { target: { value: string } }) => setF({ ...f, [k]: e.target.value });

  async function save() {
    if (!user) return;
    if (!f.title.trim()) return setError('Say what needs doing.');
    if (!f.staffId) return setError('Choose who will do it.');
    const day = parseDate(f.due);
    if (!day) return setError('Choose the day it is due.');
    const body = taskBody(
      { title: f.title.trim(), staffId: f.staffId, due: dueAt(day), when: f.when.trim(), doneAt: v?.doneAt ?? null, note: f.note, priority: f.priority as 'normal' | 'high' },
      localIso,
    );
    const { db } = firebase();
    const ok = await run(() => (t ? putRecord(db, farm.id, t, user.uid, mergeBody(t, body)) : addRecord(db, farm.id, 'tasks', user.uid, body)));
    if (ok) {
      const who = staff.find((s) => s.id === f.staffId)?.body.name ?? '';
      toast(t ? 'Task saved' : `Task given to ${who}`);
      onClose();
    }
  }

  return (
    <FormDialog
      title={t ? 'Edit task' : 'New task'}
      subtitle="The worker sees it on the farm phone after the next sync."
      onClose={onClose}
      onSubmit={save}
      busy={busy}
      error={error}
      canSave={canSave}
      online={online}
      submit={t ? 'Save changes' : 'Add task'}
    >
      <Field label="What needs doing">
        <input className="input" required value={f.title} onChange={set('title')} autoFocus placeholder="e.g. Spray the calves" maxLength={120} />
      </Field>
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Who">
          <select className="input" required value={f.staffId} onChange={set('staffId')}>
            <option value="">Choose a worker…</option>
            {staff.map((s) => (
              <option key={s.id} value={s.id}>
                {s.body.name}
                {s.body.title ? ` (${s.body.title})` : ''}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Day">
          <input className="input" type="date" required min={t ? undefined : dayKey(new Date())} value={f.due} onChange={set('due')} />
        </Field>
        <Field label="When (optional)" hint="e.g. before 10:00, after evening milking">
          <input className="input" value={f.when} onChange={set('when')} maxLength={60} />
        </Field>
        <Field label="How urgent">
          <Seg label="How urgent" value={f.priority} onChange={(p) => setF({ ...f, priority: p })} items={[['normal', 'Normal'], ['high', 'Urgent']]} />
        </Field>
      </Fit>
      <Field label="Note (optional)">
        <textarea className="input" value={f.note} onChange={set('note')} rows={2} maxLength={500} />
      </Field>
    </FormDialog>
  );
}

type Tab = 'open' | 'today' | 'late' | 'done';

export default function Tasks() {
  const farm = useFarm();
  const { user, canSave } = useSession();
  const toast = useToast();
  const boss = manages(farm);
  const tasks = useRecords<TaskBody>(farm.id, 'tasks');
  const staff = useRecords<StaffBody>(farm.id, 'staff');
  const [tab, setTab] = useState<Tab>('open');
  const [who, setWho] = useState('');
  const [q, setQ] = useState('');
  const [adding, setAdding] = useOpenFromUrl();
  const [editing, setEditing] = useState<FarmRecord<TaskBody> | null>(null);
  const [removing, setRemoving] = useState<FarmRecord<TaskBody> | null>(null);
  const toggleSave = useSave();
  const removeSave = useSave();
  const now = new Date();
  const today = startOfDay(now);

  const team = staff.data.filter((s) => s.body.active !== false).sort((a, b) => a.body.name.localeCompare(b.body.name));
  const staffName = (id: string) => staff.data.find((s) => s.id === id)?.body.name ?? '';
  const all = tasks.data.map((r) => ({ r, v: taskView(r.body) }));
  const isLate = (v: TaskView) => !v.done && v.due != null && v.due < now && !sameDay(v.due, now);
  const open = all.filter((t) => !t.v.done);
  const dueToday = open.filter((t) => t.v.due && sameDay(t.v.due, now));
  const late = open.filter((t) => isLate(t.v));
  const done = all.filter((t) => t.v.done).sort((a, b) => (b.v.doneAt?.getTime() ?? 0) - (a.v.doneAt?.getTime() ?? 0));
  const doneWeek = done.filter((t) => t.v.doneAt && t.v.doneAt >= addDays(today, -6));
  const list = (tab === 'open' ? open : tab === 'today' ? dueToday : tab === 'late' ? late : done)
    .filter((t) => !who || t.v.staffId === who)
    .filter((t) => !q || `${t.v.title} ${t.v.note} ${staffName(t.v.staffId)}`.toLowerCase().includes(q.toLowerCase()))
    .sort((a, b) =>
      tab === 'done'
        ? 0
        : a.v.priority !== b.v.priority
          ? a.v.priority === 'high'
            ? -1
            : 1
          : (a.v.due?.getTime() ?? 0) - (b.v.due?.getTime() ?? 0),
    );

  async function toggle(r: FarmRecord<TaskBody>, v: TaskView) {
    if (!user) return;
    const doneAt = v.done ? null : new Date();
    const body = mergeBody(r, {
      ...taskBody({ title: v.title, staffId: v.staffId, due: v.due ?? dueAt(now), when: v.when, doneAt, note: v.note, priority: v.priority }, localIso),
      // Older web tasks: keep their own status in step.
      ...(r.body.status ? { status: doneAt ? 'done' : 'open', completedAt: doneAt ? localIso(doneAt) : null } : {}),
    });
    if (await toggleSave.run(() => putRecord(firebase().db, farm.id, r, user.uid, body))) toast(doneAt ? `Done: ${v.title}` : `Opened again: ${v.title}`);
  }

  const csv = () =>
    downloadCsv(
      `${farm.name}-tasks-${dayKey(now)}`,
      ['Task', 'Who', 'Day', 'When', 'Urgent', 'Done', 'Note'],
      list.map(({ v }) => [v.title, staffName(v.staffId), v.due ? dayKey(v.due) : '', v.when, v.priority === 'high' ? 'Yes' : '', v.doneAt ? `${dayKey(v.doneAt)} ${time(v.doneAt)}` : '', v.note]),
    );

  return (
    <>
      <PageHead title="Tasks" subtitle="Give work to your workers. They see it and tick it off on the farm phone.">
        <SearchBox value={q} onChange={setQ} placeholder="Search tasks" />
        <button className="btn outline sm" onClick={csv} title="Download for Excel">
          <Icon name="download" /> <span className="btn-text">CSV</span>
        </button>
        {boss && (
          <button className="btn sm" onClick={() => setAdding(true)} disabled={!canSave || team.length === 0} title={team.length ? undefined : 'Add a worker first'}>
            <Icon name="plus" /> Add task
          </button>
        )}
      </PageHead>
      <LoadError code={tasks.error ?? staff.error} />
      {toggleSave.error && <div className="banner bad">{toggleSave.error}</div>}

      <Fit kind="stats">
        <Stat loading={tasks.loading} icon="list" label="Open" value={count(open.length)} hint={`${dueToday.length} due today`} />
        <Stat loading={tasks.loading} icon="alert" label="Overdue" value={count(late.length)} hint={late.length ? 'Past their day' : 'Nothing late'} tone={late.length ? 'bad' : undefined} />
        <Stat loading={tasks.loading} icon="check" label="Done, 7 days" value={count(doneWeek.length)} tone="gold" />
      </Fit>

      <div className="row wrap between no-print">
        <Tabs
          label="Tasks"
          value={tab}
          onChange={setTab}
          items={[
            ['open', 'Open', open.length],
            ['today', 'Today', dueToday.length],
            ['late', 'Overdue', late.length],
            ['done', 'Done', done.length],
          ]}
        />
        {team.length > 1 && (
          <select className="input" style={{ width: 'auto' }} value={who} onChange={(e) => setWho(e.target.value)} aria-label="Worker">
            <option value="">Everyone</option>
            {team.map((s) => (
              <option key={s.id} value={s.id}>
                {s.body.name}
              </option>
            ))}
          </select>
        )}
      </div>

      <div className="table-wrap">
        <table className="table rt">
          <thead>
            <tr>
              <th aria-label="Done" />
              <th>Task</th>
              <th>Who</th>
              <th>Day</th>
              <th>{tab === 'done' ? 'Done' : 'When'}</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {list.map(({ r, v }) => (
              <tr key={r.id}>
                <td className="acts" data-label="">
                  <label className="check-row" title={v.done ? 'Mark not done' : 'Mark done'}>
                    <input type="checkbox" checked={v.done} disabled={!canSave || toggleSave.busy} onChange={() => void toggle(r, v)} aria-label={v.done ? `Mark ${v.title} not done` : `Mark ${v.title} done`} />
                    <span className="show-sm-only small">{v.done ? 'Done' : 'Mark done'}</span>
                  </label>
                </td>
                <td data-label="Task" className="lead wide">
                  <span className={v.done ? 'task-done' : ''}>
                    <strong>{v.title}</strong>
                  </span>{' '}
                  {v.priority === 'high' && !v.done && <span className="chip bad">Urgent</span>}
                  {v.note && <div className="small muted">{v.note}</div>}
                </td>
                <td data-label="Who">{staffName(v.staffId) || <span className="muted">Not set</span>}</td>
                <td data-label="Day">
                  {v.due ? (
                    isLate(v) ? (
                      <span className="chip bad">Overdue · {shortDate(v.due)}</span>
                    ) : sameDay(v.due, now) ? (
                      <span className="chip warn">Today</span>
                    ) : (
                      date(v.due)
                    )
                  ) : (
                    '–'
                  )}
                </td>
                <td data-label={tab === 'done' ? 'Done' : 'When'}>{tab === 'done' ? (v.doneAt ? `${shortDate(v.doneAt)} ${time(v.doneAt)}` : 'Done') : v.when || '–'}</td>
                <td className="acts">
                  {boss && canSave && (
                    <div className="row" style={{ gap: 'var(--s-xs)', justifyContent: 'flex-end' }}>
                      <button className="btn sm outline" onClick={() => setEditing(r)}>
                        Edit
                      </button>
                      <button className="icon-btn" aria-label={`Remove ${v.title}`} title="Remove" onClick={() => setRemoving(r)}>
                        <Icon name="close" />
                      </button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {(tasks.loading || staff.loading) && <SkelRows rows={4} cols={5} />}
        {!tasks.loading && !staff.loading && list.length === 0 && (
          <Empty
            icon="check"
            action={
              boss && canSave && tab === 'open' && !q ? (
                team.length ? (
                  <button className="btn sm" onClick={() => setAdding(true)}>
                    <Icon name="plus" /> Add task
                  </button>
                ) : (
                  <Link className="btn sm" href="/workers/?new=1">
                    <Icon name="plus" /> Add a worker first
                  </Link>
                )
              ) : null
            }
          >
            {q || who ? 'No task matches.' : tab === 'done' ? 'Nothing done yet.' : tab === 'late' ? 'Nothing is overdue.' : tab === 'today' ? 'Nothing due today.' : team.length ? 'No open tasks. Good work!' : 'Tasks go to workers. Add your workers first.'}
          </Empty>
        )}
      </div>

      {adding && <TaskForm staff={team} onClose={() => setAdding(false)} />}
      {editing && <TaskForm t={editing} staff={team} onClose={() => setEditing(null)} />}
      {removing && (
        <ConfirmDialog
          title="Remove this task?"
          confirm="Remove"
          danger
          busy={removeSave.busy}
          error={removeSave.error}
          onClose={() => setRemoving(null)}
          onConfirm={async () => {
            if (!user) return;
            if (await removeSave.run(() => removeRecord(firebase().db, farm.id, removing, user.uid))) {
              toast('Task removed');
              setRemoving(null);
            }
          }}
        >
          “{taskView(removing.body).title}” will be removed here and from the farm phones.
        </ConfirmDialog>
      )}
    </>
  );
}

