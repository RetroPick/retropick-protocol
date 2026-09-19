# Milestones and Gates

Milestones are evidence-backed state transitions, not dates.

## M0 — Governance baseline

Evidence:
- repository scaffold;
- agent routing;
- canonical docs hierarchy;
- historical-report reconciliation.

Gate: `BASELINE-1`.

## M1 — SPEC-1

Required:
- canonical native-market boundary;
- canonical PRISM Phase-1 spec;
- one lifecycle;
- one pFEDBTC payoff table;
- explicit non-goals;
- architecture conflicts classified ACCEPT/MODIFY/DEFER/REJECT.

Pass condition:
no known semantic contradiction remains in canonical docs.

## M2 — MATH-1A exact kernel

Required:
- `h=Gx` exact evaluation;
- exact non-negative replication admission for small systems;
- component-backing model;
- mint and in-kind redemption;
- terminal solvency checks;
- settlement model.

## M3 — MATH-1B market identities

Required:
- complete-set split/merge conservation;
- corrected open-interest definition;
- executable bid/ask parity;
- PRISM creation/redeem values;
- partial-resolution NAV;
- post-resolution ERC20/ERC20 relative value.

These are classified separately from formal solvency theorems.

## M4 — MATH-1C adversarial/exhaustive

Required:
- illegal lifecycle paths rejected;
- over-mint rejected;
- over-redemption rejected;
- non-replicable AND fixture rejected;
- underfunded settlement rejected;
- duplicate resolution rejected;
- no double-use accounting path in modeled domain.

## M5 — MATH-1D precision

Required:
- fixed-point scale selected;
- round directions specified;
- dust accounting specified;
- maximum rounding leakage bounded;
- repeated-operation extraction tests.

## M6 — MATH-1 verdict

Output exactly one:

```text
MATH-1 = PASS
MATH-1 = CONDITIONAL_PASS
MATH-1 = FAIL
```

Any solvency/accounting kill criterion forces `FAIL`.

## M7 — CONTRACT-ARCH-1

Required:
- storage map;
- contract/interface map;
- authorization map;
- event schemas;
- precision implementation plan;
- invariant-to-Foundry mapping;
- no Phase-1 BackingMirror.

## M8 — CONTRACT-1

Required:
- Solidity kernel implemented;
- unit tests pass;
- fuzz tests pass;
- stateful invariants pass;
- differential fixtures pass;
- deployment smoke test passes.

## M9 — INTEGRATION-1

Required:
- Kuru markets and trades;
- Envio indexed state;
- CRE resolution path;
- RPC/WebSocket transport;
- evidence capture.

## M10 — PRODUCT-1

Required:
- retail market browse/trade/redeem;
- PRISM trade UX separated from PRISM create UX;
- account/funding integrations as accepted;
- no manual contract calls in golden path.

## M11 — MARKET-1

Required before strong economic claims:
- simulation/live evidence report;
- premium/discount metrics;
- resolution-jump analysis;
- arbitrage convergence conditions;
- liquidity/MM assumptions explicitly bounded.

## M12 — SUBMISSION-1

Required:
- deployed demo;
- tx hashes;
- market IDs;
- tests;
- evidence pack;
- demo script;
- limitations stated accurately.
