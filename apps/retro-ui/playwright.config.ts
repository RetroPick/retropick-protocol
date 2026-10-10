import { defineConfig, devices, type Project } from '@playwright/test';
import { join } from 'node:path';

// Targets (selected by e2e/run.mjs through E2E_TARGET):
//   fixture  - deterministic mock-mode UI on its own strict port 4317; mock wallet; network guard. Default / CI.
//   live     - read-only Monad Testnet + indexer from apps/retro-ui/.env.local on strict port 4318; signing bridge disabled.
//   research - read-only competitor browsing (Pons, Bags); excluded from default runs.
const target = (process.env.E2E_TARGET ?? 'fixture') as 'fixture' | 'live' | 'research';
const evidence = process.env.E2E_EVIDENCE_DIR ?? join(import.meta.dirname, '..', '..', 'evidence/platform/frontend/browser-validation', 'adhoc');
const FIXTURE_PORT = 4317;
const LIVE_PORT = 4318;

const viewports: Project[] = [
  { name: 'desktop-1440', use: { viewport: { width: 1440, height: 960 } } },
  { name: 'desktop-1280', use: { viewport: { width: 1280, height: 860 } } },
  { name: 'tablet-834', use: { viewport: { width: 834, height: 1112 }, hasTouch: true, isMobile: false } },
  { name: 'tablet-768', use: { viewport: { width: 768, height: 1024 }, hasTouch: true, isMobile: false } },
  { name: 'mobile-390', use: { ...devices['Pixel 7'], viewport: { width: 390, height: 844 }, browserName: 'chromium' } },
  { name: 'mobile-375', use: { ...devices['Pixel 7'], viewport: { width: 375, height: 740 }, browserName: 'chromium' } },
];

// Shell env takes precedence over .env.local in Vite, so these neutralise the local live config.
const fixtureEnv = { VITE_DATA_MODE: 'mock', VITE_INDEXER_URL: '', VITE_WALLET_BRIDGE_URL: '', VITE_E2E_FIXTURE: '1', DISABLE_HMR: 'true' };
const liveEnv = { VITE_WALLET_BRIDGE_URL: '', DISABLE_HMR: 'true' };

export default defineConfig({
  testDir: './e2e',
  testMatch: target === 'fixture' ? 'fixture/**/*.spec.ts' : target === 'live' ? 'live/**/*.spec.ts' : 'research/**/*.spec.ts',
  outputDir: join(evidence, 'test-output'),
  fullyParallel: true,
  workers: process.env.CI ? 2 : 4,
  // One retry absorbs host network-interface events (net::ERR_NETWORK_CHANGED); retried passes are reported as "flaky".
  retries: 1,
  timeout: target === 'fixture' ? 45_000 : 90_000,
  expect: { timeout: target === 'fixture' ? 8_000 : 30_000 },
  reporter: [['list'], ['json', { outputFile: join(evidence, 'results.json') }], ['html', { outputFolder: join(evidence, 'html-report'), open: 'never' }]],
  use: {
    baseURL: target === 'fixture' ? `http://127.0.0.1:${FIXTURE_PORT}` : target === 'live' ? `http://127.0.0.1:${LIVE_PORT}` : undefined,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    serviceWorkers: 'block',
  },
  projects: target === 'research' ? [viewports[0], viewports[4]] : viewports,
  webServer: target === 'research' ? undefined : {
    // Fixture: production build + preview (deterministic, no on-demand dev transforms under parallel load).
    // Built outside the repo so the tracked/served apps/retro-ui/dist is never touched.
    command: target === 'fixture'
      ? `pnpm exec vite build --outDir /tmp/retro-ui-e2e-fixture-dist --emptyOutDir --logLevel warn && pnpm exec vite preview --outDir /tmp/retro-ui-e2e-fixture-dist --port ${FIXTURE_PORT} --strictPort --host 127.0.0.1`
      // Live: production build too. React 19.2's dev-only Performance Tracks JSON.stringify component props and
      // throw on exact-bigint props (SDK LiveLaunch/KuruState); that profiler is absent from production bundles.
      : `pnpm exec vite build --outDir /tmp/retro-ui-e2e-live-dist --emptyOutDir --logLevel warn && pnpm exec vite preview --outDir /tmp/retro-ui-e2e-live-dist --port ${LIVE_PORT} --strictPort --host 127.0.0.1`,
    url: `http://127.0.0.1:${target === 'fixture' ? FIXTURE_PORT : LIVE_PORT}/launchpad`,
    reuseExistingServer: false,
    timeout: 240_000,
    env: target === 'fixture' ? fixtureEnv : liveEnv,
    stdout: 'ignore',
    stderr: 'pipe',
  },
});
