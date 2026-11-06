'use client';

// The buttons under an AI chat answer open the real form as a pop-up over the
// chat (decision 0027), so the farmer fills it in, closes it and is still in the
// same conversation. Each pop-up is the same component the full page uses.

import { useMemo } from 'react';
import { ContactForm } from '@/components/popups/ContactForm';
import { RecordTreatment } from '@/components/popups/RecordTreatment';
import { AnimalDetail } from '@/components/popups/AnimalDetail';
import { TaskForm } from '@/components/popups/TaskForm';
import { VetAssistant } from '@/components/VetAssistant';
import { Dialog } from '@/components/ui';
import { addDays, localIso, startOfDay } from '@/lib/dates';
import { useRecords } from '@/lib/data';
import { alive, animalLabel, drugsFrom, isActiveAnimal, manages, type AnimalBody, type ContactBody, type MilkBody, type StaffBody, type StockItemBody, type TreatmentBody } from '@/lib/domain';
import { useFarm } from '@/lib/session';

export type Popup =
  | { kind: 'treatment'; animal: string }
  | { kind: 'task'; title: string; due: string }
  | { kind: 'animal'; id: string }
  | { kind: 'vet'; animal: string }
  | { kind: 'contact' };

/** The pop-up a chat button should open, or null for a button that really goes to another page. */
export function popupOf(href: string): Popup | null {
  const u = new URL(href, 'https://farmtap.local');
  const animal = u.searchParams.get('animal') ?? '';
  if (u.pathname.startsWith('/health') && u.searchParams.has('new')) return { kind: 'treatment', animal };
  if (u.pathname.startsWith('/tasks') && u.searchParams.has('new')) return { kind: 'task', title: u.searchParams.get('title') ?? '', due: u.searchParams.get('due') ?? '' };
  if (u.pathname.startsWith('/herd') && animal) return { kind: 'animal', id: animal };
  if (u.pathname.startsWith('/ai/vet')) return { kind: 'vet', animal };
  if (u.pathname.startsWith('/contacts')) return { kind: 'contact' };
  return null;
}

export function ChatPopup({ popup, onClose, onOpen }: { popup: Popup; onClose: () => void; onOpen: (p: Popup) => void }) {
  const farm = useFarm();
  const boss = manages(farm);
  const needs = popup.kind === 'treatment' || popup.kind === 'animal';
  const animals = useRecords<AnimalBody>(needs ? farm.id : null, 'animals');
  const stock = useRecords<StockItemBody>(popup.kind === 'treatment' ? farm.id : null, 'stockItems');
  const contacts = useRecords<ContactBody>(popup.kind === 'treatment' ? farm.id : null, 'contacts');
  const staff = useRecords<StaffBody>(popup.kind === 'task' ? farm.id : null, 'staff');
  const since = useMemo(() => localIso(addDays(startOfDay(new Date()), -30)), []);
  const milk = useRecords<MilkBody>(popup.kind === 'animal' ? farm.id : null, 'milkRecords', since);
  const treatments = useRecords<TreatmentBody>(popup.kind === 'animal' ? farm.id : null, 'treatments');

  if (popup.kind === 'treatment') {
    if (animals.loading || stock.loading || contacts.loading) return null;
    const herd = animals.data.filter(isActiveAnimal).sort((a, b) => a.body.tagNumber.localeCompare(b.body.tagNumber, undefined, { numeric: true })).map((a) => ({ id: a.id, label: animalLabel(a), body: a.body }));
    const vets = alive(contacts.data).filter((c) => c.body.kind === 'vet' && (boss || c.body.showWorkers !== false));
    return <RecordTreatment animals={herd} drugs={drugsFrom(stock.data)} startAnimal={popup.animal} vets={vets} onClose={onClose} />;
  }
  if (popup.kind === 'task') {
    if (staff.loading) return null;
    return <TaskForm staff={staff.data} preset={{ title: popup.title, due: popup.due }} onClose={onClose} />;
  }
  if (popup.kind === 'animal') {
    if (animals.loading) return null;
    const a = animals.data.find((x) => x.id === popup.id);
    if (!a) return null;
    return <AnimalDetail a={a} milk={milk.data} treatments={treatments.data} onTreat={() => onOpen({ kind: 'treatment', animal: a.id })} onClose={onClose} />;
  }
  if (popup.kind === 'vet') {
    return (
      <Dialog title="Veterinary Assistant" subtitle="Tick what you see. A guide, not a diagnosis." onClose={onClose} size="lg">
        <VetAssistant animal={popup.animal} embedded />
      </Dialog>
    );
  }
  return <ContactForm kind="vet" onClose={onClose} />;
}
