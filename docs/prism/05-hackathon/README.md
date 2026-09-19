# 05 Hackathon

Metropolis scope, sponsor strategy, MVP, phase gates, demo and submission evidence.

## Source-of-truth order

For hackathon implementation, use this precedence:

1. `docs/prism/protocol/*` for economic semantics and invariants;
2. accepted ADRs under `decisions/`;
3. `PHASE_GATES.md` for build authorization and dependency order;
4. `MVP.md` and execution docs for scope;
5. `RETROPICK_METROPOLIS_AGENT_DEVELOPMENT_WORKFLOW.md` for sponsor/product strategy;
6. historical research/report material only as non-authoritative input.

If the long workflow contains wording that conflicts with the canonical protocol docs, the canonical protocol docs win.

## Canonical phase control

Read:

- [`PHASE_GATES.md`](./PHASE_GATES.md)
- [`../06-execution/ROADMAP.md`](../06-execution/ROADMAP.md)
- [`../00-context/REPORT_RECONCILIATION.md`](../00-context/REPORT_RECONCILIATION.md)

The old W0-W12 framing must be interpreted as workstreams/waves, not twelve sequential calendar weeks.

## Current hackathon kernel

```text
Native RetroPick market
-> collateralized YES/NO ERC20
-> Kuru spot market

Native outcome ERC20s
-> exact-backed PRISM basket
-> PRISM ERC20
-> Kuru spot market
```

Admission-time math:

```math
h = Gx
```

Runtime backing:

```math
B_i \ge Sx_i
```

Final settlement funding:

```math
SettlementBalance \ge Supply \times FinalPayout
```

Phase-1 exclusions include `BackingMirror`, custom cross-chain custody, per-mint terminal-state enumeration and generic StatePool/SLE.
