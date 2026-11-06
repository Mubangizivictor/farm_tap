'use client';

import { useState } from 'react';
import { Fit } from '@/components/fit';
import { Field, FormDialog, Seg, useSave, useToast } from '@/components/ui';
import { dayKey, localIso, parseDate } from '@/lib/dates';
import { addRecord, mergeBody, putRecord } from '@/lib/data';
import { taskBody, taskView, type FarmRecord, type StaffBody, type TaskBody } from '@/lib/domain';
import { date } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';

/** The phone saves a task as due at 18:00 on its day (workers_pages.dart). */
export const dueAt = (day: Date) => new Date(day.getFullYear(), day.getMonth(), day.getDate(), 18);

/** A value the AI chat put in the link, e.g. /tasks/?new=1&title=Recheck%20Bella&due=2026-11-07. */
const fromUrl = (k: string) => (typeof window === 'undefined' ? null : new URL(window.location.href).searchParams.get(k));

/** `preset` fills the title and day when the form opens inside the AI chat instead of from a link. */
export function TaskForm({ t, staff, onClose, preset }: { t?: FarmRecord<TaskBody>; staff: FarmRecord<StaffBody>[]; onClose: () => void; preset?: { title?: string; due?: string } }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const v = t ? taskView(t.body) : null;
  const [f, setF] = useState({
    title: v?.title ?? preset?.title ?? fromUrl('title') ?? '',
    staffId: v?.staffId && staff.some((s) => s.id === v.staffId) ? v.staffId : staff.length === 1 ? staff[0].id : '',
    due: dayKey(v?.due ?? (/^\d{4}-\d{2}-\d{2}$/.test(preset?.due ?? fromUrl('due') ?? '') ? new Date(`${preset?.due ?? fromUrl('due')}T12:00:00`) : new Date())),
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
