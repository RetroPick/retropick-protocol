# V2 research experiment

UNQUALIFIED. Canonical V1/V2 remain untouched. No deployment authority.

The curve-only community vertical slice now uses real experimental factory launches, curve trades, authenticated funding, delayed old-epoch settlement and independent recipient claims. CommunityLaunchBuilderV2 atomically wires CommunityControllerV2, CommunityPolicyRegistryV2 and CommunityFeeRouterV2. Protocol fees retain the existing escrow; the router holds only pre-separated community fees. See iteration 002 and its qualification evidence before interpreting capability status.

BaselineRightsConflict.t.sol explicitly imports canonical reference fixtures to reproduce existing accrued-fee and vest-beneficiary redirection. Other experimental tests import experimental contracts.

Creator caps constrain declared categories, not hidden beneficial ownership. Module address pinning is not proof of treasury/strategy behavior. Treasury vault, rewards and buyback execution remain deferred. Controller and real curve integration have local tests but incomplete full qualification. CE v4 registration disables unsupported creator/hook revenue. Kuru community revenue remains BLOCKED_EXTERNAL_CAPABILITY. Native/USDC mocks and stateful venue seams are not fork evidence.

See research/launchpad/community-economy-v2/iterations/001-policy-boundary.md and FEE_ACCOUNTING_SPEC.md at repository root.
