---
id: LP-CODE-SECURITY
type: generated_current_state
product: launchpad
version: v2
status: active
source: contracts/src/v2
---

# Current Security Notes

## Current launch-core risks/gaps

- Core V2 Factory/Curve/Graduation behavior lacks committed dedicated unit/fuzz/invariant/integration coverage.
- Factory is heavily coupled to V4 constructor dependencies and destination assumptions.
- Any Kuru migration must freeze and regression-test existing bonding math/accounting before refactoring.
- Approved quote tokens rely on explicit validation/exact-transfer assumptions; arbitrary ERC20 support is unsafe.
- Graduation rescue and creator-recipient override paths are privileged/timelocked surfaces requiring dedicated tests.

## Doorway

Doorway is experimental and OUT_OF_SCOPE_P0. Its existing tests do not qualify Launchpad.

## Release

No contract is production-authorized solely because it compiles or because Doorway tests pass. See `../../../development/launchpad/security/` and testing gates.
