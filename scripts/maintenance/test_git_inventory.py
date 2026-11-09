"""Tests for the non-destructive Git inventory generator."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parent / 'git_inventory.py'
spec = importlib.util.spec_from_file_location('git_inventory', SOURCE)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class InventoryTests(unittest.TestCase):
    def setUp(self):
        self.workspace = tempfile.TemporaryDirectory()
        self.addCleanup(self.workspace.cleanup)
        self.root = Path(self.workspace.name)
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        self.run_git('init', '--quiet')
        self.run_git('config', 'user.email', 'test@example.invalid')
        self.run_git('config', 'user.name', 'Inventory Test')
        (self.repo / 'apps' / 'retro-ui').mkdir(parents=True)
        (self.repo / 'apps' / 'retro-ui' / 'package.json').write_text(json.dumps({
            'name': '@retropick/retro-ui',
            'dependencies': {'@retropick/launchpad-sdk': 'workspace:*', 'react': '19'},
            'scripts': {'test': 'echo passing', 'build': 'echo built'},
        }), encoding='utf-8')
        (self.repo / 'contracts' / 'legacy-v2').mkdir(parents=True)
        (self.repo / 'contracts' / 'legacy-v2' / 'Frozen.sol').write_text('immutable evidence\n', encoding='utf-8')
        (self.repo / 'evidence').mkdir()
        (self.repo / 'evidence' / 'space\tfile.json').write_text('immutable evidence\n', encoding='utf-8')
        self.run_git('add', '-A')
        self.run_git('commit', '-qm', 'fixture')
        self.baseline = self.run_git('rev-parse', 'HEAD').strip()
        (self.repo / 'contracts' / 'lib').mkdir(parents=True)
        # Gitlink in index without creating a real submodule checkout.
        self.run_git('update-index', '--add', '--cacheinfo', f'160000,{self.baseline},contracts/lib/forge-std')
        self.run_git('commit', '-qm', 'add gitlink')
        self.current = self.run_git('rev-parse', 'HEAD').strip()

    def run_git(self, *cmd):
        return subprocess.check_output(['git', *cmd], cwd=self.repo, text=True)

    def test_inventory_handles_gitlink_and_special_filename(self):
        rows = self.with_cwd(mod.inspect_tree, self.current)
        self.assertEqual(len(rows), 4)
        matching = {r[0]: r for r in rows}
        self.assertEqual(matching['contracts/lib/forge-std'][1], 'commit')
        self.assertIsNone(matching['contracts/lib/forge-std'][3])
        self.assertEqual(matching['contracts/lib/forge-std'][4], 'PINNED_SUBMODULE')
        self.assertEqual(matching['evidence/space\tfile.json'][4], 'HISTORICAL_EVIDENCE')
        self.assertEqual(matching['contracts/legacy-v2/Frozen.sol'][4], 'PROTECTED_DEPLOYMENT_PROVENANCE')
        self.assertEqual(self.with_cwd(mod.workspace_graph, rows)['apps/retro-ui/package.json']['workspace_dependencies'],
                         {'@retropick/launchpad-sdk': 'workspace:*'})

    def test_cli_inventory_is_deterministic_and_does_not_modify_repo(self):
        out = self.root / 'inventory-output'
        args = [sys.executable, str(SOURCE), '--revision', self.current, '--out-dir', str(out)]
        git_before = self.run_git('status', '--porcelain')
        subprocess.run(args, cwd=self.repo, check=True, capture_output=True)
        first = {p.name: p.read_bytes() for p in out.iterdir()}
        subprocess.run(args, cwd=self.repo, check=True, capture_output=True)
        second = {p.name: p.read_bytes() for p in out.iterdir()}
        self.assertEqual(first, second)
        self.assertEqual(self.run_git('status', '--porcelain'), git_before)
        self.assertEqual(json.loads(first['SUMMARY.json'])['entries'], 4)
        self.assertIn('"evidence/space\\tfile.json"', first['TRACKED_FILE_CENSUS.tsv'].decode())
        self.assertEqual(len(json.loads(first['WORKSPACE_GRAPH.json'])), 1)

    def with_cwd(self, action, *args):
        import os
        previous = os.getcwd()
        try:
            os.chdir(self.repo)
            return action(*args)
        finally:
            os.chdir(previous)


if __name__ == '__main__':
    unittest.main()
