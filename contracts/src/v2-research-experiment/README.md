# V2 research experiment

UNQUALIFIED. Canonical V1/V2 remain untouched. No deployment authority.

CommunityPolicyRegistryV2 is an isolated noncustodial policy prototype with immutable bounds, history and delayed checkpoint-dependent activation. Its controller provider and checkpoint are tested with explicit mocks; authentic fee-source integration and full G0/G1/G2 remain open. It is not a passed M1 milestone.

BaselineRightsConflict.t.sol explicitly imports canonical reference fixtures to reproduce existing accrued-fee and vest-beneficiary redirection. Other experimental tests import experimental contracts.

Creator caps currently constrain declared categories, not hidden beneficial ownership. Module address pinning is not proof of treasury/strategy behavior. Fee router, treasury, rewards, buyback adapters and controller recovery are pending. Kuru community revenue remains BLOCKED_EXTERNAL_CAPABILITY.

See research/launchpad/community-economy-v2/iterations/001-policy-boundary.md and FEE_ACCOUNTING_SPEC.md at repository root.
