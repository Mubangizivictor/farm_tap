'use client';

import {
  collection,
  doc,
  getDoc,
  onSnapshot,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  type Firestore,
} from 'firebase/firestore';
import { useEffect, useState } from 'react';
import { localIso } from './dates.ts';
import { farmFromDoc, type Farm, type FarmRecord } from './domain.ts';
import { firebase } from './firebase.ts';

/** The account's farms: users/{uid}.memberships, role from tenants/{t}/members/{uid}. */
export async function loadFarms(uid: string): Promise<Farm[]> {
  const { db } = firebase();
  const user = await getDoc(doc(db, 'users', uid));
  const list = ((user.data()?.memberships as { tenantId: string }[] | undefined) ?? []).map((m) => m.tenantId);
  const ids = [...new Set(list)];
  const farms = await Promise.all(
    ids.map(async (id) => {
      try {
        const [t, m] = await Promise.all([getDoc(doc(db, 'tenants', id)), getDoc(doc(db, 'tenants', id, 'members', uid))]);
        if (!t.exists() || !m.exists()) return null;
        return farmFromDoc(id, t.data(), m.data());
      } catch {
        return null; // no longer a member: the rules refuse the read
      }
    }),
  );
  return farms.filter((f): f is Farm => f != null);
}

export interface Live<T> {
  data: T[];
  loading: boolean;
  error: string | null;
}

/**
 * Live list of a farm collection (online only, decision 0017). [since]
 * limits it to records made on or after that local ISO day, by createdAt.
 */
export function useRecords<B>(tenantId: string | null, name: string, since?: string): Live<FarmRecord<B>> {
  const [state, setState] = useState<Live<FarmRecord<B>>>({ data: [], loading: true, error: null });
  useEffect(() => {
    if (!tenantId) return;
    setState((s) => ({ ...s, loading: true }));
    const { db } = firebase();
    const col = collection(db, 'tenants', tenantId, name);
    const q = since ? query(col, where('createdAt', '>=', since)) : col;
    return onSnapshot(
      q,
      (snap) =>
        setState({
          data: snap.docs.map((d) => d.data() as FarmRecord<B>).filter((r) => r && r.body && !r.isDeleted),
          loading: false,
          error: null,
        }),
      (e) => setState({ data: [], loading: false, error: e.code ?? e.message }),
    );
  }, [tenantId, name, since]);
  return state;
}

/** Device id for records saved from this browser: "web-" + random, kept per browser. */
export function webDeviceId(): string {
  const key = 'farmtap.deviceId';
  try {
    const saved = localStorage.getItem(key);
    if (saved) return saved;
    const id = `web-${crypto.randomUUID()}`;
    localStorage.setItem(key, id);
    return id;
  } catch {
    return 'web-browser';
  }
}

/**
 * Saves a new record with the same base fields the phone uses, so
 * firestore.rules accept it and every phone pulls it on its next sync.
 */
export async function addRecord(
  db: Firestore,
  tenantId: string,
  name: string,
  uid: string,
  body: Record<string, unknown>,
  id: string = crypto.randomUUID(),
): Promise<string> {
  const now = localIso(new Date());
  await setDoc(doc(db, 'tenants', tenantId, name, id), {
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
  });
  return id;
}

/**
 * Saves a new version of a record, the way the phone's RecordJournal.put
 * does: the whole body is replaced (so pass the full body; use
 * [mergeBody] to start from the stored one), version goes up by one.
 * Only for collections that may change (not milk, money or deliveries,
 * which are append-only: a correction there is a new record).
 */
export async function putRecord(
  db: Firestore,
  tenantId: string,
  rec: FarmRecord<object>,
  uid: string,
  body: Record<string, unknown>,
): Promise<void> {
  const now = localIso(new Date());
  await updateDoc(doc(db, 'tenants', tenantId, rec.collection, rec.id), {
    body,
    updatedAt: now,
    updatedBy: uid,
    deviceId: webDeviceId(),
    version: (rec.version ?? 1) + 1,
    serverUpdatedAt: serverTimestamp(),
  });
}

/** The stored body with [patch] on top (keeps fields the web does not show, like the PIN). */
export const mergeBody = (rec: FarmRecord<object>, patch: Record<string, unknown>) => ({
  ...(rec.body as Record<string, unknown>),
  ...patch,
});

/**
 * Creates the record, or saves a new version when it already exists
 * (records with a fixed id, like `nfcCards/{number}` or `staffPins/{staffId}`).
 */
export async function upsertRecord(
  db: Firestore,
  tenantId: string,
  name: string,
  id: string,
  uid: string,
  body: Record<string, unknown>,
): Promise<void> {
  const snap = await getDoc(doc(db, 'tenants', tenantId, name, id));
  if (!snap.exists()) {
    await addRecord(db, tenantId, name, uid, body, id);
    return;
  }
  await putRecord(db, tenantId, snap.data() as FarmRecord<object>, uid, body);
}

/**
 * Soft delete (the phone's RecordJournal.remove): the record stays, marked
 * deleted, body unchanged. Allowed for every collection, append-only too.
 */
export async function removeRecord(db: Firestore, tenantId: string, rec: FarmRecord<object>, uid: string): Promise<void> {
  const now = localIso(new Date());
  await updateDoc(doc(db, 'tenants', tenantId, rec.collection, rec.id), {
    isDeleted: true,
    updatedAt: now,
    updatedBy: uid,
    deviceId: webDeviceId(),
    version: (rec.version ?? 1) + 1,
    serverUpdatedAt: serverTimestamp(),
  });
}

/** Friendly text for a Firestore error code. */
export function saveError(code: string | undefined): string {
  switch (code) {
    case 'permission-denied':
      return 'You are not allowed to save this. Only the owner or manager can, and not after the free trial ends.';
    case 'unavailable':
      return 'No internet. Check your connection and try again.';
    case 'failed-precondition':
    case 'not-found':
      return 'This record changed or was removed on another device. Close it and open it again.';
    default:
      return 'Could not save. Try again.';
  }
}
