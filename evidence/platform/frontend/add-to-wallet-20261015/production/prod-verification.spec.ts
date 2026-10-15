import { test, expect } from '@playwright/test';
import { installMockWallet, walletMethodCalls } from '../helpers/mock-wallet';

// PRODUCTION release verification for PR #36 (Add to Wallet, merge 94d08047).
// Read-only against https://retropick.xyz except one mocked wallet_watchAsset click —
// the mock never signs and the only provider method exercised is wallet_watchAsset.
const CIS = '0xc399c1a37d1d202d315f7f4c1a24e34c8e50e50f';
const CIS_LOGO_CID = 'QmSHMEd2FMpQfEzuzMt3arZCStvrY9g4QjU6pJsZNLkKND';

test('CIS page loads with Add to Wallet button and correct metadata (desktop+mobile)', async ({ page }) => {
  await installMockWallet(page);
  const errors: string[] = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  await page.goto(`/launchpad/token/${CIS}`);
  const term = page.getByTestId('token-terminal');
  await expect(term).toBeVisible({ timeout: 30_000 });
  await expect(term).toHaveAttribute('data-data-mode', 'live');
  // Token identity from chain: name, symbol, logo image actually decodes.
  await expect(term.locator('.rp-identity-name')).toContainText('College is Scam');
  await expect(term.locator('.rp-identity-name')).toContainText('CIS');
  const logo = term.locator('.rp-base-logo img').first();
  await expect(logo).toHaveAttribute('src', `https://gateway.pinata.cloud/ipfs/${CIS_LOGO_CID}`);
  await expect.poll(() => logo.evaluate((i: HTMLImageElement) => i.naturalWidth), { timeout: 30_000 }).toBeGreaterThan(0);
  // The Add to Wallet action is present without any wallet interaction.
  await expect(page.getByTestId('add-to-wallet')).toBeVisible();
  // Buy/sell ticket renders (trading surface operational; nothing is signed).
  // Desktop: the rail mounts the ticket. Mobile: the sticky Trade bar opens the bottom sheet.
  if (test.info().project.name.includes('mobile')) {
    const bar = page.getByTestId('mobile-trade-bar');
    await expect(bar).toBeVisible({ timeout: 30_000 });
    await bar.getByRole('button', { name: 'Trade' }).tap();
    await expect(page.getByRole('dialog').getByTestId('trade-ticket')).toBeVisible({ timeout: 30_000 });
  } else {
    await expect(page.getByTestId('trade-ticket')).toBeVisible({ timeout: 30_000 });
  }
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1);
  expect(overflow, 'no horizontal overflow').toBe(false);
  expect(errors, 'no uncaught page errors').toEqual([]);
});

test('Add to Wallet click sends the exact on-chain payload to the wallet', async ({ page }) => {
  await installMockWallet(page);
  await page.goto(`/launchpad/token/${CIS}`);
  await expect(page.getByTestId('add-to-wallet')).toBeVisible({ timeout: 30_000 });
  // Connect the mock wallet through the app's own picker.
  await page.locator('button[data-wallet-status="disconnected"]:visible').first().click();
  await page.getByRole('button', { name: 'E2E Mock Wallet' }).click();
  await expect(page.locator('button[data-wallet-status="connected"]:visible').first()).toBeVisible();
  const button = page.getByTestId('add-to-wallet');
  if (test.info().project.name.includes('mobile')) { await button.focus(); await button.press('Enter'); }
  else await button.click();
  await expect(page.getByText('submitted to your wallet')).toBeVisible({ timeout: 15_000 });
  const calls = await walletMethodCalls<{ params: { type: string; options: Record<string, unknown> } }>(page, 'wallet_watchAsset');
  expect(calls).toHaveLength(1);
  expect(calls[0].params.type).toBe('ERC20');
  expect(String(calls[0].params.options.address).toLowerCase()).toBe(CIS);
  expect(calls[0].params.options.symbol).toBe('CIS');
  expect(calls[0].params.options.decimals).toBe(18);
  expect(String(calls[0].params.options.image)).toBe('https://retropick.xyz/wallet/416b0da3cf5de37a329f941291a19230f6d7a45ee9572e858e6b7dc46d84f9fb.png');
});
