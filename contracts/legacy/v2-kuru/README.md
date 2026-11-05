# Historical Kuru regression lane

This lane preserves the **2026-11-04 development checkpoint** `7ddf4dae65e11acb489be7eceb30a4846adf18cc` for Kuru custody, policy and retry regression. It is separate from [`contracts/legacy-v2`](../../legacy-v2/README.md), which freezes the actual hackathon deployment source at `f0363249f4b74e58dde37d1241742ca5a92bcfe3`. These snapshots must not be conflated.

The owner requested concrete Kuru implementation be removed from active new-launch sources. Five files from each active lane are quarantined under `contracts/src/legacy/v2/kuru/{canonical,experimental}/`. The canonical archive includes its 30-file historical Factory/Curve/Coordinator/registry import closure so Kuru tests never run against the new V4-only admission policy. The experimental archive preserves its nine-file Kuru closure, including the distinct original `IKuruV2.sol` blob. All archived Solidity source bytes are verified against the recorded Git blobs.

`original/` retains byte-for-byte historical deployment/smoke/trade scripts and test consumers with `.orig` suffixes; `script/` and `contracts/test/legacy/v2-kuru/` contain explicitly adapted import/artifact paths. The adapted tests keep their assertion and function bodies. The verifier checks this mechanically after normalizing imports, artifact identities and formatting. The historical scripts retain their original operations and are **not authorized to run**. No broadcast or live write forms part of this extraction.

## Active and historical behavior

- Active canonical and experimental quote registries accept `venueMask == 1` only and reject venue1 admission even if an owner configures its executor slot. Existing Factory, Curve, Coordinator, fee, treasury and graduation implementation bodies are unchanged.
- `GraduationVenue.UNISWAP_V4 == 0` and `GraduationVenue.KURU == 1` are retained. Venue1 is a historical wire tombstone, never a new venue assignment. Event/receipt/packet layouts remain decodable.
- Existing deployed registries, contracts, secured packets, LP locks, fee claims, SDK/indexer decoding and judging deployment configuration are untouched. Source separation neither migrates assets nor alters immutable chain instances.
- The historical Coordinator still completes a pinned packet using its committed executor/codehash/policy/receiver; completion does not consult current active admission. Failed destination execution preserves secured obligations and retries on that historical stack.
- Continuous Kuru community fee collection remains `BLOCKED_EXTERNAL_CAPABILITY`.

## Source identity and CREATE2

`PROVENANCE.json` records original Git revision/blob/SHA-256, source-unit key, compiler settings, remappings and dependency trees for each archive entry. **Relocated compilation is a logic regression, not an exact deployed-bytecode reproduction.** In particular, changed source-unit metadata changes `KuruLiquidityLockV2.creationCode`, which participates in the executor's CREATE2 receiver prediction. Never substitute a relocated lock/executor into an old packet or refresh old deployment records from these artifacts.

Exact deployment reproduction uses `contracts/legacy-v2` under the original virtual `src/v2/...` keys and its recorded compiler/dependency/remapping settings. This regression archive is not a replacement for that procedure.

## Verification

From the repository root:

```bash
python3 contracts/legacy/v2-kuru/verify.py
python3 contracts/legacy-v2/verify.py
python3 scripts/launchpad/qualify_kuru_extraction.py \
  --evidence /absolute/new/run/directory
```

The runner refuses to overwrite prior evidence, saves every command/result/log hash incrementally, and separates source-scoped active tests from historical tests. Local commands cannot supply RPC, deployed-code or real Kuru fee qualification. The retained genuine-fork suite requires a qualified `MONAD_TESTNET_RPC_URL`, pinned `MONAD_V2_FORK_BLOCK`, and verified dependency identities; missing qualification is **BLOCKED**, not PASS.

`contracts/script/DeployV2V4OnlyCandidate.s.sol` is a separate local/fork construction candidate. It contains no Kuru construction or broadcast cheatcode, admits mask1 only, and writes only a separately named candidate output. It is neither a production deployment workflow nor release authorization.

## Authority and handoff

The owner-directed source separation is implemented for review. `KURU_DEPRECATION_ADR.md` remains a **candidate**, not a self-accepted protocol ADR. New-stack admission, independent review, release gates and deployment authorization remain separate. Historical SDK/indexer/UI Kuru capabilities must remain bound to their old deployment identity; do not globally delete their decoding or user-owned position paths. A new V4-only creation profile requires fresh economics quotes and capability discovery. Frozen production ABI/catalog files are unchanged.
