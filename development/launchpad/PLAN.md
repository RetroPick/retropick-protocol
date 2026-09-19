# Control-Plane Execution Plan

## Live inventory

The repository is Solidity-heavy: V1/V2 launch contracts exist, but web/API/indexer/shared packages are placeholders. Current Foundry tests are Doorway-only.

## Product P0

Creator token launch -> primary bonding trading -> safe graduation -> Kuru mature market, exposed through a real browser product with indexed read data.

## Current/target contract delta

CURRENT: V2 factory/graduation is directly V4-oriented.
TARGET: retain accepted token/bonding/fee behavior while replacing only the mature-market graduation boundary with a verified Kuru path.
MIGRATION: freeze current behavior with V2 tests first; verify Kuru; define parameter policy; implement safe executor; differential-test unchanged economics; retire V4 path only when proven unused.

## Documentation restructuring

- consolidate Launchpad product/protocol truth into ~20 high-authority files;
- move implementation architecture into `development/launchpad/`;
- reduce `contracts/docs/launchpad/` to current-code reference;
- preserve unique security/economic facts before deleting old thin docs.

## Agent control plane

- root AGENTS routes both Launchpad and PRISM;
- Kiro steering holds durable product/tech/structure/engineering/test/security context;
- custom agents receive narrow resources/permissions;
- machine YAML owns requirements/components/dependencies/handoffs/gates/status;
- local AGENTS files enforce directory constraints.

## Main blockers before product implementation

1. Launchpad V2 core has no dedicated committed test suite.
2. Kuru runtime/deployment/API must be pinned before target contract implementation.
3. full-stack runtime stack remains a CANDIDATE pending ADR.
4. indexer/provider and backend/storage stack remain CANDIDATE pending ADRs.
