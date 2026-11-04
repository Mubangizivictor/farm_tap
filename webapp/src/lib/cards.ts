// The farm's card register (decision 0016): nfcCards/{4-digit number}, the
// same records the phone reads to know who a tapped card belongs to.
// One holder per card; a card is revoked (returned or lost) before it can
// go to someone else, and a lost card never works again.

import type { Firestore } from 'firebase/firestore';
import { localIso } from './dates.ts';
import type { FarmRecord, NfcCardBody } from './domain.ts';

/** Lowest free 4-digit card number, so no two people ever share a card. */
export function nextFreeCard(taken: Set<string>): string {
  for (let n = 1; n < 10000; n++) {
    const c = String(n).padStart(4, '0');
    if (!taken.has(c)) return c;
  }
  return '';
}

/** "12", "FT 0012" -> "0012"; null when it is not a card number. */
export function cardNumber(typed: string): string | null {
  const t = typed.trim();
  if (!/^[A-Za-z ]*\d{1,4}$/.test(t)) return null;
  return t.replace(/\D/g, '').padStart(4, '0');
}

export const activeCardOf = (cards: FarmRecord<NfcCardBody>[], personId: string) =>
  cards.find((c) => !c.isDeleted && c.body.personId === personId && (c.body.status ?? 'active') === 'active') ?? null;

/** Why this number cannot be given to [personId], or null when it can. */
export function cardProblem(cards: FarmRecord<NfcCardBody>[], number: string, personId: string): string | null {
  const c = cards.find((x) => x.id === number && !x.isDeleted);
  if (!c) return null;
  if (c.body.status === 'lost') return `Card ${number} was reported lost and can never be used again.`;
  if ((c.body.status ?? 'active') === 'active' && c.body.personId !== personId) return `Card ${number} already belongs to ${c.body.personName || 'someone else'}.`;
  return null;
}

/** Numbers already in the register (any status) plus numbers written on people. */
export function takenNumbers(cards: FarmRecord<NfcCardBody>[], extra: (string | null | undefined)[] = []): Set<string> {
  return new Set([...cards.map((c) => c.id), ...extra.filter((x): x is string => !!x)]);
}

type Upsert = (db: Firestore, tenantId: string, name: string, id: string, uid: string, body: Record<string, unknown>) => Promise<void>;

export function issueBody(personId: string, personType: 'staff' | 'farmer', personName: string, chipId: string | null = null): NfcCardBody {
  return { personId, personType, personName, status: 'active', chipId, issuedAt: localIso(new Date()), endedAt: null };
}

export async function giveCard(
  upsert: Upsert,
  db: Firestore,
  tenantId: string,
  uid: string,
  cards: FarmRecord<NfcCardBody>[],
  number: string,
  person: { id: string; kind: 'staff' | 'farmer'; name: string },
): Promise<void> {
  const problem = cardProblem(cards, number, person.id);
  if (problem) throw new Error(problem);
  const old = cards.find((c) => c.id === number);
  await upsert(db, tenantId, 'nfcCards', number, uid, { ...issueBody(person.id, person.kind, person.name, old?.body.chipId ?? null) });
}

export async function endCard(
  upsert: Upsert,
  db: Firestore,
  tenantId: string,
  uid: string,
  card: FarmRecord<NfcCardBody>,
  why: 'returned' | 'lost',
): Promise<void> {
  await upsert(db, tenantId, 'nfcCards', card.id, uid, { ...card.body, status: why, endedAt: localIso(new Date()) });
}
