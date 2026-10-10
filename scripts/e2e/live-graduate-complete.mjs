import { chromium } from '/opt/retropick/node_modules/.pnpm/playwright@1.62.1/node_modules/playwright/index.mjs';
const browser = await chromium.launch();
const page = await browser.newPage();
const errors = [];
page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
await page.goto('http://127.0.0.1:3000/launchpad/token/0x30CcB65006665022Dfc97bB5c1985610503Fd1cf', { waitUntil: 'networkidle' });
const connect = page.getByRole('button', { name: 'Connect wallet' }).first();
if (await connect.isVisible()) { await connect.click(); await page.waitForSelector('button:has-text("0xB505")', { timeout: 15000 }); }
await page.waitForSelector('.token-trade-ticket', { timeout: 30000 });
await page.waitForTimeout(3000);
const complete = page.locator('button:has-text("Complete graduation")');
console.log('complete button:', await complete.count());
if (await complete.count()) {
  await complete.first().click();
  await page.waitForTimeout(60000);
}
await page.reload({ waitUntil: 'networkidle' });
await page.waitForTimeout(5000);
const lifecycle = await page.locator('.meta-row span').last().innerText().catch(() => '?');
console.log('final lifecycle:', lifecycle);
console.log('errors:', JSON.stringify(errors));
await browser.close();
