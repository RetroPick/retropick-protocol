# Kuru New Assets and Markets — AllInOne Agent Integration Specification
**RetroPick Metropolis 2026 | Draft plan 2026-10-11 | Deadline 2026-10-14 10:59 GMT+7**
**Eligibility:** Onchain Finance & Trading. **Prize:** $5,000 single. **Status:** NOT IMPLEMENTED/NOT PROVEN unless evidence linked below. Read `00-MASTER-PLAN.md` and `09-AGENTS-HANDOFF.md` first.

## Product thesis
Issue and trade fully collateralized binary outcome ERC20 claims, not another unbacked meme token. Do not add a sponsor logo without the sponsor's required working feature.

## Exact integration boundary
Inspect before editing: `contracts/src/v2/RetroPickLaunchFactoryV2.sol`, `contracts/src/v2/GraduationCoordinatorV2.sol`, `contracts/src/v2/KuruGraduationExecutorV2.sol`, `docs/prism/05-hackathon/MVP.md`, `docs/prism/protocol/PRISM_PROTOCOL_SPEC.md`.
Current V2 is live Monad Testnet 10143, Factory→Curve→Coordinator→Kuru; `deployments/monad-testnet/v2.json` is deployment registry. Do not use obsolete Base Sepolia Go/fe-v1 as patch targets. All contract names, methods and sponsor SDK method names MUST be reverified against installed versions; do not invent API signatures.

## Sponsor eligibility and proof gate
**Kuru New Assets and Markets** must deliver the actual integrated feature described below, not a mock. Track Onchain Finance & Trading; prize $5,000 single. Read official bounty wording captured in user portal and recheck at submission. Demo must be on deployed Monad product, with sponsor-specific working evidence. This document is a development specification, not an eligibility certification.

## Architecture and implementation plan
Build a separate isolated PredictionMarket/CompleteSetVault/YES-NO ERC20 prototype with immutable ResolutionSpec and bounded approved resolver; 1 collateral→1 YES+1 NO, merge inverse before resolution, verified winning redemption after resolution; list both ERC20s against verified quote on Kuru Router NO_NATIVE path; seed inventory from SEPARATE liquidity budget, execute real order/fill/cancel; PRISM exact-backed basket only after solvency gate. DO NOT retrofit the existing immutable V2 Factory as though it were an event claim factory.

### Agent execution checklist
1. Freeze baseline: `git rev-parse HEAD`, branch and working tree; inspect source and SDK docs; write version/chain compatibility matrix.
2. Build read-only adapter first with schema validation, typed errors, idempotency key, deadline and explicit supported-network checks.
3. Implement write flow only after simulation/quote checks and signer boundary review; record exact authorization and destination.
4. Integrate behind an independent feature flag and a truthful disabled state. No secret exposed through `NEXT_PUBLIC_*`.
5. Add telemetry for request ID, chain, block, tx hash, status, duration and sanitized failure category; redact sensitive data.
6. Add unit tests, failure/retry tests, real integration smoke and Playwright/browser or CLI E2E.
7. Record sponsor evidence under `evidence/hackathon/metropolis/sponsors/02-sponsor/`; write submission answer only after proof.
8. Disable flag or revert additive integration if test gates fail; never mutate existing V2 deployment or custody.

## State machine and security requirements
Proposed feature state: DISABLED → CHECKING → READY → ACTION_PENDING → CONFIRMED, with BLOCKED, FAILED, EXPIRED and RECOVERY_REQUIRED branches. For transaction-dependent features, distinguish submitted from confirmed and reconciled. Use onchain receipts and supported sponsor APIs as authoritative. BigInt atomic amounts, bounded allowances, chain and contract allowlists, replay/idempotency protection, retry backoff and no unbounded automated trades.

### Mandatory adversarial cases
Wrong oracle; invalid/cancel outcome; premature redemption; double mint; collateral diversion; fee-on-transfer tokens; decimal rounding; liquidity shortfall; unreviewed event-contract legality.

## Tests and acceptance
**Unit:** serialization, decimal/chain validation, stale data, state transition, wrong signature, timeout, replay, failure recovery.
**Integration:** sponsor endpoint/SDK using current pinned version, confirmed contract identity, network compatibility, provider outage.
**Onchain:** receipts and actual contract state changes where required; never represent simulated events as real transactions.
**E2E:** clean browser/profile, mobile when applicable, two-wallet flows when relevant, no inaccessible login.
**Definition of done:** Complete set mint/merge/resolution/redeem receipts; YES and NO Kuru market creation, depth, real fills; invariant/property tests. Attach exact URLs/receipts, commit SHA, SDK versions, commands and outputs; fail closed if unavailable.

## Sponsor demo
Market creation→split→Kuru trade→resolve→redeem, 120 seconds. Sponsor-specific limit is normally <=2 minutes; MetaMask permits <=5 minutes. Do not claim a successful transaction without a receipt.

## Submission response template (fill after evidence)
"RetroPick integrates Kuru New Assets and Markets to issue and trade fully collateralized binary outcome erc20 claims, not another unbacked meme token. The integration operates on Monad Testnet [chainId and verified contract address]. Our implementation uses [exact official SDK/API endpoint, pinned version] in [exact repo paths]. A user can [actual completed action], evidenced by [real tx hash / CLI simulation / GraphQL result]. Safety controls include [verified controls]. Current limitations: [actual limitations]."

## 30/60/90-day expansion
**30 days:** harden integration, run supervised external tester sessions and fix reliability gaps.
**60 days:** security review, observability and user cohort/market-quality analytics; expand only verified supported networks.
**90 days:** gated mainnet-readiness decision, commercial pilots and measured retention; no production release without risk/legal/operational gates.

## Rollback
Disable only this sponsor's feature flag, revert its isolated UI/adapter PR, retain historical proof and deployed contracts; never rollback V2 custody by changing onchain owner or withdrawing locked liquidity.

## Official starting points
https://kuru-testnet-docs.mintlify.site/ and https://docs.kuru.io/


---
## 2026-10-11 verified integration supplement — reuse existing P0 research kernels
**REPO-VERIFIED, not deployed:** `research/contract-kernels/src/hackathon/PredictionFactoryP0.sol` already implements an admissible-market factory and `createMarket(resolver,resolutionSpecHash,yesName,yesSymbol,noName,noSymbol)`; `PredictionMarketP0.sol` and `OutcomeTokenP0.sol` are the native binary-claim kernels; `research/contract-kernels/test/hackathon/PredictionP0.t.sol` includes full-collateral split tests, fee-on-transfer rejection, boundary and adverse callback cases. `research/hackathon-p0/PRISM_P0_SPEC.md` already defines **exact-lot, long-only, in-kind redeemable** structured series. Its explicit exclusions are **final cash settlement**, shared backing reservation vault, and full PRISM production settlement. Never claim those are implemented. See https://github.com/RetroPick/retropick-protocol/tree/main/research/hackathon-p0 and https://github.com/RetroPick/retropick-protocol/tree/main/research/contract-kernels/src/hackathon .

**SOURCE-VERIFIED Kuru:** https://docs.kuru.io/sdk/deploy-market . For *existing* tokens, `ParamCreator` and **Kuru Router** deploy a market. `NO_NATIVE=0` when YES/quote and NO/quote are ERC20/ERC20. `NATIVE_IN_QUOTE=2` for a MON-quoted ERC20 market. The docs expose `ParamCreator.calculatePrecisions` and `deployMarket`, but sample uses **ethers** and demonstrates passing parameters; RetroPick current web uses **viem**. Pin tested version and avoid silent ethers v5/v6 mismatch. Router deployment only instantiates venue — **seed/quote sufficient actual liquidity**, record first trades.

### Implementation reuse plan (do NOT modify existing V2 graduation contracts)
1. Freeze P0 kernel commit, run its OWN Foundry suite and compare to `research/hackathon-p0/PRISM_P0_SPEC.md`; make a requirement-to-contract-function matrix (split, merge, close, resolve, redeem, invalid handling, supply/collateral).
2. Audit `PredictionMarketP0` for who can call close/resolve, what `resolutionSpecHash` commits to and whether a creator can choose a malicious resolver. Restrict demo to curated markets and deterministic test resolution; no misleading public financial claim.
3. Choose a testnet collateral with VERIFIED address, code, decimals and balances. Canonical Circle-USDC live smoke for existing V2 is **BLOCKED_FUNDING**. An arbitrary 6-decimal mock is acceptable for an explicitly labeled P0 prototype, not a claim of Circle/live USDC readiness.
4. Create one factory + market + YES/NO ERC20 pairs on Monad 10143 under a **separate deployment manifest**. Enforce exact invariant: before resolution `YES_supply == NO_supply == collateralLocked` for simple complete sets, and actual vault holdings cover payouts. Verify merge, terminal redemption and refunded invalid markets.
5. For each side, deploy Kuru Router type 0 if quote ERC20, fetch returned market and vault, verify router registration, ABI, decimals, tick, min/max sizes and vault contents. Fund maker inventory and quote from **separate capital**; never re-use claim collateral or existing V2 protected LP.
6. Execute actual YES/quote or NO/quote order/fill/cancel and record price/size/spread/depth. A fabricated probability curve or newly minted token symbol alone does not demonstrate a novel asset class.
7. Only after that, optionally qualify an existing **PrismSeriesP0** exact-backed, 1–4 component basket, with `q % lotSizeRaw == 0` and `B_i >= S*x_i` and a demonstrable in-kind redemption. No speculative State Liquidity Engine or full terminal cash settlement before the deadline.

### Critical financial/market tests
```text
Deposit 100 collateral -> supply 100 YES + 100 NO; vault >= 100.
Merge 30 YES + 30 NO -> release 30 collateral, remaining liabilities 70.
After correct resolution: winners redeem at policy-defined amount, losing outcome cannot claim.
Wrong resolver, double redemption, reentrancy, nonstandard fee-on-transfer collateral,
delayed/invalid event, cancellation, zero supply, max supply, wrong decimals, empty Kuru depth.
PRISM P0: fractional weights exact-lot, component allowlist, no double use of backing;
counterexample AND payoff not representable by long-only basket -> REJECT.
```
Do not infer trading price is a true probability if the YES and NO books are dislocated; bid/ask and executable parity matter.

### Sponsor-winning innovation — **Tradable, redeemable complete sets**
Show BOTH issuance and reversal, *then* Kuru spot execution with a unified payoff/solvency explorer. The asset class is a collateral-backed state-contingent bearer claim, not a rebranded community coin. Measure executable parity opportunity net of spread, gas and fees; always show unavailable fills and non-guaranteed arbitrage. Judges can inspect one claim's full life from collateral→ERC20→Kuru→redemption.
**STOP:** if P0 security/math/execution gates cannot pass, submit honest V2 market-origination infrastructure but acknowledge asset-class novelty risk.
