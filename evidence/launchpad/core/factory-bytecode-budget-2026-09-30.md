# Factory V2 bytecode budget — 2026-09-30

**Baseline:** `ef53422c8a5b96baf28e718bb9211733f08e2372`; Forge 1.8.3, solc 0.8.26, optimizer 200, viaIR, current `contracts/foundry.toml` settings. Command: `forge build --sizes --skip test --skip script`. The pre-existing local `foundry.toml` edit is not part of this evidence commit and was not overwritten.

| Contract | Runtime bytes | Margin to EIP-170 24,576 bytes |
| --- | ---: | ---: |
| `RetroPickLaunchFactoryV2` | **24,502** | **74** |
| `RetroPickBondingCurveV2` | 10,711 | 13,865 |
| `RetroPickFeeEscrowV2` | 3,013 | 21,563 |
| `RetroPickQuoteAssetPolicyV2` | 682 | 23,894 |

The Factory's available margin is not feature budget. A preferred pre-DEV-4 engineering target is **≤23,500 bytes**, requiring at least **1,002 bytes** to be removed from the current Factory before any further Factory wiring. This is a target, not evidence that extraction has happened. Foundry's displayed runtime margin uses a different chain-specific cap; the table here compares against the explicitly required EIP-170 limit.

**Candidate sender-loss repair measurement:** adding exact Factory sender-debit verification to the V4 `_transferExact` path first produced `24,578` bytes, **2 bytes above** EIP-170. Simplifying its fail-closed subtraction yielded **24,565** bytes, only **11 bytes** below EIP-170 (`forge build --sizes --skip test --skip script`, same compiler profile). This keeps the safety repair executable but increases the minimum extraction required for the 23,500-byte target to **1,065 bytes**. It is not permission to add any further Factory feature.

**Narrowest proposed extraction:** preserve Factory as launch/config/record authority; move existing venue-specific V4 pool construction and verification responsibilities into a separately authoritative graduation coordinator/V4 adapter, then attach a separate Kuru executor. The Factory must only commit immutable venue selection before bonding and register a verified completion through a small bounded interface. The existing external quote policy is already separate. Avoid duplicating secured-asset balances across Factory and coordinator: choose one authoritative custody/accounting owner in the accepted specification. A bytecode-size rerun and stateful conservation tests are required after extraction; no architecture-changing extraction is authorized by this report alone.

**Hard stop:** no `deployProxy`, Kuru market-parameter/seed arithmetic, environment verification, LP custody, or Kuru ABI-heavy logic in Factory. The current Factory V4 `_transferExact` also checks recipient gain but not its own sender loss, and must be addressed during supported-asset V4 qualification; size pressure is not a reason to waive that defect.
