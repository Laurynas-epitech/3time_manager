const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const fixtures = JSON.parse(fs.readFileSync(process.env.REMEDIATION_FIXTURES, 'utf8'));
const base = process.env.REMEDIATION_URL || 'http://127.0.0.1:5173';
if (!['localhost', '127.0.0.1'].includes(new URL(base).hostname)) throw Error('Local disposable verification only');
(async () => {
  const browser = await chromium.launch({ headless: true, ...(process.env.BROWSER_EXECUTABLE_PATH ? { executablePath: process.env.BROWSER_EXECUTABLE_PATH } : {}) });
  const context = await browser.newContext({ timezoneId: 'Europe/Paris', viewport: { width: 1440, height: 1000 } });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  async function login(label) {
    await context.clearCookies();
    await page.goto(`${base}/login`);
    await page.evaluate(() => { localStorage.clear(); sessionStorage.clear(); });
    await page.reload();
    await page.locator('#login-email').fill(fixtures.users[label].email);
    await page.locator('#login-password').fill(fixtures.password);
    await page.locator('form button[type=submit]').click();
    await page.waitForURL(`${base}/`);
  }
  async function fit(path) {
    await page.goto(base + path);
    await page.waitForTimeout(350);
    assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1), `Overflow: ${path}`);
  }
  try {
    await login('manager');
    const id = fixtures.users.one.id;
    await page.goto(`${base}/team?team=${fixtures.team_id}&user=${id}`);
    const report = page.locator('section').filter({ has: page.getByRole('heading', { name: 'Team averages', exact: true }) });
    await report.locator('input[type=date]').nth(0).fill('2026-10-12');
    await report.locator('input[type=date]').nth(1).fill('2026-10-13');
    await report.locator('select').selectOption('UTC');
    await report.getByRole('button', { name: 'Show averages' }).click();
    await report.getByText('3 members', { exact: false }).waitFor();
    assert.deepEqual(await report.locator('tbody tr').allTextContents(), ['2026-10-1212.004.00', '2026-10-136.002.00', '2026-10-12 – 2026-10-13 (partial week)18.006.00']);
    await page.getByRole('button', { name: 'Empty report team', exact: true }).click();
    await report.getByText('No members', { exact: true }).waitFor();
    await page.getByRole('button', { name: 'Fixed report team', exact: true }).click();
    await report.getByText('3 members', { exact: false }).waitFor();
    await page.goto(`${base}/chartManager/${id}`);
    await page.getByRole('heading', { name: 'Working hours charts' }).waitFor();
    await page.getByLabel('From', { exact: true }).fill('2026-10-12');
    await page.getByLabel('Through', { exact: true }).fill('2026-10-13');
    await page.getByRole('button', { name: 'Update charts' }).click();
    await page.waitForFunction(() => document.querySelectorAll('canvas').length === 3);
    assert.equal(await page.locator('canvas').count(), 3);
    assert.ok((await page.locator('table').first().innerText()).includes('total 14.00 h'));
    for (const graph of ['bar', 'line', 'pie']) {
      await page.getByLabel('Graph', { exact: true }).selectOption(graph);
      assert.equal(await page.locator('canvas').count(), 1);
      const pixels = await page.locator('canvas').evaluate(canvas => canvas.width > 0 && canvas.height > 0);
      assert.ok(pixels);
    }
    await page.reload();
    await page.waitForFunction(() => document.querySelectorAll('canvas').length === 3);
    for (const path of [`/workingTimes/${id}`, `/workingTime/${id}`, `/workingTime/${id}/${fixtures.record_id}`, `/clock/${fixtures.users.manager.id}`]) {
      await page.goto(base + path);
      await page.getByRole('heading', { level: 1 }).waitFor();
      await page.reload();
      await page.getByRole('heading', { level: 1 }).waitFor();
      assert.equal(await page.locator('[role=alert]').count(), 0, path);
    }
    await page.goto(`${base}/workingTimes/${id}`);
    await page.getByText('Working times table (UTC)', { exact: true }).click();
    assert.match(await page.locator('.table-summary table').innerText(), /2026-10-12 08:00:00/);
    await page.goto(`${base}/clock/${fixtures.users.manager.id}`);
    await page.getByRole('button', { name: 'Clock in', exact: true }).click();
    await page.getByRole('button', { name: 'Clock out', exact: true }).waitFor();
    await page.getByRole('button', { name: 'Clock out', exact: true }).click();
    await page.getByRole('button', { name: 'Clock in', exact: true }).waitFor();
    assert.equal(await page.locator('[role=alert]').count(), 0);
    // Actual create, edit and delete through the required direct URLs.
    await page.goto(`${base}/workingTime/${id}`);
    await page.getByLabel('Day', { exact: true }).fill('2026-10-14');
    await page.getByLabel('In', { exact: true }).fill('09:00');
    await page.getByLabel('Out', { exact: true }).fill('11:00');
    const create = page.waitForResponse(r => r.url().endsWith(`/api/workingTime/${id}`) && r.request().method() === 'POST');
    await page.getByRole('button', { name: /^Add 2h/ }).click();
    const created = await (await create).json();
    assert.ok(created.data.id);
    await page.goto(`${base}/workingTime/${id}/${created.data.id}`);
    await page.getByLabel('Out', { exact: true }).fill('12:00');
    await page.getByRole('button', { name: /^Save 3h/ }).click();
    await page.waitForURL(`${base}/workingTimes/${id}`);
    await page.goto(`${base}/workingTime/${id}/${created.data.id}`);
    page.once('dialog', dialog => dialog.accept());
    await page.getByRole('button', { name: 'Delete', exact: true }).click();
    await page.waitForURL(`${base}/workingTimes/${id}`);
    // Server validation errors stay visible in both forms.
    for (const path of [`/workingTime/${id}`, `/workingTime/${id}/${fixtures.record_id}`]) {
      await page.route('**/api/workingTime/**', route => ['POST', 'PUT'].includes(route.request().method()) ? route.fulfill({ status: 422, contentType: 'application/json', body: JSON.stringify({ errors: { end: ['must be later than start'] } }) }) : route.continue());
      await page.goto(base + path);
      await page.getByRole('button', { name: /^(Add|Save) \d/ }).click();
      await page.getByRole('alert').filter({ hasText: 'end must be later than start' }).waitFor();
      await page.unroute('**/api/workingTime/**');
    }
    await page.goto(`${base}/chartManager/${fixtures.users.outsider.id}`);
    await page.getByRole('alert').filter({ hasText: 'Forbidden' }).waitFor();
    for (const role of ['employee', 'manager', 'admin']) {
      const label = role === 'employee' ? 'one' : role;
      await login(label);
      const paths = ['/', '/profile', '/teams', `/workingTimes/${fixtures.users[label].id}`, `/clock/${fixtures.users[label].id}`, `/chartManager/${fixtures.users[label].id}`];
      if (role !== 'employee') paths.push('/team', `/workingTime/${id}`);
      if (role === 'admin') paths.push('/admin');
      for (const width of [390, 1440]) {
        await page.setViewportSize({ width, height: 1000 });
        for (const path of paths) await fit(path);
      }
      if (role === 'employee') {
        await page.goto(`${base}/chartManager/${fixtures.users.outsider.id}`);
        await page.getByRole('alert').filter({ hasText: 'Forbidden' }).waitFor();
        await page.goto(`${base}/workingTime/${fixtures.users.one.id}`);
        await page.getByRole('alert').filter({ hasText: 'Only managers' }).waitFor();
      }
    }
    // Keyboard-native graph controls and 200% equivalent viewport sizing.
    await page.goto(`${base}/chartManager/${id}`);
    await page.getByLabel('Graph', { exact: true }).focus();
    await page.keyboard.press('Home'); await page.keyboard.press('ArrowDown');
    await page.keyboard.press('Enter');
    await page.setViewportSize({ width: 720, height: 500 });
    assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1));
    assert.deepEqual(errors, []);
    console.log('PASS: fixed team averages; three rendered/configurable charts and tables; direct routes/reload; create/edit/delete and 422 errors; authorization; role/page 390/1440px matrix; keyboard graph control. No page errors.');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
