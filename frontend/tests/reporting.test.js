import test from 'node:test';
import assert from 'node:assert/strict';
import { reportBuckets } from '../src/services/reporting.js';
process.env.TZ = 'Europe/Paris';
test('overnight clipping, weekly total and weekday distribution agree', () => {
  const sessions = [{ start: '2026-10-12T23:00:00', end: '2026-10-13T01:00:00' }, { start: '2026-10-12T08:00:00', end: '2026-10-12T16:00:00' }];
  const report = reportBuckets(sessions, '2026-10-12', '2026-10-13');
  assert.deepEqual(report.daily.map(row => row.hours), [9, 1]);
  assert.equal(report.weekly[0].hours, 10);
  assert.deepEqual(report.weekday.map(row => row.hours), [9, 1, 0, 0, 0, 0, 0]);
  assert.equal(reportBuckets(sessions, '2026-10-13', '2026-10-13').daily[0].hours, 1);
});
test('empty data and period validation', () => {
  assert.deepEqual(reportBuckets([], '2026-10-12', '2026-10-13').daily.map(row => row.hours), [0, 0]);
  for (const [from, to] of [['2026-02-30', '2026-03-01'], ['bad', '2026-10-12'], ['2026-10-13','2026-10-12'], ['2024-01-01','2026-10-12']]) assert.throws(() => reportBuckets([], from, to));
});
test('Paris spring and autumn DST use elapsed hours', () => {
  for (const [start, end, day, expected] of [
    ['2026-03-29T01:00:00+01:00','2026-03-29T04:00:00+02:00','2026-03-29',2],
    ['2026-10-25T01:00:00+02:00','2026-10-25T04:00:00+01:00','2026-10-25',4],
  ]) {
    const report = reportBuckets([{ start, end }], day, day);
    assert.equal(report.daily[0].hours, expected);
    assert.equal(report.weekly[0].hours, expected);
    assert.equal(report.weekday[6].hours, expected);
  }
});
