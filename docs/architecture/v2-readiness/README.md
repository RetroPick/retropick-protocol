# V2 architecture and implementation-readiness map

Assessment basis: `797becbed94005aaa16a7279020688aafa631744` (2026-09-29). This is a **track map**, not one deployable runtime. Accepted ADRs and canonical module specs control over this analysis. Diagrams distinguish current source from target behavior; proposed components are not implemented merely because they appear in a diagram.

| Priority / track | Current source or research state | Architecture status | Development decision |
| --- | --- | --- | --- |
| 1. Launchpad Core V2 | V2 source is behaviorally V1-equivalent and graduates to Uniswap V4, not Kuru | Target Kuru design documented; `DEVELOPMENT_READY: in_progress` | Primary production-development track; implement only against accepted policy and qualification tests |
| 2. Prediction V2 | Research kernels and model; financial semantic counterexamples remain | Research-gated / non-production | No production financial contract promotion |
| 3. PRISM V2 | Research kernels and model; `MATH-1: FAIL` | Research-gated / non-production | No production financial contract promotion |

Sources: [Core status](../../../development/launchpad/control/status.yaml), [current V2 source map](../contracts/V2_ARCHITECTURE.md), and [financial research gate](../../../research/reports/SMART_CONTRACT_RESEARCH_GATE.md). The repository's [machine-readable financial gates](../../../research/reports/qualification-gates.yaml) remain authoritative for Prediction/PRISM; this document does not change them.

## 1. Launchpad Core V2 — primary production-development track

[Architecture diagram](launchpad-core-target.architecture.html) ([source](launchpad-core-target.architecture.json)) and [graduation flow](launchpad-core-graduation.lifecycle.html) ([source](launchpad-core-graduation.lifecycle.json)) show the intended boundary. `CURRENT` tags refer to existing code in `contracts/src/v2/`, not a claim that it is deployed; `TARGET` means design intent, not runtime evidence. The separate [source-derived V2 diagrams](../contracts/V2_ARCHITECTURE.md) remain the account of implemented code.

**Authorities and custody.** Factory owns launch configuration and record identity; Deployer creates the token and curve; Curve owns primary price arithmetic, reserves and trade accounting. Fee/buyback balances must remain distinct from tradable reserves. The target graduation controller secures remaining token and quote assets before any external venue call. Kuru is a destination for mature secondary trading, not a reserve ledger, oracle, or financial backing source. The current V2 code still routes graduation through Uniswap V4; the Kuru controller/executor and secured-asset state are proposed. See [target architecture](../../../development/launchpad/contracts/TARGET_V2_ARCHITECTURE.md), [graduation design](../../../development/launchpad/contracts/GRADUATION_TO_KURU.md), and [current state audit](../../../development/launchpad/contracts/CURRENT_STATE_AUDIT.md).

**Operational flows and required checks.**

| Flow | Target sequence | Critical acceptance condition |
| --- | --- | --- |
| Create | Wallet → Factory configuration/record → Deployer → Token + Curve | Immutable identities and initial token/custody balances agree with the launch record; unauthorized configuration or duplicate initialization reverts without side effects. |
| Buy/sell | Wallet → Curve quote → balance/reserve update → fee allocation | Exact integer quote/reserve accounting, slippage/deadline checks, fee separation, and atomic failure on token transfer errors; no trade after secure graduation begins. |
| Fee/buyback | Curve accrual → authorized fee path → vault/recipient | Fees cannot be spent twice or counted as trade reserves; external call failure preserves accounting. Current escrow interface is ABI-only and must be resolved before claiming complete fee flow. |
| Graduation | Threshold → freeze curve → secure assets → `GRADUATING` → Kuru market creation/configuration → verify market ID/address → `GRADUATED` | Same-quote default; secured balances remain accounted; `GRADUATED` occurs only after verified usable destination. |
| Failed destination | Kuru revert/invalid market → keep secured assets → retry authorized destination step | No renewed ordinary trading, lost assets, duplicate destination, or false `GRADUATED` state. Recovery/rescue needs an explicit rule. |

The target lifecycle is `DRAFT → ACTIVE → GRADUATION_READY → GRADUATING → GRADUATED → ARCHIVED`; it is **not** the currently implemented V4 `NotGraduated → Swept → PoolCreated` lifecycle. [Canonical target state machine](../../../docs/launchpad/STATE_MACHINE.md) and [current V2 source account](../contracts/V2_ARCHITECTURE.md) must be read together. No V4 dependency should be retired until the Kuru path is proven and the retirement decision accepted.

**Implementation readiness, in dependency order.**

1. Freeze the concrete Kuru target: verify current official ABI, Monad addresses, market-parameter policy, same-quote asset path, market identity verification, and failure/retry behavior. Existing Kuru source pins are historical inputs, not live deployment verification. Resolve relevant proposed Kuru/V4-retirement ADRs before committing an irreversible runtime choice.
2. Add a committed Factory/Token/Curve/Fee/Graduation qualification suite against *current* behavior and then the accepted target: exact reserve/fee invariants, authorization, token transfer failures, threshold edges, duplicate calls, and stateful multi-actor sequences. Doorway-only tests do not qualify Core.
3. Implement the smallest accepted graduation transition that makes asset security atomic and external completion retryable. Instrument explicit custody, emitted events, guarded state changes and destination verification; test every revert and re-entry path.
4. Integrate the concrete Kuru executor against verified target deployment and accepted market settings. Retain V4 recovery/retirement capability until migration and regression evidence supports removal.
5. Complete web/API/indexer and admin flows only after onchain authority is stable. Wallet→chain remains the economic write path; backend/indexer views cannot set financial truth. Run deployment simulation, gas/security qualification, and acceptance reviews before claiming staging/mainnet readiness.

Core blockers are [recorded in status.yaml](../../../development/launchpad/control/status.yaml): `BLOCK-CONTRACT-TESTS`, `BLOCK-KURU-TARGET`, `BLOCK-ARCH-ADRS`, and `BLOCK-FULLSTACK`. Therefore **architecture is sufficiently mapped to drive scoped development, but Core is not implementation-complete or deployment-ready**. This map does not accept an ADR or clear a blocker.

## 2. Prediction V2 — research-gated architecture

Candidate boundary: collateral-holding market and YES/NO outcome ERC-20 liabilities; a resolver commits one deterministic result, and holders redeem by the accepted payout rule. Neither a UI/indexer nor a Kuru orderbook is economic authority. The market/collateral ownership split, INVALID holder entitlement, winning-side uint256 liveness, token admission, callback behavior, lifecycle transitions, and Python↔Solidity equivalence are not frozen. The research report records concrete counterexamples and incomplete security analysis. [Prediction semantic packet](../../../research/reports/PREDICTION_SEMANTIC_CONVERGENCE_PACKET.md) and [collateral policy](../../../research/reports/COLLATERAL_ADMISSION_PACKET.md) are decision packets, not accepted production specs.

For a future source-asset integration, an outcome token address alone is insufficient: market/outcome identity, collateral and decimals, resolution specification, payoff version, and admission status must be bound. That interface is [PROPOSED_NOT_FROZEN](../../../docs/prism/04-architecture/SOURCE_ASSET_INTERFACE.md). Prediction remains **research-gated / non-production** until its financial semantics, differential fixtures, stateful invariants and security gate close. Core may progress independently; it does not import Prediction runtime state.

## 3. PRISM V2 — research-gated architecture

Candidate path: offchain payoff compiler → spanning/exact-replication solver and independent equality recheck (`h = Gx`) → authorized admission certificate → actual component custody/reservation → back-first mint of one liability ERC-20 per series → payoff-equivalent partial transform where applicable → funded final settlement. Required solvency is physical controlled backing, including `B_i ≥ Req_i(S)` and no double reservation of one physical unit. Kuru secondary liquidity, prices, an indexer, resolver announcement, and a market-maker promise are **not backing**. See [candidate series](../../../docs/prism/04-architecture/PHASE1_CANDIDATE_SERIES.md) and [research gate](../../../research/reports/SMART_CONTRACT_RESEARCH_GATE.md).

The current independent per-call settlement floor underpays fragmented redemption (`CX-FP-SETTLEMENT-001`). Global cumulative settlement repairs aggregate telescoping but has a separate holder-ordering fairness counterexample (`CX-FP-CUM-HOLDER-001`); ADR-R03 remains proposed. Physical reservation lifecycle, exact admission authority, source identity, and X-I01..X-I07 cross-module checks are unresolved. Thus `MATH-1 = FAIL`, `CONTRACT-ARCH-1 = BLOCKED`, and PRISM is **research-gated / non-production**. The [ADR-R03 packet](../../../research/reports/ADR_R03_ACCEPTANCE_PACKET.md) cannot be treated as acceptance.

## Cross-track boundary and Graphify graph

The [Graphify dependency graph](graphify-out/graph.html) ([JSON](graphify-out/graph.json), [tool report](graphify-out/GRAPH_REPORT.md)) has **16 nodes, 14 edges, four communities**. It is manually curated from named repository sources and rendered/reclustered by Graphify; every edge is `INFERRED`. It is **not** a source-extracted Solidity call graph or proof of runtime coupling. The installed extractor did not qualify Solidity source extraction in the [earlier source-graph report](../contracts/graphify/v2/GRAPH_REPORT.md). This curated graph's useful dependency is Prediction outcome → proposed source interface → PRISM admission. That edge is conditional on financial qualification and does not imply an implemented integration. There is no Core→Prediction or Core→PRISM runtime edge; the platform may share UI/infrastructure without sharing solvency state. The graph's proposed Core→Kuru edge is a target destination, not current source behavior.

## Validation and handoff

Both Archify specifications passed showcase structural validation at 9/9 checks, zero errors/warnings; delivery produced interactive HTML. Browser visual checks were **skipped**, not passed, because Chrome was unavailable. Graphify clustered the curated graph and its multigraph diagnostic reported zero dangling endpoints, self-loops or duplicate edges. These are architecture-artifact checks only; they do not validate Core economic behavior or overturn financial gate status. See [validation record](../../../evidence/architecture/v2-readiness-2026-09-29.md).

**Next owner:** Launchpad Solidity/integration owners should close Core's test and Kuru-policy gates first, then implement against accepted decisions. Prediction/PRISM research owners should preserve their counterexamples and resolve semantic/financial gates independently. Do not move research kernels into production V2 contracts under this architecture map.
