# Universal Agent Handoffs

A handoff is an artifact contract.

## Required fields

```text
HANDOFF_ID
FROM
TO
PRODUCT
GOAL_ID
REQUIREMENTS
COMMIT/REF
INPUTS_CONSUMED
OUTPUTS_PRODUCED
INVARIANTS_NOT_CHANGED
VERIFICATION
EVIDENCE
OPEN_BLOCKERS
STATUS
```

## Launchpad canonical handoffs

Machine-readable definitions:
`development/launchpad/control/handoffs.yaml`.

Examples:
- contracts -> ABI/events/deployment manifest -> SDK/indexer;
- indexer -> entity/query/sync-health contract -> backend/frontend;
- backend -> OpenAPI/client/error/auth contract -> frontend;
- frontend -> build/routes/E2E selectors -> QA;
- DevOps -> environment/deployment/health manifest -> QA.

Do not hand off "done" without consumable artifacts.
