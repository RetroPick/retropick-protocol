# RetroPick Documentation

RetroPick has separate documentation lanes with separate semantic authority.

## Modern Launchpad

Start at:

1. `launchpad/README.md`
2. `launchpad/00-context/EXECUTIVE_SUMMARY.md`
3. `launchpad/03-protocol/PROTOCOL_SPEC.md`
4. `launchpad/03-protocol/INVARIANTS.md`
5. `launchpad/04-architecture/SYSTEM_ARCHITECTURE.md`
6. `../contracts/docs/launchpad/README.md`

The launchpad lane covers fixed/capped token issuance, bonding-curve primary markets, quote assets, fees, graduation, Kuru integration, full-stack architecture, testing and production operations.

## Prediction / PRISM

The existing prediction and PRISM specifications remain under the existing protocol/math/research hierarchy:

```text
docs/protocol/
  -> docs/math/
  -> research/prism-model/
```

Those financial semantics do not define the modern launchpad.

## Authority rule

Research is evidence, not protocol truth. Frontends and backends do not redefine economics. Implementation changes that alter canonical semantics require an ADR/spec update and the corresponding validation gates.
