#!/usr/bin/env node
// Renovation before/after screenshot matrix (goal RETROPICK-RETRO-UI-EXAMPLE-INTEGRATION-V1).
// Usage: node e2e/tools/renovation-shots.mjs <outputDir> [--target fixture|live]
// Builds the production bundle (fixture env by default), serves it on a dedicated
// port, and captures every key route at all six Playwright viewports in dark and
// light theme. Read-only: never signs, never writes app state.
import { spawn, execFileSync } from 'node:child_process';
import { mkdir, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';

const appDir = resolve(import.meta.dirname, '..', '..');
const outDir = resolve(process.argv[2] ?? '');
if (!outDir) { console.error('usage: node e2e/tools/renovation-shots.mjs <outputDir> [--target fixture|live]'); process.exit(2); }
const targetFlag = process.argv.includes('--target') ? process.argv[process.argv.indexOf('--target') + 1] : 'fixture';
const isFixture = targetFlag === 'fixture';
const PORT = isFixture ? 4390 : 4391;
const DIST = `/tmp/retro-ui-shots-${targetFlag}-dist`;

const fixtureEnv = { ...process.env, VITE_DATA_MODE: 'mock', VITE_INDEXER_URL: '', VITE_WALLET_BRIDGE_URL: '', VITE_E2E_FIXTURE: '1', DISABLE_HMR: 'true' };
const liveEnv = { ...process.env, VITE_WALLET_BRIDGE_URL: '', DISABLE_HMR: 'true' };
const buildEnv = isFixture ? fixtureEnv : liveEnv;

// (key, path) — demo fixtures render deterministically in mock mode; live target
// renders whatever the indexer currently returns (read-only).
const ROUTES = [
  ['launchpad', '/launchpad'],
  ['token-active', '/launchpad/token/demo-active'],
  ['token-graduated', '/launchpad/token/demo-graduated'],
  ['create', '/launchpad/create'],
  ['liquidity', '/liquidity'],
  ['market-making', '/liquidity/market-making'],
  ['earn', '/earn'],
];

const VIEWPORTS = [
  ['desktop-1440', { width: 1440, height: 960 }],
  ['desktop-1280', { width: 1280, height: 860 }],
  ['tablet-834', { width: 834, height: 1112 }],
  ['tablet-768', { width: 768, height: 1024 }],
  ['mobile-390', { width: 390, height: 844 }],
  ['mobile-375', { width: 375, height: 740 }],
];

console.log(`[shots] building ${targetFlag} bundle -> ${DIST}`);
execFileSync('pnpm', ['exec', 'vite', 'build', '--outDir', DIST, '--emptyOutDir', '--logLevel', 'warn'], { cwd: appDir, env: buildEnv, stdio: 'inherit' });

const server = spawn('pnpm', ['exec', 'vite', 'preview', '--outDir', DIST, '--port', String(PORT), '--strictPort', '--host', '127.0.0.1'], { cwd: appDir, env: buildEnv, stdio: 'ignore' });
const shutdown = () => { try { server.kill('SIGTERM'); } catch {} };
process.on('exit', shutdown); process.on('SIGINT', () => { shutdown(); process.exit(130); }); process.on('SIGTERM', () => { shutdown(); process.exit(143); });

async function waitReady() {
  const deadline = Date.now() + 60_000;
  while (Date.now() < deadline) {
    try { const r = await fetch(`http://127.0.0.1:${PORT}/launchpad`); if (r.ok) return; } catch {}
    await new Promise(r => setTimeout(r, 500));
  }
  throw new Error('preview server never became ready');
}

const { chromium } = await import('@playwright/test');
await waitReady();
const browser = await chromium.launch();
const manifest = [];
const consoleIssues = [];

for (const [vpName, viewport] of VIEWPORTS) {
  for (const theme of ['dark', 'light']) {
    const context = await browser.newContext({ viewport, deviceScaleFactor: 1, isMobile: viewport.width <= 480, hasTouch: viewport.width <= 1112 });
    await context.addInitScript((t) => { try { localStorage.setItem('retropick-theme', t); } catch {} }, theme);
    const page = await context.newPage();
    page.on('console', m => { if (m.type() === 'error') consoleIssues.push(`${vpName}/${theme}: ${m.text().slice(0, 200)}`); });
    for (const [key, path] of ROUTES) {
      const url = `http://127.0.0.1:${PORT}${path}`;
      try {
        await page.goto(url, { waitUntil: 'networkidle', timeout: 30_000 });
      } catch { /* fall through: capture whatever rendered */ }
      await page.waitForTimeout(700); // lazy route settle + hero count-up finish
      const file = `${vpName}-${theme}-${key}.png`;
      await page.screenshot({ path: join(outDir, file), scale: 'css', fullPage: false });
      if (vpName === 'desktop-1440' && theme === 'dark') {
        await page.screenshot({ path: join(outDir, `full-${file}`), scale: 'css', fullPage: true });
      }
      manifest.push({ viewport: vpName, theme, route: path, file });
    }
    await context.close();
  }
}

await browser.close();
shutdown();
await mkdir(outDir, { recursive: true });
await writeFile(join(outDir, 'manifest.json'), JSON.stringify({ target: targetFlag, port: PORT, generatedAt: new Date().toISOString(), shots: manifest, consoleErrors: consoleIssues }, null, 2));
console.log(`[shots] wrote ${manifest.length} viewport shots (+full-page 1440/dark) to ${outDir}`);
if (consoleIssues.length) console.log(`[shots] NOTE ${consoleIssues.length} console errors observed (see manifest.json)`);
