# apps/web Agent Contract

WHY: ship the Launchpad browser UX.
WHERE: own `apps/web/**` and approved `packages/ui/**`.
WHAT: render canonical data and construct user-signed transactions through shared SDK/domain packages.
WHAT NOT: do not modify Solidity, duplicate ABI/domain types, use API as canonical reserves, or use JS number for onchain amounts.
HOW: follow frontend development specs and shared domain/error contracts.
VERIFY: lint, typecheck, unit, build, browser smoke/E2E commands defined by the implemented workspace.
HANDOFF: web build + route inventory + stable E2E selectors/fixtures to QA.
