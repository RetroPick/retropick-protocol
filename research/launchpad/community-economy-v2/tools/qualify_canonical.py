#!/usr/bin/env python3
"""Materialize a unique source-scoped qualifier; never changes repository tests.

The historical snapshot's unused Factory must not enter short-basename artifact
lookup. Preserve the full snapshot in Git; compile only its actual import closure.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[4]
REFERENCE = ROOT / 'contracts/test/v2/community-economy/reference/v2'
FIXTURE = 'contracts/test/v2/integration/DEV4GraduationExtractionResearch.t.sol'
PATTERN = re.compile(r'\bimport\s+(?:[^;]+?from\s+)?["\']([^"\']+)["\']\s*;', re.S)


def reference_closure():
    stack = [REFERENCE / name for name in (
        'RetroPickBondingCurveV2.sol', 'RetroPickLauncherTokenV2.sol',
        'RetroPickBuybackVaultV2.sol', 'RetroPickFeeEscrowV2.sol',
        'interfaces/IRetroPickLaunchpadV2.sol')]
    seen = set()
    while stack:
        p = stack.pop().resolve()
        if p in seen:
            continue
        if not p.is_relative_to(REFERENCE):
            raise RuntimeError('Reference escaped immutable source root')
        seen.add(p)
        for name in PATTERN.findall(p.read_text()):
            if name.startswith('.'):
                target = (p.parent / name).resolve()
                if target.is_relative_to(REFERENCE):
                    stack.append(target)
    return sorted(seen)


def materialize():
    subprocess.run(['python3', str(Path(__file__).with_name('canonical_adoption.py'))],
                   stdout=subprocess.DEVNULL, check=True)
    base = Path(tempfile.mkdtemp(prefix='retropick-ce-canonical-'))
    target = base / 'contracts'
    target.mkdir()
    shutil.copytree(ROOT / 'contracts/src/v2', target / 'src/v2')
    for name in ('foundry.toml', 'remappings.txt'):
        source = ROOT / 'contracts' / name
        if source.exists():
            shutil.copyfile(source, target / name)
    (target / 'lib').symlink_to(ROOT / 'contracts/lib', target_is_directory=True)
    originals = subprocess.check_output([
        'git', '-C', str(ROOT), 'ls-tree', '-r', '--name-only',
        '7bad742b67e2fa58ebf680eadbfa6194d5bbf0c3', 'contracts/test'], text=True).splitlines()
    for name in originals:
        if '/research-experiment/' in name:
            continue
        if not (name.startswith('contracts/test/v2/') or name.startswith('contracts/test/mocks/')):
            continue
        source = ROOT / name
        destination = target / Path(name).relative_to('contracts')
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
    (target / 'script').mkdir()
    # Imported by a historical fork fixture. Compiled, never invoked/broadcast.
    shutil.copyfile(ROOT / 'contracts/script/DeployV2MonadTestnet.s.sol',
                    target / 'script/DeployV2MonadTestnet.s.sol')
    closure = reference_closure()
    for source in closure:
        destination = target / 'test/v2/community-economy/reference/v2' / source.relative_to(REFERENCE)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
    manifest = {'repository': str(ROOT), 'qualifier': str(target),
                'historicalFixtureSha256': hashlib.sha256((ROOT/FIXTURE).read_bytes()).hexdigest(),
                'historicalReferenceClosure': [str(p.relative_to(REFERENCE)) for p in closure]}
    (base/'materialization.json').write_text(json.dumps(manifest, indent=2)+'\n')
    return base, target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', action='store_true', help='Run local tests, never transactions')
    args = parser.parse_args()
    base, target = materialize()
    command = ['forge', 'test', '--root', str(target), '--contracts', 'src/v2',
               '--match-path', 'test/v2/*.t.sol', '--no-match-contract',
               '^(FullV4StackV2ForkTest|KuruV2EndToEndForkTest)$',
               '--out', str(base/'out'), '--cache-path', str(base/'cache'),
               '--chain-id', '10143', '--code-size-limit', '1048576',
               '--fuzz-runs', '256', '--fuzz-seed', '0xce05']
    (base/'command.json').write_text(json.dumps(command, indent=2)+'\n')
    print(json.dumps({'qualifier': str(base), 'run': args.run}))
    if args.run:
        env = dict(os.environ, FOUNDRY_PROFILE='default', FOUNDRY_TEST='test/v2', FOUNDRY_SCRIPT='script')
        with (base/'tests.log').open('w') as log:
            result = subprocess.run(command, env=env, cwd=target, stdout=log, stderr=subprocess.STDOUT)
        print(json.dumps({'exit': result.returncode, 'log': str(base/'tests.log')}))
        return result.returncode
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
