#!/usr/bin/env python3
"""Verify the separate 7dd Kuru regression archive and active V4 source boundary.

Read-only. The deployed hackathon archive is contracts/legacy-v2, not this archive.
"""
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
CONCRETE = (
    'KuruEnvironmentV2.sol', 'KuruGraduationExecutorV2.sol', 'KuruLiquidityLockV2.sol',
    'interfaces/IKuruV2.sol', 'libraries/KuruParameterPolicyV2.sol',
)


def git(*args):
    return subprocess.check_output(['git', '-C', str(ROOT), *args])


def main():
    manifest = json.loads((HERE / 'PROVENANCE.json').read_text())
    failures = []
    for entry in manifest['sourceUnits'] + manifest['originalConsumers']:
        actual = (ROOT / entry['archivePath']).read_bytes()
        original = git('show', manifest['baseline'] + ':' + entry['originalPath'])
        if actual != original or hashlib.sha256(actual).hexdigest() != entry['sha256']:
            failures.append('archive drift: ' + entry['archivePath'])
        if git('rev-parse', manifest['baseline'] + ':' + entry['originalPath']).decode().strip() != entry['gitBlob']:
            failures.append('blob provenance mismatch: ' + entry['originalPath'])
    checked_imports = []
    for lane in ('v2', 'v2-research-experiment'):
        base = ROOT / 'contracts/src' / lane
        for relative in CONCRETE:
            if (base / relative).exists():
                failures.append('concrete Kuru source remains active: ' + str(base / relative))
        for source in sorted(base.rglob('*.sol')):
            text = source.read_text()
            if re.search(r'kuru', text, re.I):
                failures.append('legacy venue name remains in active source: ' + str(source))
            for match in re.finditer(r'\bimport\s+(?:[^;]*?\bfrom\s+)?[\'"]([^\'"]+)[\'"]', text):
                dep = match[1]
                if dep.startswith('.'):
                    target = (source.parent / dep).resolve()
                    if not target.exists():
                        failures.append('missing import: ' + str(source) + ' -> ' + dep)
                    if '/legacy/' in str(target) or 'Kuru' in target.name or target.name == 'IKuruV2.sol':
                        failures.append('legacy dependency enters active graph: ' + str(source) + ' -> ' + dep)
                    checked_imports.append([str(source.relative_to(ROOT)), str(target.relative_to(ROOT))])
            if re.search(r'\b(?:contract|interface|library)\s+(?:I?Kuru\w*)', text):
                failures.append('concrete Kuru declaration remains active: ' + str(source))
        enum_source = (base / 'interfaces/IGraduationExecutorV2.sol').read_text()
        enum_body = re.search(r'enum\s+GraduationVenue\s*\{([^}]+)\}', enum_source)[1]
        enum_body = re.sub(r'//[^\n]*', '', enum_body)
        if [x.strip() for x in enum_body.split(',') if x.strip()] != ['UNISWAP_V4', 'LEGACY_RESERVED']:
            failures.append('venue wire identity changed in ' + lane)
    # These financial implementations are outside this source-separation change.
    for lane in ('v2', 'v2-research-experiment'):
        for name in ('RetroPickLaunchFactoryV2.sol', 'RetroPickBondingCurveV2.sol', 'GraduationCoordinatorV2.sol',
                     'RetroPickBuybackVaultV2.sol', 'CommunityFeeRouterV2.sol', 'CommunityTreasuryVaultV2.sol'):
            path = 'contracts/src/' + lane + '/' + name
            if (ROOT / path).read_bytes() != git('show', manifest['baseline'] + ':' + path):
                failures.append('out-of-scope financial source changed: ' + path)
    frozen = git('diff', '--name-only', 'HEAD', '--', 'contracts/legacy-v2',
                 'contracts/test/v2/community-economy/reference', 'contracts/src/v1', 'contracts/src/v3-research-experiment',
                 'deployments').decode().splitlines()
    if frozen:
        failures.extend('protected path changed: ' + path for path in frozen)
    # Raw historical consumers remain exact; adapted regression changes only import/artifact identity and formatting.
    test_pairs = [
        ('contracts/test/v2/unit/QuoteAssetRegistryV2.t.sol', 'unit/QuoteAssetRegistryV2.t.sol'),
        ('contracts/test/v2/unit/KuruPolicyAndLockV2.t.sol', 'unit/KuruPolicyAndLockV2.t.sol'),
        ('contracts/test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol', 'integration/RetroPickFactoryLaunchV2Qualification.t.sol'),
        ('contracts/test/v2/integration/KuruV2EndToEndFork.t.sol', 'integration/KuruV2EndToEndFork.t.sol'),
        ('contracts/test/v2/integration/KuruForkResearch.t.sol', 'integration/KuruForkResearch.t.sol'),
        ('contracts/test/v2/integration/KuruAtomicResearch.t.sol', 'integration/KuruAtomicResearch.t.sol'),
    ]
    def normalized(text):
        text = re.sub(r'/\*.*?\*/|//[^\n]*', '', text, flags=re.S)
        text = re.sub(r'\bimport\b[^;]+;', '', text)
        text = text.replace('src/legacy/v2/kuru/canonical/', '')
        text = text.replace('src/v2/', '')
        return re.findall(r'"(?:[^"\\]|\\.)*"|\w+|[^\w\s]', text)
    for original, adapted in test_pairs:
        if normalized(git('show', manifest['baseline'] + ':' + original).decode()) != normalized(
            (ROOT / 'contracts/test/legacy/v2-kuru' / adapted).read_text()
        ):
            failures.append('historical assertion/body drift: ' + adapted)
    for name in ('DeployV2MonadTestnet.s.sol', 'SmokeV2MonadTestnet.s.sol', 'TradeV2KuruTestnet.s.sol'):
        original = git('show', manifest['baseline'] + ':contracts/script/' + name).decode()
        adapted = (HERE / 'script' / name).read_text()
        if normalized(original) != normalized(adapted):
            failures.append('historical script body drift: ' + name)
    candidate = (ROOT / 'contracts/script/DeployV2V4OnlyCandidate.s.sol').read_text()
    if any(token in candidate for token in ('vm.startBroadcast', 'vm.broadcast', 'new Kuru', 'GraduationVenue.KURU')):
        failures.append('V4-only local construction candidate has a broadcast or Kuru action')
    result = {
        'status': 'FAIL' if failures else 'PASS',
        'baseline': manifest['baseline'], 'archiveSourceFiles': len(manifest['sourceUnits']),
        'rawHistoricalConsumers': len(manifest['originalConsumers']), 'activeRelativeImportsChecked': len(checked_imports),
        'historicalTestBodiesChecked': len(test_pairs), 'historicalScriptBodiesChecked': 3, 'venueWireIds': {'UNISWAP_V4': 0, 'KURU_LEGACY_RESERVED': 1},
        'deployedArchive': 'contracts/legacy-v2 (separately frozen; not this regression snapshot)',
        'failures': failures,
    }
    print(json.dumps(result, indent=2))
    if failures:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
