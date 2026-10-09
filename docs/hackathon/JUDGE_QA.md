# Judge Q&A

**Why isn't this just pump.fun on Monad?** The differentiation is the issuance-to-orderbook lifecycle and its handoff engineering: immutable venue policy, one Coordinator ledger, deterministic Kuru market creation, exact completion liveness and protected graduation assets. Whether this earns a durable advantage depends on users and market quality.

**Why bonding first?** It offers transparent primary discovery and accumulates initial quote before secondary execution. It does not guarantee a fair price or healthy market.

**Why Kuru instead of keeping an AMM?** RetroPick handles origination; Kuru provides limit orders and market-making workflows. Actual execution quality depends on depth/spreads. Kuru's vault also supplies liquidity; we do not claim an AMM-free destination.

**Why Monad?** Both bonding and secondary orderbooks generate frequent transactions. Low-cost execution and responsive state support many concurrent markets; this is a settlement dependency, not just a branding choice.

**What if Kuru deployment fails?** Completion is atomic. The launch remains GRADUATING with secured assets and no committed destination; anyone may retry. The immutable venue cannot be swapped to escape failure.

**Can the creator remove liquidity?** The hackathon lock has no protected-asset withdrawal, approval or arbitrary-call path. This protects graduation LP/excess tokens. It does not protect every holder's tokens, remove market risk or guarantee perpetual useful depth.

**What if Kuru upgrades?** Graduation validates a pinned observable environment and fails closed on drift. That can require a newly qualified policy for future launches. Existing immutable packets cannot silently change destination; existing markets also carry external Kuru risks.

**Why is the Factory large?** Issuance and configuration still have substantial logic. Moving graduation ledger/execution into the Coordinator reduced runtime from about 24,565 to 23,423 bytes, below EIP-170 and the 23.5KB target. We did not remove safety checks to fit.

**Security assumptions?** Correct Solidity and exact-transfer assets, immutable policy/ledger checks, trusted configured administrative authority, and qualified external Kuru/V4 behavior. Tests cover key failure and conservation boundaries. This is unaudited testnet code; admin/external integration and economic risks remain.

**How do you make money?** Potential launch/trading/graduation fees where policy permits, B2B launch infrastructure and integrations. No current revenue or forecasts are claimed.

**Who uses it?** Creators and communities needing a market lifecycle, early token traders, and potential liquidity participants. Wallet/app integration is a future interface.

**How do you acquire creators?** Existing community channels, a small pilot, documented feedback and qualified Monad ecosystem introductions. Reported waitlist/social signals are pending verification; no committed partnerships exist.

**How do you compete with launchpads?** Reliable origination-to-orderbook infrastructure, clear launch proofs and distribution integrations. We must prove quality and retention rather than claim leadership now.

**What prevents scams?** Transparent policy and permanent custody reduce specific withdrawal risks. They do not stop dishonest creators, harmful token narratives, manipulation or losses. Additional reputation and issuer diligence are future work, not existing guarantees.

**Why can this become large?** Apps, wallets and communities can embed programmable market creation. That is a company thesis to validate through pilots, developer adoption and sustained secondary activity.

**Why support RetroPick after Metropolis?** A qualified origination engine could generate new Monad assets, primary transactions and Kuru markets/activity. Current engineering proof makes the pilot credible; adoption and retained activity must still be demonstrated.

**What do you need from Monad?** Technical/ecosystem mentorship, eligible residency support, wallet/community/issuer introductions, Kuru coordination, infrastructure access and security/liquidity introductions. We are not asking to be declared the official launchpad.

**Does the Kuru new-assets bounty fit automatically?** No. The portal asks for a new class of markets, customer demand and operational credibility. We provide actual creator/community issuance and market infrastructure; novelty and independently verified demand remain qualification questions.

**What does current traction prove?** Founder-reported 30+ signups and ~300K X engagements suggest early interest/distribution. They do not prove committed users, conversions, trading demand or commercial pilots. Supporting evidence is pending.

**What isn't complete?** Canonical Circle-USDC live smoke is blocked by funding. Live frontend, videos, source verification and final release checks require their own evidence before submission. No mainnet/audit claims.
