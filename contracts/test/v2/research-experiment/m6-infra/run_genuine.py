#!/usr/bin/env python3
"""Build pinned genuine venue artifacts and run a local-only V2 lifecycle.

Never broadcasts, alters dependency revisions, or edits global Foundry settings.
The sole code etch in the fixture installs a modeled six-decimal quote asset.
"""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

HERE = Path(__file__).resolve().parent
CONTRACTS = HERE.parents[3]
REPO = CONTRACTS.parent
PINS = {
    "periphery": (CONTRACTS / "lib/v4-deployment-periphery", "9969eec44cfdf07e24b41de47f40276a58401976"),
    "core": (CONTRACTS / "lib/v4-deployment-periphery/lib/v4-core", "59d3ecf53afa9264a16bba0e38f4c5d2231f80bc"),
    "permit2": (CONTRACTS / "lib/v4-deployment-periphery/lib/permit2", "cc56ad0f3439c502c246fc5cfcc3db92bb8b7219"),
    "core-openzeppelin": (CONTRACTS / "lib/v4-deployment-periphery/lib/v4-core/lib/openzeppelin-contracts", "dbb6104ce834628e473d2173bbc9d47f81a9eec3"),
    "core-solmate": (CONTRACTS / "lib/v4-deployment-periphery/lib/v4-core/lib/solmate", "4b47a19038b798b4a33d9749d25e570443520647"),
    "permit2-solmate": (CONTRACTS / "lib/v4-deployment-periphery/lib/permit2/lib/solmate", "8d910d876f51c3b2585c9109409d601f600e68e1"),
}


def capture(args, cwd=REPO):
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--artifacts", type=Path, default=Path("/tmp/retropick-m6-genuine"))
    parser.add_argument("--skip-build", action="store_true")
    parser.add_argument("--trace", action="store_true", help="Persist full successful local transaction traces")
    parser.add_argument("--run", action="store_true", help="Run genuine local native and six-decimal lifecycle tests")
    args = parser.parse_args()
    output = args.artifacts.resolve()
    if output == REPO or REPO in output.parents:
        parser.error("Choose an external artifact directory; generated artifacts do not belong in source")
    output.mkdir(parents=True, exist_ok=True)
    evidence_root = HERE / "evidence"
    evidence_root.mkdir(exist_ok=True)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    evidence = evidence_root / stamp
    evidence.mkdir()
    manifest = {"kind": "LOCAL_GENUINE_VENUE_NOT_FORK", "started": stamp,
                "sourceSha": capture(["git", "rev-parse", "HEAD"]),
                "branch": capture(["git", "branch", "--show-current"]),
                "forge": capture(["forge", "--version"]), "artifactRoot": str(output),
                "pins": {}, "commands": [], "artifacts": {},
                "runnerSha256": digest(Path(__file__)),
                "configSourceSha256": digest(CONTRACTS / "foundry.toml"),
                "remappingsSourceSha256": digest(CONTRACTS / "remappings.txt"),
                "limitations": ["Modeled six-decimal quote asset; not live Circle USDC", "EOA proposer; not Safe qualification", "Existing CE hook fee is zero; not continuous venue revenue qualification"]}
    for name, (path, expected) in PINS.items():
        actual = capture(["git", "-C", str(path), "rev-parse", "HEAD"])
        dirty = capture(["git", "-C", str(path), "status", "--porcelain", "--untracked-files=no"])
        manifest["pins"][name] = {"expected": expected, "actual": actual, "trackedChanges": dirty}
        if dirty:
            (evidence / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
            raise SystemExit(f"Dependency tracked source is dirty for {name}")
        if actual != expected:
            raise SystemExit(f"Dependency revision mismatch for {name}: {actual}")
    for path in sorted(HERE.glob("*.sol")):
        manifest.setdefault("testSourceSha256", {})[path.name] = digest(path)

    def save():
        (evidence / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")

    def run(name, command, env=None):
        log = evidence / (name + ".log")
        item = {"name": name, "command": command, "cwd": str(REPO), "log": str(log.relative_to(REPO))}
        manifest["commands"].append(item)
        save()
        print("RUN", name, " ".join(command), flush=True)
        with log.open("w") as stream:
            result = subprocess.run(command, cwd=REPO, env=env, stdout=stream, stderr=subprocess.STDOUT)
        item["exitCode"] = result.returncode
        item["status"] = "COMMAND_OK" if result.returncode == 0 else "FAIL"
        if name == "03-genuine-v4-lifecycle" and result.returncode == 0:
            summary = re.search(r"(\d+) tests? passed, (\d+) failed, (\d+) skipped", log.read_text())
            if summary is None or int(summary.group(1)) < 2:
                item["status"] = "FAIL_NO_TESTS"
                item["exitCode"] = 1
                save()
                print(log.read_text(), flush=True)
                raise SystemExit("Genuine lifecycle runner did not execute both tests")
            item["tests"] = {"passed": int(summary.group(1)), "failed": int(summary.group(2)), "skipped": int(summary.group(3))}
            item["status"] = "PASS"
        item["logSha256"] = digest(log)
        save()
        print(log.read_text()[-16000:], flush=True)
        if result.returncode:
            raise SystemExit(result.returncode)

    clean_env = os.environ.copy()
    for key in ["FOUNDRY_PROFILE", "FOUNDRY_SRC", "FOUNDRY_TEST", "FOUNDRY_OUT", "FOUNDRY_CACHE_PATH", "FOUNDRY_FS_PERMISSIONS"]:
        clean_env.pop(key, None)
    v4 = output / "v4"
    permit = output / "permit2"
    if not args.skip_build:
        run("01-v4-build", ["forge", "build", "--root", str(CONTRACTS / "deployment-v4"), "--out", str(v4), "--cache-path", str(output / "v4-cache"), "--skip", "test", "--skip", "script", "--sizes"], clean_env)
        run("02-permit2-build", ["forge", "build", "--root", str(PINS["permit2"][0]), "--out", str(permit), "--cache-path", str(output / "permit2-cache"), "--skip", "test", "--skip", "script", "--sizes"], clean_env)
    for root, name in [(v4, "PoolManager"), (v4, "PositionManager"), (v4, "PositionDescriptor"), (v4, "WETH"), (permit, "Permit2")]:
        path = root / (name + ".sol") / (name + ".json")
        artifact = json.loads(path.read_text())
        metadata = artifact.get("metadata", {})
        if isinstance(metadata, str):
            metadata = json.loads(metadata)
        manifest["artifacts"][name] = {"jsonSha256": digest(path),
            "initcodeBytes": len(artifact["bytecode"]["object"].removeprefix("0x")) // 2,
            "runtimeBytes": len(artifact["deployedBytecode"]["object"].removeprefix("0x")) // 2,
            "compiler": metadata.get("compiler"), "settings": metadata.get("settings"),
            "sources": metadata.get("sources")}
        expected_compiler = "0.8.17+commit.8df45f5f" if name == "Permit2" else "0.8.26+commit.8a97fa7a"
        if metadata.get("compiler", {}).get("version") != expected_compiler:
            raise SystemExit("Unexpected genuine artifact compiler for " + name)
        if manifest["artifacts"][name]["runtimeBytes"] > 24_576:
            raise SystemExit("Genuine artifact runtime exceeds EIP-170: " + name)
        manifest["artifacts"][name]["sourceLicenses"] = sorted({v.get("license", "UNSPECIFIED") for v in metadata.get("sources", {}).values()})
    save()
    if args.run:
        config = (CONTRACTS / "foundry.toml").read_text()
        permissions = [{"access": "read-write", "path": str(CONTRACTS)}, {"access": "read", "path": str(v4)}, {"access": "read", "path": str(permit)}]
        encoded = "[" + ", ".join("{ access = " + json.dumps(x["access"]) + ", path = " + json.dumps(x["path"]) + " }" for x in permissions) + "]"
        config, count = re.subn(r"(?m)^fs_permissions\s*=.*$", "fs_permissions = " + encoded, config)
        if count != 1:
            raise SystemExit("Expected exactly one root fs_permissions declaration")
        # Foundry treats --config-path as the project root on this version.
        # Preserve existing settings while making paths and root remappings absolute.
        config = re.sub(r'(?m)^src = .*$', 'src = ' + json.dumps(str(CONTRACTS / "src")), config)
        config = re.sub(r'(?m)^test = .*$', 'test = ' + json.dumps(str(HERE)), config)
        config = re.sub(r'(?m)^script = .*$', 'script = ' + json.dumps(str(CONTRACTS / "script")), config)
        config = re.sub(r'(?m)^libs = .*$', 'libs = [' + json.dumps(str(CONTRACTS / "lib")) + ']', config)
        remappings = []
        for line in (CONTRACTS / "remappings.txt").read_text().splitlines():
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            prefix, target = line.strip().split("=", 1)
            remappings.append(prefix + "=" + str((CONTRACTS / target).resolve()) + "/")
        config = config.replace("[profile.default]", "[profile.default]\nremappings = " + json.dumps(remappings), 1)
        config_path = output / "foundry.toml"
        config_path.write_text(config)
        manifest["derivedConfigSha256"] = digest(config_path)
        env = clean_env | {"FOUNDRY_PROFILE": "test", "FOUNDRY_TEST": str(HERE), "M6_V4_ARTIFACT_ROOT": str(v4), "M6_PERMIT2_ARTIFACT_ROOT": str(permit)}
        run("03-genuine-v4-lifecycle", ["forge", "test", "--root", str(CONTRACTS), "--config-path", str(config_path), "--contracts", str(CONTRACTS / "src/v2"), "--out", str(output / "test-out"), "--cache-path", str(output / "test-cache"), "--match-contract", "^M6GenuineV4CommunityBaselineTest$", "-vvvv" if args.trace else "-vvv"], env)
        for name in ["M6GenuineV4CommunityBaselineTest", "RetroPickLaunchFactoryV2", "CommunityFeeRouterV2", "UniswapV4GraduationExecutorV2", "RetroPickMemeHookV2", "CommunityTreasuryVaultV2", "CommunityTimelockV2"]:
            candidates = list((output / "test-out").glob("*/" + name + ".json"))
            if len(candidates) != 1:
                raise SystemExit("Expected exactly one compiled current artifact for " + name)
            path = candidates[0]
            artifact = json.loads(path.read_text())
            metadata = artifact.get("metadata", {})
            if isinstance(metadata, str):
                metadata = json.loads(metadata)
            manifest.setdefault("protocolArtifacts", {})[name] = {"jsonSha256": digest(path), "runtimeBytes": len(artifact["deployedBytecode"]["object"].removeprefix("0x")) // 2, "initcodeBytes": len(artifact["bytecode"]["object"].removeprefix("0x")) // 2, "compiler": metadata.get("compiler"), "settings": metadata.get("settings"), "sources": metadata.get("sources")}
        save()
    manifest["finished"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    save()
    print("Evidence:", evidence.relative_to(REPO), flush=True)


if __name__ == "__main__":
    main()
