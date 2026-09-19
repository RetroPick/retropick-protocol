# Structure Steering

Canonical ownership:

```text
docs/launchpad/        Launchpad WHAT/WHY
docs/prism/            Prediction/PRISM WHAT/WHY
development/           implementation HOW
contracts/docs/        current Solidity reference
decisions/             ADR authority
goals/                 scoped execution
evidence/              proof
.agent/                 agent workflow/control
```

Target Launchpad runtime ownership:

```text
apps/web/              frontend
apps/api/              backend
apps/indexer/          indexer
packages/domain/       canonical TS schemas/types
packages/contracts/    generated ABI/types/deployments
packages/sdk/          typed reads/writes
packages/config/       environment/config
packages/ui/           shared UI
packages/test-utils/   fixtures/test helpers
```

Do not duplicate ownership across layers.
