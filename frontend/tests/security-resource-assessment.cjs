const fs = require('node:fs');
const assert = require('node:assert/strict');
const { performance } = require('node:perf_hooks');
const base = process.env.SECURITY_ASSESSMENT_API || 'http://127.0.0.1:4000/api';
assert.ok(['localhost', '127.0.0.1'].includes(new URL(base).hostname), 'Local assessment only');
const fixtures = JSON.parse(fs.readFileSync(process.env.SECURITY_ASSESSMENT_FIXTURES, 'utf8'));
(async () => {
  const login = await fetch(base + '/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: fixtures.actors.admin.email, password: fixtures.password }) });
  assert.equal(login.status, 200);
  const cookie = login.headers.get('set-cookie').split(';')[0];
  const { csrf_token } = await login.json();
  const headers = { Cookie: cookie, 'X-CSRF-Token': csrf_token, 'Content-Type': 'application/json' };
  const id = fixtures.actors.employee.id;
  const capped = [];
  for (const [path, cap] of [['/users?limit=999999',500], ['/teams?limit=999999',50],
    [`/teams/${fixtures.team_id}/members?limit=999999`,100], [`/workingtime/${id}?limit=999999`,2000],
    [`/clock/${id}?limit=999999`,2000]]) {
    const response = await fetch(base + path, { headers });
    assert.equal(response.status, 200);
    const text = await response.text();
    const rows = JSON.parse(text).data;
    assert.equal(rows.length, cap);
    if (path.startsWith('/teams?')) assert.ok(rows.every(team => team.members.length <= 100));
    capped.push({ path, rows: rows.length, bytes: Buffer.byteLength(text) });
  }
  const latencies = [];
  const begin = performance.now();
  let next = 0;
  await Promise.all(Array.from({ length: 4 }, async () => {
    while (next < 40) {
      next++;
      const start = performance.now();
      const response = await fetch(base + '/users?limit=999999', { headers });
      assert.equal(response.status, 200);
      assert.equal((await response.json()).data.length, 500);
      latencies.push(performance.now() - start);
    }
  }));
  latencies.sort((a,b) => a-b);
  const readDuration = performance.now() - begin;
  let accepted = 0, blocked = 0;
  for (let n = 0; n < 121; n++) {
    const response = await fetch(base + '/teams', { method: 'POST', headers,
      body: JSON.stringify({ team: { name: `Disposable resource ${n}` } }) });
    if (response.status === 201) accepted++;
    else { assert.equal(response.status, 429); assert.ok(Number(response.headers.get('retry-after')) >= 1); blocked++; }
    await response.arrayBuffer();
  }
  assert.ok(accepted <= 120 && blocked >= 1);
  assert.equal((await fetch(base + '/users', { headers })).status, 200);
  const logout = await fetch(base + '/auth/logout', { method: 'POST', headers });
  assert.equal(logout.status, 204);
  const replay = await fetch(base + '/auth/me', { headers });
  assert.equal(replay.status, 200, 'Documented copied-token replay limit changed; reassess it');
  console.log(JSON.stringify({ capped, read_requests:40, concurrency:4, read_duration_ms:readDuration,
    read_p95_ms:latencies[Math.ceil(latencies.length*.95)-1], writes_accepted:accepted, writes_blocked:blocked,
    copied_cookie_and_csrf_after_logout: replay.status, bcrypt_cost:fixtures.bcrypt_cost, hash_ms:fixtures.hash_ms }));
})().catch(error => { console.error(error); process.exitCode=1; });
