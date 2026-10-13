// Isolated local assessment; fixtures are created by backend/priv/security_assessment_seed.exs.
const { chromium, request } = require('playwright');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const base = process.env.SECURITY_ASSESSMENT_URL || 'http://127.0.0.1:5173';
assert.ok(['localhost','127.0.0.1'].includes(new URL(base).hostname), 'Local assessment only');
const fixtures = JSON.parse(fs.readFileSync(process.env.SECURITY_ASSESSMENT_FIXTURES, 'utf8'));
const payloads = ['<svg/onload=window.__assessmentExecuted=1>',
  '<script>window.__assessmentExecuted=1</script>', '<b id="assessment-injected">bold</b>'];
(async () => {
  const browser = await chromium.launch({headless:true,
    ...(process.env.BROWSER_EXECUTABLE_PATH ? {executablePath:process.env.BROWSER_EXECUTABLE_PATH} : {})});
  const admin = await request.newContext();
  let cases=0;
  const dialogs=[];
  try {
    const login = await admin.post(base+'/api/auth/login', {data:{email:fixtures.actors.admin.email,password:fixtures.password}});
    assert.equal(login.status(),200);
    const headers={'X-CSRF-Token':(await login.json()).csrf_token};
    // One browser role at a time bounds host memory and avoids parallel UI bursts.
    for(const role of ['admin','manager','employee']) {
      const context=await browser.newContext();
      try {
        const page=await context.newPage();
        page.on('dialog',async dialog=>{dialogs.push(dialog.message());await dialog.dismiss();});
        await page.goto(base+'/login');
        await page.locator('#login-email').fill(fixtures.actors[role].email);
        await page.locator('#login-password').fill(fixtures.password);
        await page.getByRole('button',{name:'Log in',exact:true}).click();
        await page.waitForURL(base+'/');
        for(const payload of payloads) {
          const update=await admin.put(base+'/api/users/'+fixtures.actors[role].id,{headers,data:{user:{username:payload}}});
          assert.equal(update.status(),200);
          const team=await admin.put(base+'/api/teams/'+fixtures.team_id,{headers,data:{team:{name:payload}}});
          assert.equal(team.status(),200);
          for(const width of [390,1440]) {
            await page.setViewportSize({width,height:900});
            for(const path of ['/profile','/teams',...(role==='admin'?['/admin']:[])]) {
              await page.goto(base+path);
              await page.waitForFunction(expected=>document.querySelector('.account-name')?.textContent===expected,payload);
              if(path==='/profile') assert.equal(await page.locator('#p-username').inputValue(),payload);
              if(path==='/teams') {
                try { await page.waitForFunction(expected=>[...document.querySelectorAll('h2')].some(h=>h.textContent===expected),payload); }
                catch(error) {
                  console.log(JSON.stringify({diagnostic:'team list',role,width,url:page.url(),headings:(await page.locator('h2').allTextContents()).slice(0,4),errors:await page.locator('.error-msg').allTextContents()}));
                  throw error;
                }
                assert.ok(await page.locator('.team-header').count()<=10);
                if(role==='admin') {
                  const picker=page.locator('.add-member').first();
                  assert.ok(await picker.locator('select option').count()<=51);
                  await picker.locator('input[type="search"]').fill('fixture-501@assessment.invalid');
                  await page.waitForFunction(()=>document.querySelector('.add-member select')?.textContent.includes('fixture-501@assessment.invalid'));
                  await picker.locator('input[type="search"]').fill('');
                }
              }
              if(path==='/admin') {
                try {
                  await page.waitForFunction(()=>document.querySelectorAll('tbody tr').length===50);
                  assert.match(await page.locator('[aria-label="User pages"]').innerText(),/505 users/);
                  await page.getByRole('button',{name:'Next users',exact:true}).click();
                  assert.equal(await page.locator('tbody tr:first-child td:first-child').innerText(),'#51');
                  await page.getByRole('button',{name:'Previous users',exact:true}).click();
                }
                catch(error) {
                  console.log(JSON.stringify({diagnostic:'admin list',url:page.url(),rows:await page.locator('tbody tr').count(),errors:await page.locator('.error-msg').allTextContents()}));
                  throw error;
                }
              }
              assert.equal(await page.locator('#assessment-injected,svg[onload],script:not([src])').count(),0);
              assert.equal(await page.evaluate(()=>window.__assessmentExecuted),undefined);
              assert.deepEqual(dialogs,[]);
              cases++;
            }
          }
        }
        if(role==='employee') {
          await page.goto(base+'/');
          await page.waitForFunction(async owner=>{
            const db=await new Promise((resolve,reject)=>{
              const open=indexedDB.open('time-manager-offline',1);
              open.onsuccess=()=>resolve(open.result);open.onerror=()=>reject(open.error);
            });
            const read=db.transaction('snapshots').objectStore('snapshots').get(['/api',owner,owner]);
            const result=await new Promise(resolve=>{read.onsuccess=()=>resolve(read.result);});
            db.close();return result?.workingTimes?.length===2001;
          },fixtures.actors.employee.id);
          await page.waitForFunction(()=>!!navigator.serviceWorker.controller);
          await context.setOffline(true);
          await page.evaluate(()=>{
            const key='tm_offline_user:/api';const user=JSON.parse(localStorage.getItem(key));
            user.role='admin';localStorage.setItem(key,JSON.stringify(user));
          });
          await page.reload();
          assert.ok((await page.locator('.tm-role').allTextContents()).includes('admin'));
          await context.setOffline(false);
          const csrf=await page.evaluate(()=>localStorage.getItem('tm_csrf_token'));
          const denied=await context.request.post(base+'/api/teams',{headers:{'X-CSRF-Token':csrf},data:{team:{name:'Attempted elevation'}}});
          assert.equal(denied.status(),403);
          const me=await context.request.get(base+'/api/auth/me',{headers:{'X-CSRF-Token':csrf}});
          assert.equal((await me.json()).data.role,'employee');
        }
      } finally {await context.close();}
    }
    console.log(JSON.stringify({stored_injection_cases:cases,viewports:[390,1440],full_cached_sessions:2001,
      offline_profile_tamper:'UI role mutable; backend privilege denied',dialogs:dialogs.length}));
  } finally {await admin.dispose();await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
