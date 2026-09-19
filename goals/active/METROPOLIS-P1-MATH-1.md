# METROPOLIS-P1-MATH-1

**Status:** ACTIVE  
**Phase:** P2 MATH-1  
**Primary gate:** `MATH-1`

The detailed live goal is mirrored in `.agent/CURRENT_GOAL.md`.

## Objective

Verify the RetroPick/PRISM accounting kernel, integer transfer semantics and adversarial boundaries before production Solidity.

Canonical equations:

```math
h=Gx
```

```math
B_i\ge Sx_i
```

```math
\sum_s Reserved_{s,a}\le PhysicalBalance_a
```

```math
SettlementBalance\ge Supply\times FinalPayout
```

## Newly resolved executable gaps

Implemented:

```text
research/prism-model/reservation_ledger.py
research/prism-model/native_market.py
research/prism-model/fixed_point_model.py
research/prism-model/adversarial.py
research/prism-model/model.py  # stateful partial-resolution extension
research/prism-model/tests/test_executable_gaps.py
```

This closes the previous reference-model gaps for:
- cross-series backing reservation uniqueness;
- stateful native complete-set split/merge/resolve/redeem;
- stateful payoff-equivalent partial backing transformation;
- mixed redemption after partial resolution;
- deterministic 0..18-decimal normalization;
- conservative integer backing requirements;
- integer redemption preservation;
- integer binary terminal-solvency checks;
- conservative final-settlement funding/redemption;
- deterministic randomized fixed-point/reservation stress.

Proof/theorem status is maintained in:

```text
docs/prism/math/05_BACKING_SOLVENCY.md
docs/prism/math/16_INVARIANTS.md
docs/prism/math/17_THEOREMS.md
```

## Validation evidence

See:

```text
evidence/latest/MATH1_EXECUTABLE_GAPS_VALIDATION_2026-09-17.md
```

Recorded implementation-tranche result:

```text
51 regression/gap tests -> OK
5000 deterministic fixed-point stress steps
20000 terminal-state checks
5000 deterministic reservation stress steps
no accounting counterexample in declared run
```

This is executable evidence, not future Solidity proof.

## Remaining work packages

### A. Bounded/exhaustive completion
- lifecycle reachability enumeration;
- independent per-component surplus grid;
- minimal-counterexample serialization.

### B. Adversarial boundary completion
- broader action-ordering fuzzer;
- zero/extreme-weight matrix;
- configured maximum-value/overflow boundaries.

### C. Solidity-equivalence fixtures
- explicit 6/8/18-decimal matrix;
- machine-readable Python fixtures;
- uint256-safe configured maxima;
- full-precision mulDiv semantics;
- zero-supply final settlement-dust disposition.

### D. Formal assistance
- Z3/SymPy only where it adds assurance beyond trivial algebra;
- machine-readable theorem-status output.

### E. Empirical market model
- arbitrage convergence;
- stale-order/resolution-jump risk;
- market-maker inventory/PnL;
- liquidity-capital sensitivity;
- post-resolution quote-token volatility.

Market-model results remain separate from accounting safety.

## Completion verdict

Close only with:

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

Production Solidity remains blocked until that verdict and `CONTRACT-ARCH-1`.

## Out of scope

- production cross-chain wrappers;
- Polymarket custody;
- arbitrary StatePool/SLE;
- approximate replication;
- claims that liquidity/demand are mathematically proven.
