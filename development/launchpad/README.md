---
id: LP-DEV-ROOT
type: normative_implementation
status: ready
owner: launchpad-planner
product: launchpad
version: v2
---

# RetroPick Launchpad V2 Engineering Control Plane

## Goal

Ship a production-shaped non-custodial Monad launchpad:

```text
create -> bonding market -> buy/sell -> graduation -> Kuru -> mature trading
```

## Authority

1. Accepted ADRs.
2. `docs/launchpad/` product/protocol truth.
3. This directory for implementation architecture.
4. Local `AGENTS.md` for directory-level implementation constraints.
5. Current code references under `contracts/docs/launchpad/`.
6. Evidence under `evidence/launchpad/`.

## Agent rule

An implementation agent should read only:
- root `AGENTS.md`;
- the owning canonical product/protocol files;
- its development lane;
- the nearest local `AGENTS.md`;
- its task spec.

Do not load the whole repository documentation by default.

## Development readiness

A lane is READY only when its agent can determine without guessing:
WHAT to build, WHERE to build it, WHAT NOT to change, required INPUTS/OUTPUTS, interfaces, exact verification, evidence, and handoff.
