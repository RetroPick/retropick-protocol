#!/usr/bin/env python3
"""Fail-closed testnet release runner. Signer secrets remain inside Foundry's keystore reader."""
import argparse
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import urllib.request

CONTRACTS = Path(__file__).resolve().parents[1]
ROOT = CONTRACTS.parent
EVIDENCE = ROOT / "evidence/launchpad/v2-monad-testnet"
CIRCLE = "0x534b2f3A21130d7a60830c2Df862319e593943A3"
ROUTER = "0x7EFbE105Ca7415dE98F96622173458ac1c054630"
MARGIN = "0xd029C2D98ff85D8F64799017fE00a59B1159CE02"
BOOK = "0x72caE0a99C19B574e8a6De558F43fc1D019c9374"
VAULT = "0x4d54e0d60CaB0cec0100cdA8e00897bC933C5Bb6"
PROXY_HASH = "0xae572ec3ca9b5f49c0364ca34edc5880b6b2837e47802e64e6b681bf2e74aa5c"
IMPL_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
ALLOWED = {"MONAD_TESTNET_RPC_URL"} | {
    f"MONAD_TESTNET_{kind}_{actor}"
    for kind in ("ACTOR", "ACCOUNT", "KEYSTORE", "PASSWORD_FILE") for actor in ("A", "B")
}


def load_env(path):
    env = dict(os.environ)
    # Never evaluate shell substitutions or export the entire local environment file.
    for line in Path(path).read_text().splitlines():
        line = line.strip().removeprefix("export ")
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key.strip() in ALLOWED:
            words = shlex.split(value, comments=True)
            if words:
                env[key.strip()] = words[0]
    assert env.get("MONAD_TESTNET_RPC_URL"), "RPC required; missing RPC is never a passing fork"
    for key in ("FOUNDRY_ETH_RPC_URL", "ETH_RPC_URL", "ETH_PRIVATE_KEY", "PRIVATE_KEY",
                "ETH_KEYSTORE", "ETH_KEYSTORE_ACCOUNT", "ETH_PASSWORD"):
        env.pop(key, None)
    env.update(FOUNDRY_NETWORK="monad", FOUNDRY_CHAIN_ID="10143")
    return env


def rpc(env, method, params):
    request = urllib.request.Request(env["MONAD_TESTNET_RPC_URL"],
        data=json.dumps(dict(jsonrpc="2.0", id=1, method=method, params=params)).encode(),
        headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=45) as response:
        result = json.load(response)
    if "error" in result:
        raise RuntimeError(f"RPC {method} failed: {result['error']}")
    return result["result"]


def pure(env, *args):
    return subprocess.check_output(["cast", *args], env=env, text=True).strip()


def call(env, target, signature, *args, block="latest"):
    data = pure(env, "calldata", signature, *map(str, args))
    return rpc(env, "eth_call", [{"to": target, "data": data}, block])


def address(word):
    return "0x" + word[-40:]


def write(path, value):
    def exact_json(item):
        if isinstance(item, dict):
            return {key: exact_json(v) for key, v in item.items()}
        if isinstance(item, list):
            return [exact_json(v) for v in item]
        # Preserve exact values for downstream JavaScript consumers too.
        if isinstance(item, int) and not isinstance(item, bool) and abs(item) > 2**53 - 1:
            return str(item)
        return item
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(exact_json(value), indent=2) + "\n")


def sha():
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()


def preflight(env):
    assert int(rpc(env, "eth_chainId", []), 16) == 10143, "Wrong chain"
    block = rpc(env, "eth_blockNumber", [])
    snapshot = {"chainId": 10143, "block": int(block, 16), "router": ROUTER,
                "marginAccount": MARGIN, "orderBookImplementation": BOOK, "vaultImplementation": VAULT}
    hashes = {
        ROUTER: PROXY_HASH, MARGIN: PROXY_HASH,
        BOOK: "0x24c5974f233021f00d607bfa191d430f79565663fb90805ebcfca52de7333500",
        VAULT: "0xde0b16a79cf8f711403e89093c1e82ce0e7813949dd0f5041b41da324fdd3dc3",
        CIRCLE: "0x96215e6049ed615cdc22fea7701e85458a8e51a2df3e7d45e8f9fa1d521b5a78",
    }
    snapshot["codeHashes"] = {}
    for target, expected in hashes.items():
        code = rpc(env, "eth_getCode", [target, block])
        actual = pure(env, "keccak", code)
        assert actual == expected, f"Environment drift: code identity {target}"
        snapshot["codeHashes"][target] = actual
    for getter, expected in (("marginAccountAddress()", MARGIN), ("orderBookImplementation()", BOOK),
                             ("kuruAmmVaultImplementation()", VAULT)):
        assert address(call(env, ROUTER, getter, block=block)).lower() == expected.lower(), getter
    snapshot["proxyImplementations"] = {}
    for target, expected in ((ROUTER, "0xaaa0f0c4d49d09ef33ae758d88afab810ecbe1ed"),
                             (MARGIN, "0xf10af40f060b7ae54a2d5da682becc981dfb52c3")):
        actual = address(rpc(env, "eth_getStorageAt", [target, IMPL_SLOT, block]))
        assert actual.lower() == expected.lower(), f"Proxy implementation drift: {target}"
        snapshot["proxyImplementations"][target] = actual
    assert int(call(env, CIRCLE, "decimals()", block=block), 16) == 6
    snapshot["actors"] = {}
    for actor in ("A", "B"):
        account = env.get(f"MONAD_TESTNET_ACTOR_{actor}")
        if account:
            snapshot["actors"][actor] = {"address": account,
                "monWei": int(rpc(env, "eth_getBalance", [account, block]), 16),
                "circleRaw": int(call(env, CIRCLE, "balanceOf(address)", account, block=block), 16)}
    return snapshot


def run(env, args, log):
    log.parent.mkdir(parents=True, exist_ok=True)
    print(f"Running {args[0]} {args[1]} -> {log.relative_to(ROOT)}", flush=True)
    with log.open("w") as output:
        result = subprocess.run(args, cwd=CONTRACTS, env=env, stdout=output, stderr=subprocess.STDOUT)
    assert result.returncode == 0, f"Command failed; inspect {log}"


def script(env, name, log, broadcast=False):
    args = ["forge", "script", f"script/{name}.s.sol:{name}", "--rpc-url", env["MONAD_TESTNET_RPC_URL"],
            "--sender", env["MONAD_TESTNET_ACTOR_A"], "--slow", "--no-storage-caching",
            "--with-gas-price", "120000000000", "--priority-gas-price", "3000000000"]
    if broadcast:
        # Called only after every release gate and current environment/funding checks.
        args += ["--broadcast"]
        for actor in (("A", "B") if name == "TradeV2KuruTestnet" else ("A",)):
            key = env[f"MONAD_TESTNET_KEYSTORE_{actor}"]
            password = env[f"MONAD_TESTNET_PASSWORD_FILE_{actor}"]
            signer = pure(env, "wallet", "address", "--keystore", key, "--password-file", password)
            assert signer.lower() == env[f"MONAD_TESTNET_ACTOR_{actor}"].lower(), "Unauthorized signer identity"
            args += ["--keystore", key, "--password-file", password]
    release_env = dict(env, FOUNDRY_PROFILE="release_script")
    run(release_env, args, EVIDENCE / log)


def size_gate():
    sizes = {}
    for path in (CONTRACTS / "out").glob("*/*.json"):
        artifact = json.loads(path.read_text())
        metadata = artifact.get("metadata", {})
        if isinstance(metadata, str):
            metadata = json.loads(metadata)
        targets = metadata.get("settings", {}).get("compilationTarget", {})
        if not any(key.startswith("src/v2/") for key in targets):
            continue
        size = len(artifact.get("deployedBytecode", {}).get("object", "").removeprefix("0x")) // 2
        assert size <= 24576, f"EIP-170: {path.stem} {size}"
        sizes[path.stem] = size
    assert 0 < sizes["RetroPickLaunchFactoryV2"] <= 23500
    for name in ("WETH", "PoolManager", "PositionManager", "PositionDescriptor"):
        artifact = json.loads((CONTRACTS / f"deployment-v4/out/{name}.sol/{name}.json").read_text())
        sizes[name] = len(artifact["deployedBytecode"]["object"].removeprefix("0x")) // 2
        assert sizes[name] <= 24576
    artifact = json.loads((CONTRACTS / "lib/v4-deployment-periphery/lib/permit2/out/Permit2.sol/Permit2.json").read_text())
    sizes["Permit2"] = len(artifact["deployedBytecode"]["object"].removeprefix("0x")) // 2
    assert sizes["Permit2"] <= 24576
    return sizes


def confirmed(env, name):
    path = CONTRACTS / f"broadcast/{name}.s.sol/10143/run-latest.json"
    data = json.loads(path.read_text())
    transactions = data["transactions"]
    assert transactions and all(tx.get("hash") for tx in transactions), "No broadcast transaction evidence"
    receipts = []
    for tx in transactions:
        receipt = rpc(env, "eth_getTransactionReceipt", [tx["hash"]])
        assert receipt and int(receipt["status"], 16) == 1, f"Unconfirmed/failed transaction: {tx['hash']}"
        receipts.append({"hash": tx["hash"], "block": int(receipt["blockNumber"], 16),
                         "status": 1, "contractName": tx.get("contractName"),
                         "contractAddress": receipt.get("contractAddress"),
                         "function": tx.get("function"), "gasUsed": int(receipt["gasUsed"], 16)})
    return receipts


def verify_launch(env, manifest, launch):
    """Read actual chain state again after the broadcast, independently of local script assertions."""
    addresses = manifest["addresses"]
    raw = call(env, addresses["coordinator"], "ledger(address)", launch["token"])[2:]
    words = [int(raw[i:i + 64], 16) for i in range(0, len(raw), 64)]
    assert len(words) == 12 and words[0] == 2, "Onchain phase must be GRADUATED"
    assert words[1] == words[3] == int(launch["securedQuote"])
    assert words[2] == words[4] == int(launch["securedLaunchTokens"])
    assert words[5] != 0 and words[6] != 0
    assert address(hex(words[7])[2:].zfill(64)).lower() == launch["lpLock"].lower()
    assert words[8] == int(launch["protectedLPAmount"]) and words[10] == int(launch["protectedExcessAmount"])
    assert int(call(env, launch["curve"], "graduated()"), 16) == 1
    assert int(call(env, launch["vault"], "balanceOf(address)", launch["lpLock"]), 16) == words[8]
    assert int(call(env, launch["token"], "balanceOf(address)", launch["lpLock"]), 16) == words[10]
    assert address(call(env, launch["vault"], "market()")).lower() == launch["market"].lower()
    assert address(call(env, launch["vault"], "marginAccount()")).lower() == MARGIN.lower()
    worker = addresses["kuruExecutor"]
    assert int(call(env, launch["token"], "balanceOf(address)", worker), 16) == 0
    assert int(call(env, launch["token"], "allowance(address,address)", worker, launch["vault"]), 16) == 0
    quote = launch["quoteAsset"]
    liability = int(call(env, addresses["coordinator"], "quoteLiability(address)", quote), 16)
    if int(quote, 16) == 0:
        physical = int(rpc(env, "eth_getBalance", [addresses["coordinator"], "latest"]), 16)
        assert int(rpc(env, "eth_getBalance", [worker, "latest"]), 16) == 0
    else:
        physical = int(call(env, quote, "balanceOf(address)", addresses["coordinator"]), 16)
        assert int(call(env, quote, "balanceOf(address)", worker), 16) == 0
        assert int(call(env, quote, "allowance(address,address)", worker, launch["vault"]), 16) == 0
    assert physical >= liability == 0
    return {"phase": "GRADUATED", "ledgerWords": words, "coordinatorPhysicalQuote": physical,
            "coordinatorQuoteLiability": liability, "workerResiduals": 0, "workerVaultAllowances": 0,
            "verifiedAtBlock": int(rpc(env, "eth_blockNumber", []), 16)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("check", "gates", "deploy", "smoke", "recover-smoke", "circle", "trade", "record"))
    parser.add_argument("--env-file", required=True, help="Authorized external env file; secrets are never printed")
    args = parser.parse_args()
    env = load_env(args.env_file)
    snapshot = preflight(env)
    write(EVIDENCE / "environment-latest.json", snapshot)
    gates_path = EVIDENCE / "release-gates.json"
    manifest_path = ROOT / "deployments/monad-testnet/v2.json"
    if args.command == "check":
        print(json.dumps(snapshot, indent=2))
    elif args.command == "gates":
        run(env, ["forge", "build", "script/TradeV2KuruTestnet.s.sol"], EVIDENCE / "trade-script-build.log")
        test_env = dict(env, FOUNDRY_ETH_RPC_URL="", FOUNDRY_CODE_SIZE_LIMIT="1048576",
                        MONAD_V2_FORK_BLOCK=str(snapshot["block"]))
        run(test_env, ["python3", "test/v2/tools/generate_completion_vectors.py", "--check"], EVIDENCE / "oracle-check.log")
        run(test_env, ["forge", "test", "--summary"], EVIDENCE / "forge-test.log")
        text = (EVIDENCE / "forge-test.log").read_text()
        suites = re.findall(r"Suite result: \w+\. (\d+) passed; (\d+) failed; (\d+) skipped", text)
        totals = [sum(int(s[i]) for s in suites) for i in range(3)]
        assert suites and totals[0] > 0 and totals[1] == totals[2] == 0, "Tests failed or skipped"
        run(env, ["forge", "build", "--sizes", "--skip", "test", "--skip", "script"], EVIDENCE / "forge-sizes.log")
        sizes = size_gate()
        script(env, "DeployV2MonadTestnet", "deployment-simulation.log")
        write(gates_path, {"sourceGitSHA": sha(), "testsPassed": totals[0], "testsFailed": 0,
                          "testsSkipped": 0, "freshForkBlock": snapshot["block"], "runtimeBytes": sizes,
                          "deploymentSimulation": "PASS", "policy": "TESTNET_POLICY_V1"})
        print("Release gates PASS", flush=True)
    elif args.command == "deploy":
        gates = json.loads(gates_path.read_text())
        assert gates["sourceGitSHA"] == sha(), "Code changed since gate run"
        dirty = subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=all", "--", "contracts"],
                                        cwd=ROOT, text=True)
        assert not dirty, "Uncommitted contract changes"
        assert snapshot["actors"]["A"]["monWei"] >= 9 * 10**18, "Deployment plus MON smoke funding required"
        assert not manifest_path.exists(), "Existing deployment: do not deploy twice; inspect broadcast evidence"
        script(env, "DeployV2MonadTestnet", "deployment-broadcast.log", broadcast=True)
        receipts = confirmed(env, "DeployV2MonadTestnet")
        addresses = json.loads((CONTRACTS / "v2-deployment-addresses.json").read_text())
        for key in ("factory", "coordinator", "kuruExecutor", "v4Executor", "quoteRegistry", "hook"):
            assert rpc(env, "eth_getCode", [addresses[key], "latest"]) != "0x", key
        for key, worker, getter in (("kuruDonationLock", "kuruExecutor", "donationLock()"),
                                   ("v4DonationLock", "v4Executor", "donationLock()"),
                                   ("v4Guard", "v4Executor", "guard()")):
            addresses[key] = address(call(env, addresses[worker], getter))
        write(manifest_path, {"chainId": 10143, "deploymentBlock": receipts[0]["block"], "gitSHA": sha(),
              "scope": "TESTNET_HACKATHON", "addresses": addresses, "kuruEnvironment": snapshot,
              "quotePolicyVersions": {"MON": 1, "CIRCLE_TEST_USDC": 1}, "quotePolicy": "TESTNET_POLICY_V1",
              "gates": gates, "deploymentTransactions": receipts, "monSmoke": "PENDING",
              "circleSmoke": "BLOCKED_FUNDING" if snapshot["actors"]["A"]["circleRaw"] < 2_000_000 else "PENDING"})
    elif args.command in ("smoke", "recover-smoke", "circle"):
        manifest = json.loads(manifest_path.read_text())
        kind = "circle" if args.command == "circle" else "mon"
        assert manifest[kind + "Smoke"] != "PASS", "Smoke already recorded; avoid a duplicate launch"
        if kind == "circle" and snapshot["actors"]["A"]["circleRaw"] < 2_000_000:
            manifest["circleSmoke"] = "BLOCKED_FUNDING"
            write(manifest_path, manifest)
            print("CIRCLE_LIVE_SMOKE = BLOCKED_FUNDING")
            return
        env.update(V2_FACTORY=manifest["addresses"]["factory"],
                   V2_SMOKE_QUOTE="0x" + "0" * 40 if kind == "mon" else CIRCLE)
        if args.command != "recover-smoke":
            intermediate = CONTRACTS / "v2-smoke-result.json"
            if intermediate.exists():
                prior = json.loads(intermediate.read_text())
                if (prior["factory"].lower() == env["V2_FACTORY"].lower()
                        and prior["quoteAsset"].lower() == env["V2_SMOKE_QUOTE"].lower()
                        and rpc(env, "eth_getCode", [prior["token"], "latest"]) != "0x"):
                    raise RuntimeError("Existing live smoke: recover confirmed receipts instead of launching again")
            script(env, "SmokeV2MonadTestnet", kind + "-smoke-simulation.log")
            assert snapshot["actors"]["A"]["monWei"] >= (3 if kind == "mon" else 1) * 10**18, "Smoke gas funding"
            script(env, "SmokeV2MonadTestnet", kind + "-smoke-broadcast.log", broadcast=True)
        result = json.loads((CONTRACTS / "v2-smoke-result.json").read_text())
        assert result["factory"].lower() == env["V2_FACTORY"].lower()
        assert result["quoteAsset"].lower() == env["V2_SMOKE_QUOTE"].lower()
        result["transactions"] = confirmed(env, "SmokeV2MonadTestnet")
        assert result["phase"] == "GRADUATED", "Expected GRADUATED"
        result["onchainVerification"] = verify_launch(env, manifest, result)
        manifest[kind + "Smoke"] = "PASS"
        manifest[kind + "Launch"] = result
        write(manifest_path, manifest)
    elif args.command == "trade":
        manifest = json.loads(manifest_path.read_text())
        assert manifest["monSmoke"] == "PASS" and "marketUsability" not in manifest
        launch = manifest["monLaunch"]
        env.update(V2_TRADE_TOKEN=launch["token"], V2_TRADE_MARKET=launch["market"],
                   V2_TRADE_VAULT=launch["vault"], V2_TRADE_LOCK=launch["lpLock"])
        for actor in ("A", "B"):
            assert snapshot["actors"][actor]["monWei"] > 10**18, "Trading gas funding"
        script(env, "TradeV2KuruTestnet", "trade-simulation.log")
        script(env, "TradeV2KuruTestnet", "trade-broadcast.log", broadcast=True)
        result = json.loads((CONTRACTS / "v2-trade-result.json").read_text())
        result["transactions"] = confirmed(env, "TradeV2KuruTestnet")
        # Confirm actual chain logs, not only the script's local trace assertions.
        events = []
        for tx in result["transactions"]:
            receipt = rpc(env, "eth_getTransactionReceipt", [tx["hash"]])
            events.extend(log for log in receipt["logs"] if log["address"].lower() == launch["market"].lower())
        topics = {log["topics"][0] for log in events}
        for event in ("OrderCreated(uint40,address,uint96,uint32,bool)",
                      "Trade(uint40,address,bool,uint256,uint96,address,address,uint96)",
                      "OrdersCanceled(uint40[],address)"):
            assert pure(env, "keccak", event) in topics, f"Missing confirmed {event} event"
        result["marketEvents"] = events
        for actor in ("A", "B"):
            account = env[f"MONAD_TESTNET_ACTOR_{actor}"]
            for suffix, asset in (("Base", launch["token"]), ("Quote", "0x" + "0" * 40)):
                actual = int(call(env, MARGIN, "getBalance(address,address)", account, asset), 16)
                assert actual == result["actor" + actor + suffix], "Confirmed trader balance mismatch"
        best = call(env, launch["market"], "bestBidAsk()")[2:]
        assert int(best[:64], 16) == result["finalBestBid"]
        assert int(best[64:128], 16) == result["finalBestAsk"]
        result["onchainVerification"] = verify_launch(env, manifest, launch)
        manifest["marketUsability"] = result
        write(manifest_path, manifest)
    else:
        manifest = json.loads(manifest_path.read_text())
        assert manifest["monSmoke"] == "PASS", "No successful MON smoke"
        manifest["monLaunch"]["onchainVerification"] = verify_launch(env, manifest, manifest["monLaunch"])
        manifest["finalEnvironment"] = snapshot
        write(manifest_path, manifest)
        print("Confirmed deployment and MON smoke evidence recorded")


if __name__ == "__main__":
    main()
