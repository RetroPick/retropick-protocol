#!/usr/bin/env node
// Campaign edit attribution against the Wave 0 preservation baseline (FEAT-001, decision B2).
//
// Classifies every path that differs from BASE_HEAD_SHA (plus every baseline entry) into:
//   CAMPAIGN_NEW                  changed or untracked now, not part of the 153-entry baseline
//   CAMPAIGN_MODIFIED_PREEXISTING baseline entry whose content differs from the recorded fingerprint
//   PREEXISTING_REVERTED          baseline entry that no longer differs from BASE (content changed back)
//   PREEXISTING_UNCHANGED         baseline entry, byte-identical to the fingerprint (not campaign-attributed)
// Note: the tool cannot tell a campaign edit from a concurrent non-campaign writer; investigate before attributing.
//
// Usage:
//   node apps/retro-ui/e2e/tools/attribute-changes.mjs [<snapshot-dir>] [--json] [--all]
//   CAMPAIGN_BASELINE_DIR=<snapshot-dir> node apps/retro-ui/e2e/tools/attribute-changes.mjs
// --all also lists PREEXISTING_UNCHANGED paths (otherwise only their count is printed).
// Exit codes: 0 report produced, 2 usage or baseline integrity error. Read-only; never prints file contents.
import { realpathSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { currentChangedPaths, hashPath, isForbidden, loadBaseline, repoRoot, resolveSnapshotDir } from './guard-forbidden-paths.mjs';

const area = (path) => {
  if (path.startsWith('.agents/tasks/task-retro-ui-trading-redesign/')) return 'task-state';
  if (path.startsWith('evidence/platform/frontend/browser-validation/')) return 'evidence';
  if (path.startsWith('apps/retro-ui/')) return 'retro-ui';
  if (path.startsWith('docs/design/')) return 'docs-design';
  return 'other';
};

export function attribute(snapDir, root = repoRoot()) {
  const { manifest, fingerprint, baseSha } = loadBaseline(snapDir);
  const changed = currentChangedPaths(root, baseSha);
  const groups = { CAMPAIGN_NEW: [], CAMPAIGN_MODIFIED_PREEXISTING: [], PREEXISTING_REVERTED: [], PREEXISTING_UNCHANGED: [] };
  for (const path of [...changed].sort()) {
    const recorded = fingerprint.get(path);
    const entry = { path, area: area(path), forbidden: isForbidden(path) };
    if (recorded === undefined) groups.CAMPAIGN_NEW.push(entry);
    else if (hashPath(root, path) !== recorded) groups.CAMPAIGN_MODIFIED_PREEXISTING.push(entry);
    else groups.PREEXISTING_UNCHANGED.push(entry);
  }
  for (const [path] of [...fingerprint].sort(([a], [b]) => (a < b ? -1 : 1))) {
    if (!changed.has(path)) groups.PREEXISTING_REVERTED.push({ path, area: area(path), forbidden: isForbidden(path) });
  }
  return { snapshot: snapDir, baselineTs: manifest.TS, base: baseSha, baselineEntries: fingerprint.size, groups };
}

function main() {
  const argv = process.argv.slice(2);
  let report;
  try {
    report = attribute(resolveSnapshotDir(argv));
  } catch (error) {
    console.error(`attribute-changes: ${error.message}`);
    process.exit(2);
  }
  if (argv.includes('--json')) {
    console.log(JSON.stringify(report, null, 2));
    return;
  }
  const g = report.groups;
  console.log(`attribute-changes: baseline ${report.baselineTs} BASE ${report.base} (${report.baselineEntries} pre-existing entries)`);
  for (const name of ['CAMPAIGN_NEW', 'CAMPAIGN_MODIFIED_PREEXISTING', 'PREEXISTING_REVERTED']) {
    console.log(`${name}: ${g[name].length}`);
    for (const e of g[name]) console.log(`  ${e.forbidden ? '[FORBIDDEN] ' : ''}${e.area}\t${e.path}`);
  }
  console.log(`PREEXISTING_UNCHANGED: ${g.PREEXISTING_UNCHANGED.length}`);
  if (argv.includes('--all')) for (const e of g.PREEXISTING_UNCHANGED) console.log(`  ${e.area}\t${e.path}`);
}

const invokedDirectly = (() => {
  try {
    return import.meta.url === pathToFileURL(realpathSync(process.argv[1])).href;
  } catch {
    return false;
  }
})();
if (invokedDirectly) main();
