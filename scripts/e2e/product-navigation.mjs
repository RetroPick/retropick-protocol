// Read-only real-browser qualification. Wallet requests only accounts/chain; no signing.
import {createRequire} from 'node:module';
import {mkdir,writeFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const require=createRequire(new URL('../../apps/retro-ui/package.json',import.meta.url));
const {chromium}=require('@playwright/test');
const base=process.env.APP_URL??'http://127.0.0.1:3002',indexer=process.env.INDEXER_URL??'http://127.0.0.1:8790';
const feed=await fetch(indexer+'/v1/launches?limit=100').then(r=>r.json());
const browser=await chromium.launch();const results=[];
try{for(const mobile of [false,true]){
 const context=await browser.newContext({viewport:mobile?{width:390,height:844}:{width:1440,height:1000}}),page=await context.newPage();const errors=[];let documents=0;
 page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>{if(r.isNavigationRequest()&&r.frame()===page.mainFrame())documents++;});
 await page.goto(base+'/launchpad',{waitUntil:'domcontentloaded'});await page.locator('.market-table tbody tr').first().waitFor();
 const started=await page.evaluate(()=>performance.timeOrigin);
 // The ticket's Connect action directly uses the already authorized local E2E provider.
 const active=feed.data.find(l=>l.phase==='ACTIVE');assert(active,'An active market is required');
 await page.locator(`a[href="/launchpad/token/${active.token}"]`).first().click();
 const ticket=page.locator('.token-trade-ticket');await ticket.waitFor();await ticket.getByRole('button',{name:'Connect wallet',exact:true}).click();
 await page.locator('[data-wallet-status="connected"]').first().waitFor();
 await page.getByRole('tab',{name:'Candles',exact:true}).click();await page.locator('[aria-label="Candles chart of executed trades"] canvas').first().waitFor();
 await page.getByRole('tab',{name:'Holders',exact:true}).click();await page.getByRole('tab',{name:'Protocol',exact:true}).click();
 await page.locator('.back-link').click();await page.locator('.market-table tbody tr').first().waitFor();
 await page.locator(`a[href="/launchpad/token/${active.token}"]`).first().click();await ticket.waitFor();
 assert.equal(await page.locator('[data-wallet-status="connected"]').count()>0,true,'Wallet survives routes');assert.equal(await page.evaluate(()=>performance.timeOrigin),started);assert.equal(documents,1,'Internal links must not reload');
 await page.goBack();await page.locator('.market-table tbody tr').first().waitFor();
 for(const label of ['New','Active','Near graduation','Graduated','Market cap']){await page.getByRole('button',{name:label,exact:true}).click();await page.waitForTimeout(150);}
 await page.getByLabel('Pair filter').selectOption('');
 await page.getByRole('button',{name:'Search tokens and markets',exact:true}).filter({visible:true}).first().click();await page.getByRole('textbox',{name:'Search Launchpad and PRISM'}).fill(active.symbol);await page.getByRole('dialog').locator(`a[href="/launchpad/token/${active.token}"]`).waitFor();await page.keyboard.press('Escape');
 await page.locator('a[href="/earn"]').filter({visible:true}).first().click();await page.getByRole('heading',{name:'Earn & Portfolio'}).waitFor();assert(!/Bags|0 SOL|Demo snapshot|demo positions/.test(await page.locator('main').innerText()));
 const shot=`evidence/launchpad/productization/browser/${mobile?'mobile':'desktop'}.png`;await mkdir('evidence/launchpad/productization/browser',{recursive:true});await page.screenshot({path:shot,fullPage:true});
 results.push({mobile,documents,walletRetained:true,pageErrors:errors});assert.deepEqual(errors,[]);await context.close();
}}finally{await browser.close();}
await writeFile('evidence/launchpad/productization/browser/navigation.json',JSON.stringify(results,null,2));console.log(JSON.stringify(results,null,2));
