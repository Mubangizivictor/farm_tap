'use client';

// Linked spending (decision 0023): every record that costs money (a feed
// purchase, a wage, a treatment, a supplier bill, a vaccination, a breeding
// service) saves its expense in the same write, so Money and the module can
// never disagree. Expenses and most money records are append-only on the
// server, so a change is "remove the old pair, save the new pair", again in
// one write. The phone reads the same records (expenses.sourceId).

import { doc, serverTimestamp, writeBatch, type Firestore } from 'firebase/firestore';
import { localIso } from './dates.ts';
import { webDeviceId } from './data.ts';
import type { ExpenseBody, FarmRecord, PayMethod, SpendSource } from './domain.ts';

export interface NewRecord {
  collection: string;
  body: Record<string, unknown>;
  id?: string;
}

export interface ExpenseSpec {
  category: string;
  amount: number;
  at: string;
  note?: string | null;
  supplierId?: string | null;
  payMethod?: PayMethod | null;
}

function base(tenantId: string, name: string, id: string, uid: string, body: Record<string, unknown>) {
  const now = localIso(new Date());
  return {
    id,
    tenantId,
    collection: name,
    body,
    createdAt: now,
    updatedAt: now,
    createdBy: uid,
    updatedBy: uid,
    deviceId: webDeviceId(),
    version: 1,
    isDeleted: false,
    serverUpdatedAt: serverTimestamp(),
  };
}

/** Body of the expense a source record makes. Same keys the phone writes, plus the links. */
export function expenseBody(sourceId: string, sourceType: SpendSource, e: ExpenseSpec): ExpenseBody {
  return {
    category: e.category,
    amount: Math.round(e.amount),
    at: e.at,
    note: e.note?.trim() || null,
    sourceId,
    sourceType,
    supplierId: e.supplierId || null,
    payMethod: e.payMethod ?? null,
    photo: null,
  };
}

/**
 * Saves a record and, when it cost money, its expense, in one write. With
 * [replace], the old record and every expense it made are removed in the
 * same write (that is how an edit works on append-only records).
 */
export async function saveWithExpense(
  db: Firestore,
  tenantId: string,
  uid: string,
  rec: NewRecord,
  sourceType: SpendSource,
  expense: ExpenseSpec | null,
  replace?: { record: FarmRecord<object>; expenses: FarmRecord<ExpenseBody>[] },
): Promise<string> {
  const batch = writeBatch(db);
  const id = rec.id ?? crypto.randomUUID();
  if (replace) {
    softDeleteIn(batch, db, tenantId, replace.record, uid);
    for (const e of replace.expenses) softDeleteIn(batch, db, tenantId, e, uid);
  }
  batch.set(doc(db, 'tenants', tenantId, rec.collection, id), base(tenantId, rec.collection, id, uid, rec.body));
  if (expense && expense.amount > 0) {
    const eid = crypto.randomUUID();
    batch.set(doc(db, 'tenants', tenantId, 'expenses', eid), base(tenantId, 'expenses', eid, uid, { ...expenseBody(id, sourceType, expense) }));
  }
  await batch.commit();
  return id;
}

/** Removes a record and the expenses it made, in one write (soft delete, as the phone does). */
export async function removeWithExpenses(
  db: Firestore,
  tenantId: string,
  uid: string,
  record: FarmRecord<object> | null,
  expenses: FarmRecord<ExpenseBody>[],
): Promise<void> {
  const batch = writeBatch(db);
  if (record) softDeleteIn(batch, db, tenantId, record, uid);
  for (const e of expenses) softDeleteIn(batch, db, tenantId, e, uid);
  await batch.commit();
}

function softDeleteIn(batch: ReturnType<typeof writeBatch>, db: Firestore, tenantId: string, rec: FarmRecord<object>, uid: string) {
  batch.update(doc(db, 'tenants', tenantId, rec.collection, rec.id), {
    isDeleted: true,
    updatedAt: localIso(new Date()),
    updatedBy: uid,
    deviceId: webDeviceId(),
    version: (rec.version ?? 1) + 1,
    serverUpdatedAt: serverTimestamp(),
  });
}

/** The live expenses a record made. */
export const expensesOf = (sourceId: string, expenses: FarmRecord<ExpenseBody>[]) =>
  expenses.filter((e) => !e.isDeleted && e.body.sourceId === sourceId);
