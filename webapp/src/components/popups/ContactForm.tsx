'use client';

import { useState } from 'react';
import { Fit } from '@/components/fit';
import { Field, FormDialog, useSave, useToast } from '@/components/ui';
import { addRecord, mergeBody, putRecord } from '@/lib/data';
import { contactKindName, contactKinds, type ContactBody, type FarmRecord } from '@/lib/domain';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';

const phoneOk = (p: string) => /^\+?[\d\s-]{9,16}$/.test(p.trim());

export function ContactForm({ c, onClose, kind }: { c?: FarmRecord<ContactBody>; onClose: () => void; kind?: string }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const b = c?.body;
  const [f, setF] = useState({
    name: b?.name ?? '',
    kind: (b?.kind ?? kind ?? 'vet') as string,
    phone: b?.phone ?? '',
    phone2: b?.phone2 ?? '',
    org: b?.org ?? '',
    place: b?.place ?? '',
    note: b?.note ?? '',
    showWorkers: b?.showWorkers ?? true,
  });
  const { busy, error, setError, run } = useSave();
  const set = (k: keyof typeof f) => (e: { target: { value: string } }) => setF({ ...f, [k]: e.target.value });

  async function save() {
    if (!user) return;
    if (!f.name.trim()) return setError('Type the name.');
    if (!phoneOk(f.phone)) return setError('Type a phone number, e.g. 0772 123 456.');
    if (f.phone2.trim() && !phoneOk(f.phone2)) return setError('The second number does not look right.');
    const body = {
      name: f.name.trim(),
      kind: f.kind,
      phone: f.phone.trim(),
      phone2: f.phone2.trim() || null,
      org: f.org.trim() || null,
      place: f.place.trim() || null,
      note: f.note.trim() || null,
      showWorkers: f.showWorkers,
    };
    const { db } = firebase();
    const ok = await run(() => (c ? putRecord(db, farm.id, c, user.uid, mergeBody(c, body)) : addRecord(db, farm.id, 'contacts', user.uid, body)));
    if (ok) {
      toast(`${body.name} saved`);
      onClose();
    }
  }

  return (
    <FormDialog title={c ? `Edit ${b?.name}` : 'Add contact'} onClose={onClose} onSubmit={save} busy={busy} error={error} canSave={canSave} online={online} submit={c ? 'Save' : 'Add contact'} size="lg">
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Name">
          <input className="input" required value={f.name} onChange={set('name')} autoFocus maxLength={80} placeholder="e.g. Dr Okello" />
        </Field>
        <Field label="Who they are">
          <select className="input" value={f.kind} onChange={set('kind')}>
            {contactKinds.map((k) => (
              <option key={k} value={k}>
                {contactKindName[k]}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Phone">
          <input className="input" type="tel" required value={f.phone} onChange={set('phone')} placeholder="0772 123 456" />
        </Field>
        <Field label="Second phone (optional)">
          <input className="input" type="tel" value={f.phone2} onChange={set('phone2')} />
        </Field>
        <Field label={f.kind === 'vet' ? 'Clinic (optional)' : 'Shop or company (optional)'}>
          <input className="input" value={f.org} onChange={set('org')} placeholder={f.kind === 'vet' ? 'e.g. Mbarara Vet Clinic' : 'e.g. Kakoba Agro-vet'} />
        </Field>
        <Field label="Where (optional)">
          <input className="input" value={f.place} onChange={set('place')} placeholder="e.g. Mbarara town" />
        </Field>
      </Fit>
      <Field label="Note (optional)">
        <input className="input" value={f.note} onChange={set('note')} placeholder="e.g. Comes on Tuesdays; sells dairy meal at 60,000" maxLength={200} />
      </Field>
      <label className="check-row">
        <input type="checkbox" checked={f.showWorkers} onChange={(e) => setF({ ...f, showWorkers: e.target.checked })} />
        <span>Workers can see and call this contact</span>
      </label>
    </FormDialog>
  );
}
