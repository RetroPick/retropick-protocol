# Shared Platform

Shared infrastructure should converge only where convergence does not blur financial authority.

## Good shared boundaries

- frontend navigation and design system;
- wallet connection and transaction status;
- discovery/search;
- profiles;
- portfolio/activity;
- analytics presentation;
- shared ABI/types/SDK packages;
- indexer infrastructure;
- non-custodial metadata/search API;
- Monad RPC configuration;
- Kuru connectivity primitives;
- environment manifests;
- CI/CD;
- logs, metrics and alerts.

## Specialized boundaries

Keep module-specific:
- contract economics;
- collateral accounting;
- issuance mechanics;
- resolution semantics;
- settlement semantics;
- lifecycle invariants;
- security proofs.

Generalize application domain interfaces before generalizing financial contracts.
