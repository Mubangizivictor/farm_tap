import { test } from 'node:test';
import assert from 'node:assert/strict';
import { rowSizes } from './fit.ts';

test('one item is full width', () => assert.deepEqual(rowSizes(1, 4), [1]));
test('fewer items than columns share one row', () => {
  assert.deepEqual(rowSizes(2, 4), [2, 2]);
  assert.deepEqual(rowSizes(3, 4), [3, 3, 3]);
});
test('rows are balanced, no empty column', () => {
  assert.deepEqual(rowSizes(4, 3), [2, 2, 2, 2]);
  assert.deepEqual(rowSizes(5, 3), [3, 3, 3, 2, 2]);
  assert.deepEqual(rowSizes(6, 4), [3, 3, 3, 3, 3, 3]);
  assert.deepEqual(rowSizes(3, 2), [2, 2, 1]);
  assert.deepEqual(rowSizes(7, 6), [4, 4, 4, 4, 3, 3, 3]);
});
test('every item is counted', () => {
  for (let n = 0; n < 20; n++) for (let c = 1; c < 7; c++) assert.equal(rowSizes(n, c).length, n);
});
