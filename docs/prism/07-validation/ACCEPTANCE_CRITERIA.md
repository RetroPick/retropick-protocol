# Acceptance Criteria

**Status:** CANONICAL VALIDATION GATES

This document defines when protocol, math, market, integration and product claims may be promoted.

---

## 1. SPEC-1 acceptance

Pass only when:
- native RetroPick and PRISM are separate layers;
- one canonical lifecycle is defined;
- `pFEDBTC` payoff examples are mathematically consistent;
- basket mode and payoff mode are distinct;
- retail BUY and primary CREATE are distinct;
- Phase-1 exclusions are explicit;
- no same-chain `BackingMirror` remains in canonical mint architecture;
- `RESOLVED` and `REDEEMABLE` are distinct.

---

## 2. MATH-1 hard safety criteria

MATH-1 cannot pass if any valid modeled sequence creates:
- unbacked claims;
- over-redemption;
- double-use backing;
- false exact-replication acceptance;
- terminal insolvency;
- illegal lifecycle resurrection;
- duplicate final resolution;
- underfunded `REDEEMABLE` state;
- repeatable positive-value rounding extraction above the accepted bound.

Canonical runtime backing:

```math
B_i\ge Sx_i
```

Canonical settlement funding:

```math
SettlementBalance\ge Supply\times FinalPayout
```

---

## 3. MATH-1 evidence classes

A final gate review must identify evidence for each claim as:

```text
PROVEN_UNDER_ASSUMPTIONS
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
SUPPORTED_BY_SIMULATION
SUPPORTED_BY_LIVE_EVIDENCE
NOT_YET_VALIDATED
COUNTEREXAMPLE_FOUND
```

No simulation result may be used to label an unsafe accounting property as proven.

---

## 4. Exact-model acceptance

Require:
- deterministic exact `h=Gx` evaluation;
- rejection of known non-replicable payoffs;
- valid mint preserves component backing;
- valid in-kind redemption preserves remaining backing;
- terminal solvency holds for all modeled terminal states;
- complete-set split/merge identities are exact;
- open-interest helper does not double-count complete sets;
- executable parity helpers use correct bid/ask sides;
- partial-resolution NAV is internally consistent;
- post-resolution pair-value identity handles nonzero quote prices.

---

## 5. Bounded/exhaustive acceptance

Require a declared finite domain and machine-readable counts for:
- mint cases;
- redeem cases;
- terminal worlds;
- settlement redemption;
- lifecycle reachability;
- legal/illegal transition attempts.

A bounded pass must be labeled `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN`, not universal proof.

---

## 6. Adversarial/property acceptance

The test generator must attempt at least:
- mint without enough backing;
- redeem above supply;
- backing withdrawal while liability remains;
- duplicate resolution;
- final redeem before funded;
- mint after cutoff/resolution;
- zero/extreme weights;
- action reordering;
- repeated dust extraction;
- invalid partial-resolution transformations.

Failures must persist a minimal counterexample or reproducible seed.

---

## 7. Precision acceptance

Before Solidity architecture is frozen:
- numeric scale is explicit;
- every multiplication/division round direction is explicit;
- required backing rounds conservatively;
- redemption cannot release more than safe entitlement;
- maximum per-operation and cumulative dust is bounded;
- dust ownership is specified;
- component token decimals are normalized;
- deterministic fixtures exist for Solidity differential tests.

---

## 8. CONTRACT-1 acceptance

After MATH-1 permits implementation, Solidity must pass:
- unit tests;
- fuzz tests;
- stateful invariant tests;
- differential tests against Python fixtures;
- reentrancy/security tests;
- authorization tests;
- fixed-point edge tests.

No UI or sponsor integration may waive a failing contract invariant.

---

## 9. Market-thesis acceptance

The following are empirical and require simulation/live evidence:
- PRISM price proximity to executable NAV;
- complete-set parity convergence;
- sufficient Kuru depth;
- reasonable slippage;
- sustainable maker inventory/PnL;
- manageable resolution-jump losses;
- actual user demand.

A safe protocol with weak liquidity may still pass accounting gates while receiving a `CONDITIONAL` market-thesis verdict.

---

## 10. Integration acceptance

An integration is complete only with concrete evidence appropriate to the claim, for example:
- Kuru market ID and executed trade;
- Envio indexed events/query output;
- CRE simulation/onchain resolution evidence;
- funding transaction evidence;
- account/wallet transaction evidence.

Mock-only demonstrations must be labeled mock/prototype.

---

## 11. Final MATH-1 verdict

Exactly one:

```text
MATH-1 = PASS
MATH-1 = CONDITIONAL_PASS
MATH-1 = FAIL
```

A core solvency/accounting kill criterion forces `FAIL`.

`CONDITIONAL_PASS` may describe unresolved empirical market assumptions only when the accounting kernel itself satisfies hard safety gates.
