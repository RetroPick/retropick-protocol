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

## Work packages

### A. Exact model
- payoff/replication;
- backing/mint/redeem;
- lifecycle;
- final settlement.

### B. Market math
- complete-set split/merge;
- open interest;
- executable bid/ask parity;
- PRISM create/redeem values;
- partial-resolution NAV;
- post-resolution ERC20/ERC20 quote identity.

### C. Verification
- bounded exhaustive state exploration;
- adversarial/property sequences;
- formal assistance where useful;
- fixed-point/rounding policy;
- Solidity-compatible fixtures.

### D. Final classification

Each claim must be classified as one of:

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
