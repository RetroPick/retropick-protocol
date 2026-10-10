import { test, expect, expectClean, expectNoHorizontalOverflow } from '../helpers/test';

for (const theme of ['dark', 'light'] as const) {
  test.describe(`discovery ${theme}`, () => {
    test.use({ theme });
    test('@discovery list renders real-shape rows with DEMO provenance and no USD/SOL', async ({ page, observed, snap }) => {
      await page.goto('/launchpad');
      const d = page.getByTestId('discovery');
      await expect(d).toHaveAttribute('data-data-mode', 'demo');
      await expect(page.getByTestId('launch-row').first()).toBeVisible();
      await expect(page.getByTestId('launch-row')).toHaveCount(5);
      const text = await d.innerText();
      expect(text).not.toMatch(/\$\d|SOL\b|ETH\b/);
      await expectNoHorizontalOverflow(page);
      await snap(`discovery-list-${theme}`);
      expectClean(observed);
    });
  });
}

test('@discovery lifecycle filters, pair dropdown, grid toggle persists, open token', async ({ page, observed, snap }) => {
  await page.goto('/launchpad');
  const life = page.getByRole('radiogroup', { name: 'Launch lifecycle' });
  await life.getByRole('radio', { name: 'Graduated' }).click();
  await expect(page.getByTestId('launch-row')).toHaveCount(1);
  await expect(page.getByTestId('launch-row').first()).toContainText('NVC');
  await life.getByRole('radio', { name: 'Near graduation' }).click();
  await expect(page.getByTestId('launch-row')).toHaveCount(0);
  await expect(page.getByText('No launches match these filters')).toBeVisible();
  await life.getByRole('radio', { name: 'Active' }).click();
  await expect(page.getByTestId('launch-row')).toHaveCount(2);
  await life.getByRole('radio', { name: 'Market cap' }).click();
  await page.getByLabel('Pair filter').selectOption('MON');
  await expect(page.getByTestId('launch-row')).toHaveCount(3);
  await page.getByLabel('Pair filter').selectOption('');
  await page.getByRole('radiogroup', { name: 'Layout' }).getByRole('radio', { name: 'Grid' }).click();
  await expect(page.getByTestId('launch-card')).toHaveCount(5);
  await snap('discovery-grid');
  await page.reload();
  await expect(page.getByTestId('launch-card')).toHaveCount(5);
  await page.getByTestId('launch-card').filter({ hasText: 'MDOG' }).click();
  await expect(page.getByTestId('token-terminal')).toHaveAttribute('data-lifecycle', 'ACTIVE');
  expectClean(observed);
});

test('@discovery Prediction, Crypto and PRISM navigation still work', async ({ page, observed }) => {
  await page.goto('/launchpad');
  await page.getByRole('navigation', { name: 'Launchpad categories' }).getByRole('link', { name: 'Prediction' }).click();
  await expect(page.locator('main')).toContainText(/Bitcoin|Fed/);
  await page.goto('/launchpad?type=stocks');
  await expect(page.getByTestId('launch-row')).toHaveCount(2);
  await page.goto('/launchpad?type=crypto');
  await expect(page.getByTestId('launch-row')).toHaveCount(3);
  await page.goto('/launchpad');
  await page.getByRole('link', { name: /PRISM/ }).first().click();
  await expect(page.locator('main')).toContainText('PRISM');
  await page.goto('/launchpad/prediction/btc-150k');
  await expect(page.locator('main')).toContainText('Bitcoin');
  expectClean(observed);
});

test('@search command palette: keyboard-only open, arrow, enter', async ({ page, observed, snap }, info) => {
  test.skip(info.project.name.startsWith('mobile') || info.project.name.startsWith('tablet'), 'hardware-keyboard shortcut');
  await page.goto('/launchpad');
  await page.locator('body').click({ position: { x: 5, y: 400 } });
  await page.keyboard.press('/');
  const box = page.getByRole('combobox', { name: 'Search Launchpad and PRISM' });
  await expect(box).toBeFocused();
  await page.keyboard.type('o');
  const list = page.getByRole('listbox', { name: 'Search results' });
  await expect(list.getByRole('option').first()).toHaveAttribute('aria-selected', 'true');
  await snap('search-palette', page, { fullPage: false });
  await box.fill('orbit cult');
  await expect(list.getByRole('option')).toHaveCount(1);
  await page.keyboard.press('Enter');
  await expect(page.getByTestId('token-terminal')).toHaveAttribute('data-lifecycle', 'GRADUATION_READY');
  await page.keyboard.press('Control+k');
  await expect(box).toBeVisible();
  await box.fill('zzzz-not-a-token');
  await expect(page.getByText('No launches match')).toBeVisible();
  await page.keyboard.press('Escape');
  await expect(box).toHaveCount(0);
  await page.keyboard.press('Control+k');
  await box.fill('fed');
  await page.keyboard.press('ArrowDown');
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/\/prism\/pfedbtc/); // ArrowDown moved from the Fed prediction market to the PRISM basket
  expectClean(observed);
});

test('@search mobile search button opens palette', async ({ page, observed }, info) => {
  test.skip(!info.project.name.startsWith('mobile'));
  await page.goto('/launchpad');
  await page.getByRole('button', { name: 'Search tokens and markets' }).filter({ visible: true }).first().tap();
  await page.getByRole('combobox', { name: 'Search Launchpad and PRISM' }).fill('nvidia');
  await page.getByRole('option').first().tap();
  await expect(page.getByTestId('token-terminal')).toHaveAttribute('data-lifecycle', 'GRADUATED');
  await expectNoHorizontalOverflow(page);
  expectClean(observed);
});
