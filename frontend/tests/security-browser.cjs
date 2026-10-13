// Run only against an isolated local server with disposable data.
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const base = process.env.SECURITY_TEST_URL || 'http://127.0.0.1:5173';
const backend = process.env.SECURITY_TEST_BACKEND || 'http://127.0.0.1:4000';
if (!['localhost', '127.0.0.1'].includes(new URL(base).hostname) ||
    !['localhost', '127.0.0.1'].includes(new URL(backend).hostname)) {
  throw new Error('Security probes require an isolated localhost server.');
}

(async () => {
  const browser = await chromium.launch({ headless: true,
    ...(process.env.BROWSER_EXECUTABLE_PATH ? { executablePath: process.env.BROWSER_EXECUTABLE_PATH } : {}) });
  const context = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const page = await context.newPage();
  const dialogs = [];
  page.on('dialog', async dialog => { dialogs.push(dialog.message()); await dialog.dismiss(); });
  let user;
  let csrf;
  try {
    await page.goto(`${base}/register`);
    const email = `security-${crypto.randomBytes(6).toString('hex')}@example.invalid`;
    const password = crypto.randomBytes(16).toString('hex');
    await page.locator('#reg-username').fill('Security probe');
    await page.locator('#reg-email').fill(email);
    await page.locator('#reg-password').fill(password);
    await page.locator('#reg-confirm').fill(password);
    const registration = page.waitForResponse(r => r.url() === `${base}/api/auth/register`);
    await page.getByRole('button', { name: 'Create account', exact: true }).click();
    const response = await registration;
    assert.equal(response.status(), 201);
    user = (await response.json()).data;
    await page.waitForURL(`${base}/`);
    csrf = await page.evaluate(() => localStorage.getItem('tm_csrf_token'));
    const headers = { 'X-CSRF-Token': csrf };

    const jwt = (await context.cookies()).find(cookie => cookie.name === 'tm_jwt');
    assert.ok(jwt?.httpOnly, 'JWT must be HttpOnly');
    assert.equal(await page.evaluate(() => document.cookie.includes('tm_jwt=')), false);
    assert.equal(await page.evaluate(() => Object.values(localStorage).some(value =>
      /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/.test(value))), false);

    const payloads = ['<svg/onload=window.__securityProbe=1>',
      '<script>window.__securityProbe=1</script>', '<b id="security-probe">bold</b>'];
    for (const width of [390, 1440]) {
      await page.setViewportSize({ width, height: 900 });
      for (const username of payloads) {
        const update = await context.request.put(`${base}/api/users/${user.id}`, {
          headers, data: { user: { username } },
        });
        assert.equal(update.status(), 200);
        await page.reload();
        await page.waitForFunction(expected => document.querySelector('.account-name')?.textContent === expected, username);
        assert.equal(await page.locator('.account-name svg, .account-name script, .account-name b').count(), 0);
        assert.equal(await page.evaluate(() => window.__securityProbe), undefined);
        assert.deepEqual(dialogs, []);
      }
    }
    console.log('PASS: stored SVG/script/HTML payloads render as text at 390px and 1440px; JWT is inaccessible to page JS/storage.');

    const filtered = await context.request.get(`${base}/api/users`, {
      headers, params: { scope: 'all', email: "' OR 1=1 --" },
    });
    assert.equal(filtered.status(), 200);
    assert.deepEqual((await filtered.json()).data, []);
    assert.equal((await context.request.put(`${base}/api/users/${user.id}/role`, {
      headers, data: { role: 'admin' },
    })).status(), 403);
    const noCsrf = await context.request.get(`${base}/api/auth/me`);
    assert.equal(noCsrf.status(), 401);
    assert.equal(noCsrf.headers()['x-content-type-options'], 'nosniff');
    console.log('PASS: SQL-style filter payload does not broaden results; employee role escalation and missing CSRF are rejected.');

    for (const path of ['/.env', '/.git/config', '/config/runtime.exs', '/dev/dashboard', '/dev/mailbox']) {
      const probe = await context.request.get(`${backend}${path}`);
      assert.equal(probe.status(), 404, `Backend must not expose ${path}`);
    }
    console.log('PASS: local dev-mode backend exposes none of the tested configuration/diagnostic paths.');
  } finally {
    if (user && csrf) {
      const cleanup = await context.request.delete(`${base}/api/users/${user.id}`, {
        headers: { 'X-CSRF-Token': csrf },
      });
      assert.equal(cleanup.status(), 204);
    }
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
