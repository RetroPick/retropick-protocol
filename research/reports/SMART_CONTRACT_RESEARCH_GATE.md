# Smart-contract research gate — 2026-09-28

**Verdict: NOT READY FOR RESEARCH HANDOFF OR V2 INTEGRATION.** This report is a dated assessment, not an accepted ADR, audit, deployment approval, or production-contract authorization. The canonical machine-readable gate source is `research/reports/qualification-gates.yaml`; its FAIL/BLOCKED states control over test counts. No financial contract was moved into `contracts/src/v2/`.

| Major gate | Status | Decisive evidence / remaining condition |
| --- | --- | --- |
| Clean local reproduction | PASS | `evidence/research/repro/codex-clean-repro-tip-2026-09-28.md`; local only, not CI/audit |
| Prediction math and semantics | FAIL | `CX-PRED-INVALID-HOLDER-001`, `CX-PRED-WINNER-OVERFLOW-001`; ADR-P05/P19 PROPOSED |
| Prediction Python↔Solidity equivalence | FAIL | Existing fixtures match on their domain, but P08/P11/P12/P13/P18/P19 and transfer/admission scope remain unresolved; `PREDICTION_SEMANTIC_CONVERGENCE_PACKET.md` |
| Prediction contract/security handoff | FAIL | Unqualified dual-role callback violates lifecycle ordering; static IR incomplete; `COLLATERAL_ADMISSION_PACKET.md`, `evidence/research/security/toolchain-2026-09-28.md` |
| PRISM exact replication math | CONDITIONAL | Exact rational solver/recheck on declared bounded shapes; no authorized onchain admission/certificate; `PRISM_ADMISSION_SOURCE_INTERFACE_PACKET.md` |
| PRISM component/reservation backing | FAIL | Requirement-delta math supported, but prefunding ownership and physical reservation semantics unaccepted; `PRISM_BACKING_RESERVATION_PACKET.md` |
| PRISM MATH-1D / MATH-1 | FAIL | Canonical per-call floor underpays; global-cursor candidate aggregates correctly but holder allocation counterexample remains; `ADR_R03_ACCEPTANCE_PACKET.md` |
| Source interface / X-I01..X-I07 | BLOCKED | Source boundary not frozen, no cross-module harness; `PRISM_ADMISSION_SOURCE_INTERFACE_PACKET.md` |
| CONTRACT-ARCH-1 | BLOCKED | Cannot choose synchronized production state boundaries before custody, holder entitlement, and source admission are frozen; candidate only in `docs/prism/04-architecture/PHASE1_CANDIDATE_SERIES.md` |
| MODULE-ADMISSION-FINANCE-1 | FAIL | Financial counterexamples and missing integration/security evidence; YAML gate remains `met: false` |

## 1. Repository baseline

Integration baseline `origin/main` at branch creation: `915241615ee3e3742d683e3900aa72741dd39bad`. New branch: `codex/financial-contract-qualification-v2`; original baseline/environment: `evidence/research/repro/codex-baseline-2026-09-28.md`. This report reflects the new branch after the Codex commits; each new counterexample artifact identifies its source basis. Current branch SHA is captured by the reproducibility record above and by Git history, not presumed to equal main.

## 2. Cursor research provenance

Historical `origin/cursor/finance-qualification-bbd4` tip at inspection: `2aeb8d8daf72f06db6c91533b5df06b9ed4ff63f`; merge-base with main: `dd7bfb5dc99dd72486649a4cbbcb26f172a1a34f`. Research files were already integrated on main with identical blobs at the named paths. The old branch remains untouched; no merge/rebase/replay occurred. Status: PASS for provenance reconstruction; see baseline record.

## 3. Codex environment

Python 3.12.3, Node 24.11, pnpm 11.25, Foundry 1.8.3, kernel solc 0.8.26 with optimizer 200/viaIR off; production contracts use a different viaIR setting. Formal virtual environment pins SymPy 1.14.0, mpmath 1.3.0, z3-solver 5.1.0 in `research/requirements-formal.txt`. Slither 0.11.6/crytic-compile 0.4.2, Aderyn 0.6.8, Semgrep 1.177.0 were available. Baseline record lists submodule/tool state. Status: PASS for local tool inventory, not security qualification.

## 4. Reproduction status

`research/benchmarks/scripts/repro_clean.sh` uses separate fresh local clones and pinned Python environments. Default at `d466cf5` passed 33 Prediction/111 PRISM Python tests and 171 Foundry tests with one expected skip. Named research profile at `bbbfaa2` passed legacy attack, holder-fairness, telescope, named exhaustive, fixture, benchmark, and long INVALID composition steps. Generated historical JSON rewrites stayed in temporary clones. Evidence: `evidence/research/repro/codex-clean-repro-2026-09-28.md` and `codex-clean-repro-tip-2026-09-28.md`. Status: PASS locally; clean external CI and new-tip long-profile rerun remain optional reproducibility improvements, not substitutes for semantics.

## 5. Prediction math

Complete-set conservation and bounded INVALID aggregate floor evidence remain. `CX-PRED-INVALID-HOLDER-001` falsifies a holder-independent half-value promise despite aggregate conservation: identical contributors receive 0/20 instead of 10/10 by valid redemption ordering. `CX-PRED-WINNER-OVERFLOW-001` leaves a fully backed `2^255` winning market unable to open redemption. Evidence in `evidence/research/prediction/` and ADR-P05/P19. Status: FAIL for full financial qualification; `PRED-MATH-1` remains partial.

## 6. Prediction semantic decisions

`PREDICTION_SEMANTIC_CONVERGENCE_PACKET.md` maps P03/P05/P06/P08/P09/P10/P11/P12/P13/P14/P15/P16/P17/P18/P19 to Python, Solidity, docs, witnesses, recommended rules, change scope, and compatibility. P05 recommendation is REVISE; P19 is new and PROPOSED. No ADR was silently accepted. Status: FAIL for canonical freeze.

## 7. Prediction differential status

Existing `PredictionDifferentialTest` has 14 matching fixture tests in its declared domain, and the long INVALID aggregate composition walk matched. The new winner boundary is a direct Python↔Solidity mismatch; draft archive, token admission, configured maximum, spec timing, and transfer operation remain divergent or deliberately reduced. Rejected-call state preservation is not complete across all operations. Status: FAIL against the required zero unexplained financial mismatch target.

## 8. Prediction invariants

Historical multi-seed issuance/conservation campaigns and current default suite pass their configured handlers. The new dual-role callback witness commits result before an in-flight split mints outcomes, falsifying the broader lifecycle property for an unqualified token/resolver configuration. INVALID holder allocation is outside aggregate invariants; winner `2^255` liveness is outside ordinary fuzz bounds. Evidence: `evidence/research/prediction/callback-resolver-lifecycle-2026-09-28.json` and the two other new artifacts. Status: FAIL for mandatory full-domain, admitted-asset, transfer-aware stateful campaign.

## 9. Prediction security

Slither's `_redeem`/mint/burn IR remains incomplete in a clean clone; isolated `OutcomeToken` exits zero but also lacks inheritance resolution. Aderyn crashes ingesting compiled content; remote Semgrep Solidity ruleset returns 404. Existing source/IR inspection is not an analyzer close. The callback negative control is a concrete lifecycle-order finding; rebasing collateral is a physical-solvency finding under an excluded class. Evidence: `evidence/research/security/toolchain-2026-09-28.md`, `COLLATERAL_ADMISSION_PACKET.md`, `docs/prediction/10_SECURITY.md`. Status: FAIL / BLOCKED_TOOL for complete static analysis; no audit claim.

## 10. PRISM exact replication

Exact nonnegative `h=Gx` and the marginal-only `AND(A,B)` non-replication control remain. The rational minimum-cost solver is bounded to declared shapes and rechecks equality; arbitrary onchain solving is not proposed. Compiler schema, independent certificate recheck, authority, and onchain admission are not frozen. Evidence: `research/prism-model/minimum_cost_replication.py`, `PRISM_ADMISSION_SOURCE_INTERFACE_PACKET.md`. Status: CONDITIONAL math, BLOCKED admission.

## 11. PRISM backing

Component requirement `B_i >= Req_i(S)` and back-first mint have formal/bounded and differential support. Duplicate/zero components, decimal limits, transferability, external donation, and non-depositor mint need accepted semantics. Existing A-deposits/B-mints/B-redeems path stays solvent but can transfer A's prefunding to B; physical balance loss after rebasing breaks accounted backing. Evidence: `PRISM_BACKING_RESERVATION_PACKET.md`, ADR-R08/R10/R14. Status: FAIL for frozen ownership/asset semantics.

## 12. PRISM fixed-point accounting

Ceil mint requirement and requirement-delta in-kind redemption are `PROVEN_UNDER_ASSUMPTIONS` for the declared nonnegative integer/decimal model; 6/8/18 and selected boundaries are tested. Overflow exclusions and 0..18 cross-source policy remain explicit. These results do not prove final settlement fairness or transfer ownership. Evidence: `docs/prism/math/17_THEOREMS.md`, `research/reports/MATRICES.md`. Status: CONDITIONAL within domain.

## 13. PRISM settlement

Canonical independent per-call floor still has `CX-FP-SETTLEMENT-001` and `MATH-1D=FAIL`. The global cumulative candidate telescopes aggregate payout and has Python↔Solidity/stateful evidence, but `CX-FP-CUM-HOLDER-001` shows order-dependent holder loss growing with fragmentation. ADR-R03 acceptance packet recommends REVISE and remains PROPOSED. Exact-ceil residual is mathematically 0 or 1 under its assumptions; ownership of residual versus donations is undecided (`SETTLEMENT_RESIDUAL_DECISION_PACKET.md`). Status: FAIL; no candidate acceptance or sweep implementation.

## 14. PRISM reservation

`CandidateReservationLedger.deposit` credits a mapping without receiving ERC-20s. `sum reserved <= ledger.balance` is a logical invariant, **not** `sum reserved <= PhysicalBalance`. Production caller authorization, beneficiary attribution, release, withdraw, donation, and loss behavior are specified as proposals in `PRISM_BACKING_RESERVATION_PACKET.md`; no physical custody harness implements them. Status: FAIL for production lifecycle equivalence.

## 15. PRISM partial resolution

`T-PARTIAL-001/002` and reduced payoff-transform Python/Solidity fixtures support equivalence only over still-possible states. The named research profile reran the existing partial fixtures. No real Prediction source redemption/resolution identity is wired into that transform. Evidence: `docs/prism/math/17_THEOREMS.md`, `research/contract-kernels/src/prism/CandidatePayoffTransform.sol`. Status: CONDITIONAL model, BLOCKED cross-module revalidation.

## 16. Source asset interface

`docs/prism/04-architecture/SOURCE_ASSET_INTERFACE.md` remains PROPOSED_NOT_FROZEN. The admission packet proposes ERC-20 custody plus versioned registry metadata bound to payoff, market/outcome, settlement asset, decimals, result semantics, and resolution identity. Prediction INVALID holder allocation and winner liveness prevent freezing its economic payoff version now. Status: BLOCKED.

## 17. Cross-module X-I01..X-I07

`PRISM_ADMISSION_SOURCE_INTERFACE_PACKET.md` specifies one executable witness per property (qualified source, distinct liabilities, unique custody, value-preserving source resolution, identity/partial transform, funded final redemption, external-service independence). No combined Prediction→PRISM harness exists. Unit tests of separate kernels are not substitutes. Status: BLOCKED / NOT_YET_VALIDATED for all seven.

## 18. Kuru boundary

No solvency proof uses Kuru orderbook depth, price, indexer state, or a market-maker promise as backing. Secondary venue compatibility and live liquidity quality are separate from primary solvency. `PRED-KURU-1` remains blocked without a live venue qualification, but it does not excuse unresolved financial invariants. Evidence: `docs/prism/04-architecture/SOURCE_ASSET_INTERFACE.md`, `qualification-gates.yaml`. Status: CONDITIONAL boundary stated; live-liquidity gate BLOCKED.

## 19. Benchmarks

The named research profile generated five local timing samples per reference shape at `bbbfaa2`; they are not production latency percentiles. Focused regression gas is in new JSON artifacts; the long INVALID composition test took 115.10 seconds at a special gas-limit profile. No post-semantic-freeze comparison of compact versus split series architecture exists. Status: CONDITIONAL research measurement, BLOCKED production comparison.

## 20. Reproducibility

The default profile is bounded; the named research profile is expensive. Both keep generated evidence in disposable clones. The existing `.cursor/install.sh` remains the repository bootstrap; no duplicate Codex bootstrap was added. Formal extras are pinned narrowly. The default profile was rerun at the latest tested Codex tip. Status: PASS locally, not a clean-room external CI guarantee.

## 21. Open counterexamples

Permanent negatives: `CX-FP-SETTLEMENT-001` (canonical PRISM per-call aggregate underpayment), `CX-FP-CUM-HOLDER-001` (candidate holder allocation), `CX-PRED-INVALID-HOLDER-001` (Prediction INVALID holder allocation), `CX-PRED-WINNER-OVERFLOW-001` (winner liveness), `CX-PRED-CALLBACK-RESOLVER-001` (unqualified token/resolver lifecycle), and recorded rebasing collateral/component physical-balance losses. Do not delete these to make CI green. Status: FAIL for promotion while any relevant invariant remains falsified.

## 22. Open ADR decisions

All ADR-P and ADR-R proposals remain PROPOSED. Immediate human choices: ADR-R03 holder entitlement; ADR-P05 INVALID holder entitlement; ADR-P19 winner arithmetic/domain; ADR-P06/P08/P09 asset admission; ownership of prefunded PRISM components; exact replication/certificate authority; source identity and residual/donation ownership. Decision packets are `ADR_R03_ACCEPTANCE_PACKET.md`, `SETTLEMENT_RESIDUAL_DECISION_PACKET.md`, `PREDICTION_SEMANTIC_CONVERGENCE_PACKET.md`, `COLLATERAL_ADMISSION_PACKET.md`, `PRISM_BACKING_RESERVATION_PACKET.md`, and `PRISM_ADMISSION_SOURCE_INTERFACE_PACKET.md`. Status: BLOCKED on human semantic acceptance, with independent research still possible.

## 23. Security findings

Confirmed under their declared configurations: extreme but reachable fully funded winner-redemption lock; order-dependent raw-unit allocation under INVALID and PRISM cumulative candidate; lifecycle mutation by unqualified callback resolver token; physical backing shortfall after externally decreasing token balances. Aggregate solvency is **not** disproven by the holder-ordering or one-unit callback witnesses; keep failure classes separate. Static analysis remains incomplete. Status: FAIL / BLOCKED_TOOL; severity and exploitability require asset/fee/gas assumptions and review.

## 24. Contract architecture recommendation

Provisionally favor one series controller with one liability ERC-20 and one authoritative backing/cursor state over a heavily split vault/mint/settlement stack, because every independent writable balance increases synchronization proof burden. This is an **inference**, not CONTRACT-ARCH-1 acceptance. A production choice requires a measured comparison of custody/permission boundaries, state count, external calls, gas, reentrancy, failure atomicity, and Monad execution after source, reservation, mint ownership, and holder settlement semantics are frozen. No production PRISM contract was written. Status: BLOCKED.

## 25. Promotion verdict

`RESEARCH_HANDOFF_READY = false`; `READY_FOR_V2_INTEGRATION = false`; `MODULE-ADMISSION-FINANCE-1 = NOT MET`; `MATH-1 = FAIL`; `PRED-CONTRACT-1 = NOT PASS`; `CONTRACT-1 = NOT MET`; X-I01..X-I07 NOT_YET_VALIDATED. Passing tests, formal subproofs, or Kuru venue compatibility cannot override these blockers. The stage remains RESEARCH, not contract architecture accepted, audit complete, testnet qualified, or deployment ready.

## 26. Next owner

Human protocol authority should decide the two holder-entitlement promises, winner uint256 formula/domain, and collateral/prefunding ownership rules first. Research owner then updates the canonical Python oracles and research kernels **together**, completes exact post-state/reject differential fixtures and stateful invariant campaigns, builds physically backed reservation and exact-admission/source harnesses, reruns X-I01..X-I07 and partial transform, obtains complete security analysis, and benchmarks a concrete architecture. Only after those gates pass should a separate production Solidity implementation phase be requested.
