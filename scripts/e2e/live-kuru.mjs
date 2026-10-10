/* E2E: Kuru flow on the canonical graduated launch through apps/retro-ui:
 * margin deposit -> limit order -> (resting) -> cancel -> withdraw. */
import { chromium } from '/opt/retropick/node_modules/.pnpm/playwright@1.62.1/node_modules/playwright/index.mjs';

const base = process.env.APP_URL ?? 'http://127.0.0.1:3000';
const token = process.argv[2] ?? '0x43e7e9b1b7d9A143573307b13D14B51580c18f15';

const browser = await chromium.launch();
const page = await browser.newPage();
const errors = [];
page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
await page.goto(`${base}/launchpad/token/${token}`, { waitUntil: 'networkidle' });

const connect = page.getByRole('button', { name: 'Connect wallet' }).first();
if (await connect.isVisible()) {
  await connect.click();
  await page.waitForSelector('button:has-text("0xB505")', { timeout: 15000 });
}
console.log('wallet connected');
let mounted = false;
for (let attempt = 0; attempt < 3 && !mounted; attempt += 1) {
  try {
    await page.waitForSelector('.kuru-ticket', { timeout: 20000 });
    mounted = true;
  } catch {
    console.log('kuru ticket not mounted, reloading…');
    await page.reload({ waitUntil: 'networkidle' });
  }
}
if (!mounted) throw new Error('kuru ticket never mounted');
const ticket = page.locator('.kuru-ticket');
console.log('kuru ticket mounted');
console.log('margin lines:', (await ticket.locator('.quote-lines').innerText()).replace(/\n/g, ' | '));

async function confirm(buttonLabel) {
  const target = buttonLabel === 'Deposit' || buttonLabel === 'Withdraw'
    ? ticket.locator(`.form-grid button:has-text("${buttonLabel}")`)
    : ticket.locator('button.btn.primary');
  await target.click();
  const toast = page.locator('[data-sonner-toast]').first();
  await toast.waitFor({ timeout: 120000 });
  const text = (await toast.textContent()).trim();
  console.log('toast:', text);
  await page.waitForTimeout(1500);
  return text;
}

// 1. deposit only if the margin account is empty (prior runs may have funded it)
const marginLine = await ticket.locator('.quote-lines').innerText();
const monMargin = Number((marginLine.match(/MON\n([\d.]+)/) ?? ['0', '0'])[1]);
console.log('margin MON:', monMargin);
if (monMargin < 0.01) {
  await ticket.locator('input').nth(0).fill('0.02');
  await confirm('Deposit');
}

// 2. place a deep resting limit buy (won't cross): 0.000001 MON per token, 1000 tokens
await page.getByRole('tab', { name: 'Buy' }).first().click();
await ticket.locator('input').nth(2).fill('0.000001'); // price
await ticket.locator('input').nth(3).fill('1000'); // size
await page.waitForTimeout(800);
await ticket.locator('button.btn.primary').click();
await page.waitForTimeout(4000);
const formError = await page.locator('.kuru-ticket .form-error').innerText().catch(() => '(none)');
console.log('order error state:', formError);
const toast = await page.locator('[data-sonner-toast]').allInnerTexts().catch(() => []);
console.log('toasts:', JSON.stringify(toast));
if (formError === '(none)') { await page.locator('[data-sonner-toast]').first().waitFor({ timeout: 60000 }); }

// 3. open orders should list it; cancel it
await page.waitForSelector('.open-order', { timeout: 10000 });
console.log('open order visible');
await ticket.locator('.open-order button').first().click();
await page.locator('[data-sonner-toast]').first().waitFor({ timeout: 60000 }).catch(() => {});
console.log('cancel sent');

// 4. withdraw the margin balance
await page.waitForTimeout(2500);
const marginAfter = await ticket.locator('.quote-lines').innerText();
const monAfter = Number((marginAfter.match(/MON\n([\d.]+)/) ?? ['0', '0'])[1]);
await ticket.locator('input').nth(1).fill(String(Math.max(0, monAfter - 0.001)));
await confirm('Withdraw');

console.log(JSON.stringify({ errors }, null, 2));
await browser.close();
