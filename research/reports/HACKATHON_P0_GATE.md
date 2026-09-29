# Hackathon P0 qualification gate — 2026-09-29

**Local contract gate: PASS under the declared P0 assumptions. Live Kuru/demo: BLOCKED_EXTERNAL.** This is a reduced research profile only; it is not a production readiness decision, audit, or authorization to deploy.

Machine-readable status source: `research/reports/hackathon-p0-gates.yaml`.

## Repository baseline and provenance

- Repository: `RetroPick/retropick-protocol`.
- Branch: `codex/hackathon-p0-qualification`.
- Base: `origin/main` at `e354db0a96eca6b56b950d87bf81ad87fa4278fd`.
- Qualified code revision before report/evidence-only additions: `da723095c84de6e1480d80aac62e62fdd3337690`.
- This branch is separate from production and from the historical Cursor research branch. It does not rewrite or merge Cursor provenance.
- Baseline environment record: `evidence/hackathon-p0/repro/baseline-2026-09-28.md`.

## Scope boundary

Hackathon P0 is an explicitly reduced, exact, demo-oriented profile. It excludes Prediction INVALID/half payouts, arbitrary collateral classes, unbounded inventory, PRISM cash settlement, settlement cursors and dust sweeps, shared prefunding, arbitrary component admission, and any solvency dependency on Kuru, an indexer, a frontend, or market prices. Production counterexamples and production gates remain intact.

## Prediction P0 — PASS, local bounded evidence

The research kernel and Python oracle cover binary YES/NO complete sets, one fixed standard collateral, exact balance-delta checks, bounded `uint128` issuance, one-time binary resolution, exact winner redemption, loser-side burn, and lifecycle atomicity. Zero/self ERC-20 transfers are modeled as no-op transitions. No INVALID or half-value path is present.

- Unit: 10 tests passed.
- Python/Solidity differential: 5 tests passed against machine-readable fixture snapshots, including both winner worlds, rejected wrong-side redemption state preservation, and zero/self transfer behavior.
- Stateful: 3 seeds × 256 runs × depth 100, 76,800 handler calls; all five invariants passed, with zero reverts/discards.
- Evidence: `evidence/hackathon-p0/prediction/prediction-p0-differential-2026-09-29.json`, `evidence/hackathon-p0/prediction/prediction-p0-stateful-2026-09-29.json`.

This is bounded local evidence for the declared token/domain. It does not qualify arbitrary ERC-20 behavior, arbitrary call sequences, or production Prediction semantics.

## PRISM P0 — PASS, local bounded evidence

The P0 series admits only factory-registered canonical Prediction outcome tokens, has a deployment-pinned series creator, commits payoff/replication/source-set hashes, and accepts reduced rational nonnegative weights. The exact lot is the LCM of reduced denominators: for `q = k·lcm(d_i)`, each `q·p_i/d_i` is integral. Mint is minter-funded and exact-receipt checked; redemption is transferable-claim burn plus in-kind component return. There is no deposit pool, cash settlement, cursor, arbitrary mint, or dust sweep.

- Unit/adversarial: 11 tests passed, including exact lot, reduced `1/3` and `2/3` weights, pre-funded donation isolation, invalid-lot state preservation, canonical source identity, pinned creator, ABI exclusions, and zero/self transfer behavior.
- Differential: one machine-readable exact-lot fixture test passed.
- Stateful: 3 seeds × 256 runs × depth 100, 76,800 handler calls; physical backing and claim/supply conservation passed, with zero reverts/discards.
- Python oracle: 9 tests passed.
- Evidence: `research/hackathon-p0/fixtures/prism_p0_exact_lot.json`, `evidence/hackathon-p0/prism/prism-p0-stateful-codex-2026-09-29.json`.

The certificate admission path still trusts the fixed creator to independently recheck offchain exact replication; this kernel is not a general onchain solver. Arbitrary/adversarial token behavior and production settlement semantics remain excluded.

## Cross-module P0 — PASS locally

The Solidity harness executes YES_WIN and NO_WIN Prediction-to-PRISM lifecycles from the checked fixture. It verifies registered source identity, distinguishes Prediction's collateral liability from PRISM's held outcome-token backing, mints and transfers PRISM claims, resolves the source, and redeems in kind. The solvency path does not call Kuru or an indexer.

- Cross-module: 2 worlds passed.
- Evidence: `research/contract-kernels/test/hackathon/CrossModuleP0.t.sol`, `research/hackathon-p0/fixtures/cross_module_p0_lifecycle.json`.

This local harness does not demonstrate deployed integration or generalized partial-resolution transformations.

## Security and toolchain

The scoped manual review found no Critical or High enabled-path defect within the P0 assumptions; it is not an audit. Solhint 6.2.4 completed with zero errors and 195 warnings. Slither 0.11.6 and Aderyn 0.6.8 were attempted and are recorded `BLOCKED_TOOL` because IR/AST processing failed. Their failures are not counted as green static-analysis results.

- Review: `research/hackathon-p0/SECURITY_REVIEW.md`.
- Tool evidence: `evidence/hackathon-p0/security/toolchain-2026-09-29.json`.

Key residual assumptions include trusted factory deployment/configuration, standard admitted ERC-20 behavior, and offchain exact-certificate review by the pinned creator. No production or unrestricted deployment conclusion follows.

## Kuru — H1 PASS, H2–H7 BLOCKED_EXTERNAL

Official Monad testnet identity and Kuru Router/Margin Account/USDC addresses were verified read-only against current official documentation and RPC. Router and token code were present, the Router getter matched the documented Margin Account, Monad chain ID was 10143, and testnet USDC reported 6 decimals. A discrepancy with an older SDK quickstart sample was recorded; the dedicated address table was used and its Router binding checked onchain. No transaction was sent.

Evidence: `evidence/hackathon-p0/kuru/kuru-testnet-verification-2026-09-29.json`.

Kuru market deployment, three-market creation, liquidity, place/fill/cancel remain blocked because this environment lacks an authorized funded signer and P0 deployment. Kuru remains secondary liquidity and is not backing.

## Reproducibility and tool configuration

The targeted Python, Solidity unit, differential, cross-module, and seeded invariant suites were rerun at qualified code revision `da723095c84de6e1480d80aac62e62fdd3337690`. Foundry 1.8.3, solc 0.8.26, Cancun EVM, optimizer enabled/200 runs, and `via_ir=false` were used. The existing baseline captures host/dependency details. A single first Python test invocation was issued from the nested Solidity-kernel directory and failed to locate the root-relative test path; rerunning from repository root passed all nine tests. This was a command working-directory error, not a test failure.

A one-command clean-room bootstrap covering every research and security tool is not yet established; reproducibility is therefore evidenced for the listed local test commands, not the entire campaign.

## Composite gate verdict

| Gate | Status | Remaining blocker |
| --- | --- | --- |
| `HACKATHON-P0-CONTRACT-READY` | PASS (local research profile) | Not an audit, testnet deployment approval, or production readiness. Static analyzers remain `BLOCKED_TOOL`. |
| `HACKATHON-P0-KURU-READY` | BLOCKED_EXTERNAL | P0 deployment, funded authorized wallet, markets, liquidity, order/fill/cancel lifecycle. |
| `HACKATHON-P0-DEMO-READY` | BLOCKED_EXTERNAL | Requires the live Kuru lifecycle. |

## Production status remains unchanged

This Hackathon P0 result does not change `research/reports/qualification-gates.yaml`, `research/reports/SMART_CONTRACT_RESEARCH_GATE.md`, Prediction's production contract gate, or PRISM MATH-1. In particular, the production PRISM cumulative-settlement counterexample and `MATH-1 = FAIL` remain authoritative. Production Solidity is not authorized by this report.

## Next owner

Next: obtain human approval for any testnet signer/funding, then perform only the explicitly authorized Kuru testnet lifecycle. In parallel, continue production financial qualification on its existing independent research lane; do not treat Hackathon P0 as closing production ADRs or the PRISM production blocker.
