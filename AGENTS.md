# AGENTS.md

This file is the mandatory repository entry point for coding, research, validation, product and integration agents.

## Mission

Build RetroPick's Monad prediction-asset protocol and PRISM structured-asset layer without allowing implementation convenience, sponsor integration, or UI shortcuts to override solvency, resolution, backing, or settlement semantics.

---

## Read before work

1. `.agent/CURRENT_GOAL.md`
2. `.agent/STATE.json`
3. `.agent/DECISIONS.md`
4. `docs/00-context/EXECUTIVE_SUMMARY.md`
5. `docs/00-context/PROJECT.md`
6. `docs/00-context/REPORT_RECONCILIATION.md`
7. `docs/05-hackathon/PHASE_GATES.md`
8. `docs/protocol/PRISM_PROTOCOL_SPEC.md`
9. `docs/protocol/INVARIANTS.md`
10. `docs/protocol/STATE_MACHINE.md`
11. `docs/05-hackathon/RETROPICK_METROPOLIS_AGENT_DEVELOPMENT_WORKFLOW.md`

For mathematical/protocol work also read, in this order:
- `docs/math/README.md`
- `docs/math/01_DEFINITIONS.md`
- `docs/math/02_ASSUMPTIONS.md`
- `docs/math/05_BACKING_SOLVENCY.md`
- `docs/math/16_INVARIANTS.md`
- `docs/math/17_THEOREMS.md`
- `docs/protocol/MATH_MODEL.md`
- `docs/protocol/FAILURE_MODES.md`
- `docs/protocol/PRECISION_MODEL.md`
- `docs/protocol/CONTRACT_REQUIREMENTS.md`
- `research/prism-model/README.md`

For implementation architecture also read:
- `docs/04-architecture/SYSTEM_ARCHITECTURE.md`
- `docs/04-architecture/SMART_CONTRACTS.md`

---

## Source-of-truth precedence

When documents conflict, use this precedence:

1. accepted ADRs under `decisions/`;
2. canonical protocol semantics under `docs/protocol/`;
3. canonical mathematical proof/claim classification under `docs/math/`, provided it does not redefine protocol semantics;
4. `docs/05-hackathon/PHASE_GATES.md` for execution authorization;
5. `.agent/CURRENT_GOAL.md` and `.agent/DECISIONS.md`;
6. architecture docs under `docs/04-architecture/`;
7. canonical hackathon workflow;
8. `docs/00-context/EXECUTIVE_SUMMARY.md` as the human-facing synthesis;
9. product/research notes;
10. historical reports;
11. implementation.

The Executive Summary is a synthesis, not a replacement for accepted ADRs or detailed canonical protocol specifications.

`docs/math/` proves/classifies the accepted semantics. It may not silently redefine them. If a proof requires changing economics, stop and use the ADR/spec process.

Historical or generated research is evidence/input, not authority over accepted protocol semantics.

Code must conform to the specification. Code does not silently redefine the specification.

---

## Phase-gate rule

Production Solidity is **not authorized** until MATH-1 closes and CONTRACT-ARCH-1 derives implementation responsibilities from the accepted model.

Current dependency order:

```text
SPEC-1
-> MATH-1
-> CONTRACT-ARCH-1
-> CONTRACT-1
-> INTEGRATION-1 / PRODUCT-1
-> E2E-1
-> SUBMISSION-1
```

Parallel integration prototypes may use mocks but may not define or weaken financial semantics.

---

## Scientific rule

Classify substantive claims as one of:

- `PROVEN_UNDER_ASSUMPTIONS`
- `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN`
- `SUPPORTED_BY_SIMULATION`
- `SUPPORTED_BY_LIVE_EVIDENCE`
- `NOT_YET_VALIDATED`
- `COUNTEREXAMPLE_FOUND`

The canonical claim registry for MATH-1 is `docs/math/17_THEOREMS.md`.

Never convert simulated or expected market behavior into a formal proof.

Every safety-critical invariant must be traceable through:

```text
protocol invariant
-> math theorem/assumptions
-> Python oracle assertion/check
-> future Solidity owner
-> future Foundry/differential evidence
```

Known missing oracle coverage must remain explicit in `docs/math/16_INVARIANTS.md`.

---

## Locked protocol constraints

### Native RetroPick

- A binary market is a fully collateralized complete-set system.
- Conceptually `1 collateral -> 1 YES + 1 NO` and inverse merge.
- Native market creation does not invoke PRISM spanning.
- Resolution semantics are immutable/pinned before activation.
- Complete-set OI is not `YES_supply + NO_supply`; in the simple canonical model it equals the collateralized complete-set quantity.

### PRISM Phase 1 / v2

- Hackathon PRISM series are non-negative exact-backed replicated baskets.
- One PRISM share has immutable replication vector `x`.
- Exact payoff is `h = Gx`.
- Feasible long-only payoff cone is `{Gx | x >= 0}`.
- Arbitrary AND/OR/custom nonlinear payoffs are not assumed replicable.
- Basket mode may supply `x` directly; payoff mode must solve exact `Gx=h, x>=0` or reject.
- Active backing must satisfy `B_i >= S*x_i`.
- Mint is backing-first, mint-second.
- Runtime mint checks component backing; they do not enumerate every terminal world.
- Same-chain Monad backing is authoritative in the PRISM vault/accounting. No Phase-1 BackingMirror.
- In-kind redemption burns/decreases liability first and releases proportional backing.
- The same token type may back many series; the same reserved balance units may not be double pledged.
- `RESOLVED` means final payout is known.
- `REDEEMABLE` additionally requires `SettlementBalance >= Supply*FinalPayout`.
- A resolved ERC-20 may remain transferable; its event uncertainty is gone, but relative price against another ERC-20 may continue moving.
- Retail PRISM BUY is a Kuru secondary trade when liquidity exists.
- Primary PRISM CREATE is a separate issuer/AP/market-maker/arbitrage path.

### Accounting domains

Never silently merge:

```text
protocol backing
LP inventory
market-maker inventory
protocol fees
settlement funds
```

---

## Explicit Phase-1 exclusions

Do not introduce without a new accepted ADR:
- Polymarket/Polygon custody as a hackathon dependency;
- custom bridge;
- cross-chain wrapped outcomes;
- BackingMirror for same-chain balances;
- statewise solvency loops inside every mint;
- approximate replication;
- generic StatePool/SLE;
- arbitrary payoff bytecode;
- protocol price oracle used to decide backing sufficiency.

---

## Evidence rule

No goal is complete without:
- exact command or action;
- commit/ref;
- result;
- relevant fixture/output;
- updated gate/status;
- documented assumptions;
- residual risks/counterexamples.

For sponsor claims, screenshots alone are insufficient when tx IDs, market IDs, logs, queries or contract state can provide stronger evidence.

For theorem/exhaustive claims, evidence must also include the assumption set and, for bounded verification, the exact finite bounds explored.

---

## Handoff rule

Every specialist handoff must identify:
- goal ID;
- current gate;
- input specification;
- output files;
- invariants/ADRs that may not change;
- assumptions;
- open questions;
- evidence required;
- whether the work is formal, exhaustive, simulated, or live.

If a task requires violating a canonical invariant, stop and request an ADR rather than implementing around it.
