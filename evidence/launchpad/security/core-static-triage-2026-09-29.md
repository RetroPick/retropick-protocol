# Launchpad Core V2 static-analysis first pass — 2026-09-29

Baseline `bbc1feae910a23a33113037d424aa2adc53b6fbe`; only test/evidence/control files were being added. This is a **raw findings inventory, not security clearance**. No production Solidity was patched during the scan.

| Tool | Version | Exact command / scope | Result | Qualification |
| --- | --- | --- | --- | --- |
| Slither | 0.11.6 | `cd contracts && slither . --filter-paths 'lib/|src/v1/|test/' --exclude-dependencies --json /tmp/kuru-v2.YU02vw/slither-core.json` | Build/IR succeeded for 112 contracts with 102 detectors; process exited 255 because 73 findings were emitted. Nine raw High findings: four `arbitrary-send-eth`, four `reentrancy-balance`, one `reentrancy-eth`. | **TRIAGE_REQUIRED**; the output is not a PASS and high finding count is not an exploit count. |
| Aderyn | 0.6.8 | `cd contracts && aderyn . -i src/v2/ -o /tmp/kuru-v2.YU02vw/aderyn-core.json` | Exit 0; ingested 15 compiled files, ran 88 detectors; 3 high categories / 15 low categories. High categories are `contract-locks-ether`, `reentrancy-state-change`, `unsafe-casting`. | **TRIAGE_REQUIRED**; successful analyzer execution is not a finding-free result. |
| Solhint | 6.2.4 | `cd contracts && solhint 'src/v2/*.sol' -f json --noPoster` | Failed: `Failed to load a solhint's config file.` No repository Solhint configuration was found. | **BLOCKED_CONFIG**, not PASS; a scoped, reviewed lint policy is needed. |

Slither high examples: `RetroPickBondingCurveV2._sendQuote` native payout; `RetroPickLaunchFactoryV2._sweepCurve` pre/post ERC20 balance around `curve.graduate`; `RetroPickBondingCurveV2.graduate` fee-escrow/native external calls. Source contains local reentrancy guards and comments for some paths, but that is not a finding disposition. Aderyn flags post-call state writes in Curve initialization, Vault locking, Factory construction and Locker, plus V4 casts and a potentially locked Ether path in the Hook. Each relevant finding needs reachable preconditions, caller/token class, source-level review and an adversarial regression or documented false-positive reason before the security gate can close.

Temporary full JSON outputs were generated outside the repository and are not treated as durable audit artifacts. The exact commands and summary above are reproducible. `BLOCK-CONTRACT-TESTS` and all release/security gates remain open.
