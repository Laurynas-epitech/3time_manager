// Candidate production build, fictional mocked API; never mutates a server.
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const base = process.env.TEAM_STATUS_TEST_URL || 'http://127.0.0.1:5173';
if (!['localhost', '127.0.0.1'].includes(new URL(base).hostname)) throw Error('Local candidate build required');
const manager = { id: 1, username: 'Test manager', email: 'manager@example.invalid', role: 'manager' };
const person = (id, username) => ({ id, username, email: `member-${id}@example.invalid`, role: 'employee' });
const healthy = person(2, 'Healthy colleague'), affected = person(3, 'Affected colleague'), other = person(4, 'Other colleague');
const teams = [{ id: 10, name: 'Test team', manager, members: [healthy, affected] }, { id: 20, name: 'Other test team', manager, members: [other] }];
(async () => {
  const browser = await chromium.launch({ headless: true, ...(process.env.BROWSER_EXECUTABLE_PATH ? { executablePath: process.env.BROWSER_EXECUTABLE_PATH } : {}) });
  const context = await browser.newContext({ timezoneId: 'Europe/Paris', viewport: { width: 390, height: 1000 }, serviceWorkers: 'block' });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  let failures = new Set([3]), held = null, holdNext = true;
  await context.addInitScript(() => localStorage.setItem('tm_csrf_token', 'fictional-csrf'));
  await context.route('**/api/**', async route => {
    const url = new URL(route.request().url());
    const clock = url.pathname.match(/^\/api\/clock\/(\d+)$/);
    const working = url.pathname.match(/^\/api\/workingtime\/(\d+)$/);
    if (clock && Number(clock[1]) === 3 && holdNext) {
      holdNext = false;
      await new Promise(resolve => { held = resolve; });
    }
    if (clock && failures.has(Number(clock[1]))) return route.fulfill({ status: 503, contentType: 'application/json', body: JSON.stringify({ errors: { detail: 'Fictional attendance outage' } }) });
    let data;
    if (url.pathname === '/api/auth/me') data = manager;
    else if (url.pathname === '/api/teams') data = teams;
    else if (clock) data = Number(clock[1]) === 3 ? [{ id: 30, user_id: 3, status: true, time: new Date(Date.now() - 600_000).toISOString() }] : [];
    else if (working) data = [];
    else if (/^\/api\/teams\/\d+\/report$/.test(url.pathname)) data = { member_count: 0, timezone: 'UTC', daily: [], weekly: [] };
    else throw Error('Unexpected mocked API path: ' + url.pathname);
    await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ data }) });
  });
  const card = name => page.locator('.person-card').filter({ has: page.locator('.name', { hasText: name }) });
  const summary = page.locator('.team-title [role=status]');
  const refresh = () => page.getByRole('button', { name: 'Refresh attendance status', exact: true });
  async function waitForHeldResponse() {
    const deadline = Date.now() + 10_000;
    while (!held && Date.now() < deadline) await new Promise(resolve => setTimeout(resolve, 10));
    assert.ok(held, 'Clock request should reach the held response');
  }
  try {
    await page.goto(base + '/team?team=10&user=3');
    await page.getByRole('heading', { name: 'Test team', exact: true }).waitFor();
    await card('Affected colleague').getByText('Loading status…', { exact: true }).waitFor();
    assert.equal(await card('Affected colleague').locator('.today').innerText(), '—');
    assert.match(await summary.innerText(), /Checking status/);
    await page.waitForFunction(() => document.querySelector('.person-card'));
    await waitForHeldResponse();
    held(); held = null;
    await card('Affected colleague').getByText('Status unavailable', { exact: true }).waitFor();
    assert.equal(await card('Affected colleague').locator('.today').innerText(), '—');
    assert.equal(await card('Affected colleague').locator('.today').getAttribute('aria-label'), "Today's hours unavailable");
    assert.equal(await card('Healthy colleague').locator('.today').innerText(), '0:00', 'A confirmed zero remains a genuine zero');
    assert.match(await summary.innerText(), /Status unavailable for 1 person/);
    assert.doesNotMatch(await summary.innerText(), /nobody on the clock/);
    await page.getByRole('alert').filter({ hasText: 'Status unavailable for Affected colleague' }).waitFor();
    assert.equal(await page.locator('.week-card').count(), 0, 'Unknown selected attendance must not display a fabricated zero week');
    failures.clear();
    await refresh().click();
    await card('Affected colleague').locator('.status').filter({ hasText: 'in since ' }).waitFor();
    assert.match(await summary.innerText(), /1 of 2 on the clock/);
    assert.equal(await page.locator('.week-card').count(), 1);
    assert.equal(await page.getByRole('alert').filter({ hasText: 'Status unavailable for Affected colleague' }).count(), 0);
    failures = new Set([2, 3]);
    await refresh().click();
    await page.waitForFunction(() => document.querySelectorAll('.person-card .status').length && [...document.querySelectorAll('.person-card .status')].filter(node => node.textContent.trim() === 'Status unavailable').length === 2);
    assert.equal(await summary.innerText(), 'Status unavailable for 2 people');
    assert.deepEqual(await page.locator('.person-card:not(.self) .today').allTextContents(), ['—', '—']);
    // Offline refresh uses the already downloaded snapshots, without an API call.
    await context.setOffline(true);
    await refresh().click();
    await card('Affected colleague').locator('.status').filter({ hasText: 'in since ' }).waitFor();
    assert.match(await summary.innerText(), /1 of 2 on the clock/);
    await context.setOffline(false);
    failures.clear(); holdNext = true;
    await refresh().click();
    await card('Affected colleague').getByText('Loading status…', { exact: true }).waitFor();
    // Let the request reach the deliberately held response before switching teams.
    await waitForHeldResponse();
    await page.getByRole('button', { name: 'Other test team', exact: true }).click();
    held(); held = null;
    await card('Other colleague').getByText('not in today', { exact: true }).waitFor();
    assert.equal(await summary.innerText(), 'nobody on the clock right now');
    assert.equal(await card('Affected colleague').count(), 0);
    assert.equal(await refresh().isEnabled(), true);
    assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1));
    assert.deepEqual(errors, []);
    console.log('PASS: loading differs from zero; partial/all failures show unavailable and unknown hours; selected zero summary hidden; retry recovers; cached offline attendance preserved; stale team requests ignored; 390px fit and zero page errors.');
  } finally {
    if (held) held();
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
