# M6 authenticated in-kind fee source — experimental specification

Status: PROPOSED FOR EXPERIMENTAL IMPLEMENTATION; owner chose in-kind pool-asset settlement and requested plan implementation. Canonical promotion still requires the concrete qualified fee-source/admission specification acceptance. No release/deployment authority.

## Boundary and immutable identity

New deployment family only; chain10143, native MON or admitted exact-transfer Circle-address6decimal quote. Existing source/deployed Curve-only Router/Vault contracts remain unchanged. Factory source/runtime must not grow. Independent Builder/deployment helpers atomically create/bind Controller, RevenueRouter, original PolicyRegistry, AssetTreasury and qualified72hTimelock before trading. New Router authenticates the actual factory-recorded Curve and the independently qualified nonproxy v4 hook. Every venue stream binds chain, factory, token, Curve, Router, PoolManager, poolId, quote, hook/codehash, coordinator/executor and frozen fee policy. No user-supplied recipients or arbitrary calls.

Exactly two supported assets: immutable quote and this launch's fixed-supply standard token. Neither asset is interchangeable with LP principal; no liquidity withdrawal or collection permissions are introduced. No conversion swaps, guaranteed quote value, rebases, mint allocations, buybacks, rewards or external-business revenue.

## Funding equations and accrued ownership

For actual v4 afterSwap unspecified-currency delta magnitude U, F=floor(U*launchHookFeeBps/10000); T=floor(U*launchCreatorTaxBps/10000). Rates and protocol share/recipient are frozen from the existing per-launch economic snapshot; each stage is disclosed independently and all controlled rates stay within immutable constitutional bounds. LPfee remains0. Fee calculation uses actual flow, including partial fills; all four exact-in/out and direction combinations require genuine-PoolManager tests. The returned hook delta must reconcile exactly with currency taken.

The hook takes G=F+T into its custody and verifies exact receipt, then authenticated fundVenue(poolId,asset,epoch,sequence,F,T) transfers G to the per-launch RevenueRouter. Router computes P=floor(F*protocolShareBps/10000), sends P to existing pull escrow, and credits C=G-P according to that accrual epoch. Protocol share is applied once. The original Curve fund(token,quote,epoch,sequence,C) API continues receiving pre-separated community value and applies no second protocol split.

For each asset independently: venueGross=protocolRemitted+venueCommunityFunded; communityFunded=paid+outstanding; physical Router assets>=outstanding; Treasury claimed=spent+held and physical Treasury assets>=held. Do not sum token quantities into MON/USDC revenue. Funding verifies both token sender/receiver deltas or exact msg.value, pre-existing backing, exact escrow remittance and allowance cleanup. Zero total fees perform no booking.

Accrual is the atomic swap callback/Curve settlement. Registry epoch is bound before external transfer and immutable policy history supplies allocations. A funding-in-progress flag blocks policy checkpoint/activation reentry. Venue funding allocates synchronously, leaving no unallocated venue epochs or price conversion backlog. If the eventual PoolManager unlock fails, the entire funding/credits/escrow effects revert with the swap. Curve checkpoint behavior remains real source settlement, not an adjustable pending counter.

Per-source replay domains: Curve sequence retains existing semantics; venue sequence is keyed by bound pool and asset. Failed transfers consume no sequence. Source authentication rejects forged pool/launch/asset/epoch, callbacks from non-Manager, direct donations and duplicate settlement. Claimants independently withdraw their own asset credit; recipients never run during allocation. At most10allocations, identical existing floor rounding and treasury dust rule. Quarantined donations create no credit or income.

## Treasury and governance

AssetTreasury is uniquely bound to its actual Router/token/quote during the authenticated launch, not through a predicted shared beneficiary. Only its own credit can be pulled. Quote-compatible views/claims remain; explicit per-asset credit/accounting/claim views are added. Each asset's claimed/spent/held/surplus/deficit is isolated. Deficit fails closed for that asset; no borrowing, rescue, approval, principal access or unrestricted Vault call exists. Spending uses existing qualified Timelock schedule/execute with a globally unique nonzero spendId and exact debit. Fixed72h delay, inclusive7day execution window, permanent open execution and governed proposer/canceller rotation remain.

Actual Safe1.4.1, initially2of3 with no enabled modules/custom bypass, is the governance test default. Controllers/guardians get no Treasury rights. Past credits survive policy/controller changes. Lost Safe quorum/proposer availability remains a liveness limitation, not grounds for confiscation.

## Gates and migration

New v4-only admission class must reject Kuru masks even for its owner; old quote registries, packets/executors, custody and retries are unchanged. Genuine v4 stack uses pinned upstream code and real callbacks/positions, never behavioral doubles. New Hook/Executor must preserve legacy entrypoint behavior; old pools cannot acquire new hooks or fees. Every new deployable runtime/initcode is strictly measured. Factory unchanged bytes/codehash must be demonstrated under identical compiler input/settings.

Before canonical promotion: repair baseline; independently review source spec/code; qualify actual swaps, accounting, temporal rights, malicious actors, two-launch isolation, LP custody, native and6decimal paths, genuine integration and Safe. Any unresolved critical/high or unbacked entitlement blocks promotion. Pin exact implementation/dependency identities and retain all failed traces. Existing live profiles remain unmodified.


## Explicit fee-activation qualification

Old Curve-only community pools retain their deliberately zero post-graduation hook fees. The new ConfigV2 family activates existing launch-snapshot hook fee/tax fields for a fresh explicitly selected mode. Reusing the numerical snapshot is not financial equivalence to the old zero-fee community mode. No existing deployed pool or Builder is modified. Concrete canonical acceptance and client consent are specified in M6_FEE_SOURCE_ADR_CANDIDATE.md; fee activation must be disclosed before signing.
