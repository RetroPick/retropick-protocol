import { test, expect } from '../helpers/test';

// Read-only competitor capture (excluded from default runs). No wallet, no sign-in, no clicks on trade/launch CTAs.
test.use({ wallet: false });
for (const [name, url] of [['pons', 'https://ponsfamily.com/launchpad'], ['bags', 'https://bags.fm']] as const) {
  test(`@research ${name} read-only capture`, async ({ page, observed, snap }) => {
    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(2500);
    await expect(page.locator('body')).not.toBeEmpty();
    await snap(`research-${name}`, page, { fullPage: false });
    expect(observed.guard.violations).toEqual([]);
  });
}
