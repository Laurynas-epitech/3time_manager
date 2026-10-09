const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');

const base = process.env.OFFLINE_TEST_URL || 'http://127.0.0.1:5173';
const api = process.env.OFFLINE_TEST_API || 'http://127.0.0.1:4000/api';
const password = crypto.randomBytes(16).toString('hex');

async function queue(page) {
  return page.evaluate(() => new Promise((resolve, reject) => {
    const request = indexedDB.open('time-manager-offline', 1);
    request.onerror = () => reject(request.error);
    request.onsuccess = () => {
      const db = request.result;
      const read = db.transaction('actions').objectStore('actions').getAll();
      read.onsuccess = () => { resolve(read.result); db.close(); };
      read.onerror = () => { reject(read.error); db.close(); };
    };
  }));
}

async function waitQueue(page, count) {
  const deadline = Date.now() + 45000;
  while (Date.now() < deadline) {
    if ((await queue(page)).length === count) return;
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  console.log('Queue timeout diagnostic:', await page.locator('body').innerText());
  assert.equal((await queue(page)).length, count, 'Queue did not reach the expected count');
}

async function register(page, label) {
  const email = `offline-${label}-${crypto.randomBytes(6).toString('hex')}@example.invalid`;
  await page.goto(`${base}/register`);
  await page.locator('#reg-username').fill(`Offline ${label}`);
  await page.locator('#reg-email').fill(email);
  await page.locator('#reg-password').fill(password);
  await page.locator('#reg-confirm').fill(password);
  const response = page.waitForResponse(response => response.url() === `${api}/auth/register`);
  await page.getByRole('button', { name: 'Create account', exact: true }).click();
  const user = (await (await response).json()).data;
  await page.waitForURL(`${base}/`);
  await page.getByRole('button', { name: /^Clock in$/i }).waitFor();
  await page.waitForFunction(() => !document.querySelector('.clock-button')?.disabled);
  return { ...user, email };
}

async function serverData(context, page, path) {
  const csrf = await page.evaluate(() => localStorage.getItem('tm_csrf_token'));
  const response = await context.request.get(`${api}${path}`, { headers: { 'X-CSRF-Token': csrf } });
  assert.equal(response.status(), 200);
  return (await response.json()).data;
}

(async () => {
  const browser = await chromium.launch({
    headless: true,
    ...(process.env.BROWSER_EXECUTABLE_PATH ? { executablePath: process.env.BROWSER_EXECUTABLE_PATH } : {}),
  });
  try {
    const context = await browser.newContext({ viewport: { width: 390, height: 844 } });
    let page = await context.newPage();
    const errors = [];
    const trackErrors = page => page.on('pageerror', error => errors.push(error.message));
    trackErrors(page);
    const user = await register(page, 'A');
    assert.equal(await page.getByRole('button', { name: 'Continue in Demo Mode' }).count(), 0);
    await page.waitForFunction(() => !!navigator.serviceWorker.controller, null, { timeout: 45000 });
    await context.setOffline(true);
    await page.reload();
    await page.getByRole('button', { name: /^Clock in$/i }).click();
    await page.getByRole('button', { name: /^Clock out$/i }).click();
    await waitQueue(page, 2);
    await page.locator('.punch-card').waitFor();
    await page.locator('.hours-report .stats').waitFor();
    assert.equal(await page.locator('.hours-report .error-msg').count(), 0);
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth), true, 'Mobile dashboard must fit the viewport');
    await page.getByRole('button', { name: 'This week', exact: true }).click();
    await page.locator('.hours-report .bars').waitFor();
    assert.equal(await page.locator('.hours-report .error-msg').count(), 0, 'Period switching must work from offline snapshots');
    await page.close();
    page = await context.newPage();
    trackErrors(page);
    await page.goto(`${base}/`);
    await page.locator('.punch-card').waitFor();
    assert.equal(await page.locator('.punch-card').count(), 1);
    const otherTab = await context.newPage();
    trackErrors(otherTab);
    await otherTab.goto(`${base}/`);
    await otherTab.getByRole('button', { name: /^Clock in$/i }).waitFor();
    await page.getByRole('button', { name: /^Clock in$/i }).click();
    await otherTab.getByRole('button', { name: /^Clock out$/i }).waitFor();
    await otherTab.getByRole('button', { name: /^Clock out$/i }).click();
    await page.getByRole('button', { name: /^Clock in$/i }).waitFor();
    await otherTab.close();
    await waitQueue(page, 4);
    const saved = await queue(page);
    assert.deepEqual(saved.map(action => action.status), [true, false, true, false]);
    console.log('PASS: production app reopens offline; clock actions and history survive closing the tab.');

    let dropped = false;
    await page.route(`${api}/clock/*`, async route => {
      if (process.env.OFFLINE_TEST_DEBUG) console.log('Clock request:', route.request().method(), route.request().postData());
      if (route.request().method() === 'POST' && !dropped) {
        const accepted = await route.fetch();
        assert.equal(accepted.status(), 201);
        dropped = true;
        await route.abort('failed');
      } else { await route.continue(); }
    });
    await context.setOffline(false);
    await page.getByText('Connection unavailable. Saved actions will retry automatically.').waitFor();
    assert.equal((await queue(page)).length, 4);
    await page.getByRole('button', { name: 'Synchronise now' }).click();
    await waitQueue(page, 0);
    await page.waitForFunction(() => document.querySelectorAll('.punch-card').length === 2);
    const clocks = await serverData(context, page, `/clock/${user.id}`);
    if (process.env.OFFLINE_TEST_DEBUG) console.log('Server clocks:', clocks, 'Queue:', await queue(page), 'Saved:', saved);
    assert.equal(clocks.length, 4);
    assert.deepEqual(clocks.map(clock => clock.client_action_id), saved.map(action => action.id));
    assert.deepEqual(clocks.map(clock => clock.time), saved.map(action => action.timestamp));
    assert.equal((await serverData(context, page, `/workingtime/${user.id}`)).length, 2);
    console.log('PASS: reconnect replays FIFO with original timestamps; lost acknowledgement retries create no duplicates.');

    await page.getByRole('button', { name: 'Synchronise now' }).waitFor();
    await context.setOffline(true);
    await page.getByRole('button', { name: /^Clock in$/i }).click();
    await page.getByRole('button', { name: /^Clock out$/i }).click();
    await waitQueue(page, 2);
    await context.setOffline(false);
    await waitQueue(page, 0);
    assert.equal((await serverData(context, page, `/workingtime/${user.id}`)).length, 3);
    console.log('PASS: a normal reconnect synchronises attendance automatically without pressing a button.');

    await context.setOffline(true);
    await page.getByRole('button', { name: /^Clock in$/i }).click();
    await page.getByRole('button', { name: /^Clock out$/i }).click();
    await waitQueue(page, 2);
    await context.clearCookies();
    await context.setOffline(false);
    await page.waitForURL('**/login');
    await page.getByText('Session expired. Sign in again; your pending attendance is saved.').waitFor();
    assert.equal((await queue(page)).length, 2);
    const other = await register(page, 'B');
    assert.equal((await queue(page)).length, 2);
    assert.deepEqual(await serverData(context, page, `/clock/${other.id}`), []);
    assert.equal(await page.locator('.punch-card').count(), 0);
    await page.getByRole('button', { name: /^Account menu for/ }).click();
    await page.getByRole('button', { name: 'Log out', exact: true }).click();
    await page.waitForURL('**/login');
    await page.locator('#login-email').fill(user.email);
    await page.locator('#login-password').fill(password);
    await page.getByRole('button', { name: 'Log in', exact: true }).click();
    await page.waitForURL(`${base}/`);
    await waitQueue(page, 0);
    assert.equal((await serverData(context, page, `/clock/${user.id}`)).length, 8);
    assert.equal((await serverData(context, page, `/workingtime/${user.id}`)).length, 4);
    await page.getByRole('button', { name: 'Synchronise now' }).waitFor();
    console.log('PASS: expired sessions retain actions; another account cannot see or upload them; original login resumes sync.');

    await page.getByRole('button', { name: /^Clock in$/i }).waitFor();
    // Let all redesigned dashboard snapshot refreshes settle before simulating
    // another device changing the server's clock state.
    await page.waitForLoadState('networkidle');
    const csrf = await page.evaluate(() => localStorage.getItem('tm_csrf_token'));
    const external = await context.request.post(`${api}/clock/${user.id}`, {
      headers: { 'X-CSRF-Token': csrf },
      data: { clock: { time: new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'), status: true } },
    });
    assert.equal(external.status(), 201);
    await context.setOffline(true);
    await page.getByRole('button', { name: /^Clock in$/i }).click();
    await waitQueue(page, 1);
    await context.setOffline(false);
    try {
      await page.getByText(/Synchronisation stopped:/).waitFor({ timeout: 45000 });
    } catch (error) {
      console.log('Conflict diagnostic:', await page.locator('body').innerText(), 'Queue:', await queue(page));
      throw error;
    }
    assert.equal((await queue(page)).length, 1);
    await context.setOffline(true);
    await page.getByRole('button', { name: /^Account menu for/ }).click();
    await page.getByRole('button', { name: 'Log out', exact: true }).click();
    await page.waitForURL('**/login');
    await page.reload();
    await page.getByRole('button', { name: 'Log in', exact: true }).waitFor();
    assert.equal((await queue(page)).length, 1);
    assert.deepEqual(errors, []);
    console.log('PASS: conflicts preserve pending actions; offline logout removes cached access without deleting the queue.');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
