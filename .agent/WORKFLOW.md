# Universal Agent Workflow

~~~text
BOOTSTRAP
  ↓
ROUTE PLATFORM / MODULE
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
~~~

## Bootstrap

Read:
- AGENT_GUIDE.md
- AGENTS.md
- .agent/README.md
- .agent/STATE.json
- .agent/CURRENT_GOAL.md
- .agent/ROUTING.md

## Route platform/module

Determine whether the task is:
- shared RetroPick platform;
- Launchpad Core;
- Prediction;
- PRISM incubation;
- cross-module infrastructure.

Never silently mix financial semantics.

## Load bounded authority

Read only canonical docs and the development/research lane required for the task.

## Check prerequisites

Verify requirement, owner, dependencies/gates, ADR state and mutable external facts.

## Define task contract

Resolve ID, goal, why, platform/module, owned paths, forbidden paths, inputs, outputs, acceptance, verification, evidence and handoff.

## Implement

Make the smallest coherent change. Do not opportunistically redesign adjacent modules.

## Verify

Run layer-appropriate deterministic tests plus adversarial/security checks where applicable.

## Evidence

Record command/action, commit/ref, result, artifacts, residual risk and blockers.

## Handoff

Pass explicit artifacts to the next owner.

## State

Update gates/status only when documented acceptance criteria pass.

No module inherits another module's readiness. Never self-authorize unrestricted mainnet release.
