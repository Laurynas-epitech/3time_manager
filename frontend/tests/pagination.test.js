import { test } from 'node:test';
import assert from 'node:assert/strict';
import { collectPages } from '../src/services/pagination.js';

test('downloads records beyond old user/team/history caps', async () => {
  for (const count of [201, 501, 2001]) {
    const rows = Array.from({ length: count }, (_, id) => ({ id }));
    const result = await collectPages(async ({ limit, offset }) => rows.slice(offset, offset + limit));
    assert.deepEqual(result, rows);
  }
});

test('newest-first pages returned oldest-first preserve all sessions', async () => {
  const rows = Array.from({ length: 2001 }, (_, id) => ({ id }));
  const descending = [...rows].reverse();
  const result = await collectPages(async ({ limit, offset }) => descending.slice(offset, offset + limit).reverse(), { reversePages: true });
  assert.deepEqual(result, rows);
});

test('exact full pages fetch the next page and repeated pages fail visibly', async () => {
  const rows = Array.from({ length: 50 }, (_, id) => ({ id }));
  const offsets = [];
  assert.deepEqual(await collectPages(async ({ offset }) => {
    offsets.push(offset);
    return rows.slice(offset);
  }), rows);
  assert.deepEqual(offsets, [0, 50]);
  await assert.rejects(collectPages(async () => rows), /List changed/);
});

test('a failed or invalid page never returns a partial list', async () => {
  const rows = Array.from({ length: 50 }, (_, id) => ({ id }));
  await assert.rejects(collectPages(async ({ offset }) => {
    if (offset) throw new Error('network failure');
    return rows;
  }), /network failure/);
  await assert.rejects(collectPages(async () => ({})), /Invalid list/);
  await assert.rejects(collectPages(async () => rows, { maxPages: 1 }), /too large/);
});
