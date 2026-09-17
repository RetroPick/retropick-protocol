# METROPOLIS-P1-MATH-1

**Status:** ACTIVE  
**Phase:** P1 SPEC -> P2 MATH-1  
**Primary gate:** `MATH-1`

The detailed live goal is mirrored in `.agent/CURRENT_GOAL.md`. This file is the durable goal record under `goals/active/`.

## Objective

Freeze and verify the exact-backed RetroPick/PRISM accounting model before production Solidity.

Canonical equations:

```math
h=Gx
```

```math
B_i \ge Sx_i
```

```math
SettlementBalance \ge Supply\times FinalPayout
```

## Locked architecture decisions

- Monad-native outcome ERC-20s are Phase-1 PRISM backing.
- No same-chain `BackingMirror`.
- No terminal-state enumeration inside mint.
- Basket mode is default PRISM MVP admission.
- Payoff mode must solve exact `Gx=h, x>=0` or reject.
- Native market creation and PRISM series creation are separate flows.
- Retail PRISM BUY and primary PRISM CREATE are separate flows.
- `RESOLVED` and `REDEEMABLE` are separate lifecycle states.
- Production Solidity starts only after MATH-1 verdict.

## Current artifact status

Implemented artifacts now include:

```text
research/prism-model/model.py
research/prism-model/replication.py
research/prism-model/settlement.py
research/prism-model/market_math.py
research/prism-model/bounded_verification.py
research/prism-model/fixed_point.py
```

and tests for the base model, market math, bounded verification and candidate fixed-point policy.

These artifacts are not a gate PASS by existence alone. Final closure requires a fresh full-suite run with captured evidence.

## Remaining work packages

### A. Adversarial model
- randomized action sequences;
- over-mint/over-redemption attempts;
- duplicate resolution;
- action reordering;
- invalid partial-resolution transformation;
- backing double-allocation abstraction;
- zero/extreme-weight cases.

### B. Exhaustive lifecycle verification
- enumerate reachable lifecycle paths;
- verify every forbidden transition;
- serialize minimal counterexamples on mutation failure.

### C. Fixed-point completion
- component decimal normalization;
- cumulative dust bound;
- dust ownership policy;
- Solidity-compatible fixtures;
- no-underback rounding proof.

### D. Formal assistance
- encode selected theorems in SymPy/Z3 where useful;
- maintain theorem-status registry;
- distinguish proof from bounded checks.

### E. Market model classification
- create/redeem arbitrage convergence;
- stale-order/resolution jump risk;
- MM inventory/PnL;
- liquidity-capital sensitivity;
- post-resolution quote-token volatility.

Every result must be classified as:

```text
PROVEN_UNDER_ASSUMPTIONS
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
SUPPORTED_BY_SIMULATION
SUPPORTED_BY_LIVE_EVIDENCE
NOT_YET_VALIDATED
COUNTEREXAMPLE_FOUND
```

## Completion verdict

Close this goal only with:

```text
MATH-1 = PASS
```

or:

```text
MATH-1 = CONDITIONAL_PASS
```

or:

```text
MATH-1 = FAIL
```

A core accounting/solvency kill criterion forces `FAIL`.

## Out of scope

- production cross-chain wrappers;
- Polymarket custody;
- arbitrary StatePool/SLE;
- approximate replication;
- production frontend;
- claims that liquidity/demand are mathematically proven.
