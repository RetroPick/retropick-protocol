/* E2E helper: connect the session-bridge wallet and run a small live curve buy
 * on a given token through apps/retro-ui. Used for flow validation evidence. */
import { chromium } from '/opt/retropick/node_modules/.pnpm/playwright@1.62.1/node_modules/playwright/index.mjs';

const base = process.env.APP_URL ?? 'http://127.0.0.1:3000';
const token = process.argv[2] ?? '0xd7b2ce2ebbf672255d339006f046c4ef7025d609';
const amount = process.argv[3] ?? '0.001';
const side = (process.argv[4] ?? 'buy').toLowerCase() === 'sell' ? 'sell' : 'buy';

const browser = await chromium.launch();
const page = await browser.newPage();
const errors = [];
page.on('console', (message) => { if (message.type() === 'error') errors.push(message.text()); });
await page.goto(`${base}/launchpad/token/${token}`, { waitUntil: 'networkidle' });

const connect = page.getByRole('button', { name: 'Connect wallet' }).first();
if (await connect.isVisible()) {
  await connect.click();
  await page.waitForSelector('button:has-text("0xB505")', { timeout: 15000 });
}
console.log('wallet connected');

const ticket = page.locator('.token-trade-ticket');
await page.getByRole('tab', { name: side === 'buy' ? 'Buy' : 'Sell' }).click();
const input = ticket.locator('input[inputmode="decimal"]');
await input.click();
await input.fill('');
await input.fill(amount);
try {
  await page.waitForFunction(() => {
    const strong = document.querySelectorAll('.quote-lines strong');
    return strong.length >= 2 && strong[0].textContent !== null && strong[0].textContent.trim() !== '—';
  }, { timeout: 20000 });
  console.log('quote ready');
} catch {
  console.log('QUOTE_TIMEOUT lines:', JSON.stringify(await page.locator('.quote-lines').allInnerTexts().catch(() => 'n/a')));
  console.log('ticket html snippet:', (await ticket.innerHTML().catch(() => 'n/a')).slice(0, 1500));
  console.log('balance line:', await ticket.locator('.quote-lines').last().innerText().catch(() => 'n/a'));
  throw new Error('quote never appeared');
}

const label = side === 'buy' ? 'Buy' : 'Sell';
const submit = ticket.locator('button.btn.primary');
await submit.click();
const toast = page.locator('[data-sonner-toast]').first();
await toast.waitFor({ timeout: 90000 });
console.log('toast:', (await toast.textContent())?.trim());
const result = { side, amount, toast: await toast.textContent(), errors };
console.log(JSON.stringify(result, null, 2));
await browser.close();
