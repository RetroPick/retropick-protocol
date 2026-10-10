/* E2E FLOW A: create a real launch through apps/retro-ui, decode TokenLaunched,
 * land on the token page. Prints the created token address for later flows. */
import { chromium } from '/opt/retropick/node_modules/.pnpm/playwright@1.62.1/node_modules/playwright/index.mjs';

const base = process.env.APP_URL ?? 'http://127.0.0.1:3000';
const suffix = String(Date.now()).slice(-5);
const browser = await chromium.launch();
const page = await browser.newPage();
const errors = [];
page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
await page.goto(`${base}/launchpad/create?type=crypto`, { waitUntil: 'networkidle' });

const connect = page.getByRole('button', { name: 'Connect wallet' }).first();
if (await connect.isVisible()) {
  await connect.click();
  await page.waitForSelector('button:has-text("0xB505")', { timeout: 15000 });
}
console.log('wallet connected');

await page.getByRole('textbox', { name: /^Name/ }).fill(`Retro Live ${suffix}`);
await page.getByRole('textbox', { name: /^Ticker/ }).fill(`RTL${suffix.slice(-3)}`);
await page.getByRole('button', { name: 'Continue' }).click();
await page.waitForSelector('h2:has-text("2 · Economics")');
console.log('economics step visible');

// admit MON + Kuru venue (defaults); submit
await page.locator('select').nth(0).selectOption({ index: 0 }).catch(() => {});
const launchButton = page.locator('button.btn.primary:has-text("Launch")');
await launchButton.waitFor({ timeout: 20000 });
await launchButton.click();
await page.waitForTimeout(6000);
console.log('post-click error:', await page.locator('.form-error').innerText().catch(() => '(none)'));
console.log('post-click status:', await page.locator('[data-tx-phase]').innerText().catch(() => '(none)'));
await page.waitForSelector('h1:has-text("is live")', { timeout: 180000 });
const heading = await page.locator('h1').first().innerText();
const link = await page.locator('a.btn.primary').first().getAttribute('href');
const tx = await page.locator('.tx-hash').first().innerText().catch(() => '');
console.log('success heading:', heading);
console.log('token route:', link);
console.log('tx hash:', tx);
console.log(JSON.stringify({ link, tx, errors }, null, 2));
await browser.close();
