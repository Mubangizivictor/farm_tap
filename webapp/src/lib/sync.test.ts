// The web writes what the phone reads: PIN hashes, tasks and the card register.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { hashPin, pinProblem } from './pin.ts';
import { nextTag, tagTaken, taskBody, taskView, type AnimalBody, type FarmRecord, type NfcCardBody } from './domain.ts';
import { cardNumber, cardProblem, nextFreeCard, takenNumbers } from './cards.ts';

const rec = <T>(id: string, body: T, isDeleted = false): FarmRecord<T> => ({
  id,
  tenantId: 't',
  collection: 'x',
  body,
  createdAt: '2026-11-04T07:00:00.000',
  updatedAt: '2026-11-04T07:00:00.000',
  createdBy: 'owner',
  updatedBy: 'owner',
  deviceId: 'web-1',
  version: 1,
  isDeleted,
});

test('PIN hash matches the phone (same RFC 7914 vector as pin_security_test.dart)', async () => {
  const stored = await hashPin('passwd', new TextEncoder().encode('salt'), 1);
  assert.equal(stored, 'pbkdf2-sha256$1$c2FsdA==$VawEblbjCJ/sFpHCJUS2BflBhSFt3gRl5oudV8INrLw=');
});

test('a new PIN uses 20000 rounds and a fresh 16-byte salt', async () => {
  const a = await hashPin('4821');
  const b = await hashPin('4821');
  assert.match(a, /^pbkdf2-sha256\$20000\$[A-Za-z0-9+/]{22}==\$[A-Za-z0-9+/]{43}=$/);
  assert.notEqual(a, b);
});

test('easy PINs are refused', () => {
  assert.equal(pinProblem('4821'), null);
  assert.ok(pinProblem('1234'));
  assert.ok(pinProblem('7777'));
  assert.ok(pinProblem('12a4'));
});

test('tasks: the phone shape and the older web shape read the same', () => {
  const phone = taskView({ title: 'Spray', staffId: 's1', due: '2026-11-04T18:00:00.000', when: 'before 10:00', doneAt: null });
  assert.equal(phone.staffId, 's1');
  assert.equal(phone.done, false);
  const old = taskView({ title: 'Old', assignedTo: 's2', dueDate: '2026-11-04T00:00:00.000', status: 'done' } as never);
  assert.equal(old.staffId, 's2');
  assert.equal(old.done, true);
});

test('tasks are written with every field the phone needs', () => {
  const b = taskBody({ title: 'Fix fence', staffId: 's1', due: new Date(2026, 10, 6, 18), when: '', doneAt: null }, (d) => d.toISOString());
  for (const k of ['title', 'staffId', 'due', 'when', 'doneAt']) assert.ok(k in b, k);
  assert.equal(typeof b.staffId, 'string');
  assert.equal(typeof b.when, 'string');
});

test('cards: the next free number skips any used before, even returned ones', () => {
  const cards = [rec<NfcCardBody>('0001', { personId: 'a', personType: 'staff', personName: 'A', status: 'returned' } as NfcCardBody)];
  assert.equal(nextFreeCard(takenNumbers(cards, ['0002'])), '0003');
  assert.equal(cardNumber('FT 12'), '0012');
  assert.equal(cardNumber('12345'), null);
});

test('cards: a card in use or lost cannot be given', () => {
  const cards = [
    rec<NfcCardBody>('0101', { personId: 'tom', personType: 'staff', personName: 'Tom', status: 'active' } as NfcCardBody),
    rec<NfcCardBody>('0102', { personId: 'amos', personType: 'staff', personName: 'Amos', status: 'lost' } as NfcCardBody),
  ];
  assert.match(cardProblem(cards, '0101', 'grace') ?? '', /Tom/);
  assert.equal(cardProblem(cards, '0101', 'tom'), null);
  assert.match(cardProblem(cards, '0102', 'grace') ?? '', /lost/);
  assert.equal(cardProblem(cards, '0200', 'grace'), null);
});

test('animals: next tag follows the highest, and a tag in use is refused', () => {
  const herd = [rec<AnimalBody>('a1', { tagNumber: 'FT-007', status: 'active' } as AnimalBody), rec<AnimalBody>('a2', { tagNumber: 'FT-012', status: 'sold' } as AnimalBody)];
  assert.equal(nextTag(herd), 'FT-013');
  assert.equal(tagTaken(herd, 'ft-007'), true);
  assert.equal(tagTaken(herd, 'FT-007', 'a1'), false);
  assert.equal(tagTaken(herd, 'FT-012'), false);
});
