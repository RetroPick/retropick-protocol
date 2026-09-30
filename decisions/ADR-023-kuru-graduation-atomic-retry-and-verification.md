# ADR-023: Atomic Kuru destination completion and verification

**Status:** PROPOSED

**Date:** 2026-09-29

**Scope:** Launchpad Core V2 Kuru graduation phase 2; no executor implementation authorized by this proposal.

## Problem

Core's primary curve must stop trading and secure its assets before depending on Kuru. A Kuru revert, implementation upgrade, wrong market, partial seed, or LP-share misdirection must not mark the launch `GRADUATED` or erase its secured balances. The old V4 `Swept → PoolCreated` retry concept is useful, but its venue-specific checks do not prove a Kuru completion. See the [target freeze packet](../development/launchpad/integrations/KURU_TARGET_FREEZE_PACKET.md).

## Proposed state and transaction contract

Phase 1 is an independently committed `GRADUATING` transition: freeze ordinary buy/sell, settle/identify fees under the accepted Core policy, move and reconcile the exact launch-token and same-quote seed assets to controlled custody, and record immutable source amounts. A failed or unavailable Kuru call cannot unwind that already-committed phase.

Phase 2 is **one atomic transaction**: revalidate the accepted Kuru Router, MarginAccount, OrderBook and vault implementation addresses/code hashes at execution; derive the unique expected market/vault from accepted parameters and current Router implementation state; reject an already-existing destination unless a separate adoption rule is accepted; call `deployProxy`; verify code, Router `verifiedMarket`, OrderBook market/vault parameters, owner/router identity, vault base/quote/MarginAccount/spread; seed exact physical liquidity; verify consumed balances, nonzero vault order sizes, price-continuity bound and LP shares minted to the accepted lock; record market/vault identities and `GRADUATED` last. An external return address or event alone is insufficient.

External proxy EIP-1967 implementation slots are **offchain qualification evidence** read through RPC and pinned in a versioned manifest. The executor cannot `SLOAD` another contract's private storage slot. Its onchain drift guard uses `chainid`, the accepted Router address, Router-exposed MarginAccount/implementation getters, code presence and `extcodehash` of observable implementations, followed by CREATE2 identity and independently read market/vault state. It must not claim to atomically inspect an external proxy's EIP-1967 slot. An upgrade not visible through those getters/code hashes remains an external trust risk requiring monitoring and requalification.

Any phase-2 revert returns to the unchanged durable `GRADUATING` state, so P0 retry is permissionless using the same secured assets. No trade reopens implicitly. A second completion must revert before any asset movement or market creation. P0 has no rescue shortcut and no path that marks a launch `GRADUATED` without full postcondition verification. Any future recovery design requires a separate protocol decision.

## Why atomic and what could falsify it

Atomicity minimizes independently writable states and double-use opportunities. It also creates a gas/DoS risk if market deployment, verification and first vault deposit exceed target-chain execution limits. A representative Monad Testnet fork or simulation must measure gas for ERC20/USDC and ERC20/native cases and inject reverts at each external step. If the atomic flow is infeasible, **revise this ADR** with explicit intermediate states and conservation invariants before any executor is implemented; do not silently split transactions. A Kuru implementation upgrade that changes the CREATE2 identity or a paused market also falsifies a previously accepted environment snapshot and must stop graduation pending requalification.

## Acceptance criteria and blocker

Require exact target environment manifest and code hashes, accepted parameter/quote policy, accepted LP-share custody ADR, a non-guessing market verification fixture, atomic revert/retry/duplicate tests on a local fork, gas bounds for representative launches, and security review of external callbacks. The protocol owner supplied the P0 permissionless-retry/no-rescue direction; executable qualification and ADR acceptance remain required. Until those conditions hold, this ADR remains **PROPOSED** and `READY_FOR_DEV4_KURU_EXECUTOR` is BLOCKED.
