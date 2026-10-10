import { test, expect, expectClean } from '../helpers/test';

// Live read-only target: real Monad Testnet + indexer from apps/retro-ui/.env.local. No wallet (mock wallet rejects all
// signing), network guard blocks any signing/broadcast JSON-RPC. Unreachable infrastructure is reported as an
// ENVIRONMENT skip, never as an app pass.
const INDEXER = process.env.LIVE_INDEXER_URL ?? 'http://127.0.0.1:8787';
let feed: { data: Array<{ token: string; phase: string; symbol: string }> } | null = null;
let reason = '';
test.beforeAll(async () => {
  try {
    const r = await fetch(`${INDEXER}/v1/launches?limit=20`, { signal: AbortSignal.timeout(5000) });
    if (!r.ok) reason = `indexer HTTP ${r.status}`; else feed = await r.json();
  } catch (e) { reason = `ENVIRONMENT: indexer unreachable at ${new URL(INDEXER).host} (${(e as Error).message})`; }
});

test('@live discovery renders indexed launches read-only', async ({ page, observed }) => {
  test.skip(!feed, reason);
  await page.goto('/launchpad');
  await expect(page.getByTestId('discovery')).toHaveAttribute('data-data-mode', 'live');
  await expect(page.getByTestId('launch-row').first()).toBeVisible();
  expectClean(observed);
});

for (const phase of ['ACTIVE', 'GRADUATED']) {
  test(`@live ${phase} token terminal renders from indexer + chain without signing`, async ({ page, observed, snap }) => {
    test.skip(!feed, reason);
    const launch = feed!.data.find((l) => l.phase === phase);
    test.skip(!launch, `no ${phase} launch indexed`);
    await page.goto(`/launchpad/token/${launch!.token}`);
    const terminal = page.getByTestId('token-terminal');
    await expect(terminal).toHaveAttribute('data-data-mode', 'live');
    await expect(terminal).toHaveAttribute('data-lifecycle', phase);
    await expect(terminal.locator('[data-provenance="demo"]')).toHaveCount(0);
    await expect(terminal).toContainText(launch!.symbol);
    await expect(page.getByTestId('token-price')).not.toHaveText('—');
    await expect(page.locator('[data-chart-mode="Line"] canvas').first()).toBeVisible();
    await expect(terminal.locator('a[href*="testnet.monadexplorer.com"]').first()).toBeVisible();
    if (test.info().project.name.startsWith('mobile')) await page.getByTestId('mobile-trade-bar').getByRole('button', { name: 'Trade' }).tap();
    const ticket = page.getByTestId('trade-ticket');
    await expect(ticket).toBeVisible();
    await expect(ticket.getByRole('button', { name: /Connect wallet/ })).toBeVisible();
    if (phase === 'ACTIVE') await expect(ticket.getByRole('radiogroup', { name: 'Order type' }).getByRole('radio', { name: 'Limit' })).toHaveAttribute('aria-disabled', 'true');
    if (phase === 'GRADUATED') await expect(ticket).toContainText('Kuru orderbook');
    await snap(`live-${phase.toLowerCase()}`);
    expectClean(observed);
  });
}
