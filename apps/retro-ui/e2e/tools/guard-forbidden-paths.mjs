#!/usr/bin/env node
// Forbidden-path guard for the retro-ui trading redesign campaign (campaign decision B13, section 32).
//
// Compares the current working tree against the Wave 0 preservation baseline (FEAT-001): every path under a
// forbidden prefix that differs from BASE_HEAD_SHA (or is untracked) must be a pre-existing baseline entry whose
// content is byte-identical to the recorded fingerprint. Anything new, modified or reverted fails the guard.
//
// Usage:
//   node apps/retro-ui/e2e/tools/guard-forbidden-paths.mjs [<snapshot-dir>] [--json]
//   CAMPAIGN_BASELINE_DIR=<snapshot-dir> node apps/retro-ui/e2e/tools/guard-forbidden-paths.mjs
// Exit codes: 0 pass, 1 forbidden path changed relative to the baseline, 2 usage or baseline integrity error.
//
// No dependencies. Read-only: never writes to the repository, its index or its refs, and never prints file contents.
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { lstatSync, readFileSync, readlinkSync, realpathSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

export const FORBIDDEN_PREFIXES = ['apps/web/', 'contracts/', 'packages/launchpad-sdk/', 'apps/indexer/', 'apps/abi/', 'deployments/'];
export const FORBIDDEN_FILES = ['development/fullstack-integration/write-allowlist.md'];

export const isForbidden = (path) =>
  FORBIDDEN_FILES.includes(path) || FORBIDDEN_PREFIXES.some((prefix) => path.startsWith(prefix) || path === prefix.slice(0, -1));

const GIT_ENV = { ...process.env, GIT_OPTIONAL_LOCKS: '0' };
const sha256 = (data) => createHash('sha256').update(data).digest('hex');

const git = (root, args) => execFileSync('git', ['-C', root, ...args], { env: GIT_ENV, maxBuffer: 256 * 1024 * 1024 }).toString('utf8');
const splitZ = (text) => text.split('\0').filter(Boolean);

/** Same algorithm as the baseline builder: sha256 of raw bytes, or a marker for special cases. */
export function hashPath(root, rel) {
  const abs = join(root, rel);
  let st;
  try {
    st = lstatSync(abs);
  } catch {
    return 'DELETED';
  }
  if (st.isSymbolicLink()) return 'symlink:' + sha256(readlinkSync(abs));
  if (st.isDirectory()) return 'DIRECTORY';
  return sha256(readFileSync(abs));
}

export function repoRoot() {
  const here = dirname(fileURLToPath(import.meta.url));
  return execFileSync('git', ['-C', here, 'rev-parse', '--show-toplevel'], { env: GIT_ENV }).toString('utf8').trim();
}

export function resolveSnapshotDir(argv = process.argv.slice(2)) {
  const positional = argv.find((a) => !a.startsWith('--'));
  const dir = positional || process.env.CAMPAIGN_BASELINE_DIR;
  if (!dir) throw new UsageError('snapshot dir required: pass it as the first argument or set CAMPAIGN_BASELINE_DIR');
  return dir;
}

export class UsageError extends Error {}

/** Loads manifest.json and baseline-fingerprint.txt and checks the fingerprint against the manifest. */
export function loadBaseline(snapDir) {
  let manifest, fpText;
  try {
    manifest = JSON.parse(readFileSync(join(snapDir, 'manifest.json'), 'utf8'));
    fpText = readFileSync(join(snapDir, 'baseline-fingerprint.txt'), 'utf8');
  } catch (error) {
    throw new UsageError(`cannot read baseline in ${snapDir}: ${error.message}`);
  }
  if (sha256(fpText) !== manifest.baseline_fingerprint_sha256) {
    throw new UsageError('baseline-fingerprint.txt does not match manifest.baseline_fingerprint_sha256 (snapshot altered?)');
  }
  const fingerprint = new Map();
  for (const line of fpText.split('\n')) {
    if (!line) continue;
    const i = line.lastIndexOf(' ');
    fingerprint.set(line.slice(0, i), line.slice(i + 1));
  }
  return { manifest, fingerprint, baseSha: manifest.BASE_HEAD_SHA };
}

/** Paths whose working-tree or index state differs from the base commit, plus untracked (non-ignored) paths. */
export function currentChangedPaths(root, baseSha) {
  const paths = new Set();
  for (const p of splitZ(git(root, ['diff', '--name-only', '--no-renames', '--no-relative', '-z', baseSha]))) paths.add(p);
  for (const p of splitZ(git(root, ['diff', '--cached', '--name-only', '--no-renames', '--no-relative', '-z', baseSha]))) paths.add(p);
  for (const p of splitZ(git(root, ['ls-files', '--others', '--exclude-standard', '-z']))) paths.add(p);
  return paths;
}

export function runGuard(snapDir, root = repoRoot()) {
  const { manifest, fingerprint, baseSha } = loadBaseline(snapDir);
  const head = git(root, ['rev-parse', 'HEAD']).trim();
  const changed = currentChangedPaths(root, baseSha);
  const result = { snapshot: snapDir, base: baseSha, head, headMoved: head !== baseSha, unchangedPreexisting: [], violations: [] };
  for (const path of [...changed].filter(isForbidden).sort()) {
    const recorded = fingerprint.get(path);
    if (recorded === undefined) result.violations.push({ path, kind: 'NEW_SINCE_BASELINE' });
    else if (hashPath(root, path) !== recorded) result.violations.push({ path, kind: 'MODIFIED_SINCE_BASELINE' });
    else result.unchangedPreexisting.push(path);
  }
  for (const [path] of fingerprint) {
    if (isForbidden(path) && !changed.has(path)) result.violations.push({ path, kind: 'REVERTED_SINCE_BASELINE' });
  }
  result.checkedForbiddenBaselineEntries = [...fingerprint.keys()].filter(isForbidden).length;
  result.pass = result.violations.length === 0;
  result.baselineTs = manifest.TS;
  return result;
}

function main() {
  const argv = process.argv.slice(2);
  let result;
  try {
    result = runGuard(resolveSnapshotDir(argv));
  } catch (error) {
    console.error(`guard-forbidden-paths: ${error.message}`);
    process.exit(2);
  }
  if (argv.includes('--json')) {
    console.log(JSON.stringify(result, null, 2));
  } else {
    console.log(`guard-forbidden-paths: baseline ${result.baselineTs} BASE ${result.base}`);
    console.log(`HEAD ${result.head}${result.headMoved ? ' (HEAD moved since baseline; comparison is against BASE)' : ''}`);
    console.log(`forbidden: ${FORBIDDEN_PREFIXES.join(' ')} ${FORBIDDEN_FILES.join(' ')}`);
    console.log(`pre-existing forbidden-prefix entries in baseline: ${result.checkedForbiddenBaselineEntries}; unchanged now: ${result.unchangedPreexisting.length}`);
    for (const v of result.violations) console.log(`VIOLATION ${v.kind} ${v.path}`);
    console.log(result.pass ? 'RESULT: PASS (no forbidden path changed relative to the baseline)' : `RESULT: FAIL (${result.violations.length} violation(s))`);
  }
  process.exit(result.pass ? 0 : 1);
}

const invokedDirectly = (() => {
  try {
    return import.meta.url === pathToFileURL(realpathSync(process.argv[1])).href;
  } catch {
    return false;
  }
})();
if (invokedDirectly) main();
