#!/usr/bin/env node
// Quick spot screenshots for design iteration (goal RETROPICK-RETRO-UI-EXAMPLE-INTEGRATION-V1).
// Usage: pnpm exec node e2e/tools/spot-shots.mjs [route]...   (default: /launchpad)
// Captures dark 1440/834/390 + light 1440 to /tmp/spot-*.png against a fixture build.
import { chromium } from '@playwright/test';
import { spawn, execFileSync } from 'node:child_process';

const appDir = process.cwd();
const routes = process.argv.slice(2).length ? process.argv.slice(2) : ['/launchpad'];
execFileSync('pnpm', ['exec', 'vite', 'build', '--outDir', '/tmp/retro-ui-spot-dist', '--emptyOutDir', '--logLevel', 'warn'], {
  cwd: appDir, stdio: 'ignore',
  env: { ...process.env, VITE_DATA_MODE: 'mock', VITE_INDEXER_URL: '', VITE_WALLET_BRIDGE_URL: '', VITE_E2E_FIXTURE: '1', DISABLE_HMR: 'true' },
});
const server = spawn('pnpm', ['exec', 'vite', 'preview', '--outDir', '/tmp/retro-ui-spot-dist', '--port', '4392', '--strictPort', '--host', '127.0.0.1'], { cwd: appDir, stdio: 'ignore' });
for (let i = 0; i < 120; i++) { try { if ((await fetch('http://127.0.0.1:4392/launchpad')).ok) break; } catch {} await new Promise(r => setTimeout(r, 500)); }
const browser = await chromium.launch();
const configs = [
  ['1440', { width: 1440, height: 960 }, 'dark'],
  ['834', { width: 834, height: 1112 }, 'dark'],
  ['390', { width: 390, height: 844 }, 'dark'],
  ['1440', { width: 1440, height: 960 }, 'light'],
];
const slug = (r) => r.replaceAll('/', '-').replace(/^-/, '') || 'root';
for (const route of routes) {
  for (const [vp, viewport, theme] of configs) {
    const ctx = await browser.newContext({ viewport, deviceScaleFactor: 1, isMobile: viewport.width <= 480, hasTouch: viewport.width <= 1112 });
    await ctx.addInitScript(t => localStorage.setItem('retropick-theme', t), theme);
    const page = await ctx.newPage();
    await page.goto(`http://127.0.0.1:4392${route}`, { waitUntil: 'networkidle' }).catch(() => {});
    await page.waitForTimeout(600);
    await page.screenshot({ path: `/tmp/spot-${slug(route)}-${vp}-${theme}.png`, scale: 'css' });
    await ctx.close();
  }
}
await browser.close(); server.kill('SIGTERM');
console.log(`[spot] wrote ${routes.length * configs.length} shots to /tmp/spot-*.png`);
