# Current V2 / M6 client handoff

Status: development handoff, not authorization to redirect the hackathon frontend or deploy contracts.

Keep judging configuration, deployed ABI records and addresses pinned to the existing testnet profile. `contracts/legacy-v2` preserves its recorded source. New profiles admit only venue0; decode historical venue1 using the old deployment profile. Solidity consumers of the current source use `GraduationVenue.LEGACY_RESERVED` for the reserved numeric slot. Never globally renumber indexer events or delete old market history.

The canonical Curve-only community mode still has zero post-graduation community hook fees. The new experimental family advertises `revenueRouterVersion()==2` and `revenueHookVersion()==2`. These are capability indicators, not substitutes for deployed identity/codehash and configuration verification.

New-mode consent must include ConfigV2, the Builder/codehash commitment, existing economics commitment and explicit venue fee/tax preview. Show the actual maximum future constitutional bounds, current policy, pending policy, activation delay and controller separately from economic beneficiaries. Do not label the new fee-bearing mode equivalent to the old zero-hook-fee mode.

For each **individual asset**, read Router `creditOf`, `funded`, `paid`, `liability`, `venueGross`, `venueProtocolRemitted`, `venueCommunityFunded`, `venueSequence` and `epochFundedAsset`. Index `VenueFunded`, `AllocatedAsset` and `ClaimedAsset`; retain pool/asset/epoch/sequence identities and ordinary reorg rollback. Trading volume is not revenue. Do not sum MON/USDC/token units into an unpriced single revenue number.

Router withdrawals are wallet-authorized `claimAsset`/`claimAssetTo`; users cannot select another beneficiary's credit. Treasury `claimAssetFromRouter` is permissionless collection of the Treasury's own credit only. Read `claimedAsset`, `spentAsset`, `heldAsset`, physical balance, surplus and deficit separately. A donation is surplus, not earned income. Surface deficits as blocked operations, never as zero available revenue.

Treasury spending uses the existing Timelock schedule/cancel/execute flow with a nonzero globally unique spend ID, fixed72h delay and inclusive seven-day execution window. Controller/guardian recovery grants no Treasury spending authority. Safe quorum/configuration must be separately qualified; EOA fixture success is insufficient.

Graduation status comes from Coordinator ledger plus receipt/physical destination verification. Report secured/retryable failures, terminal pool ID, PositionManager NFT owner and liquidity. Do not infer harvestable principal or creator revenue from LP ownership. No new module grants NFT approvals, liquidity withdrawal or unrestricted rescue.

Current SDK/indexer/frontend code is unchanged in this milestone. New-mode financial writes remain disabled until deployment identities, ABI integration, truthful previews and wallet-security qualification are completed. Production ABI artifacts are not regenerated from experimental contracts.
