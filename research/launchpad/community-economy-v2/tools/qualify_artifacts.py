#!/usr/bin/env python3
"""Read-only identity/size gate for source-scoped experimental Foundry artifacts."""
import argparse
import json
from pathlib import Path

NAMES = [
    "CommunityFeeRouterV2", "CommunityPolicyRegistryV2", "CommunityControllerV2",
    "CommunityLaunchBuilderV2", "RetroPickLaunchFactoryV2", "RetroPickLaunchDeployerV2",
    "RetroPickBondingCurveV2", "UniswapV4GraduationExecutorV2",
]


def qualify(directory):
    results = {}
    for name in NAMES:
        artifact = json.loads((directory / (name + ".sol") / (name + ".json")).read_text())
        metadata = artifact["metadata"]
        if isinstance(metadata, str):
            metadata = json.loads(metadata)
        target = metadata["settings"]["compilationTarget"]
        expected = {"src/v2-research-experiment/" + name + ".sol": name}
        if target != expected:
            raise ValueError(f"Wrong artifact source identity: {name}: {target}")
        if not metadata["compiler"]["version"].startswith("0.8.26+"):
            raise ValueError("Compiler identity differs from required 0.8.26")
        runtime = len(artifact["deployedBytecode"]["object"].removeprefix("0x")) // 2
        initcode = len(artifact["bytecode"]["object"].removeprefix("0x")) // 2
        if runtime > 24576 or initcode > 49152:
            raise ValueError(f"Runtime/initcode deployment size exceeded: {name}")
        results[name] = {"target": target, "runtime": runtime, "initcode": initcode,
                         "eip170_margin": 24576 - runtime, "abi": artifact["abi"]}
    return results


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("out", type=Path)
    print(json.dumps(qualify(parser.parse_args().out), indent=2))
