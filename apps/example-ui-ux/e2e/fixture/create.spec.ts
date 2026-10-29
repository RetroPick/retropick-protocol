import { test, expect, expectClean, expectNoHorizontalOverflow } from '../helpers/test';
import { walletCalls } from '../helpers/mock-wallet';

test('@create wizard: Token → Market & economics → Review, validation, unsupported option, no signing', async ({ page, observed, snap }) => {
  await page.goto('/launchpad/create');
  await expect(page.getByLabel('Token launch progress')).toContainText('Review');
  await expect(page.locator('main')).toContainText('DEMO · NOT DEPLOYED');
  await expect(page.locator('main')).not.toContainText(/\bETH\b|\bSOL\b/);
  await page.getByRole('button', { name: 'Continue' }).click();
  await expect(page.getByRole('alert')).toContainText('name');
  await page.getByPlaceholder('Retro Coin', { exact: true }).fill('Test Comet');
  await page.getByPlaceholder('RETRO', { exact: true }).fill('TCOM');
  await page.getByRole('button', { name: 'Continue' }).click();
  await expect(page.getByRole('heading', { name: /2 · Market & economics/ })).toBeVisible();
  const holders = page.getByRole('radio', { name: /Holders/ });
  await expect(holders).toBeDisabled();
  await page.getByPlaceholder('0').first().fill('1');
  await snap('create-economics');
  await page.getByRole('button', { name: 'Review' }).click();
  const review = page.getByTestId('launch-review');
  await expect(review).toContainText('Test Comet · TCOM');
  await expect(review).toContainText('1,000,000,000');
  await expect(review).toContainText('Kuru orderbook');
  await expect(review).toContainText('DEMO');
  await expectNoHorizontalOverflow(page);
  await snap('create-review');
  await page.getByRole('button', { name: 'Back' }).click();
  await expect(page.getByRole('heading', { name: /2 · Market & economics/ })).toBeVisible();
  expect(await walletCalls(page)).toEqual([]);
  expectClean(observed);
});

test('@create prediction market wizard still renders (regression)', async ({ page, observed }) => {
  await page.goto('/launchpad/create?type=prediction');
  await expect(page.locator('main')).toContainText(/market|Market/);
  expectClean(observed);
});
