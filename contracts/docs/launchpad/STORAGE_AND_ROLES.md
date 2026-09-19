---
id: LP-CODE-STORAGE
type: generated_current_state
product: launchpad
version: v2
status: active
source: contracts/src/v2
---

# Storage and Roles

## Factory current state groups

- immutable V4 dependencies: PoolManager, PositionManager, Permit2, locker, hook, fee escrow, buyback vault, graduation guard;
- once-wired helpers: graduation executor, launch deployer, launch forwarder;
- owner-controlled global settings: creator-tax ceiling, anti-snipe parameters, launch fee/enabled;
- mappings: launcher allowlist, approved quote assets, quote economics, fee-policy snapshots, launch records, pending creator-recipient changes;
- launch configuration array.

## Roles

Factory owner controls bounded global configuration/helper wiring/quote admission and delayed recovery/creator override paths.

Creator fee recipient has only explicitly implemented creator controls.

Factory is trusted by deployer/curve/buyback/locker/hook helper paths as implemented.

## Change warning

The current factory contains venue-specific V4 immutables. Kuru migration cannot be represented as a configuration-only change to an already deployed current factory; target architecture must account for constructor/storage/API impact.
