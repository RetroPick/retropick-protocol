# Metropolis Phase Gates

**Status:** CANONICAL EXECUTION CONTROL  
**Purpose:** prevent parallel hackathon work from bypassing protocol correctness.

This document overrides any historical interpretation of W0-W12 as twelve sequential calendar weeks.

The Metropolis build runs as a dependency DAG with hard financial gates.

---

## Gate hierarchy

```text
BASELINE-1
   |
   v
SPEC-1
   |
   v
MATH-1
   |
   v
CONTRACT-ARCH-1
   |
   v
CONTRACT-1
   |
   +--------------------+
   |                    |
   v                    v
INTEGRATION-1       PRODUCT-1
   |                    |
   +---------+----------+
             v
          E2E-1
             |
             v
       SUBMISSION-1
```

Market-economics validation runs alongside later phases but never substitutes for accounting gates.

---

## BASELINE-1

Pass when:
- repository governance exists;
- source-of-truth hierarchy exists;
- evidence directories exist;
- historical report is reconciled;
- no agent is using an obsolete architecture as canonical.

---

## SPEC-1

Pass when canonical docs agree on:
- native RetroPick market architecture;
- PRISM exact-backed scope;
- basket vs payoff admission modes;
- one lifecycle;
- one pFEDBTC payoff table;
- runtime backing invariant;
- final settlement funding gate;
- Phase-1 exclusions.

Blockers:
- unresolved economic contradictions;
- ambiguous payout semantics;
- ambiguous collateral authority.

---

## MATH-1

Purpose:
prove/falsify the economic accounting kernel before Solidity.

Mandatory sub-gates:

```text
MATH-1A exact arithmetic
MATH-1B finite/exhaustive checks
MATH-1C adversarial/property testing
MATH-1D fixed-point/rounding
MATH-1E theorem/formal assistance where useful
MATH-1F market simulation classification
```

`MATH-1F` cannot repair failure in `MATH-1A-D`.

Possible verdicts:

```text
PASS
CONDITIONAL_PASS
FAIL
```

Protocol solvency/accounting failure => `FAIL`.

Market-behavior uncertainty with sound accounting may => `CONDITIONAL_PASS` for market claims while contract work proceeds only if accounting gates pass.

---

## CONTRACT-ARCH-1

Pass when every critical contract responsibility traces to canonical math/spec requirements.

Required:
- storage map;
- interface map;
- role/authorization map;
- lifecycle function matrix;
- event schemas;
- precision implementation;
- invariant-to-test mapping.

Phase-1 architecture MUST NOT reintroduce:
- BackingMirror for Monad-native assets;
- custom bridge;
- state enumeration in mint;
- arbitrary nonlinear payoff engine.

---

## CONTRACT-1

Pass when Solidity kernel demonstrates:
- complete-set conservation;
- outcome resolution/redemption;
- exact PRISM backing;
- back-first mint;
- in-kind redeem;
- lifecycle safety;
- settlement funding safety;
- fixed-point safety;
- unit/fuzz/stateful/differential tests.

A UI demo cannot waive failing invariant tests.

---

## INTEGRATION-1

Integrations may develop in parallel against mocks after interfaces stabilize, but production evidence waits for real contracts.

Pass when claimed sponsor integration has concrete evidence.

Examples:
- Kuru market IDs + trades;
- Envio queries/indexing logs;
- CRE workflow logs/tx;
- account/funding integration tx/log evidence.

No sponsor integration may become the authoritative same-chain backing ledger.

---

## PRODUCT-1

Pass when a normal user can:
- browse;
- trade YES/NO;
- trade PRISM;
- understand resolution state;
- redeem;
without manually executing protocol internals.

Normal retail PRISM purchase uses exchange liquidity where available.

Primary PRISM CREATE remains an advanced issuer/AP path.

---

## E2E-1

Golden path must prove the entire economic lifecycle:

```text
collateral
-> YES/NO issuance
-> Kuru trade
-> PRISM exact backing
-> PRISM mint
-> PRISM trade
-> resolution
-> settlement funding
-> redemption
```

Evidence must reconcile balances and supply, not just screenshots.

---

## SUBMISSION-1

Pass when:
- live/deployed demo works;
- all claimed integrations have evidence;
- architecture docs match code;
- test output is captured;
- limitations are explicit;
- no rejected/deferred architecture is described as implemented.

---

## Parallel work policy

Allowed before MATH-1:
- UI prototypes against typed mocks;
- sponsor SDK capability verification;
- Envio schema drafts;
- Kuru deployment scripts against dummy ERC-20s;
- CRE workflow prototype against mock resolution contract.

Not allowed before MATH-1:
- treating provisional Solidity as canonical economics;
- freezing storage around unproven math;
- writing production mint/settlement logic from historical report pseudocode.

---

## Stop conditions

Stop the affected phase and escalate when:
- a kill criterion is reached;
- docs and reference model disagree;
- a sponsor capability used in architecture is not verified;
- a requested feature requires changing a canonical invariant;
- a shortcut would convert an empirical assumption into a protocol dependency.
