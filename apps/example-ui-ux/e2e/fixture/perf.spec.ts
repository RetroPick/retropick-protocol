import { test, expect, expectClean } from '../helpers/test';

for (const route of ['/launchpad', '/launchpad/token/demo-active', '/launchpad/token/demo-graduated']) {
  test(`@perf ${route}: cumulative layout shift < 0.1, no RPC/indexer calls in demo`, async ({ page, observed }, info) => {
    test.skip(!['desktop-1440', 'mobile-390'].includes(info.project.name));
    await page.addInitScript(() => {
      (window as unknown as { __cls: number }).__cls = 0;
      new PerformanceObserver((list) => { for (const e of list.getEntries() as Array<PerformanceEntry & { value: number; hadRecentInput: boolean }>) if (!e.hadRecentInput) (window as unknown as { __cls: number }).__cls += e.value; }).observe({ type: 'layout-shift', buffered: true });
    });
    await page.goto(route);
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(800);
    const cls = await page.evaluate(() => (window as unknown as { __cls: number }).__cls);
    test.info().annotations.push({ type: 'cls', description: cls.toFixed(4) });
    expect(cls).toBeLessThan(0.1);
    expect(observed.guard.requests.filter((r) => /rpc|indexer|:8787/i.test(r.url))).toEqual([]);
    expectClean(observed);
  });
}
