# RetroPick PRISM Documentation

**Status:** CANONICAL PRISM ROUTER

This namespace contains the Prediction + PRISM product, protocol, mathematical, architecture, hackathon, execution, validation, evidence and pitch documentation.

## Product boundary

```text
NATIVE PREDICTION MARKET
Event + ResolutionSpec
-> CompleteSetVault
-> YES / NO ERC-20
-> Kuru

PRISM
Supported outcome ERC-20s
-> exact admission h = Gx
-> backing B_i >= S*x_i
-> PRISM ERC-20
-> Kuru
-> partial/final settlement
```

## Reading order

1. `00-context/EXECUTIVE_SUMMARY.md`
2. `00-context/REPORT_RECONCILIATION.md`
3. `protocol/PRISM_PROTOCOL_SPEC.md`
4. `protocol/INVARIANTS.md`
5. `protocol/STATE_MACHINE.md`
6. `math/README.md`
7. `04-architecture/SYSTEM_ARCHITECTURE.md`
8. `04-architecture/SMART_CONTRACTS.md`
9. `05-hackathon/PHASE_GATES.md`
10. `../../contracts/docs/prism/README.md`

## Authority

Accepted ADRs remain highest authority. Under them:
- `protocol/` owns canonical financial semantics.
- `math/` proves/classifies those semantics.
- `research/prism-model/` is the executable semantic oracle.
- `04-architecture/` maps accepted semantics into system responsibilities.
- `contracts/docs/prism/` owns implementation-facing Solidity requirements.

The Modern Launchpad is separate under `../launchpad/`.
