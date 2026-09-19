# Module Model

**Status:** CANONICAL PLATFORM MODULE MODEL

RetroPick uses one product platform with independently qualified financial modules.

## Module state

Each module records:
- module_id;
- product_parent;
- financial authority;
- current state;
- current gate;
- required evidence;
- open blockers;
- integration contract;
- production inheritance rules.

## Current classification

| Module | Parent | Current state | Production track | Current gate |
|---|---|---|---|---|
| Launchpad Core | RetroPick Launchpad | DEVELOPMENT | yes | existing Launchpad gates |
| Prediction | RetroPick Launchpad | RESEARCH | no | module-specific research/spec |
| PRISM | RetroPick Launchpad | RESEARCH | no | MATH-1 |

## Production inheritance

A module does not inherit another module's release status.

For example, Launchpad Core reaching STAGING_READY does not make PRISM staging-qualified.

Shared environment qualification and module qualification are separate dimensions.
