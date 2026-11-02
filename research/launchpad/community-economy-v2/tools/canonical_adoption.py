#!/usr/bin/env python3
"""ADR-CE02 stage check. Does not weaken or replace historical baseline.py."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tomllib

ROOT = Path(__file__).resolve().parents[4]
BASE = '7bad742b67e2fa58ebf680eadbfa6194d5bbf0c3'
EXPERIMENT = 'ff7540ba'
FILES = ['CommunityControllerV2.sol', 'CommunityFeeRouterV2.sol', 'CommunityLaunchBuilderV2.sol',
         'CommunityPolicyRegistryV2.sol', 'CommunityTimelockV2.sol', 'CommunityTreasuryDeployerV2.sol',
         'CommunityTreasuryLaunchBuilderV2.sol', 'CommunityTreasuryVaultV2.sol',
         'interfaces/ICommunityFeesV2.sol', 'RetroPickLaunchFactoryV2.sol', 'RetroPickBondingCurveV2.sol',
         'UniswapV4GraduationExecutorV2.sol']

def git(*args):
    return subprocess.check_output(['git', '-C', str(ROOT), *args])

def main():
    errors = []
    def require(ok, message):
        if not ok:
            errors.append(message)
    paths = git('ls-tree', '-r', '--name-only', EXPERIMENT,
                'contracts/src/v2-research-experiment/vendor').decode().splitlines()
    allowed = {'contracts/src/v2/' + p for p in FILES}
    for source in paths:
        allowed.add(source.replace('/v2-research-experiment/', '/v2/'))
    for target in sorted(allowed):
        p = ROOT / target
        source = target.replace('/v2/', '/v2-research-experiment/', 1)
        require(p.exists() and p.read_bytes() == git('show', EXPERIMENT + ':' + source),
                'Canonical source differs from qualified experiment: ' + target)
    protected = ['contracts/src/v1', 'contracts/src/v2', 'contracts/src/v3-research-experiment',
                 'contracts/script', 'deployments', 'apps', 'packages']
    changed = set(git('diff', '--name-only', BASE, '--', *protected).decode().splitlines())
    untracked = set(git('ls-files', '--others', '--exclude-standard', '--', *protected).decode().splitlines())
    require(not ((changed | untracked) - allowed), 'Unauthorized protected changes: ' + str(sorted((changed | untracked) - allowed)))
    oldtests = git('ls-tree', '-r', '--name-only', BASE, 'contracts/test/v2').decode().splitlines()
    for target in oldtests:
        p = ROOT / target
        expected = git('show', BASE + ':' + target)
        if target == 'contracts/test/v2/integration/DEV4GraduationExtractionResearch.t.sol':
            expected = expected.replace(b'../../../src/v2/', b'../community-economy/reference/v2/')
        require(p.exists() and p.read_bytes() == expected, 'Original test changed beyond accepted import-only pin: ' + target)
    frozen = ROOT / 'contracts/test/v2/community-economy/reference/v2'
    originals = git('ls-tree', '-r', '--name-only', BASE, 'contracts/src/v2').decode().splitlines()
    for source in originals:
        if source.endswith('.sol'):
            p = frozen / source.removeprefix('contracts/src/v2/')
            require(p.exists() and p.read_bytes() == git('show', BASE + ':' + source), 'Frozen reference changed: ' + source)
    oldconfig = tomllib.loads(git('show', BASE + ':contracts/foundry.toml').decode())
    newconfig = tomllib.loads((ROOT/'contracts/foundry.toml').read_text())
    ignored = newconfig['fmt'].pop('ignore', [])
    require(set(ignored) == {'src/v2-research-experiment/vendor/openzeppelin-v5.4.0/**',
                             'src/v2/vendor/openzeppelin-v5.4.0/**', 'test/v2/community-economy/reference/**'},
            'Unexpected formatter exclusions')
    require(oldconfig == newconfig, 'Compiler/remapping/nonformat configuration changed')
    print(json.dumps({'baseline':BASE, 'qualifiedExperiment':EXPERIMENT, 'ownerAcceptance':'ADR-CE02 canonical implementation subject to qualification',
                      'status':'PASS' if not errors else 'FAIL', 'allowedCanonicalPaths':sorted(allowed),
                      'originalTestsVerified':len(oldtests), 'ownerApprovedTestException':'Five DEV4 historical fixture import paths only; assertions and bodies unchanged', 'errors':errors}, indent=2))
    return bool(errors)

if __name__ == '__main__':
    sys.exit(main())
