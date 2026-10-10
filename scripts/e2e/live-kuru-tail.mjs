/* E2E tail: verify the resting order is listed, cancel it, withdraw margin. */
import { chromium } from '/opt/retropick/node_modules/.pnpm/playwright@1.62.1/node_modules/playwright/index.mjs';
const base = process.env.APP_URL ?? 'http://127.0.0.1:3000';
const token = '0x43e7e9b1b7d9A143573307b13D14B51580c18f15';
const browser = await chromium.launch();
const page = await browser.newPage();
const errors = [];
page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
await page.goto(`${base}/launchpad/token/${token}`, { waitUntil: 'networkidle' });
const connect = page.getByRole('button', { name: 'Connect wallet' }).first();
if (await connect.isVisible()) { await connect.click(); await page.waitForSelector('button:has-text("0xB505")', { timeout: 15000 }); }
await page.waitForSelector('.kuru-ticket', { timeout: 30000 });
await page.waitForSelector('.open-order', { timeout: 30000 });
const order = page.locator('.open-order').first();
console.log('open order listed:', (await order.innerText()).replace(/\n/g, ' '));
await order.locator('button').click();
await page.waitForTimeout(90000);
const marginLines = await page.locator('.kuru-ticket .quote-lines').innerText();
console.log('margin after cancel:', marginLines.replace(/\n/g, ' | '));
const monMargin = Number((marginLines.match(/MON\n([\d.]+)/) ?? ['0', '0'])[1]);
if (monMargin > 0.001) {
  const ticket = page.locator('.kuru-ticket');
  await ticket.locator('input').nth(1).fill(String(monMargin));
  await ticket.locator('.form-grid button:has-text("Withdraw")').click();
  await page.waitForTimeout(60000);
  console.log('withdraw sent');
}
console.log(JSON.stringify({ errors }, null, 2));
await browser.close();
