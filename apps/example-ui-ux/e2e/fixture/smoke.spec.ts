import { test, expect, expectClean } from '../helpers/test';

// Fresh browser smoke (@smoke): renders each primary route in the deterministic mock-mode server,
// captures a screenshot + console/network record, and asserts no app exception and no signing/broadcast.
const routes: Array<[string, string, RegExp | string]> = [
  ['launchpad', '/launchpad', /Launch/],
  ['token-active', '/launchpad/token/monad-dog', 'MDOG'],
  ['token-graduated', '/launchpad/token/nvidia-cult', 'NVC'],
  ['prediction', '/launchpad/prediction/btc-150k', /Bitcoin/],
  ['prism', '/prism', /PRISM/],
  ['earn', '/earn', /Earn/],
  ['create', '/launchpad/create', /Launch|Create/],
];

for (const [name, path, text] of routes) {
  test(`@smoke ${name} renders`, async ({ page, observed, snap }) => {
    await page.goto(path);
    await expect(page.locator('main, #root').first()).toContainText(text);
    // Data mode must be mock in the fixture target: no indexer requests are allowed to leave the browser.
    await page.waitForLoadState('networkidle');
    expect(observed.guard.blockedExternal.filter((r) => /indexer|8787|rpc/i.test(r.url))).toEqual([]);
    await snap(`smoke-${name}`);
    expectClean(observed);
  });
}
