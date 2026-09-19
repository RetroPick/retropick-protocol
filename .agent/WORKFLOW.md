# Universal Agent Workflow

This workflow applies regardless of harness.

```text
BOOTSTRAP
  ↓
ROUTE PRODUCT
  ↓
LOAD BOUNDED AUTHORITY
  ↓
CHECK STATE / GATES / ADRs
  ↓
DEFINE TASK CONTRACT
  ↓
PLAN
  ↓
IMPLEMENT OR ANALYZE
  ↓
VERIFY
  ↓
WRITE EVIDENCE
  ↓
HANDOFF
  ↓
UPDATE STATE/GATE WHEN AUTHORIZED
```

## Bootstrap

Read:
- `AGENT_GUIDE.md`
- `AGENTS.md`
- `.agent/README.md`
- `.agent/STATE.json`
- `.agent/CURRENT_GOAL.md`
- `.agent/ROUTING.md`

## Route product

Determine Launchpad, Prediction/PRISM, or shared infrastructure. Never silently mix financial semantics.

## Load bounded authority

Read only the canonical docs and development lane required for the task, plus the nearest local `AGENTS.md`.

## Check prerequisites

Before coding verify requirement, owner, dependencies/gates, ADR state and mutable external facts.

## Define task contract

Resolve:
ID, goal, why, owned paths, forbidden paths, inputs, outputs, acceptance, verification, evidence and handoff.

## Implement

Make the smallest coherent change. Do not opportunistically redesign adjacent components.

## Verify

Run layer-appropriate deterministic tests plus adversarial/security checks where applicable.

## Evidence

Record command/action, commit/ref, result, artifacts, residual risk and blockers.

## Handoff

Pass explicit artifacts to the next owner rather than prose-only status.

## State

Update gates/status only when documented acceptance criteria actually pass.

Never self-authorize unrestricted mainnet release.
