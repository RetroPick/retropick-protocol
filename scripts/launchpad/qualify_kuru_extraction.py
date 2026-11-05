#!/usr/bin/env python3
"""Local source-scoped Kuru extraction regression; never deploys or broadcasts.

Writes immutable, timestamped raw logs and an incrementally saved result manifest.
A local pass never supplies missing RPC/block/deployed-bytecode qualification.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence', type=Path, required=True)
    parser.add_argument('--out', default='/tmp/retropick-kuru-extraction-out')
    parser.add_argument('--cache', default='/tmp/retropick-kuru-extraction-cache')
    args = parser.parse_args()
    evidence = args.evidence.resolve()
    if evidence.exists():
        raise SystemExit('Refusing to overwrite existing run evidence: ' + str(evidence))
    evidence.mkdir(parents=True)
    env = dict(os.environ, FOUNDRY_PROFILE='test', FOUNDRY_FUZZ_RUNS='10000',
               FOUNDRY_INVARIANT_RUNS='256', FOUNDRY_INVARIANT_DEPTH='128')
    source_sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    source_files = {}
    for base in ('contracts/src/v2', 'contracts/src/v2-research-experiment', 'contracts/src/legacy/v2/kuru',
                 'contracts/test/legacy/v2-kuru', 'contracts/test/v2', 'contracts/script',
                 'contracts/legacy/v2-kuru/script'):
        for path in sorted((ROOT / base).rglob('*.sol')):
            source_files[str(path.relative_to(ROOT))] = hashlib.sha256(path.read_bytes()).hexdigest()
    (evidence / 'source-sha256.json').write_text(json.dumps(source_files, indent=2) + '\n')
    manifest = {'sourceCommit': source_sha, 'workingTreeOverlay': 'source-sha256.json',
                'profile': 'test', 'fuzzSeed': '0x6a', 'fuzzRuns': 10000,
                'invariantRuns': 256, 'invariantDepth': 128,
                'environment': 'Local EVM; no live transactions, no RPC fork',
                'forkQualification': {'status': 'BLOCKED', 'reason': 'No qualified RPC, pinned current block/hash and deployed-code identity supplied to this local campaign'},
                'commands': []}
    def save():
        (evidence / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    save()
    common = ['--out', args.out, '--cache-path', args.cache]
    def test(scope, path):
        return ['forge', 'test', '--contracts', scope, '--match-path', path, '--fuzz-seed', '0x6a', *common, '-vvv']
    fmt_paths = [
        'src/v2/RetroPickQuoteAssetRegistryV2.sol', 'src/v2/interfaces/IGraduationExecutorV2.sol',
        'src/v2-research-experiment/RetroPickQuoteAssetRegistryV2.sol', 'src/v2-research-experiment/interfaces/IGraduationExecutorV2.sol',
        'test/v2/unit/QuoteAssetRegistryV2.t.sol', 'test/v2/unit/V4OnlyLaunchAdmissionV2.t.sol',
        'test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol', 'test/v2/integration/RetroPickV4GraduationBehavior.t.sol',
        'test/v2/integration/FullV4StackV2Fork.t.sol', 'test/v2/community-economy/CommunityFactoryFixtureV2.sol',
        'test/v2/community-economy/CommunityV4Registration.t.sol', 'test/v2/research-experiment/CommunityFactoryFixtureV2.sol',
        'test/v2/research-experiment/CommunityV4Registration.t.sol', 'test/legacy/v2-kuru',
        'script/DeployV2V4OnlyCandidate.s.sol', 'legacy/v2-kuru/script',
    ]
    commands = [
        ('archive-verify', ['python3', str(ROOT / 'contracts/legacy/v2-kuru/verify.py')]),
        ('deployed-archive-verify', ['python3', str(ROOT / 'contracts/legacy-v2/verify.py')]),
        ('foundry-version', ['forge', '--version']),
        ('fmt', ['forge', 'fmt', '--check', *fmt_paths]),
        ('active-unit', test('src/v2', 'test/v2/unit/*.t.sol')),
        ('active-factory', test('src/v2', 'test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol')),
        ('active-v4-behavior', test('src/v2', 'test/v2/integration/RetroPickV4GraduationBehavior.t.sol')),
        ('active-invariants', test('src/v2', 'test/v2/invariant/*.t.sol')),
        ('active-community', test('src/v2', 'test/v2/community-economy/**/*.t.sol')),
        ('experimental-community', test('src/v2-research-experiment', 'test/v2/research-experiment/*.t.sol') + ['--no-match-path', 'test/v2/research-experiment/m6*/**']),
        ('legacy-unit', test('src/legacy/v2/kuru/canonical', 'test/legacy/v2-kuru/unit/*.t.sol')),
        ('legacy-factory', test('src/legacy/v2/kuru/canonical', 'test/legacy/v2-kuru/integration/RetroPickFactoryLaunchV2Qualification.t.sol')),
        ('active-build-sizes', ['forge', 'build', '--contracts', 'src/v2', '--sizes', '--skip', 'test', '--skip', 'script', *common]),
    ]
    for index, (name, command) in enumerate(commands, 1):
        log = evidence / f'{index:02d}-{name}.log'
        started = datetime.now(timezone.utc).isoformat()
        start = time.monotonic()
        with log.open('wb') as output:
            result = subprocess.run(command, cwd=ROOT / 'contracts', env=env, stdout=output, stderr=subprocess.STDOUT)
        text = log.read_text(errors='replace')
        counts = re.findall(r'(\d+) tests passed, (\d+) failed, (\d+) skipped', text)
        record = {'name': name, 'argv': command, 'cwd': 'contracts', 'startedAt': started,
                  'elapsedSeconds': round(time.monotonic() - start, 3), 'exitCode': result.returncode,
                  'status': 'PASS' if result.returncode == 0 else 'FAIL', 'log': log.name,
                  'logSHA256': hashlib.sha256(log.read_bytes()).hexdigest()}
        if counts:
            p, f, s = map(int, counts[-1])
            record['runnerReportedTests'] = {'passed': p, 'failed': f, 'skipped': s}
        manifest['commands'].append(record)
        save()
        print(json.dumps(record), flush=True)
    manifest['status'] = 'LOCAL_PASS_FORK_BLOCKED' if all(c['exitCode'] == 0 for c in manifest['commands']) else 'FAIL'
    save()
    raise SystemExit(0 if manifest['status'] == 'LOCAL_PASS_FORK_BLOCKED' else 1)


if __name__ == '__main__':
    main()
