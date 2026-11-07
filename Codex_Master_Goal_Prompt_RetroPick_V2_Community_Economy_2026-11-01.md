# MASTER EXECUTION PROMPT — RETROPICK V2 COMMUNITY ECONOMY
# 2026-11-01 ARCHITECTURE, SECURITY, PRODUCT RESEARCH & IMPLEMENTATION UPGRADE

**Send this COMPLETE document to Codex.** This addendum extends—not replaces or abridges—the previous 1,177-line V2 Community Economy campaign prompt preserved verbatim in Appendix A. If older text conflicts with this addendum's newer observed SHA, verified repo facts, or explicit stage sequencing, this addendum takes precedence. All unchanged safety restrictions remain binding.

## 0. Mission and instruction priority

Act as Principal Protocol Engineer, Solidity Security Architect, DeFi Market Structure Researcher, Product/PMF Lead, Foundry Qualification Lead and senior Codex execution agent. You are CONTINUING the existing work; do not begin from a blank slate, duplicate fee ledgers, or generate a generic proposal and stop. Carry out research, write and review specs, implement *only* explicitly gated experimental scope, prove via real commands and preserve historical evidence.

The mission is **not** to merge V2 into V3. It is to complete the existing V2 community-economy vertical slice's next production-critical component: a securely governed Community Treasury funded by *actual authenticated V2 curve fees*, with unchanged fees, rights, trading, reserve math, claims, and graduation. Use V3 venue-neutral architecture as READ-ONLY guidance for future portability and fee-capability disclosures; do NOT create or modify V3 code in this campaign. Adopt a product-facing thesis of **'Launch a community with an economy'**: configurable and transparent rights, contributor claims, protected shared funds, governed continuity, honest liquidity and fee-source disclosures. Reject empty feature accumulation.

Mandatory classifications for ALL findings: 
- `CONFIRMED_SOURCE` with exact path/lines/SHA.
- `CONFIRMED_TEST` with exact command, seed, tool version, output and scope.
- `PRIMARY_EXTERNAL_SOURCE` with URL/date/version.
- `PROPOSED` pending ADR and proof.
- `MOCK_ONLY` and `FORK_VERIFIED` are distinct.
- `BLOCKED`, `NOT_RUN`, `REJECTED` are explicit statuses.

Do not promote a proposal to accepted ADR, local test to fork proof, mocked fee stream to revenue entitlement, or main-branch research to production deployment.

## 1. Freshly observed repository state (MUST REVALIDATE)

GitHub: https://github.com/RetroPick/retropick-protocol

At the time of THIS prompt, `main` was observed at:

`6d9ac546d856f021d9e597f6e625a134b8ab8bcd`

This was the merge of V3 research **PR #43**. V3 venue registry **PR #41** is also merged. The previous V2 experiment checkpoint is:

`665dbff3054f627e3ebc4e5573334a062fa7ecad`

The appended original prompt's `6be1e84ccbdd800a0744331b9106021e8a71272b` was a **past** observed main, NOT a current head assertion. `main` may advance again. Start with `git status --short`, current branch/worktrees, `git fetch origin --prune`, `git rev-parse HEAD origin/main`, SHA parity, status of untracked files, merge-base, current agent goal and accepted ADR statuses. Never reset, clean, rebase another active worktree without approval, overwrite untracked research, force push, or silently merge production-affecting financial semantics. If you cannot fetch, mark blocked and do not infer remote parity.

New repository materials that MUST BE READ (READ-ONLY under this campaign):

- `docs/architecture/launchpad/V3_ENGINEERING_LANDSCAPE.md`
- `decisions/ADR-024-modular-venue-registry-and-chain-aware-graduation.md` (**PROPOSED; not release authority**)
- `.agents/skills/retropick-v3-framework-engineering/SKILL.md`
- `.agents/skills/retropick-venue-adapter-engineering/SKILL.md`
- `contracts/src/v3-research-experiment/VenueRegistryV3.sol`
- `contracts/src/v3-research-experiment/framework/LaunchFrameworkTypesV3.sol`
- `contracts/src/v3-research-experiment/framework/QuoteVenuePolicyV3.sol`
- `contracts/src/v3-research-experiment/framework/LaunchCommitmentHubV3.sol`
- `contracts/src/v3-research-experiment/framework/AtomicGraduationEscrowV3.sol`
- `contracts/src/v3-research-experiment/framework/IAsyncSettlementV3.sol`
- `contracts/deployment-profiles/v3-research/`
- `.github/workflows/v3-framework-research.yml`

The V3 research build, formatting and **16 tests** were observed passing under its GitHub Actions scope before merge. This proves only a structural registry/commitment/mock atomic escrow proof; V3 does not deploy actual real tokens/curves, qualify Kuru/Uniswap or give Community Economy fee rights. Do not reuse its mocked receipt as production evidence.

The complete V2 experiment's current source-of-truth is still:

- `contracts/src/v2-research-experiment/CommunityPolicyRegistryV2.sol`
- `contracts/src/v2-research-experiment/CommunityFeeRouterV2.sol`
- `contracts/src/v2-research-experiment/CommunityControllerV2.sol`
- `contracts/src/v2-research-experiment/CommunityLaunchBuilderV2.sol`
- experimental Factory/Curve and UniswapV4Executor as already modified, NOT canonical paths
- `research/launchpad/community-economy-v2/QUALIFICATION_REPORT.md`
- `research/launchpad/community-economy-v2/iterations/002-real-curve-accounting.md`
- `research/launchpad/community-economy-v2/V2_EXPERIMENT_ARCHITECTURE.md`
- `research/launchpad/community-economy-v2/FEE_ACCOUNTING_SPEC.md`
- `research/launchpad/community-economy-v2/INVARIANT_TEST_MAP.md`
- `research/launchpad/community-economy-v2/VENUE_CAPABILITY_MATRIX.md`
- `evidence/launchpad/community-economy-v2/2026-10-31-authenticated-curve/COMMANDS.md`
- `evidence/launchpad/community-economy-v2/2026-10-31-authenticated-curve/result.json`

The repo records scoped 22 experimental tests + 11 registry tests passing, 3 × 10,000 fuzz cases and 256 × 128 = 32,768 stateful handler calls; canonical local 64 PASS / 10 fork skips; full canonical two missing-RPC setup failures; mixed-tree runs with unqualified failures. A reported experimental Factory runtime of **24,486 bytes**, **90 bytes** below standard EIP-170; this number must be remeasured under the exact profile, not copied as fresh evidence. Existing community Treasury is a fixed recipient only, NOT a timelocked vault. No deployed/fork-qualified CE V4 or Kuru community fee stream. No live deployments or broadcasts.

## 2. Final target architecture — finish V2 research without expanding its Factory

```mermaid
flowchart TB
  Trader[Trader] --> Curve[Experimental V2 Bonding Curve]
  Curve -->|P protocol share| Escrow[Existing RetroPickFeeEscrowV2]
  Curve -->|C authenticated community share| Router[Existing per-launch CommunityFeeRouterV2]
  Router -->|credit claims| Benef[Creator and contributors]
  Router -->|credit[TreasuryVault]| Vault[NEW CommunityTreasuryVaultV2]
  Vault -->|Router.claimTo(self,amount)| Router
  Safe[Community Safe multisig / approved proposer] -->|schedule/cancel| Time[Audited pinned TimelockController]
  Time -->|after delay: authorized Vault spend| Vault
  Vault -->|verified native/ERC20 transfers| Recipient[Spending recipient]
  Controller[Existing CommunityControllerV2] -->|bounded future policy| Policy[Existing CommunityPolicyRegistryV2]
  Policy -->|old-epoch source checkpoint before switch| Router
  V3[Separate V3 Venue and Quote Capability Lane] -.->|READ ONLY planning interface| Policy
```

**Source-specific correctness requirements:**

1. `CommunityFeeRouterV2.claimTo(recipient,amount)` uses `credit[msg.sender]`, not an unrestricted treasury-credit claim. The treasury vault must itself CALL the Router; an external keeper can invoke a suitably permissionless vault wrapper, but the Router must see `msg.sender = vault` and the funds must go only to the vault, never to arbitrary third parties.
2. `CommunityLaunchBuilderV2.Config.modules` is an `address[5]`, mapped by the Registry to categories 2–6, with category **2 = treasury**. The treasury address can be pinned in NEW launch configuration using the existing slot if code/interface compatibility is proven. Do not modify Factory/Curve/Router merely for the module address.
3. Community Router remains the ONLY accrued fee-credit ledger; its `totalFunded`, `totalPaid`, `totalLiability` and `credit` states remain authoritative. Treasury keeps a distinct physical-custody/spend ledger, NOT duplicate claims against source fees.
4. Existing `protocol share P` remains in the canonical escrow; only existing authenticated `C` is deposited to Router. No second trader fee, fee-rate change, or claim on LP/grad reserves.
5. Controller only changes **future** policy. Guardian is not an instant treasury spender. Module beneficiaries and old accrued credits cannot be rewritten via controller rotation or future policy activation. Treasury-vault governance must be independently specified; never infer that community controller takeover grants the ability to move existing treasury funds.
6. Real graduation must always sweep source pending fees before securing net assets for graduation. Post-grad Router claims survive even if venue continuing fees are unsupported.
7. No additive branches to experimental Factory (24,486-byte reported runtime). The V3 architecture's venue-neutral Factory is an eventual separately approved lane, not a shortcut in V2.

## 3. Decision recommendation: Timelocked Treasury, restricted custody, deliberate roles

Research three candidate designs in a threat/permission/gas/dependency matrix, then choose and justify one under accepted ADR authorization:

**Candidate A — preferred contingent design:** per-community `CommunityTreasuryVaultV2` with immutable launch/router/asset identity; narrow `claimRouterCredit(amount)` and `spend(asset,to,amount)` only. Only a **pinned, independently qualified OpenZeppelin Contracts 5.x `TimelockController`** can call `spend`. A Community Safe is proposer/canceller; executor configured explicitly (permissionless execution of already-ready operations may be considered). Bootstrap admin must be renounced/secured after validating roles. No unrestricted treasury owner withdraw, admin escape, arbitrary `execute`, delegated external call, open approvals, rescue of accounted funds or mutable router.

**Candidate B:** Safe multisig with Zodiac Delay. IMPORTANT: Zodiac Delay applies to its enabled *module pathway*; direct transactions signed by Safe owners or directly enabled modules can bypass it. It is not sufficient to claim every Safe-owner withdrawal has an enforced delay unless the actual custody authority and bypass paths are independently constrained. Its FIFO queue also creates liveness consequences. Official reference: https://docs.zodiac.eco/developers/delay.

**Candidate C:** custom immutable timelock or privileged module only if pinned/audited dependencies cannot safely satisfy requirements and an accepted governance/security ADR justifies additional custom code. Do NOT invent a new timer solely because local vendored OpenZeppelin lacks `TimelockController`/`AccessControl`.

The provisional product model is **Safe proposer -> qualified timelock -> restricted Treasury Vault**, NOT Safe as direct transferable asset custodian. Timelock roles: proposer, canceller, executor, admin/bootstrap; explicitly test loss of each role, expiration, proposal replay, owner compromise, role revocation, delay updates, and emergency liveness. Clarify that a configurable TimelockController minimum delay can later be changed through timelocked governance; an **immutable** delay claim requires a separate enforceable constraint or honest UI disclosure. Source: https://docs.openzeppelin.com/contracts/5.x/access-control ; https://docs.openzeppelin.com/contracts/5.x/api/governance.

Do a dependency pin/version/license/diff study before updating contracts/lib. Consider isolated vendoring, pinned git submodule/ref or a separately accepted dependency addition. Do not broad-upgrade OZ or use new release code with mismatched solidity/ABI semantics without traceable audit and licensing evidence. If no acceptable implementation can be adopted under repository governance, STOP at `ARCHITECTURE_SELECTED / IMPLEMENTATION_BLOCKED`, preserving full evidence; do NOT fake a qualified timelock.

## 4. Product scope and market-fit guardrails

Customer: creator-led onchain communities with 2–10 contributors, shared operations and a genuine need to account for earned trading fees. Jobs: fair disclosure at creation, independently claimable revenue, durable historic rights, a treasury with reviewable delayed spending, continuity when controller changes. PMF hypothesis, not established user demand. Avoid claiming generic 'creator fee sharing', 'buyback', 'burn', 'staking' as unique—existing launchpads already provide many such features. Stronger hypothesis: **enforceable rights continuity + governed treasury + verifiable fee source across the lifecycle**.

External current primary materials to recheck with dates and versions:
- https://pump.fun/docs/fees (May 2026 official published bonding fee 1.25% total in specified configurations; actual tiers vary post-graduation).
- https://github.com/pump-fun/pump-public-docs/blob/main/docs/instructions/CREATOR_FEE_SHARING.md (creator share updates sweep pending old fees first; distribution rules matter).
- https://developers.uniswap.org/docs/protocols/v4/guides/position-manager (v4 position fee collection through zero-liquidity decrease + TAKE_PAIR, subject to position authority).
- https://developers.uniswap.org/docs/get-started/concepts/fees (LP fees, protocol fees, hook fees are separate concepts).
- https://docs.kuru.io/llms.txt and the pinned onchain Kuru implementation code (DO NOT infer creator entitlement from maker/taker fees or vault inventory).

Existing V2 fee example at base `100bps` + creator tax `50bps` is **150bps effective trader fee**, with `30bps` protocol and `120bps` community in the example. Compare all-in fees *plus gas, slippage and exit liquidity* to competition; this is a configurable example, NOT an automatic production fee level. Check other curves and low-volume economics. Interview 12–15 *real* creators/contributors/traders, seek >=3 credible design partners. Record source-backed interviews rather than invent them. If outreach tools absent, create the questions, scripts, consent notes, qualification worksheet, price/gas objection test and status `FIELD_VALIDATION_PENDING`.

North-star candidate: **qualified community launches with independent claims and active markets at day 30**, supplemented by creator activation, claim/treasury proposal completion, liquidity depth and meaningful repeat use. Do not optimize raw token count or gross wash-traded volume. Creator-facing economic UI = Fee Matrix + Launch Passport displaying real rights, revenue origin, current/previous policy, governance powers, claim gas and venue support. Any promise of 'no rugs', 'anti-sniping', automatic buyback price support, APY, Kuru creator fees or continuous V4 community fees is blocked without specific tests/source proof.

## 5. Two independently managed architecture lanes

**Lane E: Community Economy V2 — THIS campaign, implement now in experiment.**

- `contracts/src/v2-research-experiment/**`
- `contracts/test/v2/research-experiment/**` — add new tests, do not modify the existing passing financial tests to hide failures.
- `research/launchpad/community-economy-v2/**`
- `evidence/launchpad/community-economy-v2/**` — append-only, new distinct evidence run.
- A narrowly scoped candidate treasury ADR under repository decision rules, not an accepted replacement.

**Lane V: Venue-neutral multi-chain framework — READ-ONLY in THIS campaign.**

- `contracts/src/v3-research-experiment/**`
- `contracts/test/v3-research-experiment/**`
- `docs/architecture/launchpad/V3_ENGINEERING_LANDSCAPE.md`
- `decisions/ADR-024-*` proposed
- `contracts/deployment-profiles/v3-research/**`

Do not copy V3 registry/escrow interfaces into V2 or ask a V3 mock executor to generate V2 fee income. Produce *documents only* for a future cross-lane interface contract: venue's fee **origin**, actual entitled owner, collector authorization, destination adapter codehash/version, immutable launch policy, quote asset, payable token, execution class `ATOMIC_EVM | NATIVE_ASYNC | CROSS_CHAIN_ASYNC`, collector timelock/rights and current capability status. Only the real V2 curve has locally tested authenticated community fees. Future chain-specific deployment must not imply uniform fee collection on every venue. HyperCore HIP-1/2 is native multi-step and cannot be treated as an atomic Uniswap LP NFT.

## 6. Goal DAG — execute in dependency order

**G0 — BOOTSTRAP + FROZEN CURRENT-STATE RECONCILIATION (first, cannot skip)**

- Revalidate origin/main and all current worktrees, active goals, local untracked research, decision statuses and submodule revisions.
- Read authoritative agent control plane, full 002 research, failed logs and prior prompt appendix. Read V3 landscape/skills as READ ONLY.
- Reproduce source-scoped V2 experimental fee/claim baseline, canonical separate-source regression, `baseline.py --check`, protected files, exact compiler/ABI sources and real bytecode size. Pin solc 0.8.26 / Cancun / optimizer 200 / viaIR; Foundry and dependency revisions. Do not count previous successes as fresh reruns.
- Write `003/CURRENT_STATE_RECONCILIATION.md` (or repository iteration convention) with explicit done/partial/blocked/contradictory findings, identified gaps, source paths/line numbers, complete scope boundary and risk register.
- **Gate**: if baseline regresses or protected drift exists, diagnose first. Do not proceed with financial changes.

**G1 — TREASURY OPTIONS / GOVERNANCE SECURITY / DEPENDENCY ADR**

- Build source-backed detailed option comparison (OZ + restricted vault; Safe+Zodiac delay; immutable alternative), including exact versions/license/dependency hashes, roles, onchain-enforced delays, bypass pathways, compromised operator, cancellations, upgrades/admin privileges, compatibility, gas and integration with `CommunityFeeRouterV2.claimTo`.
- Specify immutability vs future delay changes, proposer deadlock, open executors, guardian rescue, schedule collision, operation ID salt, expiry/cancel semantics, downgrade/override and pausing.
- Generate threat model (STRIDE-like trust boundaries + DeFi cash-flow abuse), explicit role matrix, state transitions and candidate ADR. Use accepted repo decision process; don't self-approve.
- **Gate**: choose candidate, but block contract coding if imported dependency or governance policy remains unaccepted.

**G2 — TREASURY ACCOUNTING AND ABI CONTRACT**

- Specify `CommunityTreasuryVaultV2` constructor/bindings: immutable router, token, fee asset, chain, timelock; existing module[2] must point at correct Vault at NEW launch inception.
- Define functions for `claimFromRouter(amount)` (Vault -> Router, `claimTo(address(this), amount)`); balance/claim views; `spend(recipient, amount)` restricted timelock; no arbitrary contract calls. Draw actual asset delta diagrams for native and exact-transfer ERC20.
- Model `treasuryRevenueClaimed`, `treasuryRevenueSpent`, `treasuryRevenueHeld`, unexpected donations/surplus and asset-liability reconciliation with exact rounding. No duplicate accrued rights. If `receive()` accepts unsolicited native, classify separately; no owner rescue of accounted revenue.
- Specify events to index, errors, sequence, timelock operation ID, exact deadline behavior, audit trails. Test and pin wrong factory, wrong router, wrong asset, donation, malicious recipient and one-unit dust.
- **Gate**: independent reviewer confirms no spend/fee/bypass ambiguity.

**G3 — MINIMAL ADDITIVE TREASURY IMPLEMENTATION**

- Implement only selected vault, interfaces, and dedicated fixtures under V2 experimental source/tests. Do not edit original Factory, Curve, Router, Registry, Controller or core compiler if integration works through existing `Config.modules` and credit claims. Avoid duplicate splitter/fee ledger.
- Build NEW test launch with vault pinned in category 2, real trades and fees, authenticated settlement, independent other beneficiary claims, vault withdrawal from its own credit, timelock proposal/early revert/execution, exact recipient balance delta, old-right preservation after policy/controller changes, graduation reserve separation.
- Where dependency acceptance is blocked, implement no fake custom timelock; document the blocker and avoid pretending G3 is done.
- **Gate**: no changes in protected paths and complete trace from actual fees to approved transfer.

**G4 — FORMALIZED ADVERSE-CASE QUALIFICATION**

- Fuzz 10k relevant cases for credit conservation, no bypass, partial claims, per-asset math and unauthorized actor behavior; run stateful 256×128 where justified with actual enabled selectors and nonvacuous success counts.
- Test reentrancy (native and ERC20), false-return, fee-on-transfer, externally reducible token, rebase/negative backing, donations, stale/canceled/expired/duplicate timelock, proposer/executor/admin takeover, missing signers, policy checkpoint during claim, two treasuries, wrong community, timestamp edges, precision/overflow, direct transfers and unsupported currencies.
- Run format, source-only build+sizes, invariant/legacy differential, Slither+Semgrep triage, gas benchmark and protector checker; preserve failing traces and seeds. Do not whitelist warnings without explanation.
- **Gate**: no unresolved critical/high defects; no mock-only pass portrayed as production release proof.

**G5 — CONTROLLER/RIGHTS TEMPORAL HARDENING (parallel after G0)**

- Create complete transition table and Foundry tests for 3-day voluntary / 7-day guardian recovery, recovery precedence, expiry, cancellation, controller round trips, guardian compromise, multiple proposals, policy authority epochs, stale pending policy, exact deadline and old credit claims.
- Existing guardian recovery does NOT freeze the current controller automatically. Analyze prospective policy changes during guardian delay, tradeoffs and possible security disclosure. No automatic 'inactive creator takeover' based only on offchain heuristics.
- Do not modify Controller until a reproducer and accepted minimal change are established.

**G6 — VENUE FEE CAPABILITY RESEARCH (parallel documentation, not live payout)**

- Verify actual current Monad supported contracts by deployed address/bytecode, not docs only. Distinguish Uniswap v4 LP-position fees, protocol fees and hook fees; verify position owner, lock, allowance/operator permissions, zero-liquidity decrease collector path, origin of fees and whether collection could unlock LP principal or mutate pool identity. Mocked v4 registration test is not fork qualification.
- For Kuru, verify deployed implementation, fee recipients, maker/taker, MM vault accounting, an authenticated claim right, dependency/approval, recipient contract; if no claim right, keep `BLOCKED_EXTERNAL_CAPABILITY`.
- Do not integrate new graduation venue, alter V3, or add extra Factory conditions. Classify choice: (A) curve-only income; (B) verified collector permitted on NEW venue version; (C) a future venue version required, old untouched.
- Research only HyperEVM/HIP-1/2 capabilities; separate native asynchronous settlement and fee-rights assumptions.

**G7 — PRODUCT / MARKET FIT + FEE MATRIX (parallel after G0)**

- Refresh dated official Pump, Zora, Uniswap, Kuru competitor sources, plus independent onchain studies; preserve evidence provenance (documentation vs onchain counts vs forum anecdote vs interviews).
- Recruit 12–15 interview candidates and >=3 real design partners if tools permit; otherwise publish interview script and contact qualification rubric with pending status. Evaluate willingness to pay/use for governance-delayed treasury vs fee-split-only product, claim gas vs payout, controller succession, trust assumptions and retention.
- Produce full creator Fee Matrix specification with precise BPS denominators, worked native/USDC examples, fee-source claimability disclosure, controller/guardian roles, delay, pending policy, accrued/claimable/claimed and graduation. No frontend edits; provide SDK/indexer events/read-model handoff only.

**G8 — FUTURE MODULE RESEARCH ONLY AFTER G3/G4/G5/G6**

- Independently rank stake-to-earn (funded reward accounting/no-stakers), buy-and-lock, buy-and-burn, buy-and-treasury (credible price oracle, slippage, MEV clip, cooldown, no pool reserve access), vesting (requires issuance economics change), LP reinvestment (LP custody issue). Only implement if real user demand and financial model pass.
- Do not add automatic buyback execution to showcase a prototype. Keep budgets ordinary fixed credits until admissible execution and all checks are accepted. Preserve legacy five-year buyback lock. No guaranteed APY, external business revenue, or broad RWA/private-equity product within this campaign.

**G9 — RELEASE, EVIDENCE AND NON-DESTRUCTIVE INTEGRATION**

- Append iteration `003-treasury-governance-and-custody` + immutable evidence directory. Preserve 000–002 and the original uploaded/untracked research report.
- Produce explicit compiled artifact metadata proof distinguishing same-name canonical vs experimental Contracts; source-scope builds, independent release limits, real compiler profile. Do not rely on artificially enlarged test harness code limit as EIP-170 deployment proof.
- Canonical V1/V2 (and V3 research) protected diffs must be clean. Existing experimental financial math preserved except a separately approved necessity+reproducer.
- Gate results: `RESEARCH_COMPLETE | TREASURY_IMPLEMENTED_LOCAL | EXPERIMENT_QUALIFIED_LOCAL | FORK_QUALIFIED | MAINNET_AUTHORIZED` independently. Do not silently upgrade a status.
- Commit small validated experimental units on isolated branch; prepare PR with evidence. Do not merge unresolved high financial defects or modify canonical production. Respect explicit project policy and ownership for eventually landing experimental research in main. Do not deploy or broadcast.

## 7. Mandatory test design and exact baseline proof

Read `evidence/launchpad/community-economy-v2/2026-10-31-authenticated-curve/COMMANDS.md` IN FULL and use its exact proven commands. At minimum from repo root:

```bash
python3 research/launchpad/community-economy-v2/tools/baseline.py --check
python3 -m unittest discover -s research/launchpad/community-economy-v2/tools -p 'test_*.py'
git diff --check
```

From `contracts/` in fresh distinct `/tmp` output/cache paths and pinned profile:

```bash
forge fmt --check
forge build --contracts src/v2-research-experiment --skip test --skip script --sizes \
  --out /tmp/retropick-ce003-build-out --cache-path /tmp/retropick-ce003-build-cache
FOUNDRY_INVARIANT_RUNS=256 FOUNDRY_INVARIANT_DEPTH=128 forge test \
  --contracts src/v2-research-experiment \
  --match-path 'test/v2/research-experiment/Community*.t.sol' \
  --match-test '^(testCE|testFuzzCE|testLegacy|invariantCE)' \
  --out /tmp/retropick-ce003-test-out --cache-path /tmp/retropick-ce003-test-cache \
  --chain-id 10143 --code-size-limit 1048576 \
  --fuzz-runs 10000 --fuzz-seed 0xce02 -vv
```

**Caution:** These are reference starting commands. Source-scoping and match regex MUST include the new Treasury test contract and correct new test names. The previous dedicated Registry run and canonical reference run must also be reproduced; never use `--match-path` filters to hide failures and never count excluded tests as passed. The artificially enlarged `--code-size-limit` is a test harness allowance only; source artifact sizes must independently meet target chain limits. The 2026-10-31 evidence includes mixed tree false positives and true missing-RPC setup failures; preserve them, explicitly classify, then run full relevant regressions. Record source/input SHA256 and compiler artifact selection to avoid `deployCode` name collision.

## 8. Deliverables — artifacts and naming

Continue existing `research/launchpad/community-economy-v2` structure and append (rather than overwrite):

- `iterations/003-treasury-governance-and-custody/CURRENT_STATE_RECONCILIATION.md`
- `TREASURY_OPTIONS_AND_DEPENDENCIES.md`
- `TREASURY_DECISION_ADR_CANDIDATE.md`
- `TREASURY_THREAT_MODEL.md`
- `TREASURY_ROLE_MATRIX.md`
- `TREASURY_STATE_MACHINE.md`
- `TREASURY_FEE_ACCOUNTING_SPEC.md`
- `CONTROLLER_TEMPORAL_QUALIFICATION.md`
- `VENUE_REVENUE_CAPABILITY_DECISION.md`
- `V2_V3_FEE_CAPABILITY_INTERFACE_RESEARCH.md` (**DOCUMENT ONLY**)
- `PRODUCT_PMF_RESEARCH_PROTOCOL.md`
- `CREATOR_FEE_MATRIX_AND_PASSPORT_SPEC.md`
- `SECURITY_AND_DEPENDENCY_TRIAGE.md`
- `IMPLEMENTATION_CHANGELOG.md`
- `TESTS_FUZZ_INVARIANTS_GAS_SIZES.md`
- `QUALIFICATION_DECISION.md`
- `NEXT_STEPS.md`

The repository already has many equivalents at root. Follow the established naming/conventions or add a dated iteration manifest; do not duplicate an existing canonical artifact if a precise amendment can be made with history retained. Create an immutable evidence folder of machine-readable command metadata, outputs, seeds, source hashes, gas snapshots, solver artifacts, static-analysis reports and optional local fork provenance.

## 9. Source-specific protocol acceptance table

| Financial domain | Baseline guarantee | New required proof |
|---|---|---|
| Fees | P stays escrowed, C goes to router with exact source funding | No extra fee, no redirect or double allocation |
| Claims | `credit[msg.sender]`, independent failure containment | Vault claims ONLY `credit[vault]` and does not drain others |
| Policy epochs | Atomic settlement before new split | Treasury source remains historically stable across changes |
| Controller | Future permissions change, historic credits persist | Guardian, expiry, precedence and stale-policy race coverage |
| Treasury | New recipient is fixed at launch | No withdrawal bypass; verified delay; real native+ERC20 custody |
| Liquidity | Net reserves to coordinator, at most once | No fee/router/treasury claim on secured liquidity/LP principal |
| Venues | v4 CE continuous fees disabled; Kuru blocked | Authenticated external rights, not claimed from volume |
| Factory | Experimental runtime only 90-byte margin historically | Absolutely no treasury-specific Factory growth |
| Multichain | Existing CE is chain 10143 specific | V3 chain/venue portability is future proposal, not V2 deployment |
| Product | Accounting is locally testable, PMF unproven | Real interviews and design partners; transparent fee previews |

## 10. Codex execution contract

Proceed autonomously within this **non-destructive, no-broadcast experimental authorization**, and show concise checkpoints after G0, G1, G2, G3/G4, G5/G6/G7, G9. Do not ask for approvals for routine read-only inspection, source-scoped tests, safe branch creation or evidence collection. **Pause and present a precise decision** only when an accepted ADR, external dependency change, governance design, protected path edit, production deployment, or materially different user-facing economic terms require authority. Do not replace a missing approval with vague assumptions. If blocker exists, continue independent documentation/PMF/test research; never fake successful implementation.

Expected conclusion format:

A. GOAL STATUS (scope-specific COMPLETE / PARTIAL / BLOCKED)
B. CURRENT GIT TRUTH (main/branch SHA, merge-base, dirty files, protected hashes)
C. SOURCE-DERIVED V2/SEPARATE V3 STATUS (and limitations)
D. SELECTED TREASURY PRIMITIVE (dependency provenance, governance authority, bypass/liveness risks)
E. CHANGED FILES & ADR DECISION STATUS
F. REAL FEE/ROUTER/TREASURY FLOW (native/ERC20 before/after exact balance figures)
G. FINANCIAL SECURITY (threat model, adversarial reproductions, critical/high triage)
H. TEST EVIDENCE (unit, fuzz cases, handler calls, fork skips/failures, source selector, logs)
I. GAS/BYTECODE (compiler settings, runtime/initcode, 90-byte Factory headroom protected)
J. CONTROLLER RECOVERY & HISTORIC RIGHTS
K. VENUE FEE CAPABILITY & V3 BOUNDARY (Uniswap V4/Kuru/HyperCore claims explicitly verified or blocked)
L. PMF / DESIGN-PARTNER RESEARCH (actual vs pending, customer evidence)
M. SDK/INDEXER/FEE MATRIX HANDOFF (documentation only)
N. RELEASE GO/NO-GO (experimental local, fork, testnet, mainnet independently)
O. NEXT PRIORITIZED GOAL (specific PR-sized implementation work and blockers)

**Primary exit condition:** a newly launched experimental V2 community has a fixed treasury beneficiary address; real curve trades fund authenticated Router credits; the restricted Vault claims only its credit; an independently qualified timelock is proven to delay authorized spending; transfers reconcile to physical native/approved ERC20 balances; controller/guardian and policy changes preserve every previously earned right; protected V1/V2/V3 paths stay untouched. If dependency/ADR gates prevent that outcome, return rigorously qualified PARTIAL/BLOCKED status rather than writing a substitute custom timelock.

**Absolute invariant: DO NOT BREAK WHAT ALREADY WORKS.**

---

# APPENDIX A — USER'S PRIOR MASTER V2 COMMUNITY ECONOMY PROMPT (PRESERVED UNABRIDGED)

The complete previously supplied prompt follows. Older observed Git SHAs and dates are historical. All safety, test, product and delivery instructions not explicitly updated above remain in effect. The new introductory addendum supplies current repo status, a more concrete custody design and sequencing, and a strictly read-only V3 compatibility lens.

---
# EXECUTE — RETROPICK V2 COMMUNITY ECONOMY
# NON-BREAKING RESEARCH, SECURITY, ARCHITECTURE & DEVELOPMENT CAMPAIGN

## ROLE

You are my Principal Smart Contract Engineer, Protocol Security Architect, Solidity Researcher, DeFi Mechanism Designer, Product Manager, Product-Market-Fit Researcher, Foundry Testing Engineer, and Codex Development Lead.

You own the engineering execution for the existing RetroPick V2 Community Economy research campaign.

Your task is to continue research and implementation from the latest verified state, preserving all previously completed work.

Act as a rigorous engineer. Challenge assumptions, establish source truth, write precise specifications, implement incrementally, and validate financial correctness.

Do not stop after producing a generic architecture document.

Do not restart the campaign from scratch.

Do not create unnecessary duplicate contracts.

**ABSOLUTE PRIORITY: DO NOT BREAK THE EXISTING PROTOCOL.**

---

# 0. VERIFIED REPOSITORY CONTEXT

Repository:

https://github.com/RetroPick/retropick-protocol

Previously qualified V2 Community Economy research checkpoint:

`665dbff3054f627e3ebc4e5573334a062fa7ecad`

Latest remotely observed main:

`6be1e84ccbdd800a0744331b9106021e8a71272b`

The latest main includes a separate proposed V3 venue-neutral research campaign.

Recheck origin/main before doing any work. The remote may advance again.

Do not assume a historical SHA is still the latest.

## Relevant paths

Canonical V1:

`contracts/src/v1/`

Canonical V2:

`contracts/src/v2/`

V2 Community Economy experiment:

`contracts/src/v2-research-experiment/`

V2 experimental tests:

`contracts/test/v2/research-experiment/`

V2 research documents:

`research/launchpad/community-economy-v2/`

V2 execution evidence:

`evidence/launchpad/community-economy-v2/`

Separate V3 venue experiment:

`contracts/src/v3-research-experiment/`

V3 research ADR:

`decisions/ADR-024-modular-venue-registry-and-chain-aware-graduation.md`

V3 venue skill:

`.agents/skills/retropick-venue-adapter-engineering/SKILL.md`

### Scope separation

This campaign concerns V2 Community Economy.

The V3 research campaign is a separate engineering lane.

You may read V3 research to understand future venue capabilities, but MUST NOT modify V3 files, rewrite ADR-024, change chain architecture, or merge its unqualified assumptions into V2 without separate accepted authority.

ADR-024 is PROPOSED, not accepted production architecture.

---

# 1. ABSOLUTE NON-BREAKING RULES

These rules override any desire to complete features rapidly.

## Protected production paths

DO NOT modify:

- `contracts/src/v1/**`
- `contracts/src/v2/**`
- `contracts/src/v3-research-experiment/**`
- `contracts/test/v3-research-experiment/**`
- Existing production deployment scripts
- Existing deployed contract manifests
- Original V2 unit/integration/invariant tests
- Historical qualification evidence
- Accepted ADRs
- Production ABIs
- Production frontend and indexer consumers
- PRISM contracts
- Other unrelated application modules

Do not alter any deployed contract identity.

Do not change live token supply, fee rates, custody, graduation thresholds, economic formulas, or liquidity mechanics.

Do not deploy or broadcast any transaction.

Do not execute wallet operations or privileged onchain administration.

Do not touch production environment variables or private keys.

Do not modify existing user research reports or untracked files.

## Existing experimental financial behavior must also be preserved

Treat the verified V2 experimental contracts as a behavioral baseline.

In particular, preserve:

- Actual bonding-curve trading.
- Constant-product reserve mathematics.
- Protocol fee entitlement.
- Authenticated community fee collection.
- Router liability conservation.
- Recipient independent claims.
- Old-policy rights preservation.
- Policy activation checkpoint semantics.
- Controller generation checks.
- Legacy mode equivalence.
- Native MON and supported exact-transfer ERC-20 behavior.
- No double graduation.
- No unauthorized recovery of escrowed funds.

Before changing any existing experimental financial contract, prove that the change is necessary.

Prefer additive contracts and adapters rather than editing existing core contracts.

Do not change `CommunityFeeRouterV2`, `CommunityPolicyRegistryV2`, or experimental Factory/Curve merely to simplify another feature.

## Git safety

1. Inspect local branch, worktrees, remotes and dirty files.
2. Fetch latest remote main.
3. Identify the exact common ancestor and current changes.
4. Work in a separate safe branch/worktree.
5. Preserve all existing uncommitted files.
6. Never use destructive `git reset --hard`, `git clean`, force push, or blind overwriting.
7. Do not silently drop another developer's changes.
8. Do not automatically cherry-pick conflicting financial code.
9. Commit small, validated changes only.
10. Verify full protected-path integrity before integration.

If the main branch advances during this campaign, reconcile it non-destructively.

The desired eventual delivery destination is `origin/main`, but merging experimental research does not promote it to production.

Do not merge unresolved critical/high financial defects as qualified milestones.

---

# 2. REQUIRED BOOTSTRAP

Read the repository agent instructions in their authoritative order.

Start with:

- `AGENT_GUIDE.md`
- `AGENTS.md`
- `.agent/STATE.json`
- `.agent/CURRENT_GOAL.md`
- `.agent/ROUTING.md`
- `contracts/AGENTS.md`
- Relevant steering and accepted ADR files
- `docs/launchpad/PROTOCOL.md`
- `docs/launchpad/INVARIANTS.md`
- `docs/launchpad/FEES_AND_ECONOMICS.md`
- `docs/launchpad/GRADUATION.md`
- Existing development/security/testing guidelines

Continue the existing research workflow.

Read:

- `research/launchpad/community-economy-v2/README.md`
- `EXECUTIVE_DECISION.md`
- `NEXT_STEPS.md`
- `QUALIFICATION_REPORT.md`
- `SECURITY_FINDINGS.md`
- `FEE_ACCOUNTING_SPEC.md`
- `SOURCE_TRUTH_MATRIX.md`
- `ADVERSARIAL_GRILL.md`
- `FEATURE_PRIORITY_MATRIX.md`
- `PRODUCT_DEMAND_EVIDENCE.md`
- `VENUE_CAPABILITY_MATRIX.md`
- `V2_EXPERIMENT_ARCHITECTURE.md`
- `INVARIANT_TEST_MAP.md`
- `MIGRATION_AND_COMPATIBILITY.md`
- Existing iteration manifests 000–002
- Historical evidence and test logs

Read the uploaded/repository-preserved Deep Research report.

Treat research claims as hypotheses until confirmed by primary sources.

Reconcile historical milestone descriptions with the current source. Some older NEXT_STEPS sections remain historical rather than current.

Never delete historical evidence to make reporting cleaner.

---

# 3. EXISTING VERIFIED DEVELOPMENT

The V2 experiment already implements:

- `CommunityPolicyRegistryV2`
- `CommunityFeeRouterV2`
- `CommunityLaunchBuilderV2`
- `CommunityControllerV2`
- Experimental Factory community-launch mode
- Experimental Curve fee routing/checkpointing
- Independent per-recipient claims
- Experimental Uniswap v4 registration with unsupported CE fee paths disabled

Previously captured results:

- 22 curve/integration tests passed.
- 11 separate Registry tests passed.
- Three fuzz properties ran 10,000 cases each.
- Stateful accounting ran 256 × 128 = 32,768 handler calls.
- Canonical local reference: 64 passed, 10 skips.
- Separate full canonical reference retained missing-RPC setup failures.
- Broad mixed-tree run was not a clean PASS.
- No fork qualification.
- No deployment.
- No external audit.

Reported experimental runtime sizes:

- Registry: 5,679 bytes.
- Router: 6,487 bytes.
- Controller: 1,494 bytes.
- Launch Builder: 19,332 bytes.
- Factory: 24,486 bytes.
- Curve: 13,805 bytes.

The Factory is only 90 bytes under the 24,576-byte EIP-170 runtime limit.

Do not treat these historic measurements as current without reproducing the exact compiler profile.

## Bytecode rule

Do not add features to the Factory unless an unavoidable, explicitly justified, independently qualified change is required.

Prefer isolated helper contracts.

Never increase Foundry's harness size limit and then treat that as deployability proof.

---

# 4. PRIMARY PRODUCT GOAL

RetroPick should enable creators to launch communities with transparent, enforceable economics.

Target positioning:

"Launch a community with an economy."

But avoid becoming a launchpad with twenty features and no validated users.

The first valuable customer is a creator-led community with multiple contributors, seeking:

1. Transparent fee splits.
2. Enforceable recipient claims.
3. Protected community treasury.
4. Immutable fee bounds.
5. Predictable controller succession.
6. Tradable ERC-20 liquidity.
7. Accurate economic disclosure.

Do not prioritize passive holder yield, automatic burn, complex governance or external-business revenue over these needs without evidence.

## Product-market-fit research

Update existing competitor and user-demand research.

Investigate:

- Pump.fun creator fee sharing.
- Pump.fun holder rewards.
- Zora creator economics.
- Community takeovers.
- Contributor payment agreements.
- Trading fee transparency.
- Launch survivability.
- Liquidity/exit expectations.
- Creator onboarding friction.
- Creator and contributor payout friction.

Distinguish:

- Actual observed demand.
- Platform marketing claims.
- Independent onchain usage.
- Reddit anecdotes.
- Interviews.
- Engineering inference.

Do not fabricate interviews or adoption metrics.

Prepare a 12–15 interview research protocol for creator-led communities, contributor teams and active traders. If real interviews cannot be performed, provide interview materials and mark field validation PENDING.

## Product KPIs

Define measurement for:

- Qualified creator activation.
- Community launches completed.
- Beneficiaries successfully claiming.
- Treasury funding.
- 7-day and 30-day token trading activity.
- Graduation rate.
- Genuine versus suspected inorganic volume.
- Creator retention.
- Community treasury spending.
- User transaction failure rate.
- Time to first successful claim.
- Effective gas cost of claims.
- Trading slippage.
- Continued activity after graduation.

Do not equate cumulative volume with product-market fit.

---

# 5. GOAL G0 — CURRENT SOURCE AND SECURITY FREEZE

Before building, reproduce the existing successful campaign.

Pin:

- Git SHA.
- Solidity compiler.
- Optimizer runs.
- via-IR configuration.
- EVM version.
- Dependency revisions.
- Foundry version.
- Runtime bytecode hashes.
- ABI hashes.
- Test counts and seeds.
- Protected-source hashes.

Use the existing source-scoped Foundry approach to avoid canonical/experimental basename collisions.

Run the baseline protection checker:

`python3 research/launchpad/community-economy-v2/tools/baseline.py --check`

Reproduce existing relevant tests.

Preserve missing-RPC and skip results without representing them as passes.

If the baseline no longer passes, investigate the regression before implementing anything new.

### Acceptance

Existing V2 research functionality still behaves as previously qualified.

Canonical V1/V2 and separate V3 research remain unchanged.

No new feature implementation until baseline parity is established.

---

# 6. GOAL G1 — TREASURY SECURITY RESEARCH

Research the correct treasury custody model for RetroPick.

The current router can credit a fixed treasury beneficiary, but a recipient address is not automatically a safely governed treasury.

The current repository has a constrained vendored OpenZeppelin dependency subset that does not contain all intended governance and access-control contracts.

Do not write a custom unaudited timelock simply to bypass that dependency issue.

Compare:

### Option A — OpenZeppelin TimelockController + restricted Treasury Vault

Evaluate pinned dependency availability, integration cost, role configuration and audit history.

### Option B — Safe multisig + explicitly verified spending timelock

Evaluate onchain enforcement, owner thresholds, transaction review, upgrade/admin exposure and executable testability.

### Option C — Immutable dedicated treasury custody module

Only consider if the needed delayed spending and authorization guarantees can be provided with justified, separately reviewed code.

### Design assessment

For every option analyze:

- Dependency provenance.
- Licenses.
- Verified source.
- Pinned revisions.
- Attack surface.
- Administrator permissions.
- Proposal permissions.
- Cancellation rights.
- Execution rights.
- Delay enforcement.
- Recovery policy.
- Storage safety.
- Native/ERC-20 support.
- Gas.
- Bytecode.
- Failure modes.
- Operational simplicity.

Select one.

If the selected implementation requires adding or changing vendored dependencies, document the exact affected files and candidate ADR.

Do not alter the existing dependency tree without the repository's required authorization.

---

# 7. GOAL G2 — TREASURY ARCHITECTURE

Proposed module:

`CommunityTreasuryVaultV2`

Experimental location:

`contracts/src/v2-research-experiment/`

The Treasury is a fixed beneficiary in the Community Constitution.

It must receive only its own allocation of legitimately collected fees.

It cannot seize creator, contributor, holder, protocol, LP or buyback entitlements.

## Financial boundary

Existing fee flow:

Trader
→ Experimental Bonding Curve
→ Protocol entitlement to existing escrow
→ Community entitlement to authenticated Router
→ Fixed beneficiary credit

Treasury extension:

Router treasury credit
→ Treasury claims its own credit
→ Treasury physically receives supported asset
→ Timelocked approved spending
→ External recipient

The Treasury must not acquire a right to call other beneficiaries' claims.

The Treasury must not become the Factory owner.

The Treasury must not control the Router's source authentication.

The Treasury must not modify immutable fee policy bounds.

## Required custody invariants

- Treasury can claim only its own Router credit.
- The entire withdrawal process is independently authorized.
- Every privileged transfer respects the declared timelock.
- No owner/guardian can bypass spending delays.
- External callbacks cannot double-withdraw.
- No arbitrary delegatecall.
- No unconstrained external calls as a bypass.
- No arbitrary ERC-20 allowance granting.
- No withdrawal from another community.
- No access to protected graduation reserves.
- Direct donations do not automatically become trading revenue.
- Failed destination transfers revert without consuming the proposal.
- A canceled action cannot be executed.
- An executed action cannot be replayed.
- Expired actions follow explicit lifecycle rules.
- Treasury remains usable after owner/controller changes.
- Supported asset balances reconcile before and after claims/spending.

## Critical deployment constraint

The current Registry pins module addresses at launch.

Do not replace a previously pinned EOA treasury beneficiary on an existing community launch as though it were dynamically upgradeable.

For the first experiment, create NEW test launches with the qualified Treasury Vault address pinned as the treasury beneficiary.

No retroactive migration of existing funded entitlements.

Do not introduce proxy upgradeability unless accepted governance explicitly requires it.

## Treasury contract interface

Specify before coding:

- Deposits/claims from Router.
- Treasury balances per asset.
- Spending proposals.
- Scheduling.
- Cancellation.
- Timelock execution.
- Proposal nonce.
- Expiry behavior.
- Proposer/executor permissions.
- Multisig/administrator configuration.
- Events.
- Historical auditability.

Prefer narrow spend functions over generic arbitrary external execution.

Document privilege boundaries using a role/capability matrix.

---

# 8. GOAL G3 — IMPLEMENTATION

Implement only the selected treasury architecture, its dedicated interfaces and its tests.

Use the existing V2 experiment directory.

Do not edit the canonical Factory, Curve, Hook, Coordinator, or Router.

If integration can be completed through the Registry's existing fixed beneficiary mechanism and the Router's claim API, use that.

Do not introduce a second fee router.

Do not duplicate claim ledgers unnecessarily.

Do not implement a second bonding curve.

Do not modify the ERC-20 transfer function.

Do not change existing launch/graduation state machines.

Use a new, additive experimental test fixture for a community launched with Treasury Vault custody.

Build the complete treasury funding path with actual experimental trading fees.

### Required integration scenario

1. Deploy experimental V2 environment.
2. Deploy qualified Treasury Vault.
3. Configure Registry with Treasury Vault as beneficiary.
4. Create new community launch.
5. Execute real bonding-curve trades.
6. Accrue actual fees.
7. Settle through authenticated Router.
8. Verify existing protocol and community fee splits.
9. Verify Treasury receives only its allocated claim.
10. Claim from Router into Treasury custody.
11. Schedule a permitted treasury expenditure.
12. Attempt early execution; it must revert.
13. Advance past the minimum delay.
14. Execute permitted expenditure.
15. Verify exact recipient balance increase and Treasury decrease.
16. Verify every unrelated recipient credit remains unchanged.
17. Verify no effect on bonded reserves or graduation custody.
18. Verify existing Registry/Router tests remain green.

Use both native and admitted exact-transfer ERC-20 scenarios where supported.

---

# 9. GOAL G4 — ADVERSARIAL TESTING

Test the Treasury under realistic adversarial actions.

Required cases:

- Unauthorized proposer.
- Unauthorized executor.
- Unauthorized canceler.
- Early execution.
- Exact timelock boundary.
- Expired proposal.
- Duplicate execution.
- Proposal replay.
- Changed controller.
- Compromised proposer simulation.
- Guardian recovery.
- Two concurrent proposals.
- Canceled proposal reuse.
- Reentrancy on native transfer.
- Reentrant ERC-20.
- False-return token.
- Fee-on-transfer token.
- Negative balance changes.
- Unexpected token donations.
- Zero amount.
- Dust amount.
- Large amount.
- Insufficient balance.
- Partial Router claims.
- Beneficiary claim failure.
- Wrong asset.
- Cross-community caller.
- Cross-community asset use.
- Direct unauthorized asset transfer.
- Compromised admin attempting immediate payout.
- Treasury called during policy activation.
- Treasury called during graduation.
- Treasury operator unavailable.

## Invariants

Write handler-based tests for:

- Funding.
- Claiming.
- Scheduling.
- Cancellation.
- Execution.
- Controller rotation.
- Policy activation.
- Direct donation.
- Invalid/unauthorized calls.

Assert:

`treasury funded funds = treasury paid + treasury held liabilities`, with donations and external surplus accounted for separately.

Assert that no other beneficiary's Router credit is touched.

Assert that active treasury proposals cannot bypass the immutable delay.

Assert that already accrued entitlements remain unchanged by controller transitions.

## Verification campaign

Run:

- Formatting.
- Build.
- Unit tests.
- At least 10,000 relevant fuzz cases for critical accounting/authorization properties.
- Stateful invariants, targeting 256 runs × 128 depth where justified.
- Relevant legacy differential tests.
- Existing Community Economy suite.
- Protected-path regression tests.
- Gas report.
- Runtime and initcode size checks.
- Static analysis.
- Targeted source review by an independent reviewer.

Record exact commands, tool versions, seeds, pass/fail/skip counts and hashes.

Do not describe mock tests as forks.

Do not describe agent review as an external audit.

A test suite with 0 failures does not automatically prove solvency or release readiness.

---

# 10. GOAL G5 — CONTROLLER HARDENING

The existing `CommunityControllerV2` supports:

- Three-day voluntary handoff.
- Seven-day guardian recovery.
- Acceptance period.
- Controller generation.
- Expiry cleanup.

Do not rewrite it without evidence.

Extend tests to cover:

- Voluntary versus guardian proposal precedence.
- Replacement during a pending proposal.
- Expired guardian proposal.
- Old controller recovering control after expiry.
- Controller round trips.
- Stale policy proposals.
- Acceptance at exact time boundary.
- Cancellation at exact boundary.
- Unauthorized cancellation.
- Guardian key compromise model.
- No loss of historical Router credits.
- No arbitrary takeover.
- No transfer of vested rights without explicit entitlement.

Produce a formal state-transition table before modifying code.

Where a liveness or safety defect is found, implement the minimal experimental fix with a reproducer.

Do not add arbitrary emergency takeover capability.

---

# 11. GOAL G6 — GRADUATION ECONOMICS RESEARCH

This is a parallel research decision, not permission to change production graduation logic.

## Current source truth

The experimental Community Economy launch currently selects Uniswap v4.

The experimental Uniswap v4 executor disables unsupported continuing community hook fees for that launch.

Kuru community fee entitlement is not verified.

The separate V3 venue-registry research does not prove a new venue integration works.

## Research questions

Determine:

1. Which destination venues are actually available on Monad?
2. What fees exist after graduation?
3. Who legally/protocol-wise owns those fees?
4. Who physically receives them?
5. Can RetroPick claim them?
6. Can a Community Economy contract claim them?
7. What interface performs collection?
8. Does collecting them compromise LP custody?
9. Can the revenue continue without privileged operators?
10. Does the model remain viable when volume is low?
11. Can fee rights be established without changing already deployed pools?
12. Which venue supports a new version of this model?

For Kuru, verify actual upstream implementation and the deployed target version.

Do not infer fee entitlement from trading volume, market-maker inventory, or locked LP ownership.

For Uniswap v4, research a separately qualified pool/hook-based collection path without mutating an existing pool identity.

Read ADR-024 and the V3 venue engineering skill before proposing venue architecture changes, but keep any V3 implementation in its separately authorized research lane.

Do not copy V3 registry components into V2.

## Required decision

Choose and justify one:

A. Community economics is launch-stage only.

B. Supported post-graduation venue fees are collectable and can be authenticated.

C. New venue/version required; existing V2 remains unchanged.

Mark all unavailable sources BLOCKED.

Do not promise perpetual fee income until it is technically proven.

---

# 12. GOAL G7 — FUTURE OPTIONAL ECONOMIC MODULES

After Treasury qualification and controller hardening, research and implement modules in descending business value.

## Stake-to-Earn

Use actual collected quote-asset fees.

Do not claim passive rewards for all holders if only stakers participate.

Model:

- Stake principal.
- Reward accumulator.
- Reward debt.
- New reward deposits.
- Reward periods.
- Empty staking periods.
- Late staking.
- Unstaking.
- Precision rounding.
- Reward funding.
- Underlying token custody.
- Claim gas.
- Economic viability at low volume.

No promised APY.

Do not build until the underlying reward-liability model is proven.

## Buyback Strategy

Preserve existing legacy five-year buyback-and-lock behavior.

For Community Economy, research separate opt-in strategies:

- Buy and lock.
- Buy and burn.
- Buy and hold in treasury.

Require:

- Authenticated funding.
- Budget isolation.
- Price reference quality.
- Maximum clip.
- Cooldown.
- Minimum output.
- MEV threat model.
- No protected reserve spending.
- Zero-output and failed-execution handling.
- Independent strategy custody.

Do not enable automatic swaps merely to demonstrate a feature.

If the price reference is untrustworthy, keep execution disabled and preserve the budget's beneficiary.

## Creator vesting

Do not silently change supply allocation away from the existing bonding curve.

Vesting requires a distinct opt-in launch economic design and differential tests.

## LP reinvestment

Do not implement without proven LP ownership, venue permissions, withdrawal limits and price/MEV rules.

## External business revenue

Remain out of scope.

Do not introduce dividend/profit-share promises into ordinary community-token trading mechanics.

---

# 13. PRODUCT DEVELOPMENT — FEE MATRIX

Prepare an implementation-ready specification for a creator-facing Fee Matrix.

Do not edit the production frontend in this campaign.

The intended UI should explain:

- Total fee paid by trader.
- Protocol share.
- Creator share.
- Contributor share.
- Treasury share.
- Holder/staker allocation.
- Buyback budget.
- Liquidity budget.
- Beneficiary wallet addresses.
- Immutable limits.
- Pending policy changes.
- Timelock countdown.
- Controller and guardian powers.
- Actual accrued claims.
- Claimed versus unclaimed fees.
- Graduation venue.
- Whether post-graduation community fees are supported.
- Risks and unsupported guarantees.

Create clear economic presets:

- Creator Economy.
- Contributor Economy.
- Community Treasury Economy.
- Staker Rewards Economy, only after rewards qualify.

Presets must not imply that unimplemented strategies already function.

Provide SDK/indexer event contracts and read models as documentation only.

A future frontend task can integrate them after ABI and economic qualification.

---

# 14. PERFORMANCE AND SIZE CONTROL

Do not expand experimental Factory runtime.

Its historical size was 24,486 bytes under the captured compilation profile.

There is minimal headroom.

Any new deployment logic must be placed in a narrowly scoped helper.

Avoid expensive on-trade loops.

Bound recipient counts.

Benchmark long policy histories.

Benchmark maximum configured beneficiaries.

Measure:

- Launch deployment gas.
- Router settlement.
- Individual claims.
- Treasury claim.
- Treasury proposal.
- Treasury execution.
- Controller transition.
- Policy activation.
- Graduation.

Do not report gas estimates based on reverted calls as the expected successful cost.

Every runtime must independently satisfy deployment limits.

---

# 15. CI AND DEPENDENCY HEALTH

Investigate GitHub dependency alerts.

Classify findings by:

- Package.
- Version.
- Advisory.
- Reachability.
- Runtime versus development dependency.
- Relevant contract impact.
- Available patched version.
- Upgrade compatibility.
- Tests required.

Do not broadly update dependencies without justification.

Do not run automated dependency upgrades that silently alter Solidity bytecode.

Pin any newly required OpenZeppelin dependencies.

Preserve the current verified build profile.

Create a scoped CI workflow proposal if the existing workflow does not cover the experiment.

Do not break unrelated workflows.

CI should clearly distinguish:

- Experimental-source unit tests.
- Canonical V2 tests.
- Fork-dependent tests.
- Protected-path checks.
- Runtime size qualification.
- Static analysis.
- Unavailable dependencies.

Missing RPC must be recorded as NOT RUN or SKIPPED, never PASS.

---

# 16. RESEARCH AND EVIDENCE PACKAGE

Continue using:

`research/launchpad/community-economy-v2/`

Add numbered iterations without overwriting older findings.

Suggested next iteration:

`003-treasury-governance-and-custody`

Required outputs:

- CURRENT_STATE_RECONCILIATION.md
- TREASURY_OPTIONS.md
- TREASURY_THREAT_MODEL.md
- TREASURY_ACCOUNTING_SPEC.md
- TREASURY_ROLE_MATRIX.md
- TREASURY_STATE_MACHINE.md
- CONTROLLER_RECOVERY_QUALIFICATION.md
- VENUE_REVENUE_DECISION.md
- DEPENDENCY_SECURITY_TRIAGE.md
- PMF_VALIDATION_PLAN.md
- FEE_MATRIX_PRODUCT_SPEC.md
- IMPLEMENTATION_CHANGELOG.md
- TEST_AND_INVARIANT_RESULTS.md
- UPDATED_QUALIFICATION_REPORT.md
- NEXT_STEPS.md

Follow existing repository document conventions.

Update existing files instead of duplicating equivalent research artifacts.

Keep actual command logs and machine-readable results in a new immutable evidence directory.

Preserve previous unsuccessful runs and counterexamples.

For every finding distinguish:

CONFIRMED_SOURCE

CONFIRMED_TEST

PROPOSED

MOCK_ONLY

FORK_VERIFIED

BLOCKED

REJECTED

Never inflate the evidence classification.

---

# 17. ACCEPTANCE GATES

## Gate A — Baseline protection

All existing experiment and relevant canonical tests retain their prior validated behavior.

No protected file changes.

## Gate B — Treasury architecture

Dependencies and authority model approved under existing repository decision rules.

No unaudited custom governance primitive substituted for missing dependencies.

## Gate C — Treasury implementation

Real Router-funded Treasury receives only its legitimate allocation.

Timelocked spending enforced.

No administrative bypass.

## Gate D — Financial invariants

Every claim and expenditure reconciles to real custody.

No double claims, theft, replay or cross-community leakage.

## Gate E — Security

Required unit/fuzz/invariant tests pass.

Critical and high findings resolved or explicitly block qualification.

## Gate F — Graduation

Existing graduation behavior remains unchanged.

New revenue assumptions are not silently introduced.

## Gate G — Performance

Deployable bytecode size passes.

Gas behavior is bounded and documented.

## Gate H — Product fit

Creator and trader jobs clearly defined.

Unvalidated benefits marked as hypotheses.

No unqualified feature advertised as available.

## Gate I — Delivery

Evidence committed.

Protected paths checked.

No deployment.

No production promotion.

---

# 18. DELIVERY STRATEGY

The founder's previous preference is to integrate validated experimental research into main.

This does not authorize production deployment or modification of canonical V2.

During work:

- Use an isolated branch/worktree.
- Commit individual validated milestones.
- Preserve complete evidence.
- Do not overwrite unrelated changes.
- Recheck current origin/main.
- Run regression and protected-path checks.
- Integrate using non-destructive Git operations.
- Never force-push.
- Verify remote parity after an authorized push.

If dependencies or high-severity financial risks block a milestone, keep the unqualified implementation isolated with explicit evidence and do not falsely classify it as a completed release.

Do not auto-merge accepted economics or modify accepted ADRs.

---

# 19. REQUIRED FINAL REPORT

Provide:

A. GOAL STATUS — COMPLETE / PARTIAL / BLOCKED.

B. GIT STATE — branch, exact commit, remote SHA, changed paths, protected paths.

C. EXISTING SYSTEM PROTECTION — what was preserved, with regression evidence.

D. RESEARCH — product demand, competitor findings and engineering decisions.

E. ARCHITECTURE — selected Treasury implementation, dependency rationale and trust boundaries.

F. IMPLEMENTATION — all new/changed contracts and interfaces.

G. ACCOUNTING — real funding, claims, spending and liability conservation.

H. SECURITY — adversarial findings, exact tests, fuzz counts, invariant coverage and static analysis.

I. PERFORMANCE — gas and bytecode sizes, comparison with baseline.

J. VENUE DECISION — Kuru/V4 capability, fork status and remaining revenue blockers.

K. PRODUCT READINESS — what can truthfully be shown to creators.

L. NEXT MILESTONE — the next validated engineering task and prerequisites.

Do not say DONE unless the completed scope is precisely identified.

---

# 20. EXECUTE

Continue the existing RetroPick V2 Community Economy development campaign immediately.

Do not restart the project.

Do not rewrite working financial modules.

Do not create V3.

Do not modify production.

Do not deploy.

Begin by reconciling the current main with the V2 financial baseline and preserving the separate V3 research lane.

Then perform Treasury architecture research and adversarial design.

Implement the minimal qualified Treasury custody module when dependencies and design gates permit.

Build real funding/claim/spending integration tests.

Complete controller recovery test expansion and venue revenue research.

Preserve all previous economic guarantees.

Continue into the later economic modules only after the prerequisite security gates are satisfied.

**Primary success criterion: a functioning, secure, transparently governed Community Treasury funded by real RetroPick V2 fees, without any regression to existing trading, fee routing, beneficiary claims or graduation.**

**DO NOT BREAK WHAT ALREADY WORKS.**
