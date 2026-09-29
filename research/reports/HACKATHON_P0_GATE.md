# Hackathon P0 qualification gate — 2026-09-29

**Local contract gate: PASS under the declared P0 assumptions. Live Kuru/demo: BLOCKED_EXTERNAL.** This is a reduced research profile only; it is not a production readiness decision, audit, or authorization to deploy.

Machine-readable status source: `research/reports/hackathon-p0-gates.yaml`.

## Repository baseline and provenance

- Repository: `RetroPick/retropick-protocol`.
- Branch: `codex/hackathon-p0-hardening` (hardening changes are being prepared for fast-forward integration into `main`).
- Base: `origin/main` at `4b1eb2839fdef310395c0a2ce238e162a6f5a5d6`.
- Qualified code revision after security hardening: `4f3c70b965d1ee16e31425dc8e8624bb6a06860a`.
- This branch is separate from production and from the historical Cursor research branch. It does not rewrite or merge Cursor provenance.
- Baseline environment record: `evidence/hackathon-p0/repro/baseline-2026-09-28.md`.

## Scope boundary

Hackathon P0 is an explicitly reduced, exact, demo-oriented profile. It excludes Prediction INVALID/half payouts, arbitrary collateral classes, unbounded inventory, PRISM cash settlement, settlement cursors and dust sweeps, shared prefunding, arbitrary component admission, and any solvency dependency on Kuru, an indexer, a frontend, or market prices. Production counterexamples and production gates remain intact.

## Prediction P0 — PASS, local bounded evidence

The research kernel and Python oracle cover binary YES/NO complete sets, one fixed standard collateral, exact balance-delta checks, bounded `uint128` issuance, one-time binary resolution, exact winner redemption, loser-side burn, and lifecycle atomicity. Zero/self ERC-20 transfers are modeled as no-op transitions. No INVALID or half-value path is present.

- Unit and fuzz: 14 tests passed, including a 256-run deterministic property campaign over both YES_WIN and NO_WIN exact payouts.
- Python/Solidity differential: 5 tests passed against machine-readable fixture snapshots, including both winner worlds, rejected wrong-side redemption state preservation, and zero/self transfer behavior.
- Stateful: 3 seeds × 256 runs × depth 100, 76,800 handler calls; all five invariants passed, with zero reverts/discards.
- Outbound merge/redemption now checks exact market debit and receiver credit; a fee-on-transfer outbound regression proves failed calls preserve outcome balances, supplies, liability, and collateral.
- Evidence: `evidence/hackathon-p0/prediction/prediction-p0-differential-2026-09-29.json`, `evidence/hackathon-p0/prediction/prediction-p0-stateful-2026-09-29.json`, `evidence/hackathon-p0/security/p0-hardening-qualification-2026-09-29.json`.

This is bounded local evidence for the declared token/domain. It does not qualify arbitrary ERC-20 behavior, arbitrary call sequences, or production Prediction semantics.

## PRISM P0 — PASS, local bounded evidence

The P0 series admits only factory-registered canonical Prediction outcome tokens, has a deployment-pinned series creator, commits payoff/replication/source-set hashes, and accepts reduced rational nonnegative weights. The exact lot is the LCM of reduced denominators: for `q = k·lcm(d_i)`, each `q·p_i/d_i` is integral. Mint is minter-funded and exact-receipt checked; redemption is transferable-claim burn plus in-kind component return. There is no deposit pool, cash settlement, cursor, arbitrary mint, or dust sweep.

- Unit/adversarial and fuzz: 15 tests passed, including exact lot, reduced `1/3` and `2/3` weights, pre-funded donation isolation, invalid-lot state preservation, canonical source identity, pinned creator, ABI exclusions, zero/self transfer behavior, a 256-run exact-lot mint/redeem property, and direct-constructor bypass rejection.
- Differential: one machine-readable exact-lot fixture test passed.
- Stateful: 3 seeds × 256 runs × depth 100, 76,800 handler calls; physical backing and claim/supply conservation passed, with zero reverts/discards.
- Outbound component transfers check exact series debit and recipient credit; `address(this)` cannot be a mint or redemption receiver.
- Python oracle: 9 tests passed.
- Evidence: `research/hackathon-p0/fixtures/prism_p0_exact_lot.json`, `evidence/hackathon-p0/prism/prism-p0-stateful-codex-2026-09-29.json`, `evidence/hackathon-p0/security/p0-hardening-qualification-2026-09-29.json`.

The audit found historical counterexample `CX-HACK-PRISM-DIRECT-DEPLOY-001`: revision `da723095` allowed callers to construct `PrismSeriesP0` directly with arbitrary nonzero certificate hashes, bypassing the pinned factory creator and canonical registry. It could create a misleading unregistered asset; no direct backing theft was demonstrated. Revision `4f3c70b` repairs this by requiring constructor caller/factory identity and matching Prediction factory, with permanent regression `test_directSeriesDeploymentCannotBypassCanonicalFactory`. The certificate path still trusts the fixed creator to independently exact-recheck offchain replication; the kernel is not a general onchain solver. Arbitrary/adversarial token behavior and production settlement semantics remain excluded.

## Cross-module P0 — PASS locally

The Solidity harness executes YES_WIN and NO_WIN Prediction-to-PRISM lifecycles from the checked fixture. It verifies registered source identity, distinguishes Prediction's collateral liability from PRISM's held outcome-token backing, mints and transfers PRISM claims, resolves the source, and redeems in kind. The solvency path does not call Kuru or an indexer.

- Cross-module: 2 worlds passed.
- Evidence: `research/contract-kernels/test/hackathon/CrossModuleP0.t.sol`, `research/hackathon-p0/fixtures/cross_module_p0_lifecycle.json`.

This local harness does not demonstrate deployed integration or generalized partial-resolution transformations.

## Security and toolchain

The scoped manual review found no currently unresolved Critical or High enabled-path defect within the P0 assumptions; it is not an audit. Solhint 6.2.4 completed with zero errors and 203 warnings. Slither 0.11.6 and Aderyn 0.6.8 were rerun and are recorded `BLOCKED_TOOL` because IR/AST processing failed. Slither's resulting dead-code notices include live P0 helpers whose IR could not be resolved. Tool failures and warning lists are not green static-analysis results.

- Review: `research/hackathon-p0/SECURITY_REVIEW.md`.
- Tool evidence: `evidence/hackathon-p0/security/toolchain-2026-09-29.json`.

Key residual assumptions include trusted factory deployment/configuration, standard admitted ERC-20 behavior, and offchain exact-certificate review by the pinned creator. No production or unrestricted deployment conclusion follows.

## Kuru — H1 PASS, H2–H7 BLOCKED_EXTERNAL

Official Monad testnet identity and Kuru Router/Margin Account/USDC addresses were verified read-only against current official documentation and RPC. Router and token code were present, the Router getter matched the documented Margin Account, Monad chain ID was 10143, and testnet USDC reported 6 decimals. A discrepancy with an older SDK quickstart sample was recorded; the dedicated address table was used and its Router binding checked onchain. No transaction was sent.

Evidence: `evidence/hackathon-p0/kuru/kuru-testnet-verification-2026-09-29.json`.

Kuru market deployment, three-market creation, liquidity, place/fill/cancel remain blocked because this environment lacks an authorized funded signer and P0 deployment. A parameter packet records official Router/SDK inputs and explicitly demo-only candidate values; it is not a deployment instruction or evidence that any live market exists. Kuru remains secondary liquidity and is not backing.

## Reproducibility and tool configuration

The checked-in fast/stateful script was rerun at qualified code revision `4f3c70b965d1ee16e31425dc8e8624bb6a06860a`. Foundry 1.8.3, solc 0.8.26, Cancun EVM, optimizer enabled/200 runs, and `via_ir=false` were used. Fast fuzz uses deterministic seed 1 with 256 runs; Prediction and PRISM stateful use seeds 1/2/3, 256 runs per seed, and depth 100. Raw output is preserved in `evidence/hackathon-p0/security/p0-stateful-raw-2026-09-29.txt`. The existing baseline captures host/dependency details. A single first Python test invocation was issued from the nested Solidity-kernel directory and failed to locate the root-relative test path; rerunning from repository root passed all nine tests. This was a command working-directory error, not a test failure.

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
