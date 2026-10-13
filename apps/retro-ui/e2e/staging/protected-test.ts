import { test as base, expect, request as apiRequest } from '@playwright/test';
/** Existing project automation credential, supplied in memory by the validation runner.
 * Browser auth is origin-scoped so it cannot accompany Monad RPC or external media requests. */
export const test = base.extend({
 page: async ({ page, baseURL }, use) => {
  const secret = process.env.VERCEL_AUTOMATION_BYPASS_SECRET;
  if (secret && baseURL) await page.context().route(`${new URL(baseURL).origin}/**`, route => route.continue({ headers: { ...route.request().headers(), 'x-vercel-protection-bypass': secret } }));
  await use(page);
 },
 request: async ({ baseURL }, use) => {
  const secret = process.env.VERCEL_AUTOMATION_BYPASS_SECRET;
  const request = await apiRequest.newContext({ baseURL, extraHTTPHeaders: secret ? { 'x-vercel-protection-bypass': secret } : {} });
  await use(request); await request.dispose();
 },
});
export { expect };
