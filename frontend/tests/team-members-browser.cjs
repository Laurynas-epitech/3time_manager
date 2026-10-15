const { chromium } = require('playwright');
const assert = require('node:assert/strict');
(async () => {
  const browser = await chromium.launch({headless:true, ...(process.env.PLAYWRIGHT_CHANNEL ? {channel:process.env.PLAYWRIGHT_CHANNEL} : {})});
  try {
    const page = await browser.newPage();
    page.setDefaultTimeout(10000);
    await page.addInitScript(() => localStorage.setItem('tm_csrf_token', 'fictional-csrf'));
    const manager = {id:1, username:'Manager', role:'manager'};
    const employee = {id:2, username:'New employee', email:'new@example.invalid', role:'employee'};
    const team = {id:10, name:'Managed team', manager, members:[]};
    let added = false;
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.route('**/api/**', async route => {
      const {pathname} = new URL(route.request().url());
      let data;
      if (pathname === '/api/auth/me') data = manager;
      else if (['/api/clock/1', '/api/workingtime/1'].includes(pathname)) data = [];
      else if (pathname === '/api/teams') data = [team];
      else if (pathname === '/api/teams/10/member-candidates') data = [employee];
      else if (pathname === '/api/teams/10/members/2' && route.request().method() === 'POST') {
        added = true; team.members = [employee]; data = team;
      } else throw Error('Unexpected API call: ' + pathname);
      await route.fulfill({json:{data}});
    });
    await page.goto((process.env.TEAM_MEMBERS_TEST_URL || 'http://127.0.0.1:5173') + '/teams');
    const select = page.getByRole('combobox', {name:'Add a member to Managed team', exact:true});
    await page.getByRole('option', {name:'New employee (new@example.invalid)', exact:true}).waitFor({state:'attached'});
    await select.selectOption('2');
    await page.getByRole('button', {name:'Add', exact:true}).click();
    await page.getByRole('cell', {name:'New employee', exact:true}).waitFor();
    assert.ok(added);
    assert.equal(await select.locator('option[value="2"]').count(), 0);
    assert.deepEqual(errors, []);
    console.log('PASS: manager selects a new employee, adds them, and sees updated membership without page errors.');
  } finally {await browser.close();}
})().catch(error => {console.error(error); process.exitCode=1;});



