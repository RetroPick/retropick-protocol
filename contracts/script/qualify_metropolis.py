#!/usr/bin/env python3
"""Read-only Metropolis qualification; never changes historical deployment evidence or broadcasts."""
import argparse
import json
import re
import subprocess
from pathlib import Path
import release_v2_monad as release

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'evidence/hackathon/metropolis'

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--env-file', required=True)
    args = parser.parse_args()
    source_sha = release.sha()
    source_dirty = bool(subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'], cwd=ROOT))
    env = release.load_env(args.env_file)
    snapshot = release.preflight(env)
    block = int(release.rpc(env, 'eth_blockNumber', []), 16)
    env.update(FOUNDRY_ETH_RPC_URL='', FOUNDRY_CODE_SIZE_LIMIT='1048576', MONAD_V2_FORK_BLOCK=str(block))
    OUT.mkdir(parents=True, exist_ok=True)
    release.write(OUT / 'environment.json', snapshot)
    commands = [
        ('v4-dependencies', ['forge', 'build', '--root', 'deployment-v4', '--sizes', '--skip', 'test', '--skip', 'script'], ROOT / 'contracts'),
        ('permit2', ['forge', 'build', '--sizes', '--skip', 'test', '--skip', 'script'], ROOT / 'contracts/lib/v4-deployment-periphery/lib/permit2'),
        ('format', ['forge', 'fmt', '--check'], ROOT / 'contracts'),
        ('oracle', ['python3', 'test/v2/tools/generate_completion_vectors.py', '--check'], ROOT / 'contracts'),
        ('tests', ['forge', 'test'], ROOT / 'contracts'),
        ('sizes', ['forge', 'build', '--sizes'], ROOT / 'contracts'),
        ('runtime-sizes', ['forge', 'build', '--sizes', '--skip', 'test', '--skip', 'script'], ROOT / 'contracts'),
    ]
    report = {'repositorySHA': source_sha, 'dirty': source_dirty,
              'deployedSourceSHA': 'f0363249f4b74e58dde37d1241742ca5a92bcfe3', 'forkBlock': block, 'exitCodes': {}}
    for label, command, cwd in commands:
        print('Running', label, flush=True)
        with (OUT / (label + '.log')).open('w') as log:
            result = subprocess.run(command, cwd=cwd, env=env, stdout=log, stderr=subprocess.STDOUT)
        report['exitCodes'][label] = result.returncode
        if result.returncode:
            release.write(OUT / 'qualification.json', report)
            raise SystemExit(f'Failed {label}; inspect the recorded log.')
    totals = re.search(r'(\d+) tests passed, (\d+) failed, (\d+) skipped', (OUT / 'tests.log').read_text())
    if not totals or totals.group(2) != '0' or totals.group(3) != '0': raise SystemExit('Missing clean test totals; qualification fails closed.')
    report['tests'] = dict(zip(('passed', 'failed', 'skipped'), map(int, totals.groups())))
    report['sizes'] = release.size_gate()
    manifest = json.loads((ROOT / 'deployments/monad-testnet/v2.json').read_text())
    report['canonicalLive'] = release.verify_launch(env, manifest, manifest['monLaunch'])
    release.write(OUT / 'qualification.json', report)
    print('PASS:', report['tests'], 'fork:', block, 'Factory:', report['sizes']['RetroPickLaunchFactoryV2'])

if __name__ == '__main__': main()
