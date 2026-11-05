#!/usr/bin/env python3
"""Local genuine venue revenue qualification. Never broadcasts or relabels mocks as forks."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import runpy
import subprocess

HERE = Path(__file__).resolve().parent
CONTRACTS = HERE.parents[3]
REPO = CONTRACTS.parent


def main():
    upstream = runpy.run_path(str(HERE.parent / "m6-infra/run_genuine.py"))
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    evidence = REPO / "evidence/launchpad/community-economy-v2/2026-11-05-m6-revenue" / stamp
    evidence.mkdir(parents=True)
    artifacts = Path(os.environ.get("M6_GENUINE_ROOT", "/tmp/retropick-m6-genuine"))
    work = artifacts / ("revenue-" + stamp)
    work.mkdir(parents=True)
    base_config = artifacts / "foundry.toml"
    config = base_config.read_text()
    config = re.sub(r'(?m)^test = .*$', 'test = ' + json.dumps(str(HERE)), config)
    config_path = work / "foundry.toml"
    config_path.write_text(config)
    manifest = {
        "sourceCommit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO, text=True).strip(),
        "kind": "LOCAL_GENUINE_V4_NOT_FORK", "status": "RUNNING", "chainId": 10143,
        "limitations": ["Modeled six-decimal quote; not live Circle", "EOA proposer; not Safe qualification",
                        "Experimental financial modules; no canonical promotion or release authorization"],
        "sourceSha256": {}, "pins": {}, "configSha256": hashlib.sha256(config.encode()).hexdigest(),
    }
    for name, (path, expected) in upstream["PINS"].items():
        actual = subprocess.check_output(["git", "-C", str(path), "rev-parse", "HEAD"], text=True).strip()
        dirty = subprocess.check_output(["git", "-C", str(path), "status", "--porcelain", "--untracked-files=no"], text=True)
        if actual != expected or dirty:
            raise SystemExit("Dependency mismatch or tracked modification: " + name)
        manifest["pins"][name] = actual
    for folder in [HERE, CONTRACTS / "src/v2-research-experiment/m6", HERE.parent / "m6-infra"]:
        for path in sorted(folder.rglob("*.sol")):
            manifest["sourceSha256"][str(path.relative_to(REPO))] = hashlib.sha256(path.read_bytes()).hexdigest()
    manifest["runnerSha256"] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    command = ["forge", "test", "--root", str(CONTRACTS), "--config-path", str(config_path),
               "--contracts", str(CONTRACTS / "src/v2-research-experiment/m6"),
               "--out", str(artifacts / "revenue-out"), "--cache-path", str(artifacts / "revenue-cache"),
               "--match-contract", "^M6GenuineV4RevenueTest$", "-vvvv"]
    manifest["command"] = command
    output = evidence / "manifest.json"
    output.write_text(json.dumps(manifest, indent=2) + "\n")
    env = dict(os.environ, FOUNDRY_PROFILE="test", FOUNDRY_TEST=str(HERE),
               M6_V4_ARTIFACT_ROOT=str(artifacts / "v4"), M6_PERMIT2_ARTIFACT_ROOT=str(artifacts / "permit2"))
    log = evidence / "genuine-revenue.log"
    print("RUN", evidence, flush=True)
    with log.open("w") as stream:
        result = subprocess.run(command, cwd=REPO, env=env, stdout=stream, stderr=subprocess.STDOUT)
    text = log.read_text()
    counts = re.search(r"(\d+) tests? passed, (\d+) failed, (\d+) skipped", text)
    manifest["exitCode"] = result.returncode
    manifest["status"] = "FAIL"
    if counts:
        passed, failed, skipped = map(int, counts.groups())
        manifest["tests"] = {"passed": passed, "failed": failed, "skipped": skipped}
        if result.returncode == 0 and passed >= 2 and failed == 0 and skipped == 0:
            manifest["status"] = "LOCAL_PASS"
    manifest["logSha256"] = hashlib.sha256(log.read_bytes()).hexdigest()
    output.write_text(json.dumps(manifest, indent=2) + "\n")
    print(text[-12000:])
    raise SystemExit(0 if manifest["status"] == "LOCAL_PASS" else 1)


if __name__ == "__main__":
    main()
