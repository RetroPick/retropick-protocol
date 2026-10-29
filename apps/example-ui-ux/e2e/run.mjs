#!/usr/bin/env node
// Stable Playwright Test entry point for apps/retro-ui (direct @playwright/test runner, NOT a Kiro workflow).
// Usage: node e2e/run.mjs <fixture|live|research|smoke> [label] [-- extra playwright args]
// Creates one fresh evidence folder per run: evidence/platform/frontend/browser-validation/<UTC ts>-<target>[-label]/
// Never overwrites earlier evidence. Never signs or broadcasts (see e2e/helpers/mock-wallet.ts, network-guard.ts).
import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const appDir = resolve(here, '..');
const repoRoot = resolve(appDir, '..', '..');
const argv = process.argv.slice(2);
const sep = argv.indexOf('--');
const own = sep === -1 ? argv : argv.slice(0, sep);
const extra = sep === -1 ? [] : argv.slice(sep + 1);
const [target = 'fixture', label = ''] = own;
if (!['fixture', 'live', 'research', 'smoke'].includes(target)) {
  console.error('target must be fixture | live | research | smoke');
  process.exit(2);
}
const ts = new Date().toISOString().replace(/[-:]/g, '').replace(/\.\d+Z$/, 'Z');
const evidence = join(repoRoot, 'evidence/platform/frontend/browser-validation', `${ts}-${target}${label ? `-${label}` : ''}`);
mkdirSync(evidence, { recursive: true });
const env = { ...process.env, E2E_TARGET: target === 'smoke' ? 'fixture' : target, E2E_EVIDENCE_DIR: evidence };
const args = ['playwright', 'test', '--config', 'playwright.config.ts'];
if (target === 'smoke') args.push('--grep', '@smoke');
args.push(...extra);
writeFileSync(join(evidence, 'RUN.json'), JSON.stringify({ target, label, startedAt: new Date().toISOString(), command: `pnpm exec ${args.join(' ')}`, cwd: 'apps/retro-ui' }, null, 2));
const result = spawnSync('pnpm', ['exec', ...args], { cwd: appDir, env, stdio: 'inherit' });
writeFileSync(join(evidence, 'EXIT.txt'), String(result.status ?? 1));
console.log(`\nevidence: ${evidence}`);
process.exit(result.status ?? 1);
