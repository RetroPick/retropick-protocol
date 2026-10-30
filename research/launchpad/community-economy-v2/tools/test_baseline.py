"""Exercise the protection gate in disposable Git repositories, never the checkout."""
import contextlib
import importlib.util
import io
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('baseline', Path(__file__).with_name('baseline.py'))
baseline = importlib.util.module_from_spec(spec)
spec.loader.exec_module(baseline)


class ProtectionTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for name in ['contracts/src/v2/A.sol', 'contracts/src/v2-research-experiment/A.sol',
                     'contracts/test/v2/unit/A.t.sol']:
            p = self.root / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text('pragma solidity ^0.8.26; contract A {}\n')
        self.git('init', '-q')
        self.git('add', '.')
        self.git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                 'commit', '-qm', 'fixture')
        self.ref = self.git('rev-parse', 'HEAD').strip()

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.root), *args], text=True)

    def check(self):
        with patch.object(baseline, 'ROOT', self.root), patch.object(baseline, 'BASE', self.ref), \
                patch('sys.argv', ['baseline.py', '--check']), contextlib.redirect_stdout(io.StringIO()):
            baseline.main()

    def test_clean_and_owned_additions_pass(self):
        p = self.root / 'contracts/test/v2/research-experiment/New.t.sol'
        p.parent.mkdir(parents=True)
        p.write_text('// permitted experimental test\n')
        self.check()

    def test_staged_canonical_mutation_fails(self):
        p = self.root / 'contracts/src/v2/A.sol'
        p.write_text('contract Changed {}\n')
        self.git('add', str(p.relative_to(self.root)))
        with self.assertRaises(SystemExit) as failure:
            self.check()
        self.assertEqual(failure.exception.code, 1)

    def test_untracked_protected_file_fails(self):
        (self.root / 'contracts/src/v2/Unexpected.sol').write_text('contract Unexpected {}\n')
        with self.assertRaises(SystemExit):
            self.check()

    def test_original_test_deletion_fails(self):
        (self.root / 'contracts/test/v2/unit/A.t.sol').unlink()
        with self.assertRaises(SystemExit):
            self.check()


if __name__ == '__main__':
    unittest.main()
