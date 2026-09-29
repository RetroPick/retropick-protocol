# ADR-023: Atomic Kuru destination completion and verification

**Status:** PROPOSED

**Date:** 2026-09-29

**Scope:** Launchpad Core V2 Kuru graduation phase 2; no executor implementation authorized by this proposal.

## Problem

Core's primary curve must stop trading and secure its assets before depending on Kuru. A Kuru revert, implementation upgrade, wrong market, partial seed, or LP-share misdirection must not mark the launch `GRADUATED` or erase its secured balances. The old V4 `Swept → PoolCreated` retry concept is useful, but its venue-specific checks do not prove a Kuru completion. See the [target freeze packet](../development/launchpad/integrations/KURU_TARGET_FREEZE_PACKET.md).

## Proposed state and transaction contract

Phase 1 is an independently committed `GRADUATING` transition: freeze ordinary buy/sell, settle/identify fees under the accepted Core policy, move and reconcile the exact launch-token and same-quote seed assets to controlled custody, and record immutable source amounts. A failed or unavailable Kuru call cannot unwind that already-committed phase.

Phase 2 is **one atomic transaction**: revalidate the accepted Kuru Router, MarginAccount, OrderBook and vault implementation addresses/code hashes at execution; derive the unique expected market/vault from accepted parameters and current Router implementation state; reject an already-existing destination unless a separate adoption rule is accepted; call `deployProxy`; verify code, Router `verifiedMarket`, OrderBook market/vault parameters, owner/router identity, vault base/quote/MarginAccount/spread; seed exact physical liquidity; verify consumed balances, nonzero vault order sizes, price-continuity bound and LP shares minted to the accepted lock; record market/vault identities and `GRADUATED` last. An external return address or event alone is insufficient.

Any phase-2 revert returns to the unchanged durable `GRADUATING` state, so authorized or permissionless retry (caller policy to be accepted) may use the same secured assets. No trade reopens implicitly. A second completion must revert before any asset movement or market creation. Any future recovery/rescue is a separate delayed, observable governance decision, not a shortcut to `GRADUATED` or a permissionless refund path.

## Why atomic and what could falsify it

Atomicity minimizes independently writable states and double-use opportunities. It also creates a gas/DoS risk if market deployment, verification and first vault deposit exceed target-chain execution limits. A representative Monad Testnet fork or simulation must measure gas for ERC20/USDC and ERC20/native cases and inject reverts at each external step. If the atomic flow is infeasible, **revise this ADR** with explicit intermediate states and conservation invariants before any executor is implemented; do not silently split transactions. A Kuru implementation upgrade that changes the CREATE2 identity or a paused market also falsifies a previously accepted environment snapshot and must stop graduation pending requalification.

## Acceptance criteria and blocker

Require exact target environment manifest and code hashes, accepted parameter/quote policy, accepted LP-share custody ADR, a non-guessing market verification fixture, atomic revert/retry/duplicate tests on a local fork, gas bounds for representative launches, and security review of external callbacks. Human authority must approve the retry caller set and any rescue model. Until those conditions hold, this ADR remains **PROPOSED** and `READY_FOR_DEV4_KURU_EXECUTOR` is BLOCKED.
