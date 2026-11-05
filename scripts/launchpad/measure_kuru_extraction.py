#!/usr/bin/env python3
"""Inspect compiler artifacts by metadata source target, never by basename alone."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

NAMES = ('RetroPickLaunchFactoryV2', 'GraduationCoordinatorV2', 'RetroPickQuoteAssetRegistryV2',
         'RetroPickBondingCurveV2', 'UniswapV4GraduationExecutorV2', 'KuruGraduationExecutorV2', 'KuruLiquidityLockV2')
PREFIXES = ('src/v2/', 'src/legacy/v2/kuru/canonical/')


def keccak(raw):
    return subprocess.check_output(['cast', 'keccak', '0x' + raw.hex()], text=True).strip()


def without_metadata(raw):
    if len(raw) < 2:
        return raw
    size = int.from_bytes(raw[-2:], 'big') + 2
    return raw[:-size] if size <= len(raw) else raw


def static_words(item):
    kind = item['type']
    if kind in ('string', 'bytes') or kind.endswith('[]'):
        return None
    if kind == 'tuple':
        parts = [static_words(x) for x in item['components']]
        return None if None in parts else sum(parts)
    if '[' in kind:
        base, size = kind.rsplit('[', 1)
        words = static_words({**item, 'type': base})
        return None if words is None else words * int(size[:-1])
    return 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    result = {'artifactKind': 'Compiler templates; constructor immutables are not a deployed-code identity',
              'limits': {'runtimeEIP170': 24576, 'initcodeEIP3860': 49152},
              'artifacts': [], 'abiComparisons': [], 'failures': []}
    artifacts = {}
    for name in NAMES:
        for path in args.out.rglob(name + '.json'):
            doc = json.loads(path.read_text())
            metadata = doc.get('metadata', {})
            if isinstance(metadata, str):
                metadata = json.loads(metadata)
            target = metadata.get('settings', {}).get('compilationTarget', {})
            if len(target) != 1:
                continue
            source, contract = next(iter(target.items()))
            if source not in [prefix + name + '.sol' for prefix in PREFIXES]:
                continue
            runtime = bytes.fromhex(doc['deployedBytecode']['object'].removeprefix('0x'))
            initcode = bytes.fromhex(doc['bytecode']['object'].removeprefix('0x'))
            constructor = next((entry for entry in doc['abi'] if entry['type'] == 'constructor'), {'inputs': []})
            words = [static_words(entry) for entry in constructor['inputs']]
            argument_bytes = None if None in words else 32 * sum(words)
            transaction_init_bytes = None if argument_bytes is None else len(initcode) + argument_bytes
            record = {'sourceUnit': source, 'contract': contract,
                      'artifactRelativePath': str(path.relative_to(args.out)),
                      'runtimeBytes': len(runtime), 'initcodeTemplateBytes': len(initcode),
                      'staticConstructorArgumentBytes': argument_bytes, 'transactionInitcodeBytes': transaction_init_bytes,
                      'runtimeTemplateKeccak256': keccak(runtime), 'initcodeTemplateKeccak256': keccak(initcode),
                      'runtimeWithoutOuterMetadataKeccak256': keccak(without_metadata(runtime)),
                      'abiSHA256': hashlib.sha256(json.dumps(doc['abi'], sort_keys=True, separators=(',', ':')).encode()).hexdigest(),
                      'compiler': metadata.get('compiler', {}), 'settings': metadata.get('settings', {})}
            artifacts[source] = (doc['abi'], runtime, record)
            result['artifacts'].append(record)
            if len(runtime) > 24576 or len(initcode) > 49152 or (transaction_init_bytes is not None and transaction_init_bytes > 49152):
                result['failures'].append('Artifact exceeds deployable size limit: ' + source)
    for prefix in PREFIXES:
        for name in NAMES:
            if prefix == PREFIXES[0] and name.startswith('Kuru'):
                continue
            source = prefix + name + '.sol'
            if source not in artifacts:
                result['failures'].append('Missing measured artifact: ' + source)
    for name in NAMES[:3]:
        active = PREFIXES[0] + name + '.sol'
        legacy = PREFIXES[1] + name + '.sol'
        if active not in artifacts or legacy not in artifacts:
            result['failures'].append('Missing active or regression artifact: ' + name)
            continue
        a, b = artifacts[active], artifacts[legacy]
        def abi_entries(abi):
            return sorted(json.dumps(x, sort_keys=True, separators=(',', ':')) for x in abi)
        abi_equal = abi_entries(a[0]) == abi_entries(b[0])
        body_equal = without_metadata(a[1]) == without_metadata(b[1])
        result['abiComparisons'].append({'contract': name, 'activeSource': active, 'historicalSource': legacy,
                                         'allABIEntriesIdentical': abi_equal,
                                         'runtimeWithoutOuterMetadataIdentical': body_equal,
                                         'intentionalBehaviorChange': name == 'RetroPickQuoteAssetRegistryV2'})
        if not abi_equal:
            result['failures'].append('Unexpected ABI change: ' + name)
        if name != 'RetroPickQuoteAssetRegistryV2' and not body_equal:
            result['failures'].append('Unexpected executable-body change: ' + name)
    result['status'] = 'PASS' if not result['failures'] else 'FAIL'
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'status': result['status'], 'artifacts': len(result['artifacts']),
                      'abiComparisons': result['abiComparisons'], 'failures': result['failures']}, indent=2))
    if result['failures']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
