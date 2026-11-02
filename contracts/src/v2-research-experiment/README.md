# V2 research experiment

UNQUALIFIED. Canonical V1/V2 remain untouched. No deployment authority.

The curve-only community vertical slice now uses real experimental factory launches, curve trades, authenticated funding, delayed old-epoch settlement and independent recipient claims. CommunityLaunchBuilderV2 atomically wires CommunityControllerV2, CommunityPolicyRegistryV2 and CommunityFeeRouterV2. Protocol fees retain the existing escrow; the router holds only pre-separated community fees. See iteration 002 and its qualification evidence before interpreting capability status.

BaselineRightsConflict.t.sol explicitly imports canonical reference fixtures to reproduce existing accrued-fee and vest-beneficiary redirection. Other experimental tests import experimental contracts.

Creator caps constrain declared categories, not hidden beneficial ownership. Module address pinning is not proof of treasury/strategy behavior. Treasury custody now has an experimental atomic implementation (iteration004); rewards and buyback execution remain deferred. Controller and real curve integration have local tests but incomplete full qualification. CE v4 registration disables unsupported creator/hook revenue. Kuru community revenue remains BLOCKED_EXTERNAL_CAPABILITY. Native/USDC mocks and stateful venue seams are not fork evidence.

See research/launchpad/community-economy-v2/iterations/001-policy-boundary.md and FEE_ACCOUNTING_SPEC.md at repository root.

Iteration004 adds CommunityTreasuryLaunchBuilderV2, CommunityTreasuryDeployerV2, CommunityTreasuryVaultV2 and CommunityTimelockV2. Use the new builder only in a fresh once-wired experimental factory environment; no existing deployment is modified. Real treasury tests are distinct from the noncustodial binding probe. Pinned OZ5.4.0 closure is isolated under vendor with upstream bytes preserved; formatter-only exclusion does not change remappings or compiler configuration. Scoped canonical implementation is owner-authorized subject to qualification under ADR-CE02; no deployment approval.
