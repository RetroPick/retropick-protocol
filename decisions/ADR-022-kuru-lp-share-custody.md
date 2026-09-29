# ADR-022: Kuru graduation LP-share and excess-token custody

**Status:** PROPOSED

**Date:** 2026-09-29

**Scope:** Launchpad Core V2 graduation; no production implementation authorized by this proposal.

## Economic question

Kuru's first vault deposit mints transferable LP shares to a caller-specified `receiver`; the holder can burn shares to withdraw underlying assets. Replacing V4's locked position with creator-owned or operator-owned shares would make the graduation liquidity withdrawable, changing the anti-rug promise even if the Curve itself remains fixed. The current [target freeze packet](../development/launchpad/integrations/KURU_TARGET_FREEZE_PACKET.md) and [source-pinned evidence](../evidence/launchpad/kuru/target-snapshot-2026-09-29.json) identify this as an unaccepted economic authority decision.

## Proposed rule

All LP shares minted from RetroPick graduation go directly to a dedicated, immutable-authorization liquidity-lock custody contract bound to the exact launch token, quote asset, Kuru market/vault identity and amount minted. Neither creator, protocol operator, nor arbitrary caller may transfer, approve, burn, withdraw or arbitrary-call those shares. Excess launch tokens excluded from the price-preserving Kuru seed are locked under the same non-withdrawal promise and separately accounted from LP shares. The lock records quantities and emits auditable events.

Unexpected unrelated ERC-20s may be rescued only through a narrow, delayed, explicit asset-class exclusion proof; LP shares, the launch token, quote asset and any token that represents the locked Kuru position must never be rescue-eligible. A generic `execute` or arbitrary target-call escape hatch is prohibited. Any recovery method must be separately specified and tested before acceptance.

## Alternatives and consequences

| Alternative | Consequence |
| --- | --- |
| Creator receives LP shares | Creator can remove liquidity; fails the intended anti-rug continuity. |
| Protocol treasury receives freely transferable shares | Concentrates rug/compromise authority; changes the economic promise. |
| Last-graduation caller receives shares | Permissionless race grants valuable withdrawal rights to a caller with no economic entitlement. |
| Permanent dedicated lock (recommended) | Preserves non-withdrawable liquidity but cannot recover from a Kuru venue failure or adverse upgrade without a distinct human-approved emergency policy. |

Locking RetroPick shares does **not** make Kuru immutable: its Router/OrderBook/Vault can be governed/upgraded or paused externally. A permanent lock can preserve a no-withdrawal promise while leaving users exposed to Kuru malfunction. Monitor implementation/code-hash and market state changes; pause *new* graduations when the accepted external identity changes. Do not silently add a withdrawal escape in response to an upgrade.

## Acceptance criteria and blocker

Human protocol/economic authority must choose permanent versus bounded emergency withdrawal, identify who can trigger any unrelated-asset rescue, set a delay and destination, and accept treatment of the excess launch tokens. Security review must prove no route to approve/transfer/burn LP shares or withdraw the excess, including inherited token hooks and arbitrary-call paths. Fork tests must show first deposit shares reach the lock and that a failed deposit leaves no partially owned shares. Until then this ADR is **PROPOSED** and `READY_FOR_DEV4_KURU_EXECUTOR` remains BLOCKED.
