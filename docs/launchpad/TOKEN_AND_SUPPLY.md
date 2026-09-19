---
id: LP-TOKEN
type: normative
product: launchpad
version: v2
status: active
---

# Token and Supply

P0 launches use a fixed/capped ERC20 model.

Current V2 intent:
- metadata includes name/symbol/logo/description/social references;
- declared supply is bounded;
- current token construction mints launch supply to the curve;
- creator identity/reference grants no hidden mint privilege.

Normative rules:
- no arbitrary hidden post-launch mint;
- total minted/capped supply must reconcile allocations;
- decimals/supply units are explicit;
- burn behavior cannot make reserve accounting insolvent;
- future allocation/vesting changes require explicit protocol/ADR changes.

Implementation mapping lives in `development/launchpad/contracts/TOKEN_AND_SUPPLY.md`.
