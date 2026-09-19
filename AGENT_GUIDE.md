# RetroPick Agent Engineering Guide

This is the universal entry point for Cursor, Codex, Kiro, Claude Code, Hermes, and other coding agents working in this repository.

The canonical agent control plane is:

~~~text
.agent/
~~~

Read this file, then AGENTS.md and the routed authority for the task.

# 1. Mental model

RetroPick is **one Launchpad platform** with shared product infrastructure and independently qualified financial modules.

~~~text
RetroPick Launchpad Platform
├── Launchpad Core
│   └── token launch -> bonding market -> graduation -> Kuru
├── Prediction Module
│   └── event-linked outcome issuance/resolution
└── PRISM Module
    └── exact-backed structured outcome assets
~~~

Separate engineering qualification does not mean separate product.

Shared product infrastructure may converge where safe. Financial semantics do not.

Never mix:
- Launchpad reserves/fees/graduation;
- Prediction complete-set collateral/resolution;
- PRISM backing/replication/settlement.

# 2. Authority

Use this precedence:

~~~text
accepted ADRs
-> canonical platform/module docs
-> development architecture/control plane
-> .agent steering/local AGENTS constraints
-> task/goal specification
-> implementation
-> evidence
~~~

Code cannot silently redefine accepted financial semantics.

# 3. Repository map

~~~text
docs/platform/            umbrella product/platform architecture
docs/launchpad/           Launchpad-Core WHAT/WHY
docs/prism/               Prediction/PRISM WHAT/WHY + proof layers

development/launchpad/    Launchpad-Core implementation HOW
research/production/      shared platform + Launchpad production research
research/prism-model/     PRISM executable semantic oracle
research/prism/           broader PRISM incubation research

contracts/                Solidity implementation/reference
decisions/                ADR authority
goals/                    scoped execution goals
evidence/                 reproducible proof
.agent/                   universal agent control plane
~~~

# 4. Mandatory bootstrap

For every task:

~~~text
1. Read AGENT_GUIDE.md.
2. Read AGENTS.md.
3. Read .agent/STATE.json.
4. Read .agent/CURRENT_GOAL.md.
5. Use .agent/ROUTING.md.
6. Determine platform/module + specialist lane.
7. Read relevant steering.
8. Read only required canonical docs.
9. Read relevant development/research lane.
10. Read nearest local AGENTS.md.
11. Check ADRs and gates.
12. Identify owned/read-only/forbidden paths.
~~~

Bounded context is intentional.

# 5. Platform routing

For umbrella product architecture and shared product surfaces read:

~~~text
docs/platform/
.agent/ROUTING.md
research/production/
~~~

Shared-platform work includes discovery, portfolio/activity, wallet integration, common SDK/types, indexer infrastructure, APIs, observability, environment/config and common Kuru connectivity where safe.

Shared infrastructure must not become financial authority.

# 6. Launchpad Core routing

Launchpad Core is the current production-engineering track.

Product/UX:
- docs/launchpad/PRODUCT.md
- docs/launchpad/PRODUCT_SCOPE.md
- docs/launchpad/USER_FLOWS.md
- development/launchpad/frontend/

Solidity:
- docs/launchpad/PROTOCOL.md
- docs/launchpad/BONDING_CURVE.md
- docs/launchpad/FEES_AND_ECONOMICS.md
- docs/launchpad/GRADUATION.md
- docs/launchpad/STATE_MACHINE.md
- docs/launchpad/INVARIANTS.md
- development/launchpad/contracts/
- contracts/AGENTS.md

Kuru/integrations:
- docs/launchpad/KURU.md
- docs/launchpad/MONAD.md
- docs/launchpad/INTEGRATIONS.md
- development/launchpad/integrations/

QA/DevOps:
- development/launchpad/testing/
- development/launchpad/security/
- development/launchpad/devops/
- development/launchpad/control/

Launchpad Core follows its existing DEVELOPMENT_READY, HACKATHON_READY, STAGING_READY, MAINNET_CANDIDATE and MAINNET_AUTHORIZED gates.

# 7. Prediction / PRISM incubation routing

Prediction and PRISM are RetroPick platform modules under independent qualification.

Start with:

~~~text
docs/prism/README.md
docs/prism/00-context/EXECUTIVE_SUMMARY.md
docs/prism/protocol/PRISM_PROTOCOL_SPEC.md
docs/prism/protocol/INVARIANTS.md
docs/prism/protocol/STATE_MACHINE.md
docs/prism/math/README.md
docs/prism/05-hackathon/PHASE_GATES.md
research/prism-model/README.md
research/prism/README.md
~~~

PRISM remains math-first.

Production Solidity remains blocked until its MATH-1 and CONTRACT-ARCH-1 gates authorize implementation.

PRISM does not inherit Launchpad-Core release status merely because both belong to RetroPick.

# 8. Production research routing

Production research primarily targets:
- shared RetroPick platform infrastructure;
- Launchpad Core.

Read:
- research/production/README.md
- research/production/WORKFLOW.md
- research/production/PRODUCTION_RESEARCH_GATES.md
- research/production/matrices/

PRISM may reuse shared infrastructure research but remains under its incubation program until module admission.

# 9. Universal task contract

Resolve before implementation:

~~~text
ID
GOAL
WHY
PLATFORM/MODULE
OWNER
READ
OWN
READ-ONLY
DO NOT
INPUTS
OUTPUTS
ACCEPTANCE
VERIFY
EVIDENCE
HANDOFF
BLOCKERS
~~~

If these cannot be resolved from repository authority, the task is not development-ready.

# 10. Current vs target

Every architecture-changing task distinguishes:

~~~text
CURRENT
TARGET
DELTA
MIGRATION ORDER
~~~

Never describe target architecture as already implemented.

# 11. Ownership

A specialist writes only owned paths, treats other specialist paths as read-only unless scope explicitly expands, does not invent missing upstream interfaces, and hands off explicit artifacts.

# 12. Decision states

Architecture/technology decisions are:

~~~text
CANDIDATE
DECIDED
IMPLEMENTED
~~~

A candidate suggestion is not permission to implement it as accepted architecture.

# 13. Testing and evidence

Completion may require unit, fuzz, invariant, integration, browser E2E, security/static analysis, deployment smoke and resilience/failure injection depending on layer.

Evidence records:
- exact command/action;
- commit/ref;
- result;
- artifacts;
- residual risk/blockers;
- downstream handoff.

# 14. Security

- no secrets in repository;
- backend/indexer are not canonical financial state;
- frontend cannot invent reserves/economics;
- normal user economic writes remain wallet -> chain;
- external failures cannot silently corrupt protocol state;
- agents cannot self-authorize unrestricted mainnet deployment;
- no hackathon shortcut may bypass accepted financial invariants.

# 15. Completion

Before DONE verify requirements, owned scope, tests, security cases, generated artifacts, evidence, handoffs, gate state and blockers.

The repository should always tell one coherent story:

**one RetroPick Launchpad platform, shared product infrastructure where safe, independently qualified financial modules.**
