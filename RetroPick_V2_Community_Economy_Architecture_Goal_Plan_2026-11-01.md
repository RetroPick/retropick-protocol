# RetroPick V2 Community Economy — Current-State Reconciliation, Architecture and Goal Plan

**Date:** 2026-11-01  
**Scope:** Community Economy in `contracts/src/v2-research-experiment/`. No canonical V1/V2 changes, production changes, V3 code changes, or deployment.  
**Current GitHub `main` observed in this review:** `6d9ac546d856f021d9e597f6e625a134b8ab8bcd` (the V3 framework PR #43 has merged). Codex MUST fetch and recheck before starting.  
**Historical community checkpoint:** `665dbff3054f627e3ebc4e5573334a062fa7ecad`.  
**Status:** PARTIAL; new development must remain experimental.

## 1. Engineering decision

Continue the *existing* opt-in V2 community-economy research. Do not restart or port the curve, rewrite the community router, or build a new V3 as part of this campaign. Integrate a **per-community, independently governed, timelocked treasury vault** as a fixed existing beneficiary on NEW test launches. Reuse the current `CommunityFeeRouterV2` authenticated funding and claim mechanism; do not change its fee ledger. Expand temporal/controller testing and research venue-fee entitlement in parallel. Treat V3's venue/settlement capability design as interface/operating-model research only, not a V2 dependency or accepted architecture.

The business hypothesis is **'Launch a community with a transparent, enforceable economy'**: contributors can receive fees independently; treasury funds follow visible rules; old entitlements survive handoff. The product is not 'ten fee features'. Validate buyer demand with real prospective community founders/traders.

## 2. Exact source-grounded implementation state

`CommunityPolicyRegistryV2` has immutable policy bounds, max 10 allocations, one delayed future policy, epoch history, module categories and an old-epoch source checkpoint before activation. `CommunityFeeRouterV2` is per-launch/per-asset, holds exact-funding liabilities and exposes `claim(amount)` / `claimTo(recipient,amount)` where **msg.sender owns the credited entitlement**. It has no owner rescue. `CommunityControllerV2` has controller/guardian authority, controller epoch, 3-day voluntary transitions, 7-day recovery and an acceptance period; `expire(nonce)` clears old proposals. `CommunityLaunchBuilderV2` is invoked only from the factory and creates controller/router/registry at launch; its `Config.modules[0]` is registry category 2 (treasury). The new vault address should be passed through **new-launch configuration**, without editing factory/curve/router.

Existing fee pipeline (already tested locally): actual curve buy/sell -> F/T fee accrual -> authenticated curve checkpoint -> protocol P to existing escrow -> C to per-launch CommunityFeeRouter -> fixed beneficiary `credit[beneficiary]` -> independent claims. Existing economic sample at F=100bps, T=50bps, protocol share=3000bps yields a **150bps aggregate trader fee**, 30bps protocol and 120bps community on the illustrative gross base; this is an example configuration, NOT a new default. The fee should be measured alongside gas and competitors' actual fee schedules; fee splits alone are not a PMF proof.

Real destination fee entitlement is NOT established: experimental v4 CE registration sets hook community fee/tax to zero and buyback off, with mocked venue destinations; Kuru fee rights remain blocked. Continuous post-graduation revenue must NOT be advertised.

Baseline evidence `research/launchpad/community-economy-v2/QUALIFICATION_REPORT.md` and `evidence/launchpad/community-economy-v2/2026-10-31-authenticated-curve/COMMANDS.md`: scoped 22 tests plus 11 registry tests, three 10,000-case fuzz properties and 256 × 128 stateful calls. Canonical local 64 passed/10 fork skips. Mixed-tree tests had failures including missing RPC and artifact-name collision. Source-only Factory V2 experiment runtime 24,486 bytes, 90-byte headroom. No fork/live financial qualification.

## 3. Ownership and protocol boundary

```mermaid
flowchart TB
  U[Trader] --> C[Experimental Bonding Curve V2]
  C -->|Protocol entitlement P| PE[Existing Fee Escrow]
  C -->|Authenticated community entitlement C| R[CommunityFeeRouterV2 - existing]
  R -->|Independent credit claim| CR[Creator / Contributors / Other Modules]
  R -->|credit[fixed TreasuryVault]| T[CommunityTreasuryVaultV2 - NEW]
  T -->|Claim router credit to itself| T
  S[Community Safe / DAO proposer] -->|Schedule and cancel| L[Qualified TimelockController]
  L -->|Delayed allowed spend| T
  T -->|Actual transfer only| OUT[Approved community spending recipient]
  CP[CommunityControllerV2] -->|Future policy only| P[CommunityPolicyRegistryV2]
  P -->|Old-epoch checkpoint| R
  X[V3 venue/quote capability research - READ ONLY] -.->|Capability vocabulary, no imports| P
```

**Rights separation**: Trader fee source != protocol escrow != community router != vault != controller != guardian != executor != destination DEX. The treasury's *router credit* is an enforceable entitlement; unclaimed credit remains in Router custody. The treasury's physical balance appears only after it calls Router's claim. Donations and unexpected transfers are not fee-derived revenue. A controller/guardian handoff NEVER moves another beneficiary's historical claim or instantly grants treasury spending power.

## 4. Preferred treasury architecture — contingent on dependency qualification

Provisional preferred design: **a restricted per-community `CommunityTreasuryVaultV2` with immutable router/asset binding, spending authorized exclusively by a verified, pinned OpenZeppelin `TimelockController`, whose proposal authority belongs to a community Safe multisig**. The vault provides *narrow* transfer methods, not `execute(address,bytes)` or arbitrary delegatecall. The vault itself calls `router.claimTo(address(this),amount)` (so `msg.sender` at Router is exactly the credited vault), records real receipt deltas, and exposes truthful `claimable`, `claimed`, `donations/surplus` and `spent` read models. Treasury spending decreases its accounted custody only after a successful transfer, and every execution goes through the timelock. For native and ERC20 transfers enforce exact pre/post balance deltas and prohibit draining assets or credit belonging to other launches.

**Dependency gate**: the current vendored OZ subset does not include approved governance/AccessControl/TimelockController code. The agent must inspect dependency provenance, licensing, version, license compatibility, immutable compile hashes, and repository ADR authority. Do not write a custom timelock just because OZ is absent. Do not mutate global dependencies without a scoped decision and before/after regression evidence. Research viable alternatives: (A) Safe -> OZ TimelockController -> restricted Vault; (B) Safe + Zodiac Delay module only if direct owner/modules bypass cannot violate the promised delay; (C) immutable specialized vault if independently justified/audited. Official Zodiac docs explicitly caution that Delay affects *only* transactions routed through the module; Safe owners can bypass. A standalone Safe is NOT an enforced spending timelock.

**Hard question**: OZ TimelockController delay and role config can later be changed via its governance pathway. Decide whether the product promises an immutable minimum delay or a disclosed governance-changeable delay; do NOT falsely promise an immutable delay if privileged future operations can reduce it. Plan liveness if last proposer/executor is lost, cancellation abuse, executor openness and emergency procedure; choose an explicit non-bypassable authority model.

**Constructor/launch compatibility**: treasury recipient is fixed by the existing policy registry at launch. Create NEW launches with a properly deployed treasury vault address in the relevant module slot; do not retrofit existing EOAs or already accrued credits. Confirm actual factory/builder configuration and token/quote compatibility via source, not memory.

## 5. Threat model and financial invariants

Critical safety requirements:

- Router credits only authenticated C; Vault's source of claimed revenue is its own independent credit, not an arbitrary admin transfer.
- `Router.totalFunded == Router.totalPaid + Router.totalLiability` and router physical balance >= liabilities; unrelated recipients remain independent.
- `vault.revenueClaimedFromRouter == vault.revenueSpent + vault.revenueRemaining` **only when** surplus/donations, token behavior and rounding are modeled separately. Physical balance >= accounted unspent revenue; never classify donations as creator fees.
- Any early, canceled, expired, duplicate, stale, wrong-chain or unauthorized treasury spend must revert.
- Admin, guardian, controller, builder and factory cannot bypass the timelock or seize treasury funds after deployment.
- Reentrant recipients and malicious tokens cannot double spend or steal claims; failed transfers revert proposals/transfer effects atomically.
- Partial claims, time boundaries, direct donations, zero-dust, large values, one-unit ERC20 rounding, multi-community isolation and policy/controller transition races are covered.
- No allowed function grants arbitrary allowance or delegates to an external contract; no new trading loop or Factory branch.
- No treasury rights to secured graduation assets, v4 LP NFTs, Kuru LP/MM vault funds, or unrelated contract balances.
- Enforce exact transfer behavior of supported ERC20 and native MON; malicious/fee-on-transfer/rebasing assets fail closed, with evidence.

Important subtleties to test: Router `claimTo` uses `credit[msg.sender]`; vault MUST be caller, so an offchain keeper cannot directly claim its balance to an arbitrary recipient. Controller recovery's waiting period does not freeze current controller's existing policy authority; reproduce schedules and competing proposals. Checkpoint before new policy activates must settle pending old policy fees in the *actual source*, not mock only.

## 6. Phased goal plan (Codex should create numbered iterations)

| Gate | Work | Required output | Stop/go |
|---|---|---|---|
| G0 SOURCE_RECONCILIATION | Fetch latest main, agent control plane, protected paths, 002 evidence; run baseline and build | Current-state matrix, protected SHA map, tool settings | Zero unexplained drift |
| G1 GOVERNANCE_PRIMITIVE_DECISION | Compare OZ+Safe, Safe+Zodiac, custom immutable constraints; audit dependency tree | Treasury ADR candidate and threat/role matrix | No dependency changes without accepted authority |
| G2 TREASURY_ABI_AND_ACCOUNTING | Specify claim, transfer, delay, multisig, cancellation, donated assets, ERC20/native, liveness | Typed interfaces and temporal state machine | All negative paths specified |
| G3 ADDITIVE_VAULT | Create `CommunityTreasuryVaultV2.sol` and new fixtures in V2 experiment; no Factory/Router changes | Real curve -> router -> vault -> timed spend | 100% exact delta and rights tests |
| G4 ADVERSARIAL_CAMPAIGN | 10k fuzz/property and stateful 256×128 where justified, malicious recipients | Foundry/Slither/Semgrep + proof artifacts | No unresolved high/critical issues |
| G5 CONTROLLER_HARDENING | Model guardian/voluntary priority, stale policy, expiry, controller epochs | Temporal test matrix, smallest necessary experimental fix | Old credits never redirected |
| G6 VENUE_FEE_ENTITLEMENT | Qualify v4 LP fee collector under locked custody; Kuru maker/taker / builder rights | Venue-specific rights proof/status; capability matrix | No post-grad fee claim without verified custody/receipt |
| G7 PMF_DISCOVERY | 12–15 founder/trader/contributor interviews, fee matrix tests and gas comparison | Interview script, design-partner pipeline, evidence scoreboard | No fabricated PMF or launch success |
| G8 OPTIONAL_MODULES | Only after G3–G7: staking/rewards, buy/lock/burn, future venue modules | Separate accounting/MEV/price-risk ADR per module | No unfunded reward, reserve access or fake anti-sniping |
| G9 RELEASE_REVIEW | Source-scoped & canonical regressions, fork RPC, gas/size, audit, handoffs | Qualification, remaining blockers, release/no-release | Testnet/mainnet individually gated |

**Priority:** G0 -> G1 -> G2 -> G3 -> G4, with G5/G6/G7 research parallel once baseline is frozen. G8 follows validated customer demand and prerequisite security decisions. No mixed-scope 'feature complete' declarations.

## 7. Cross-lane V3 integration contract — **READ ONLY**

V3 PRs #41/#43 are merged as *research*, and include separate `VenueRegistryV3`, `QuoteVenuePolicyV3`, `LaunchCommitmentHubV3`, `AtomicGraduationEscrowV3`, `IAsyncSettlementV3` and a documented capability manifest. The research CI passed 16 tests and compiler/format checks in its own scope; it did not validate community-fee portability or a real V3 Factory. ADR-024 remains PROPOSED.

In V2 Community Economy research, produce a DOCUMENT ONLY mapping between source-of-fee and settlement class:

| Source / venue | Potential right | Admissible status now | Next proof |
|---|---|---|---|
| Active experimental V2 curve | P+C fee accounting | Local tested | Preserve and extend to treasury |
| New CE Uniswap v4 pool | LP-position swap fees; separate hook fees only if preconfigured | Continuous CE hook route disabled | Prove actual owner, locked-position permissions, zero-liquidity fee collection, exact received token deltas and separate router authorization |
| Kuru order book / MM vault | Maker/taker fees or inventory performance are NOT automatically creator fees | BLOCKED | Upstream version, deployed identity, actual claimable right and receipt |
| HyperEVM-compatible EVM venue | Venue-specific fee rights | FUTURE | Independent chain/venue profile and ERC20 precision |
| HyperCore HIP-1/HIP-2 native | Native deployment, spot and liquidity | FUTURE / ASYNC, no LP-NFT assumption | Native permissions, supply/custody/proof/recovery, separate V3 lane |
| Cross-chain route | Bridge + destination rights | FUTURE / ASYNC | Source/destination conservation, finality and independent proof |

Do NOT copy V3 code into V2, generalize V2 Factory enum/mask or change graduation coordinator as part of treasury work. Write a `FEE_SOURCE_CAPABILITY_CONTRACT.md` as a research specification for future cross-version integrations; no new onchain interface until acceptance.

## 8. Product strategy and experiments

Primary early customer: small-to-mid creator-led crypto communities with 2–10 contributors and a treasury budget. Core customer job: **enforceable split and contributor payout without trust in one creator's wallet**, plus visible governance continuity and post-graduation honesty. Existing Pump.fun already has fee sharing and price-dependent creator fee schedules; differentiation must be demonstrated, not assumed. Public Pump documentation currently shows a bonding-curve total fee of 1.25% for its specified quote pairs, and enforces settling accrued fees before fee-share updates. [Official fees](https://pump.fun/docs/fees) / [Official fee-sharing](https://github.com/pump-fun/pump-public-docs/blob/main/docs/instructions/CREATOR_FEE_SHARING.md).

Research measurable choices between **(A) frozen one-time split, (B) delayed future policy with preserved historical entitlements, and (C) governed treasury**. Track creator configuration completion, second collaborator claim, claim gas vs payout, fee comprehension, treasury proposal success, seven/thirty-day active markets, actual liquidity depth, slippage, and repeat launches. Distinguish real wallets from suspected wash trading where possible; do not claim wallet clustering proves common ownership. Recruit at least 3 true design partners and 12–15 interviews; if no external outreach access exists, create materials and mark outcomes PENDING.

Product disclosure: No guarantee of no sniping, no rugs, buyback execution, yield/APY, automatic token-price support, Kuru creator fees or continuing V4 community-fee sharing. Standard ERC20 token, own risk review and verified contract state still matter.

## 9. Data, SDK and UX interface proposal — **document only**

Write a Fee Matrix and Community Economy Passport read-model spec before frontend edits: `chainId`, `launchId`, `token`, `curve`, `quote`, `communityMode`, `policyEpoch`, `policyHash`, `controllerEpoch`, `beneficiaryBps`, `treasuryVault`, `currentTimelockDelay`, `creditAccrued`, `creditClaimed`, `creditClaimable`, `feeAsset`, `transactionFeeBps`, `protocolSplitBps`, `pendingProposal`, `graduationState`, `graduationVenue`, `postGraduationFeeCapability`, and provenance of fee source. Mark all unimplemented modules disabled. Exact integers/bigints, no float money authority. Backend/indexer only projects proven chain state.

## 10. Artifacts and verification

Use the existing path hierarchy. Next iteration: `research/launchpad/community-economy-v2/iterations/003-treasury-governance-and-custody/` (or repo-standard single manifest if iterations convention requires), plus new immutable evidence directory. Do not overwrite 000–002 evidence or the user's untracked research files. Create current state, options, selected ADR candidate, contracts/tests, threat model, roles, state transitions, accounting examples, quantified performance, controller suite, venue revenue decision, product interview protocol and a revised qualification report.

Baseline reproduction starts with:

```sh
# From repository root
python3 research/launchpad/community-economy-v2/tools/baseline.py --check
python3 -m unittest discover -s research/launchpad/community-economy-v2/tools -p 'test_*.py'

# From contracts (use isolated out/cache + source-scoped compilation)
forge build --contracts src/v2-research-experiment --skip test --skip script --sizes
forge fmt --check
# Reproduce exact source-scoped 002 command from evidence/launchpad/community-economy-v2/2026-10-31-authenticated-curve/COMMANDS.md
# Do not run broad mixed-tree as if it were a clean regression gate.
```

Accepted criteria must include 10k fuzz properties, stateful invariants (256×128 where relevant), independent contract deployment sizes, no artifacts spoofed by same-basename source collisions, static analysis triage, canonical local regression and clearly labeled fork skips. Deployment is forbidden in this campaign. Run target RPC forks only in read-only/test contexts when configured and source verified. All results and failures persist with exact tool versions/seeds/exits.

## 11. Acceptance/outcome decision

**G0/G1 documentation is complete** only if all required authority/custody assumptions are sourced and independently reviewed. **Treasury milestone complete** only if a new community launch routes actual local trade fees into the Router, the pinned vault claims only its own credit, a valid timelocked spend succeeds, invalid spending fails, all other rights survive policy/controller changes, and differential/canonical/protection checks pass. **Production not ready** without upstream venue qualification, audits, deployment and product gates. Never confuse 'merged experimental research' with 'released and financially qualified'.

## 12. External primary research used in this plan

- OpenZeppelin Contracts 5.x access control and TimelockController: https://docs.openzeppelin.com/contracts/5.x/access-control and https://docs.openzeppelin.com/contracts/5.x/api/governance
- Zodiac Delay warning on direct Safe-owner bypass and FIFO queue: https://docs.zodiac.eco/developers/delay
- Uniswap v4 PositionManager collecting fees with zero liquidity change: https://developers.uniswap.org/docs/protocols/v4/guides/position-manager
- Uniswap v4 fee ownership: https://developers.uniswap.org/docs/get-started/concepts/fees
- Pump official fee schedule and fee-share update semantics: https://pump.fun/docs/fees and https://github.com/pump-fun/pump-public-docs/blob/main/docs/instructions/CREATOR_FEE_SHARING.md
- Repo source references: https://github.com/RetroPick/retropick-protocol/tree/main/contracts/src/v2-research-experiment ; https://github.com/RetroPick/retropick-protocol/tree/main/research/launchpad/community-economy-v2 ; https://github.com/RetroPick/retropick-protocol/blob/main/docs/architecture/launchpad/V3_ENGINEERING_LANDSCAPE.md
