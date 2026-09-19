# RetroPick Prediction + PRISM Documentation

**Status:** CANONICAL INCUBATING MODULE ROUTER

Prediction and PRISM are independently qualified financial modules of the **RetroPick Launchpad platform**.

They remain isolated here because their financial mechanisms must be researched, falsified, mathematically verified, economically tested, security-reviewed and implemented before module admission.

Separate engineering qualification does not mean separate product.

## Product boundary

~~~text
PREDICTION MODULE
Event + ResolutionSpec
-> CompleteSetVault
-> YES / NO ERC20
-> Kuru

PRISM MODULE
Supported outcome ERC20s
-> exact admission h = Gx
-> backing B_i >= S*x_i
-> PRISM ERC20
-> Kuru
-> partial/final settlement
~~~

## Reading order

1. 00-context/EXECUTIVE_SUMMARY.md
2. 00-context/REPORT_RECONCILIATION.md
3. protocol/PRISM_PROTOCOL_SPEC.md
4. protocol/INVARIANTS.md
5. protocol/STATE_MACHINE.md
6. math/README.md
7. 04-architecture/SYSTEM_ARCHITECTURE.md
8. 04-architecture/SMART_CONTRACTS.md
9. 05-hackathon/PHASE_GATES.md
10. ../../research/prism-model/README.md
11. ../../research/prism/README.md

## Authority

Accepted ADRs remain highest authority. Under them:
- protocol/ owns canonical financial semantics;
- math/ proves/classifies those semantics;
- research/prism-model/ is the executable semantic oracle;
- research/prism/ owns the broader incubation research program;
- 04-architecture/ maps accepted semantics into system responsibilities;
- contracts/docs/prism/ owns implementation-facing Solidity requirements.

## Production relationship

Launchpad Core is the current production-engineering track under ../launchpad/.

PRISM does not inherit Launchpad-Core STAGING_READY, MAINNET_CANDIDATE or MAINNET_AUTHORIZED status. It must pass its own mechanism and module-admission gates first.
