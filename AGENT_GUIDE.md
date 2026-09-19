# RetroPick Agent Engineering Guide

This is the universal entry point for **Cursor, Codex, Kiro, Claude Code, Hermes, or any other coding agent** working in this repository.

The repository does not use tool-specific workflow directories as its canonical control plane.

```text
.agent/
```

is the shared agent operating system.

Every agent should begin here, then follow `AGENTS.md` and the routes below.

---

# 1. Mental model

RetroPick has two separate product lanes:

```text
RetroPick
├── Launchpad V2
│   └── token launch -> bonding market -> graduation -> Kuru
└── Prediction + PRISM
    └── outcome assets -> exact-backed structured products -> settlement
```

They may share infrastructure, but they do **not** share financial semantics.

Do not mix:
- Launchpad reserves/fees/graduation;
- Prediction complete-set collateral;
- PRISM backing/replication/settlement.

---

# 2. Repository authority layers

Use this precedence:

```text
accepted ADRs
    ↓
canonical product/protocol docs
    ↓
development architecture/control plane
    ↓
.agent steering + local AGENTS constraints
    ↓
task/goal specification
    ↓
implementation
    ↓
evidence
```

Code does not silently redefine accepted protocol semantics.

If implementation requires changing an accepted architecture or financial invariant, create/supersede an ADR first.

---

# 3. Directory map

```text
retropick-protocol/
│
├── AGENT_GUIDE.md
│   Full repository map for all agents.
│
├── AGENTS.md
│   Small bootstrap/router. Read this at the start of every task.
│
├── .agent/
│   Universal agent control plane shared by Cursor, Codex, Kiro, etc.
│
│   ├── README.md
│   │   Control-plane overview.
│   │
│   ├── CONTEXT.md
│   │   Current project/product context.
│   │
│   ├── CURRENT_GOAL.md
│   │   Active goals by product.
│   │
│   ├── DECISIONS.md
│   │   Agent-readable summary of accepted decisions.
│   │
│   ├── ROUTING.md
│   │   Maps task type -> agent role -> required docs.
│   │
│   ├── WORKFLOW.md
│   │   Universal execution workflow.
│   │
│   ├── HANDOFFS.md
│   │   Artifact-based specialist handoff contract.
│   │
│   ├── STATE.json
│   │   Machine-readable current product/gate state.
│   │
│   ├── steering/
│   │   Durable instructions every agent should obey.
│   │   ├── product.md
│   │   ├── tech.md
│   │   ├── structure.md
│   │   ├── engineering.md
│   │   ├── testing.md
│   │   └── security.md
│   │
│   └── agents/
│       Role instructions.
│       Existing generic roles serve cross-product work.
│       launchpad-* roles contain Launchpad-specific ownership.
│
├── docs/
│   Canonical WHAT and WHY.
│
│   ├── README.md
│   ├── launchpad/
│   │   Product/protocol truth for Launchpad.
│   └── prism/
│       Product/protocol/math truth for Prediction + PRISM.
│
├── development/
│   Canonical HOW for implementation.
│
│   └── launchpad/
│       ├── README.md
│       ├── GOAL.md
│       ├── CURRENT_STATE.md
│       ├── MASTER_PLAN.md
│       ├── contracts/
│       ├── shared/
│       ├── indexing/
│       ├── backend/
│       ├── frontend/
│       ├── integrations/
│       ├── testing/
│       ├── security/
│       ├── devops/
│       ├── hackathon/
│       └── control/
│           ├── requirements.yaml
│           ├── components.yaml
│           ├── dependencies.yaml
│           ├── handoffs.yaml
│           ├── gates.yaml
│           └── status.yaml
│
├── contracts/
│   Solidity implementation.
│
│   ├── AGENTS.md
│   ├── src/
│   ├── test/
│   ├── script/
│   └── docs/
│       ├── launchpad/
│       │   Current-code reference only.
│       └── prism/
│           PRISM contract-target/reference docs.
│
├── decisions/
│   ADRs. Accepted ADRs outrank implementation.
│
├── goals/
│   Scoped execution goals.
│
├── evidence/
│   Reproducible proof of completed work.
│
├── research/
│   Research and executable reference models.
│
├── apps/
│   Product runtimes after architecture gates.
│
├── packages/
│   Shared packages after interfaces stabilize.
│
├── scripts/
│   Automation/deployment/evidence tooling.
│
└── tests/
    Cross-layer/E2E tests.
```

---

# 4. What each layer means

## `docs/*` = WHAT / WHY

Use for:
- product behavior;
- protocol semantics;
- economics;
- state machines;
- invariants;
- security boundaries;
- canonical integration intent.

Do not put detailed runtime implementation instructions here if they belong in `development/`.

## `development/*` = HOW

Use for:
- target architecture;
- frontend/backend/indexer implementation;
- contract migration plans;
- interfaces;
- data models;
- errors;
- test matrices;
- DevOps;
- CI/CD;
- handoffs;
- implementation gates.

## `contracts/docs/*` = CURRENT CODE REFERENCE

Use for:
- current ABI/event/storage/role/accounting reference;
- deployment facts derived from existing Solidity.

Do not use it to silently define future architecture.

## `.agent/*` = HOW AGENTS WORK

Use for:
- routing;
- durable steering;
- specialist ownership;
- execution workflow;
- machine state;
- handoffs.

## `evidence/*` = PROOF

Use for:
- command output;
- tx hashes;
- deployment addresses;
- test reports;
- security findings;
- screenshots only as supplemental proof.

---

# 5. Mandatory agent bootstrap

For every task:

```text
1. Read AGENT_GUIDE.md.
2. Read AGENTS.md.
3. Read .agent/STATE.json.
4. Read .agent/CURRENT_GOAL.md.
5. Use .agent/ROUTING.md to identify the product + specialist lane.
6. Read the relevant .agent/steering files.
7. Read only the canonical docs required for the task.
8. Read the relevant development lane.
9. Read the nearest local AGENTS.md if one exists.
10. Check accepted/proposed ADRs.
11. Identify owned and forbidden paths.
12. Check prerequisites/gates before coding.
```

Do not read the entire repository by default.

Bounded context is intentional.

---

# 6. Launchpad task routing

## Product/UX

Read:

```text
docs/launchpad/PRODUCT.md
docs/launchpad/PRODUCT_SCOPE.md
docs/launchpad/USER_FLOWS.md
development/launchpad/frontend/
```

## Solidity

Read:

```text
docs/launchpad/PROTOCOL.md
docs/launchpad/BONDING_CURVE.md
docs/launchpad/FEES_AND_ECONOMICS.md
docs/launchpad/GRADUATION.md
docs/launchpad/STATE_MACHINE.md
docs/launchpad/INVARIANTS.md

development/launchpad/contracts/
contracts/AGENTS.md
contracts/docs/launchpad/
```

## Kuru / integrations

Read:

```text
docs/launchpad/KURU.md
docs/launchpad/MONAD.md
docs/launchpad/INTEGRATIONS.md
development/launchpad/integrations/
development/launchpad/contracts/GRADUATION_TO_KURU.md
development/launchpad/contracts/KURU_MARKET_PARAMETERS.md
```

## Indexer

Read:

```text
development/launchpad/indexing/
development/launchpad/shared/
development/launchpad/control/
```

## Backend

Read:

```text
development/launchpad/backend/
development/launchpad/shared/
development/launchpad/indexing/QUERY_CONTRACT.md
```

## Frontend

Read:

```text
docs/launchpad/PRODUCT.md
docs/launchpad/USER_FLOWS.md
development/launchpad/frontend/
development/launchpad/shared/
```

## QA / E2E

Read:

```text
development/launchpad/testing/
development/launchpad/control/requirements.yaml
development/launchpad/control/gates.yaml
```

## DevOps

Read:

```text
development/launchpad/devops/
development/launchpad/shared/ENVIRONMENT_SCHEMA.md
development/launchpad/control/gates.yaml
```

---

# 7. Prediction / PRISM routing

Prediction/PRISM remains math-first.

Start with:

```text
docs/prism/README.md
docs/prism/00-context/EXECUTIVE_SUMMARY.md
docs/prism/protocol/PRISM_PROTOCOL_SPEC.md
docs/prism/protocol/INVARIANTS.md
docs/prism/protocol/STATE_MACHINE.md
docs/prism/math/README.md
docs/prism/05-hackathon/PHASE_GATES.md
```

For mathematical work also read:
- theorem/assumption files under `docs/prism/math/`;
- executable model under `research/prism-model/`.

Do not authorize PRISM production Solidity before its own MATH-1 and CONTRACT-ARCH-1 gates close.

---

# 8. Universal task contract

Every agent task should resolve these fields before implementation:

```text
ID
GOAL
WHY
PRODUCT
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
```

If these cannot be resolved from repository authority, the task is not development-ready.

---

# 9. Current vs target rule

Every architecture-changing task distinguishes:

```text
CURRENT
TARGET
DELTA
MIGRATION ORDER
```

Example:

```text
CURRENT:
Launchpad V2 graduation is Uniswap-V4-oriented.

TARGET:
Launchpad V2 graduates to Kuru.

DELTA:
Replace venue-specific graduation behavior while preserving accepted primary-market economics.

MIGRATION ORDER:
freeze current behavior with tests
-> verify Kuru
-> accept parameter policy
-> implement destination path
-> prove failure/retry safety
-> retire obsolete V4 coupling only after proof
```

Never describe target architecture as already implemented.

---

# 10. Agent ownership rule

A specialist:
- writes only its owned paths;
- treats other specialist paths as read-only unless the task explicitly expands ownership;
- does not invent missing upstream interfaces;
- hands off explicit artifacts to downstream agents.

Examples:

```text
contracts -> ABI/events/deployment manifest -> SDK/indexer

indexer -> entity/query/sync-health contract -> backend/frontend

backend -> OpenAPI/client/error contract -> frontend

frontend -> build/routes/E2E selectors -> QA

DevOps -> environment/deployment/health manifest -> QA
```

Canonical handoffs are under:
`development/launchpad/control/handoffs.yaml`.

---

# 11. Machine-readable control

For Launchpad, agents must consult:

```text
development/launchpad/control/requirements.yaml
development/launchpad/control/components.yaml
development/launchpad/control/dependencies.yaml
development/launchpad/control/handoffs.yaml
development/launchpad/control/gates.yaml
development/launchpad/control/status.yaml
```

Markdown explains these controls.

Do not maintain conflicting copies of the same status/configuration in multiple docs.

---

# 12. Technology decision states

A technology or architecture choice is one of:

```text
CANDIDATE
DECIDED
IMPLEMENTED
```

A candidate suggestion is not permission to build it as though accepted.

Check `decisions/` before implementing a major framework, provider, custody, authentication, storage, upgradeability, admin, or venue decision.

---

# 13. Testing and evidence rule

A task is not complete merely because code compiles.

Depending on layer, completion may require:
- unit;
- fuzz;
- invariant;
- integration;
- browser E2E;
- security/static analysis;
- deployment smoke;
- resilience/failure injection.

Evidence must record:
- exact command/action;
- commit/ref;
- result;
- relevant artifact/output;
- residual blockers;
- downstream handoff.

---

# 14. Security rules

Global:
- no secrets in repository;
- no normal user economic transaction signed by backend;
- indexer/backend cannot become canonical financial state;
- frontend cannot invent reserves/economics;
- external integration failure cannot silently corrupt protocol state;
- agents cannot self-authorize unrestricted mainnet deployment;
- do not bypass accepted invariants to make a hackathon demo work.

---

# 15. Completion discipline

Before claiming DONE:

```text
requirements satisfied?
owned files coherent?
forbidden scope untouched?
tests passed?
security cases covered?
generated artifacts updated?
evidence written?
handoff produced?
status/gate updated?
blockers explicit?
```

If not, report partial completion accurately.

---

# 16. First command for an agent

The conceptual first action of any agent should be:

```text
READ:
AGENT_GUIDE.md
AGENTS.md
.agent/README.md
.agent/STATE.json
.agent/CURRENT_GOAL.md
.agent/ROUTING.md
```

Then narrow into the product/domain lane.

That is the shared workflow for Cursor, Codex, Kiro, Hermes, and any other agent.
