#!/usr/bin/env node
// Measures page-level horizontal overflow + launch-table width at each Playwright
// viewport against a fresh fixture build on a private port. Read-only.
// Usage: pnpm exec node e2e/tools/fit-check.mjs [route]... (default /launchpad)
import { chromium } from '@playwright/test';
import { spawn } from 'node:child_process';
const PORT = 4395;
const routes = process.argv.slice(2).length ? process.argv.slice(2) : ['/launchpad'];
const server = spawn('pnpm', ['exec', 'vite', 'preview', '--outDir', '/tmp/retro-ui-fit-dist', '--port', String(PORT), '--strictPort', '--host', '127.0.0.1'], { cwd: process.cwd(), stdio: 'ignore', env: { ...process.env, VITE_DATA_MODE: 'mock', VITE_INDEXER_URL: '', VITE_WALLET_BRIDGE_URL: '', DISABLE_HMR: 'true' } });
const shutdown = () => { try { server.kill('SIGKILL'); } catch {} };
process.on('exit', shutdown);
for (let i = 0; i < 120; i++) { try { if ((await fetch(`http://127.0.0.1:${PORT}/launchpad`)).ok) break; } catch {} await new Promise(r => setTimeout(r, 500)); }
const browser = await chromium.launch();
for (const route of routes) {
  for (const [w, h] of [[1440, 960], [1280, 860], [834, 1112], [768, 1024], [390, 844], [375, 740]]) {
    const page = await browser.newPage({ viewport: { width: w, height: h } });
    await page.goto(`http://127.0.0.1:${PORT}${route}`, { waitUntil: 'networkidle' }).catch(() => {});
    await page.waitForTimeout(400);
    const r = await page.evaluate(() => {
      const doc = document.documentElement;
      const offenders = [...document.querySelectorAll('body *')].filter(el => {
        const rc = el.getBoundingClientRect();
        if (rc.right <= doc.clientWidth + 1) return false;
        // only count elements that actually expand the page (no scrollable ancestor clipping them)
        let n = el.parentElement;
        while (n && n !== document.body) { const s = getComputedStyle(n); if ((s.overflowX === 'auto' || s.overflowX === 'scroll') && n.scrollWidth > n.clientWidth) return false; n = n.parentElement; }
        return true;
      }).slice(0, 4).map(el => `${el.tagName}.${(el.className || '').toString().split(' ').slice(0, 2).join('.')} r=${Math.round(el.getBoundingClientRect().right)}`);
      return { overflow: doc.scrollWidth - doc.clientWidth, offenders };
    });
    console.log(`${route} ${w}x${h}: overflow=${r.overflow}px ${r.offenders.length ? 'OFFENDERS: ' + r.offenders.join(' | ') : 'clean'}`);
    await page.close();
  }
}
await browser.close(); shutdown();
