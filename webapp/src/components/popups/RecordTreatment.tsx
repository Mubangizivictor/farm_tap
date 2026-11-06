'use client';

import { useEffect, useState } from 'react';
import { Fit } from '@/components/fit';
import { Field, FormDialog, useSave, useToast } from '@/components/ui';
import { addDays, dayKey, localIso, parseDate, startOfDay } from '@/lib/dates';
import { saveWithExpense } from '@/lib/linked';
import { manages, payMethodName, payMethods, type ContactBody, type FarmRecord, type PayMethod, conditions, drugRoutes, type AnimalBody, type Drug } from '@/lib/domain';
import { date, shortDate, words } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';

export function RecordTreatment({
  animals,
  drugs,
  startAnimal,
  vets,
  onClose,
}: {
  animals: { id: string; label: string; body: AnimalBody }[];
  drugs: Drug[];
  startAnimal: string;
  vets: FarmRecord<ContactBody>[];
  onClose: () => void;
}) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const today = dayKey(new Date());
  const [f, setF] = useState({
    animalId: animals.some((a) => a.id === startAnimal) ? startAnimal : '',
    condition: 'mastitis',
    drugId: drugs[0]?.id ?? '',
    given: today,
    dose: '',
    route: 'injection',
    givenBy: user?.displayName ?? '',
    note: '',
    vetId: '',
    cost: '',
    payMethod: 'cash',
  });
  const boss = manages(farm);
  const { busy, error, setError, run } = useSave();
  // The herd may still be loading when the dialog opens from an animal's page.
  useEffect(() => {
    if (startAnimal && animals.some((a) => a.id === startAnimal)) setF((x) => (x.animalId ? x : { ...x, animalId: startAnimal }));
  }, [startAnimal, animals]);
  const set = (k: keyof typeof f) => (e: { target: { value: string } }) => setF({ ...f, [k]: e.target.value });
  const drug = drugs.find((d) => d.id === f.drugId);
  const givenDay = parseDate(f.given);
  const safe = givenDay && drug ? addDays(startOfDay(givenDay), drug.withdrawalDays) : null;

  async function save() {
    if (!user) return;
    const a = animals.find((x) => x.id === f.animalId);
    if (!a) return setError('Choose the animal that was treated.');
    if (!drug) return setError('Choose the drug that was given.');
    if (!givenDay) return setError('Choose the day it was given.');
    if (givenDay > new Date()) return setError('The day given cannot be in the future.');
    // Given today: now. Given earlier: that day at noon, like a typed date on the phone.
    const at = f.given === today ? new Date() : new Date(givenDay.getFullYear(), givenDay.getMonth(), givenDay.getDate(), 12);
    const cost = boss && f.cost.trim() ? Number(f.cost) : 0;
    if (cost && (!Number.isInteger(cost) || cost < 0)) return setError('Type the cost in whole shillings, e.g. 35000.');
    const vet = vets.find((v) => v.id === f.vetId);
    const ok = await run(() =>
      saveWithExpense(firebase().db, farm.id, user.uid, { collection: 'treatments', body: {
        animalId: a.id,
        animalName: a.body.name?.trim() || a.body.tagNumber,
        tag: a.body.tagNumber,
        avatarIndex: a.body.avatarIndex ?? 1,
        animalDry: a.body.dairyStatus === 'dry',
        condition: f.condition,
        drugId: drug.id,
        withdrawalDays: drug.withdrawalDays,
        given: localIso(at),
        courseDays: 3,
        dose: f.dose.trim() || null,
        route: f.route,
        givenBy: f.givenBy.trim() || vet?.body.name || null,
        photo: null,
        note: f.note.trim() || null,
        cost: cost || null,
        vetId: vet?.id ?? null,
      } }, 'treatment', cost ? { category: 'vet', amount: cost, at: localIso(at), note: `${a.label} · ${words(f.condition)}`, supplierId: vet?.id ?? null, payMethod: f.payMethod as PayMethod } : null),
    );
    if (ok) {
      toast(drug.withdrawalDays ? `Saved. ${a.label}: milk not for sale until ${shortDate(safe)}` : `Treatment saved for ${a.label}`);
      onClose();
    }
  }

  return (
    <FormDialog
      title="Record treatment"
      subtitle="The phones block this animal’s milk until the safe day."
      onClose={onClose}
      onSubmit={save}
      busy={busy}
      error={error}
      canSave={canSave}
      online={online}
      submit="Save treatment"
      size="lg"
    >
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Animal">
          <select className="input" required value={f.animalId} onChange={set('animalId')} autoFocus>
            <option value="">Choose…</option>
            {animals.map((a) => (
              <option key={a.id} value={a.id}>
                {a.label}
                {a.body.name ? ` (${a.body.tagNumber})` : ''}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Problem">
          <select className="input" value={f.condition} onChange={set('condition')}>
            {conditions.map((c) => (
              <option key={c} value={c}>
                {words(c)}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Drug" hint={drug ? (drug.withdrawalDays ? `Milk not for sale for ${drug.withdrawalDays} days.` : 'No milk withdrawal.') : undefined}>
          <select className="input" required value={f.drugId} onChange={set('drugId')}>
            {drugs.map((d) => (
              <option key={d.id} value={d.id}>
                {d.name}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Day given" hint={safe && drug?.withdrawalDays ? `Milk safe from ${date(safe)}.` : undefined}>
          <input className="input" type="date" required max={today} min={dayKey(addDays(new Date(), -60))} value={f.given} onChange={set('given')} />
        </Field>
        <Field label="Dose (optional)">
          <input className="input" value={f.dose} onChange={set('dose')} placeholder="e.g. 20 ml" />
        </Field>
        <Field label="How it was given">
          <select className="input" value={f.route} onChange={set('route')}>
            {drugRoutes.map((r) => (
              <option key={r} value={r}>
                {words(r)}
              </option>
            ))}
          </select>
        </Field>
        {vets.length > 0 && (
          <Field label="Vet (optional)">
            <select className="input" value={f.vetId} onChange={set('vetId')}>
              <option value="">No vet</option>
              {vets.map((v) => (
                <option key={v.id} value={v.id}>
                  {v.body.name}
                  {v.body.org ? ` · ${v.body.org}` : ''}
                </option>
              ))}
            </select>
          </Field>
        )}
        <Field label="Given by (optional)">
          <input className="input" value={f.givenBy} onChange={set('givenBy')} placeholder="e.g. the vet’s name" />
        </Field>
        {boss && (
          <Field label="Cost, UGX (optional)" hint="Drugs and the vet’s fee. Goes to Money as a health expense.">
            <input className="input" type="number" min={0} step={500} inputMode="numeric" value={f.cost} onChange={set('cost')} />
          </Field>
        )}
        {boss && Number(f.cost) > 0 && (
          <Field label="Paid by">
            <select className="input" value={f.payMethod} onChange={set('payMethod')}>
              {payMethods.map((m) => (
                <option key={m} value={m}>
                  {payMethodName[m]}
                </option>
              ))}
            </select>
          </Field>
        )}
        <Field label="Note (optional)">
          <input className="input" value={f.note} onChange={set('note')} />
        </Field>
      </Fit>
    </FormDialog>
  );
}
