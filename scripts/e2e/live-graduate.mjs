/* E2E FLOW C: complete the fresh launch's bonding curve with a terminal buy
 * through apps/retro-ui, then graduate (auto or explicit) and verify the
 * resulting Kuru market. */
import { chromium } from '/opt/retropick/node_modules/.pnpm/playwright@1.62.1/node_modules/playwright/index.mjs';

const base = process.env.APP_URL ?? 'http://127.0.0.1:3000';
const token = process.argv[2];
if (!token) throw new Error('token address required');
const rpc = 'https://testnet-rpc.monad.xyz';
const viem = await import('/home/ubuntu/project/retropick/retropick-protocol/apps/retro-ui/node_modules/viem/_esm/index.js');
const { createPublicClient, http, formatUnits } = viem;
const client = createPublicClient({ transport: http(rpc) });
const curveAbi = [
  { type: 'function', name: 'readyToGraduate', stateMutability: 'view', inputs: [], outputs: [{ type: 'bool' }] },
  { type: 'function', name: 'completionQuote', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint256' }, { type: 'uint256' }] },
  { type: 'function', name: 'getReserves', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint256' }, { type: 'uint256' }] },
] ;
const packetAbi = [{ type: 'function', name: 'packet', stateMutability: 'view', inputs: [{ type: 'address' }], outputs: [{ type: 'tuple', components: [{ name: 'token', type: 'address' }, { name: 'curve', type: 'address' }] }] }];
const coordinator = '0xaD62309242EA65BB07C833669EC6a4ED23AF738F';

const browser = await chromium.launch();
const page = await browser.newPage();
const errors = [];
page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
await page.goto(`${base}/launchpad/token/${token}`, { waitUntil: 'networkidle' });
const connect = page.getByRole('button', { name: 'Connect wallet' }).first();
if (await connect.isVisible()) { await connect.click(); await page.waitForSelector('button:has-text("0xB505")', { timeout: 15000 }); }
const ticket = page.locator('.token-trade-ticket');

async function ensureConnected() {
  const connected = await page.locator('button:has-text("0xB505")').count();
  if (!connected) {
    const btn = page.getByRole('button', { name: 'Connect wallet' }).first();
    if (await btn.isVisible()) {
      await btn.click();
      await page.waitForSelector('button:has-text("0xB505")', { timeout: 15000 });
    }
  }
}

async function curveState() {
  const packet = await client.readContract({ address: coordinator, abi: packetAbi, functionName: 'packet', args: [token] });
  const curve = packet.curve ?? packet[0]?.curve ?? packet[1];
  const [ready, completion, reserves] = await Promise.all([
    client.readContract({ address: curve, abi: curveAbi, functionName: 'readyToGraduate' }),
    client.readContract({ address: curve, abi: curveAbi, functionName: 'completionQuote' }),
    client.readContract({ address: curve, abi: curveAbi, functionName: 'getReserves' }),
  ]);
  return { curve, ready, terminal: completion[0] ?? completion[0n], quote: reserves[0] ?? reserves[0n] };
}

let state = await curveState();
console.log('curve:', state.curve, '| terminal:', formatUnits(state.terminal, 18), 'MON | reserve:', formatUnits(state.quote, 18), '| ready:', state.ready);

// Keep buying through the UI ticket until the curve reports readiness.
let guard = 0;
while (!state.ready && guard < 4) {
  guard += 1;
  // Terminal purchase: buy() clamps output at the remaining sellable supply
  // and refunds the unspendable quote (CurveBuyRefunded + CurveCompleted).
  const chunk = 12n * 10n ** 17n; // 1.2 MON gross; excess refunds
  const amount = Number(formatUnits(chunk, 18)).toFixed(4).slice(0, 8);
  console.log('buying', amount, 'MON (round', guard, ')');
  const input = ticket.locator('input[inputmode="decimal"]').first();
  const before = state.quote;
  await input.fill('');
  await input.fill(amount);
  await ticket.locator('button.btn.primary').click();
  // The bridge already waits for the receipt; poll the curve until it advances.
  for (let waited = 0; waited < 180; waited += 3) {
    await page.waitForTimeout(3000);
    const next = await curveState();
    if (next.quote > before || next.ready) { state = next; break; }
  }
  console.log('reserve now:', formatUnits(state.quote, 18), '| ready:', state.ready);
  if (state.ready) break;
  await page.reload({ waitUntil: 'networkidle' }).catch(() => {});
  await page.waitForSelector('.token-trade-ticket', { timeout: 30000 });
  await ensureConnected();
}
if (!state.ready) throw new Error('curve still not ready after buys');

// Explicit graduation through the UI (idempotent if auto-graduation already ran).
await page.reload({ waitUntil: 'networkidle' });
await page.waitForSelector('.token-trade-ticket', { timeout: 30000 });
await ensureConnected();
await page.waitForTimeout(2000);
const graduateButton = page.locator('button:has-text("Graduate")');
const phaseText = await page.locator('.launch-progress span').last().innerText().catch(() => '');
console.log('phase before graduate:', phaseText);
let graduated = false;
for (let attempt = 0; attempt < 3 && !graduated; attempt += 1) {
  if (await graduateButton.count()) {
    await graduateButton.first().click();
    console.log('graduate clicked (attempt', attempt + 1, ')');
    for (let waited = 0; waited < 60; waited += 3) {
      await page.waitForTimeout(3000);
      const check = await curveState().catch(() => state);
      if (check.ready === false && check.quote === 0n) { graduated = true; break; } // curve drained = graduated
      state = check;
    }
    if (!graduated) {
      const ledgerPhase = await fetch(`${rpc}` , { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'eth_call', params: [{ to: coordinator, data: '0x' }, 'latest'] }) }).catch(() => null);
      await page.reload({ waitUntil: 'networkidle' }).catch(() => {});
      await page.waitForSelector('.token-trade-ticket', { timeout: 30000 });
      await ensureConnected();
    }
  } else {
    console.log('no graduate button; phase may already be past CURVE');
    break;
  }
}
console.log('graduated:', graduated);
await page.reload({ waitUntil: 'networkidle' });
await page.waitForTimeout(4000);
const lifecycle = await page.locator('.meta-row span').last().innerText().catch(() => '?');
console.log('final lifecycle:', lifecycle);
console.log(JSON.stringify({ errors }, null, 2));
await browser.close();
