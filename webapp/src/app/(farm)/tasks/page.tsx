'use client';

import { useState, type FormEvent } from 'react';
import { Icon } from '@/components/Icon';
import { Dialog, Empty, PageHead } from '@/components/ui';
import { addRecord, saveError, updateRecord, useRecords } from '@/lib/data';
import { localIso } from '@/lib/dates';
import { manages, planState, type FarmRecord, type StaffBody, type TaskBody } from '@/lib/domain';
import { date, shortDate, words } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';

const CATEGORIES = [
  { value: 'milk', label: 'Milking' },
  { value: 'health', label: 'Animal health' },
  { value: 'feeding', label: 'Feeding' },
  { value: 'cleaning', label: 'Cleaning' },
  { value: 'general', label: 'General' },
  { value: 'other', label: 'Other' },
];

const PRIORITIES = [
  { value: 'low', label: 'Low', chip: '' },
  { value: 'normal', label: 'Normal', chip: 'brand' },
  { value: 'high', label: 'High', chip: 'bad' },
];

function categoryIcon(cat?: string) {
  const m: Record<string, 'drop' | 'health' | 'feed' | 'refresh' | 'flag' | 'check'> = {
    milk: 'drop',
    health: 'health',
    feeding: 'feed',
    cleaning: 'refresh',
    general: 'flag',
  };
  return m[cat ?? ''] ?? 'check';
}

function AddTask({
  staff,
  onClose,
  onSaved,
}: {
  staff: FarmRecord<StaffBody>[];
  onClose: () => void;
  onSaved: () => void;
}) {
  const farm = useFarm();
  const { user } = useSession();
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [assignedTo, setAssignedTo] = useState('');
  const [dueDate, setDueDate] = useState(localIso(new Date()));
  const [priority, setPriority] = useState<'low' | 'normal' | 'high'>('normal');
  const [category, setCategory] = useState('general');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const activeStaff = staff.filter((s) => s.body.active !== false);
  const chosen = activeStaff.find((s) => s.id === assignedTo);

  async function save(ev: FormEvent) {
    ev.preventDefault();
    if (!user) return;
    setBusy(true);
    setError('');
    try {
      const { db } = firebase();
      const body: TaskBody = {
        title: title.trim(),
        description: description.trim() || undefined,
        assignedTo: assignedTo || undefined,
        assignedToName: chosen?.body.name,
        dueDate,
        status: 'open',
        priority,
        category,
      };
      await addRecord(db, farm.id, 'tasks', user.uid, body as unknown as Record<string, unknown>);
      onSaved();
      onClose();
    } catch (e) {
      setError(saveError((e as { code?: string }).code));
      setBusy(false);
    }
  }

  return (
    <Dialog title="New task" onClose={onClose}>
      <form className="stack" onSubmit={save}>
        <label className="field">
          <span>Task</span>
          <input className="input" value={title} onChange={(e) => setTitle(e.target.value)} required placeholder="e.g. Clean the milking parlour" />
        </label>
        <label className="field">
          <span>Details (optional)</span>
          <textarea className="input" rows={2} value={description} onChange={(e) => setDescription(e.target.value)} />
        </label>
        <div className="grid">
          <label className="field">
            <span>Category</span>
            <select className="input" value={category} onChange={(e) => setCategory(e.target.value)}>
              {CATEGORIES.map((c) => (
                <option key={c.value} value={c.value}>{c.label}</option>
              ))}
            </select>
          </label>
          <label className="field">
            <span>Priority</span>
            <select className="input" value={priority} onChange={(e) => setPriority(e.target.value as 'low' | 'normal' | 'high')}>
              {PRIORITIES.map((p) => (
                <option key={p.value} value={p.value}>{p.label}</option>
              ))}
            </select>
          </label>
          <label className="field">
            <span>Due date</span>
            <input className="input" type="date" value={dueDate} onChange={(e) => setDueDate(e.target.value)} />
          </label>
          <label className="field">
            <span>Assign to</span>
            <select className="input" value={assignedTo} onChange={(e) => setAssignedTo(e.target.value)}>
              <option value="">Anyone</option>
              {activeStaff.map((s) => (
                <option key={s.id} value={s.id}>{s.body.name}</option>
              ))}
            </select>
          </label>
        </div>
        {error && <div className="banner bad">{error}</div>}
        <div className="actions">
          <button type="button" className="btn outline" onClick={onClose}>Cancel</button>
          <button className="btn" disabled={busy}>Add task</button>
        </div>
      </form>
    </Dialog>
  );
}

function TaskRow({
  task,
  canManage,
  onToggle,
}: {
  task: FarmRecord<TaskBody>;
  canManage: boolean;
  onToggle: () => void;
}) {
  const b = task.body;
  const done = b.status === 'done';
  const overdue = !done && b.dueDate && b.dueDate < localIso(new Date());
  const pri = PRIORITIES.find((p) => p.value === b.priority);
  return (
    <div className={`list-row wrap ${done ? 'muted' : ''}`} style={{ opacity: done ? 0.6 : 1 }}>
      <button
        className={`chip ${done ? 'ok' : overdue ? 'bad' : pri?.chip ?? ''}`}
        style={{ cursor: 'pointer', border: 0 }}
        onClick={onToggle}
        title={done ? 'Mark open' : 'Mark done'}
      >
        <Icon name={done ? 'check' : categoryIcon(b.category)} className="icon" />
      </button>
      <div className="stack grow" style={{ gap: 'var(--s-xxs)' }}>
        <span style={{ textDecoration: done ? 'line-through' : undefined }}>{b.title}</span>
        {b.description && <span className="small muted">{b.description}</span>}
        <span className="small muted">
          {b.assignedToName ? `${b.assignedToName} · ` : ''}
          {b.dueDate ? (overdue ? `Overdue (${shortDate(new Date(b.dueDate))})` : `Due ${shortDate(new Date(b.dueDate))}`) : 'No due date'}
          {done && b.completedByName ? ` · Done by ${b.completedByName}` : ''}
        </span>
      </div>
      {b.priority === 'high' && !done && <span className="chip bad">Urgent</span>}
      {canManage && <span className="small muted">{words(b.category ?? 'general')}</span>}
    </div>
  );
}

export default function TasksPage() {
  const farm = useFarm();
  const { user, online } = useSession();
  const isBoss = manages(farm);
  const tasks = useRecords<TaskBody>(farm.id, 'tasks');
  const staff = useRecords<StaffBody>(farm.id, 'staff');
  const [adding, setAdding] = useState(false);
  const [filter, setFilter] = useState<'open' | 'done' | 'mine'>('open');
  const now = new Date();
  const plan = planState(farm.subscription, now);
  const canWrite = plan.kind !== 'readOnly';

  const myName = staff.data.find((s) => s.body.phone === (user?.email ?? ''))?.body.name ?? user?.displayName ?? '';

  const rows = tasks.data
    .filter((t) => !t.isDeleted)
    .filter((t) => {
      if (filter === 'done') return t.body.status === 'done';
      if (filter === 'mine') return t.body.status === 'open' && (!t.body.assignedTo || t.body.assignedToName === myName);
      return t.body.status === 'open';
    })
    .sort((a, b) => {
      // High priority first, then by due date
      const pa = a.body.priority === 'high' ? 0 : a.body.priority === 'normal' ? 1 : 2;
      const pb = b.body.priority === 'high' ? 0 : b.body.priority === 'normal' ? 1 : 2;
      if (pa !== pb) return pa - pb;
      return (a.body.dueDate ?? '9999') < (b.body.dueDate ?? '9999') ? -1 : 1;
    });

  async function toggleTask(task: FarmRecord<TaskBody>) {
    if (!user || !online) return;
    const { db } = firebase();
    const done = task.body.status !== 'done';
    const patch: Partial<TaskBody> = {
      ...task.body,
      status: done ? 'done' : 'open',
      completedAt: done ? localIso(new Date()) : null,
      completedBy: done ? user.uid : null,
      completedByName: done ? (user.displayName ?? user.email ?? '') : null,
    };
    try {
      await updateRecord(db, farm.id, 'tasks', task.id, user.uid, patch as unknown as Record<string, unknown>, task.version);
    } catch {
      // silent — the list will stay in sync via onSnapshot
    }
  }

  const openCount = tasks.data.filter((t) => t.body.status === 'open').length;
  const overdueCount = tasks.data.filter((t) => t.body.status === 'open' && t.body.dueDate && t.body.dueDate < localIso(now)).length;

  return (
    <>
      <PageHead title="Tasks" subtitle="Assign and track daily work">
        {isBoss && canWrite && (
          <button className="btn sm" onClick={() => setAdding(true)}>
            <Icon name="plus" /> Add task
          </button>
        )}
      </PageHead>

      {overdueCount > 0 && (
        <div className="banner bad">
          <Icon name="alert" />
          <span className="grow">{overdueCount} overdue task{overdueCount === 1 ? '' : 's'}.</span>
        </div>
      )}

      <div className="row" style={{ gap: 'var(--s-xs)', marginBottom: 'var(--s-md)' }}>
        <div className="seg" role="group" aria-label="Filter tasks">
          <button aria-pressed={filter === 'open'} onClick={() => setFilter('open')}>Open ({openCount})</button>
          <button aria-pressed={filter === 'mine'} onClick={() => setFilter('mine')}>Mine</button>
          <button aria-pressed={filter === 'done'} onClick={() => setFilter('done')}>Done</button>
        </div>
      </div>

      <section className="card">
        <div className="list">
          {rows.map((task) => (
            <TaskRow
              key={task.id}
              task={task}
              canManage={isBoss}
              onToggle={() => canWrite && void toggleTask(task)}
            />
          ))}
          {rows.length === 0 && <Empty>{filter === 'done' ? 'No completed tasks.' : 'No open tasks. Good work!'}</Empty>}
        </div>
      </section>

      {adding && staff.data && (
        <AddTask staff={staff.data} onClose={() => setAdding(false)} onSaved={() => {}} />
      )}
    </>
  );
}
