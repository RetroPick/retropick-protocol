# Frontend Write Allowlist — SECURITY_AGENT Decision Document (H3)

Campaign: `RETROPICK-V2-FULLSTACK-INTEGRATION` — Phase 3 gate `FRONTEND_WRITE_SECURITY`.
Author: SECURITY_AGENT (SMART_CONTRACT_SECURITY: `smart-contract-security` + `evm-security`).
Chain: Monad Testnet 10143. Deployed source pin `f0363249f4b74e58dde37d1241742ca5a92bcfe3` (verified: the only
contracts/src/v2 diff since the pin is formatting in `RetroPickBuybackVaultV2.sol` — import wrap + constructor line
wrap, no semantic change). Kuru pinned source `/tmp/retropick-kuru-contracts/contracts/{OrderBook,MarginAccount}.sol`.

Inputs reviewed: `abi-capabilities.json` (`frontendWrites`, 20 entries), `packages/launchpad-sdk/src/{prepare,wallet,decode,registry,model,math,chain,abi,release,kuru}.ts`,
`contracts/src/v2/**`, pinned Kuru source, `apps/abi/*` (via `@retropick/abi/abi`), `docs/contracts/V2_APPLICATION_CAPABILITY_MAP.md` §5.

Verdict summary: **17 APPROVED, 3 APPROVED-WITH-CONDITIONS, 0 REJECTED** (of 20 candidates; one surface amendment:
`GraduationCoordinatorV2.complete(address)` added alongside `factory.createGraduatedPool`). 8 SDK conditions
(C-1..C-8) must be cleared by SDK_AGENT before Phase 5 gates; none block on-chain safety — every condition is either
an SDK-side wrong precondition (contract still fails closed) or missing coverage of an approved surface.

---

## 1. Max-payable / approval matrix (binding for SDK tx engine)

| # | Write | msg.value rule (source-verified) | ERC20 approvals required |
|---|---|---|---|
| 1 | factory `launchToken(…,uint8 venue)` | `== launchFee()` **exactly** (`LaunchFeeNotPaid`, factory sol:706) | none (fee is native regardless of quote venue) |
| 2 | factory `launchToken(…,address[])` | `== launchFee()` exactly | none |
| 3 | curve `buy` | native quote: `== quoteIn` **exactly** (`NativeValueMismatch`, curve sol:584); ERC20 quote: `== 0` (`UnexpectedNativeValue`, sol:588) | ERC20 quote only: `pairToken → curve` for `quoteIn` (exact-delta transfer enforced, sol:596-601) |
| 4 | curve `sell` | `== 0` (nonpayable) | launch token `→ curve` for `tokensIn` (transferFrom, sol:480) |
| 5 | factory `graduate` | `== 0` | none |
| 6 | factory `createGraduatedPool` / coordinator `complete` | `== 0` | none (coordinator self-approves exact amounts, coordinator sol:217-223) |
| 7 | margin `deposit(address,address,uint256)` | token `== 0x0`: `== amount` **exactly** (`NativeAssetMismatch`, MarginAccount sol:220); ERC20: `== 0` (sol:223) | ERC20 only: `token → MarginAccount 0xd029C2D98ff85D8F64799017fE00a59B1159CE02` |
| 8 | margin `withdraw(uint256,address)` | `== 0` | none |
| 9 | margin `batchWithdrawMaxTokens(address[])` | `== 0` | none |
| 10 | OrderBook `addBuyOrder` | `== 0` (funds pre-deposited in margin) | none |
| 11 | OrderBook `addSellOrder` | `== 0` | none |
| 12/13 | OrderBook `batchCancelOrders[NoRevert]` | `== 0` | none |
| 14 | OrderBook `placeAndExecuteMarketBuy` | **margin path (SDK): `== 0`** (`NativeAssetNotRequired`, OrderBook sol:750). Non-margin native path (NOT exposed): msg.value in exact bracket `[cost(q), cost(q+1))` with `cost(x)=x·10^quoteDec/pricePrecision` floor (sol:742-748) | non-margin ERC20 only: `quote → market` (NOT exposed) |
| 15 | OrderBook `placeAndExecuteMarketSell` | `== 0` on NATIVE_IN_QUOTE markets (sol:802; native leg is buy-side only) | non-margin only: `base → market` (NOT exposed) |
| 16 | FeeEscrow `claim()` | `== 0` | none |
| 17 | FeeEscrow `claimToken(address)` | `== 0` | none |
| 18 | BuybackVault `release(address)` | `== 0` | none (vault self-approves escrow, vault sol:205) |
| 19/20 | token / quote-asset `approve(address,uint256)` | `== 0` | n/a — IS the approval; spender must be ∈ {per-launch curve, MarginAccount} |

**Hard rule for the tx engine:** a prepared write whose `value` deviates from this matrix must never be signed. The
native "exact" rules (1, 3-native, 7-native) are `!=` reverts on-chain, not refunds — the matrix is a signing gate,
not only a convenience.

---

## 2. Per-candidate verification and verdicts

### W-1 `RetroPickLaunchFactoryV2.launchToken(TokenParams,uint256,address,uint8)` — APPROVED

- Caller/target: connected wallet → factory `0xa7f18b9eceb0A9852b08408854A45D00fc682454`.
- Access control: `canLaunch(msg.sender) = launchEnabled || whitelistedLaunchers[msg.sender]` (factory sol:497-499, enforced sol:705). SDK checks it live (`registry.ts:73`).
- Asset movement: native launch fee → `memeHook.protocolFeeRecipient()` only (factory sol:1083-1092); token + curve deployed; **no bundled opening buy exists anywhere in the flow** (verified: `_launchToken` deploys, registers, pays fee — no buy call; H2's finding that the UI's opening-buy control is UNSUPPORTED stands).
- Max payable: `msg.value == launchFee()` exactly (sol:706). SDK: `value: preconditions.launchFee` read fresh (prepare.ts:119).
- Gates replicated by SDK: config exists/enabled, `creatorTaxBps ≤ maxCreatorTaxBps` (sol:709 → prepare.ts:82), admitted quote per venue via `quoteRegistry.admitted(pairToken, venue)` (sol:713 → prepare.ts:86 checks the per-venue admitted candidate list).
- Economics pin: SDK reads `previewVenueEconomics(id, pairToken, venue)` fresh and always pins a non-zero `expectedEconomics` (prepare.ts:69-77,112) — strictly better than the contract's optional pin (sol:722-724 reverts `LaunchEconomicsMismatch` on drift). Condition C-7 notes the SDK's combined-fee pre-check covers only the `curveFeeBps` leg.
- Salt: `randomSalt()` uses `crypto.getRandomValues(32B)` (prepare.ts:38-42). CREATE2 namespace is per initiating account; reuse on identical terms reverts at deploy (retry with a fresh salt is the documented recovery). No vanity grinding required. Confirmed from factory TokenParams.salt doc (sol:143-154).
- Overload correctness: args `[params, launchConfigId, pairToken, venue]` with `venue: 0|1` (`VENUE.KURU = 1` matches `enum GraduationVenue { UNISWAP_V4=0, KURU=1 }`) resolve viem to the uint8 venue overload, selector `0x41c0731e` (H1 cast-verified).
- Events: `TokenLaunched`. Errors: NotWhitelisted, LaunchFeeNotPaid, InvalidLaunchConfigId, LaunchConfigDisabled, InvalidTokenParams, CreatorTaxTooHigh, CombinedFeeTooHigh, CurveNotQuotable, LaunchEconomicsMismatch, GraduationExecutorNotSet, LaunchDeployerNotSet, LaunchDependenciesNotWired, UnsupportedQuote (registry), MetadataTooLong (deployer) — all present in decode ABI set.
- Retry: revert = nothing persisted; on tx-drop, same salt resends safely unless landed (then deploy collision → new salt).

### W-2 `launchToken(TokenParams,uint256,address,address[] snipeTaxExemptions)` — APPROVED-WITH-CONDITIONS (DEFERRED — not exposed in v1)

- Source-verified: UNISWAP_V4 venue is hardcoded in this overload (factory sol:648-656) — it cannot launch KURU-venue tokens; exemption list capped at 32 (`ExemptionListTooLong`, sol:682).
- The RetroPick app launches via the venue overload (W-1). No SDK prepare exists and none is required for v1 screens. **Condition:** do NOT wire this overload into the create form unless/until a UNISWAP_V4 venue path + explicit exemption-list UX exists; exposing exemptions without UI copy explaining the declared-bundle semantics would be a user-harm surface, not a security hole (exemptions are public on-chain and bounded).

### W-3 `RetroPickBondingCurveV2.buy(uint256,uint256,address)` — APPROVED

- Target resolved authoritatively from `coordinator.packet(token)` (model.ts:8-16 rejects non-V2 tokens). Demo curve `0x454A…E276`.
- Value rules: native `msg.value == quoteIn` exactly; ERC20 `msg.value == 0` + approve — verified at curve sol:582-603 (`_receiveQuote`).
- SDK minOutput math verified against contract: fee-then-CFM order matches (contract sol:404-407 computes `fee` and `tax` on the input, then `getAmountOut(net, quoteReserveBefore, tokenReserveBefore)`; SDK `buyQuote` math.ts:6-10 is identical floor arithmetic on identical reserves `getReserves()` = `(phantomQuote + trackedQuote − feeBal − taxBal, trackedTokens)`). Remaining-cap semantics: contract clamps `tokensOut` to `sellable = trackedTokens − reservedTokens` and reprices `spent` (sol:409-422); SDK caps at `launch.remaining = sellableTokens()` (same expression, curve sol:278-281). Both conservative and consistent.
- Slippage: contract enforces the **price bound** `spent·minTokensOut ≤ received·tokensOut` (sol:427), which reduces to `tokensOut ≥ minTokensOut` when unclamped. SDK `minTokensOut = expected·(10000−50)/10000` provably passes every legitimate clamped fill (marginal price at clamp ≥ average price at `received`), so no over-conservative reverts.
- Phase check: `Number(launch.ledger.phase) !== 0` fails closed (prepare.ts:138) — matches `GraduationState.NONE=0`; contract independently re-checks `graduated` twice (sol:388,398).
- Native/ERC20 branch: prepare.ts:144-169 (balance check per branch, value/approval per matrix). Approve target is the curve itself (transferFrom to curve).
- Events: `CurveBuy`, `CurveBuyRefunded` (partial-fill refund), `CurveCompleted` + `GraduationSecured`/`AutoGraduationFailed` when the buy crosses completion. Retry: safe after revert; a buy may atomically graduate — re-read curve state on success (SDK model does).
- Note (informational): the curve's anti-snipe surfaces are inert in the deployed source (`exemptFromSnipeTax` is an onlyFactory no-op stub, curve sol:861-865), so SDK quoting with only `feeBps`+`creatorTaxBps` is exact — no hidden launch-window tax to model.

### W-4 `RetroPickBondingCurveV2.sell(uint256,uint256,address)` — APPROVED

- Value `== 0` (nonpayable); token `approve → curve` for exact `tokensIn`.
- SDK math matches contract sell exactly: `gross = CFM(tokensIn, tokenRes, quoteRes)` then `net = gross − floor(gross·fee) − floor(gross·tax)` (contract sol:482-486; SDK sellQuote math.ts:11-14).
- Gating: contract blocks sells once `graduated || readyToGraduate()` (sol:474) — i.e. `sellableTokens()==0`; the SDK's phase check plus `tokensIn > remaining` guard (prepare.ts:182-185) is strictly more conservative than the contract (the contract allows a sell larger than the current sellable window while sellable > 0). Acceptable; keep.
- `minQuoteOut` bounds the net quote leg (sol:487 `SlippageExceeded`). Retry on `CurveGraduated` → route user to venue trading (post-graduation).

### W-5 `RetroPickLaunchFactoryV2.graduate(address)` — APPROVED-WITH-CONDITIONS (C-1)

- Access: **permissionless** (no gating modifier; factory sol:1019-1029). One-at-a-time global: `_securingToken != 0 → WrongGraduationPhase` (sol:1022) — concurrent graduations serialize.
- Chain of enforcement: factory.graduate → coordinator.secure (onlyFactory; requires ledger phase `NONE`, `!curve.graduated()`, `curve.readyToGraduate()`, reserves within ceiling — coordinator sol:178-204) → factory.secureCurve callback → `curve.graduate(coordinator)` which reverts `NotReadyToGraduate` unless `readyToGraduate()` (curve sol:535). `readyToGraduate() ⇔ sellableTokens() == 0` (curve sol:352-355).
- **Condition C-1 (defect, prepare.ts:218-220):** the SDK's precondition `quoteReserve ≥ completionQuote().terminalQuote` is not the binding condition. `getReserves().quoteReserve` includes `phantomQuote` while `terminalQuote` is a real-quote figure, so the check passes whenever `remaining > 0` but the completion buy costs ≤ phantomQuote — producing a deterministic on-chain `NotReadyToGraduate` revert (fail-closed, no fund risk, but a broken graduation UX and a mislabeled `checks[]` receipt). Correct check: `launch.remaining === 0n` (sellableTokens) or read `curve.readyToGraduate()`. SDK_AGENT must fix before Phase 5.
- Asset movement: curve tradeable reserves → coordinator custody (exact handoff verified, coordinator sol:193-197). Events: `GraduationSecured`. Retry: safe until phase flips to GRADUATING; wrong-phase (`WrongGraduationPhase` from one-at-a-time) → retry shortly.

### W-6 `factory.createGraduatedPool(address)` / `GraduationCoordinatorV2.complete(address)` — APPROVED (surface amendment)

- `factory.createGraduatedPool` is a thin permissionless wrapper: exists-check + `coordinator.complete(token)` (factory sol:1058-1062). `coordinator.complete` is itself **public and permissionless** (no onlyFactory; coordinator sol:206-250) — verified recovery path for BOTH venues (dispatches to the packet's venue executor with exact-allowance handoff and full receipt validation).
- SDK implements `prepareCoordinatorComplete` → `coordinator.complete` (prepare.ts:235-249) with the correct phase gate (`ledger.phase == 1` = GRADUATING). This is approved as an equivalent, equally-safe surface; the allowlist records both. abi-capabilities.json should gain a `frontendWrites` entry for `GraduationCoordinatorV2.complete(address)` (see §5).
- Preconditions: phase GRADUATING; stays GRADUATING until success → transient-failure retry is the recovery policy; validation errors (`InvalidPacket`, `InvalidReceipt`, `BackingDeficit`, `EnvironmentDrift`, `GraduationSeedNotViable`, `SqrtPriceOutOfBounds`) are report-don't-retry.
- Events: `GraduationCompleted` (+ `PoolGraduated` on V4 venue; Kuru venue emits no PoolGraduated — UI must anchor venue discovery on `GraduationCompleted.destinationIdentity`/receipt).

### W-7 `MarginAccount.deposit(address,address,uint256)` — APPROVED (condition C-2)

- Value rules verified (MarginAccount sol:217-229): native token `0x0` → `msg.value == amount` exact; ERC20 → `msg.value == 0` + `transferFrom(msgSender, margin)`. SDK prepare.ts:324-351 matches (branch, balance check, approval to `0xd029C2D9…`).
- Gating: `protocolActive` (not paused). `_user` may differ from caller — **condition C-2:** the app must always pass the connected account as `_user`; crediting third-party margin accounts from the UI is out of scope and must not be exposed.

### W-8 `MarginAccount.withdraw(uint256,address)` — APPROVED

- Own-balance only (`_msgSender()` keyed, sol:236-246); arg order `(amount, token)` matches ABI/SDK (prepare.ts:367-377). Nonpayable. Errors: InsufficientBalance, ProtocolPaused.

### W-9 `MarginAccount.batchWithdrawMaxTokens(address[])` — APPROVED (condition C-3: add SDK prepare)

- Sweeps the caller's balances per token list (sol:195-209). Idempotent. No prepare function exists in prepare.ts — SDK_AGENT adds one (portfolio sweep screen) or the portfolio screen falls back to per-token W-8.

### W-10 `OrderBook.addBuyOrder(uint32,uint96,bool)` — APPROVED

- Grid validation verified (OrderBook sol:183-208): `0 < price < type(uint32).max`, `price % tickSize == 0`, `minSize ≤ size ≤ maxSize`. SDK replicates all three (prepare.ts:393-397) after `priceToUnits` snapping (buy snaps down to tick, away from crossing) and `sizeToUnits` exact-divisibility (prepare.ts:278-299).
- Funding: margin quote debit only (`_consumeFunds → marginAccount.debitUser`, sol:458-460); nonpayable. Margin-balance precondition (SDK prepare.ts:398-403) uses `quoteCostBuy = ceil(priceUnits·sizeUnits·10^quoteDec / pricePrecision)`, which is provably ≥ the contract's two-stage debit `floor(ceil(p·s/sizePrecision)·10^quoteDec/pricePrecision)` for all `sizePrecision ≥ 1` — conservative by construction. Aggressive fills at better prices only consume less; per-price-level rounding dust (≤ 1 grid unit per level) can in principle exceed the estimate by dust in a deeply-tiered immediate fill — contract still fails closed on `InsufficientBalance`; informational only.
- postOnly semantics: reverts `PostOnlyError` if any fill occurs on placement (sol:195-197). Order ids: only `OrderCreated` logs carry ids; fully-consumed placements emit nothing (early return sol:198-199) — decode.ts:57-66 rule (ids from logs, never counters) is correct and must be preserved.

### W-11 `OrderBook.addSellOrder(uint32,uint96,bool)` — APPROVED

- Same grid rules (sol:254-278); base debit `floor(size·10^baseDec/sizePrecision)` — SDK's exact-divisibility requirement makes debit == `sizeRaw` exactly, and the margin-base precondition (prepare.ts:404-408) is exact.

### W-12 `OrderBook.batchCancelOrdersNoRevert(uint40[])` — APPROVED (preferred cancel)

- Idempotent by construction (sol:493-505; zero entries in `OrdersCanceled` = not cancelled). Owner-checked per order (`OnlyOwnerAllowedError`), non-flip only (`WrongOrderTypeCancel`), `marketNotHardPaused`.

### W-13 `OrderBook.batchCancelOrders(uint40[])` — APPROVED (condition C-4)

- Strict variant reverts the whole batch on a stale id (sol:480-486, `OrderAlreadyFilledOrCancelled`). SDK `prepareKuruCancel` (prepare.ts:464-477) uses this. **Condition C-4:** switch default to the NoRevert variant (W-12) or implement the documented fallback (on `OrderAlreadyFilledOrCancelled`, re-prepare with NoRevert); ids must continue to come only from confirmed `OrderCreated` logs for the same market.

### W-14 `OrderBook.placeAndExecuteMarketBuy(uint96,uint256,bool,bool)` — APPROVED (margin path only)

- SDK always uses `isMargin=true, isFillOrKill=true` (prepare.ts:454) → `msg.value == 0` (`NativeAssetNotRequired`, sol:750), quote debited from margin (`debitUser`, sol:751-752) at `floor(quoteUnits·10^quoteDec/pricePrecision)`; SDK's `quoteToUnits` floor round-trip guarantees debit ≤ user-input quote.
- `_minAmountOut` semantics verified: net base tokens received (post taker fee), compared at sol:777 (`SlippageExceeded`); `isFillOrKill` reverts `InsufficientLiquidity` on partial (sol:763-764); unfilled remainder auto-refunded to margin (sol:770-772).
- The non-margin native bracket (`[cost(q), cost(q+1))` exact, sol:742-748) is deliberately NOT exposed — the app routes all Kuru trading through margin. Market type confirmed: RetroPick Kuru graduations deploy `OrderBookType` 2 = NATIVE_IN_QUOTE for MON-native launches (`router.deployProxy(p.quoteAsset == address(0) ? 2 : 0, …)`, KuruGraduationExecutorV2 sol:172-185).

### W-15 `OrderBook.placeAndExecuteMarketSell(uint96,uint256,bool,bool)` — APPROVED (margin path only)

- Margin base debit exact (SDK exact-divisibility); `msg.value == 0` on NATIVE_IN_QUOTE markets (sol:802); `_minAmountOut` bounds net quote credited (sol:826). Same isMargin/isFillOrKill pinning as W-14.

### W-16 `RetroPickFeeEscrowV2.claim()` — APPROVED (condition C-6)

- Verified: no-arg `claim()` pays the caller's **entire** native credit `balanceOf[msg.sender]` (escrow sol:63-66 → `_claimNative`, sol:83-94 with full-liability backing check). Nonpayable; permissionless to the beneficiary.
- SDK `prepareFeeClaim` (prepare.ts:484-498) prechecks `readFeeEscrowCredit` and targets `claim()` — correct.
- **Condition C-6 (defect, decode.ts:77):** `decodeEscrowClaim` listens for `['FeesClaimed','Claimed','TokenFeesClaimed']` — none exist; the deployed escrow emits `NativeClaimed` / `TokenClaimed` (escrow sol:24-25; confirmed present in the deployed ABI artifacts). Claim receipts currently decode to nothing. SDK_AGENT fixes the event-name list.

### W-17 `RetroPickFeeEscrowV2.claimToken(address)` — APPROVED (condition C-5)

- Verified: no-arg-amount variant claims the caller's full per-token credit (escrow sol:73-76) with exact-delta transfer checks. **Condition C-5:** this is the mandatory second leg of the buyback flow — `BuybackVault.release` pays out as escrow **token credit** (vault sol:205-207), so without an SDK prepare for `claimToken(token)` released vested buyback tokens are stranded in the UI. No prepare exists today; SDK_AGENT adds `prepareFeeClaimToken` (claims screen).

### W-18 `RetroPickBuybackVaultV2.release(address)` — APPROVED

- Authorization verified: `msg.sender` must equal `vestingTerms(token).creatorRecipient` **or** `.protocolRecipient` (`NotVestBeneficiary`, vault sol:184-188) — the creator fee recipient of the launch, not "anyone". SDK prechecks `releasable(token) > 0` (prepare.ts:501-503; vault sol:268-271 includes previewed newly-vested).
- Payout path: vested launch tokens are credited to FeeEscrow token balances split creator/protocol (vault sol:196-207); the user then claims via W-17. No-op (returns 0, no revert) when nothing newly vested.
- Event: `Released(token, creatorAmount, protocolAmount)` — decode.ts:80-82 correct.
- Note: `_requireTokenBacking` on claim can revert `PhysicalBalanceDeficit` if the escrow is under-backed — user-facing error, report (no user remedy; protocol-level).

### W-19 `RetroPickLauncherTokenV2.approve(address,uint256)` — APPROVED (condition C-8)

- Allowance grant only. **Condition C-8:** spender must be restricted to the per-launch curve (sell flow) or the Kuru MarginAccount (base deposit flow). The SDK approval pipeline (prepare.ts:19,169,197,338 + `missingApprovals`) already emits only these two spenders — keep it that way; no free-form spender may ever enter an approval from the UI.

### W-20 `ERC20MetadataInterface.approve(address,uint256)` (USDC / ERC20 quote) — APPROVED (condition C-8)

- Same restriction, spender = the launch's curve (ERC20-quote buys). The pipeline uses the shared `tokenAbi` `approve` fragment — standard ERC20, valid for USDC. Exact-amount approvals only (current pipeline behavior); note USDC is a blocklistable fiat token — a blocked-address transfer revert surfaces as a plain RPC error.

---

## 3. EXPLICIT EXCLUSION LIST (forbidden surfaces — enforce in SDK + frontend)

Verified absent from `prepare.ts` and from every `PreparedWrite` this allowlist sanctions; must remain absent:

1. **All owner/admin/config ops** across the catalog: factory `addLaunchConfig`/`updateLaunchConfig`/`setLaunchFee`/`setLaunchEnabled`/`setWhitelistedLauncher`/`setMaxCreatorTaxBps`/`setSnipeTax*`/`setLaunchForwarder`/`setLaunchDeployer`/`configureVenueExecutor`/`transferOwnership`/`acceptOwnership`; coordinator `bindFactory`/`configureExecutor`; registry `configure`; curve `setCreatorFeeRecipient`/`setBuybackEnabled` (onlyFactory); vault `setFactory`/`updateCreatorRecipient`; OrderBook `toggleMarket`/`updateVaultOrdSz`/`transferOwnership`; MarginAccount `toggleProtocolState`/`setFeeCollector`/`updateMarkets`; Kuru Router `toggleMarkets`/`upgrade*`/`transferOwnership*`. Reason: owner-gated protocol authority; a UI path to these is a direct compromise surface.
2. **`launchTokenFor`** — forwarder-only (`NotLaunchForwarder`, factory sol:665-675). Never user-callable; also the atomic launch-and-buy router's entry.
3. **Curve `sweepFees`/`rescueFees`/`exemptFromSnipeTax`**; factory `secureCurve`/`rescueCurveFees`/`rescueSweptGraduation` — operator/owner/internal trust paths (fee routing and graduation unwedging are protocol-operated).
4. **Coordinator `secure`/`registerLaunch`/`configureExecutor`** — onlyFactory.
5. **All executor `execute`/`verifyReceipt`/`validateLaunch`** — coordinator-called only.
6. **Hook admin/sweeps** (`RetroPickMemeHookV2` internals), **locker/vault protocol internals** (`RetroPickLaunchLockerV2`, `KuruLiquidityLockV2`), **BuybackVault `lock`** (curve/hook-called only).
7. **Permit2 / PoolManager / PositionManager — everything.** The user path uses plain ERC20 approvals; V4 positions are minted by the graduation flow, never by the user.
8. **Kuru MM primitives**: `addFlipBuyOrder`/`addFlipSellOrder`/`addPairedLiquidity`/`batchAddPairedLiquidity`/`batchProvisionLiquidity`/`batchUpdate`, `collectFees`, Router `anyToAnySwap` (future candidate only), KuruAMMVault `deposit`/`mint`/`withdraw`/`permit`.
9. **MarginAccount market-credit ops** (`debitUser`/`creditUser`/`creditUsersEncoded`/`creditFee`) — verified-market-only.
10. **Proxy/upgrade surface on anything** (`initialize`, `upgradeToAndCall`, `proxiableUUID`, ownership handovers).
11. **Token `burn`/`burnFrom`**; **WETH wrap/unwrap**.
12. **Non-margin market-order legs** (`isMargin=false` on W-14/W-15, incl. the native msg.value bracket and quote/base approve-to-market) — out of v1 scope by design (all Kuru trading is margin-funded).

---

## 4. SDK write-boundary audit (prepare.ts / wallet.ts / decode.ts)

**Wallet layer (wallet.ts) — PASS.** EIP-1193 only: `eth_requestAccounts`, `eth_chainId`, `wallet_switchEthereumChain`, `wallet_addEthereumChain` (+ EIP-6963 discovery events). No key material, no `personal_sign`/`eth_signTypedData`/raw `eth_sendTransaction`, no arbitrary method passthrough. Signing happens in the wallet via viem `custom` transport.

**bigint exactness — PASS.** All financial values (value, quoteIn, tokensIn, launchFee, amounts, minOuts, grid math) are `bigint` end-to-end; `Number()` appears only for enum/grid coercions: `ledger.phase` (prepare.ts:138,182,210,237), `priceUnits`→uint32 after an explicit `< 2^32` bound check (prepare.ts:298,414), order-id `uint40`s (prepare.ts:464), decimals (registry.ts:51-52). `parseExact` (math.ts:18-24) rejects excess precision rather than rounding a signed amount.

**No forbidden surface in prepare.ts — PASS.** Full-file review: the only targets produced are factory(`launchToken`,`graduate`), coordinator(`complete`), per-launch curve(`buy`,`sell`), MarginAccount(`deposit`,`withdraw`), per-launch market(`addBuyOrder`,`addSellOrder`,`batchCancelOrders`,`placeAndExecuteMarketBuy/Sell`), FeeEscrow(`claim`), BuybackVault(`release`), plus the approval pipeline (token `approve` with spender ∈ {curve, margin}). No Permit2/PoolManager/PositionManager/Hook/import appears anywhere in the SDK write path.

**Read-path anchoring — PASS with condition C-9 (advisory).** Curve/escrow/vault/factory/coordinator/margin targets are all anchored to the release manifest or to `coordinator.packet` (model.ts rejects unknown tokens). Kuru market addresses, however, are caller-supplied in `prepareKuruLimitOrder`/`prepareKuruMarketOrder`/`prepareKuruCancel` with no identity check — unlike `readKuru` (kuru.ts), which validates the market against `router.verifiedMarket` params, environment codehashes, and the margin wiring. A counterfeit market cannot steal funds through these paths (margin debits require `verifiedMarket` membership; approvals are never pointed at markets), but it can waste user txs and mislead. Condition: run the same identity gate before preparing any market write (reuse `readKuru`'s checks).

**Conditions register** (owners: SDK_AGENT unless noted; FRONTEND_AGENT where UI):

- **C-1 (SDK, must-fix before P5):** `prepareFactoryGraduate` precondition wrong — prepare.ts:218-220 compares virtual `quoteReserve` to `completionQuote().terminalQuote`; replace with `launch.remaining === 0n` (or `curve.readyToGraduate()`). Source authority: RetroPickBondingCurveV2.sol:352-355,535; GraduationCoordinatorV2.sol:183.
- **C-2 (SDK/FRONTEND):** margin `deposit` must always credit the connected account (`_user == account`); no third-party crediting UI.
- **C-3 (SDK):** add `prepareBatchWithdrawMaxTokens` (W-9) or document per-token withdraw fallback on the portfolio screen.
- **C-4 (SDK):** prefer `batchCancelOrdersNoRevert` for cancels (or implement the strict→NoRevert fallback on `OrderAlreadyFilledOrCancelled`); ids only from confirmed `OrderCreated` logs of the same market.
- **C-5 (SDK, must-ship for claims flow):** add `prepareFeeClaimToken(token)` (W-17) — required to withdraw buyback releases.
- **C-6 (SDK, must-fix):** `decodeEscrowClaim` event names wrong — decode.ts:77 `['FeesClaimed','Claimed','TokenFeesClaimed']` → `['NativeClaimed','TokenClaimed']`.
- **C-7 (SDK, minor):** `prepareLaunchToken` combined-fee pre-check (prepare.ts:85) covers only `curveFeeBps + creatorTaxBps`; the factory also enforces `hookFeeBps + creatorTaxBps ≤ 2000` (factory sol:734). Read `memeHook.currentFeePolicy().hookFeeBps` for the second leg or accept the raw `CombinedFeeTooHigh` revert with decoded-error UX.
- **C-8 (SDK/FRONTEND, standing rule):** approval spenders restricted to {per-launch curve, MarginAccount}; never free-form.
- **C-9 (SDK, advisory):** market identity gate before preparing Kuru writes (mirror `readKuru` checks).

---

## 5. Required changes to `abi-capabilities.json` `frontendWrites` (for CONTRACT_AGENT)

1. **Add** `GraduationCoordinatorV2.complete(address)` as a `LIFECYCLE_WRITE`-style frontend write (mirror of entry 5; equal asset movement/events; note factory wrapper equivalence). The SDK implements this surface today.
2. Optional metadata fix: entry 5's `eventsDecoded` should include `GraduationCompleted` (emitted by the coordinator on both venues); `PoolGraduated` is V4-venue-only.
3. No removals; no other field corrections found — entries 0-19 matched deployed source on every checked attribute (access control, value rules, allowance spenders, event/error names, retry semantics).

---

## 6. Signed-off final allowlist

| # | Contract | Canonical signature | prepare.ts function | Screens | Verdict |
|---|---|---|---|---|---|
| 1 | RetroPickLaunchFactoryV2 | `launchToken((string,string,string,string,(string,string,string,string,string),address,uint16,bool,bytes32,bytes32),uint256,address,uint8)` | `prepareLaunchToken` | create | APPROVED |
| 2 | RetroPickLaunchFactoryV2 | `launchToken((…,bytes32,bytes32),uint256,address,address[])` | — (deferred) | — (not v1) | APPROVED-WITH-CONDITIONS (W-2) |
| 3 | RetroPickBondingCurveV2 | `buy(uint256,uint256,address)` | `prepareCurveBuy` | trade | APPROVED |
| 4 | RetroPickBondingCurveV2 | `sell(uint256,uint256,address)` | `prepareCurveSell` | trade | APPROVED |
| 5 | RetroPickLaunchFactoryV2 | `graduate(address)` | `prepareFactoryGraduate` | graduation | APPROVED-WITH-CONDITIONS (C-1) |
| 6 | RetroPickLaunchFactoryV2 | `createGraduatedPool(address)` | — (wrapper) | graduation | APPROVED |
| 6b | GraduationCoordinatorV2 | `complete(address)` *(amendment)* | `prepareCoordinatorComplete` | graduation | APPROVED |
| 7 | MarginAccount | `deposit(address,address,uint256)` | `prepareMarginDeposit` | kuru | APPROVED (C-2) |
| 8 | MarginAccount | `withdraw(uint256,address)` | `prepareMarginWithdraw` | portfolio | APPROVED |
| 9 | MarginAccount | `batchWithdrawMaxTokens(address[])` | — (C-3: add) | portfolio | APPROVED (C-3) |
| 10 | OrderBook | `addBuyOrder(uint32,uint96,bool)` | `prepareKuruLimitOrder` | kuru | APPROVED |
| 11 | OrderBook | `addSellOrder(uint32,uint96,bool)` | `prepareKuruLimitOrder` | kuru | APPROVED |
| 12 | OrderBook | `batchCancelOrdersNoRevert(uint40[])` | — (C-4: add/prefer) | kuru | APPROVED |
| 13 | OrderBook | `batchCancelOrders(uint40[])` | `prepareKuruCancel` | kuru | APPROVED (C-4) |
| 14 | OrderBook | `placeAndExecuteMarketBuy(uint96,uint256,bool,bool)` *(isMargin=true)* | `prepareKuruMarketOrder` | kuru | APPROVED |
| 15 | OrderBook | `placeAndExecuteMarketSell(uint96,uint256,bool,bool)` *(isMargin=true)* | `prepareKuruMarketOrder` | kuru | APPROVED |
| 16 | RetroPickFeeEscrowV2 | `claim()` | `prepareFeeClaim` | claims | APPROVED (C-6) |
| 17 | RetroPickFeeEscrowV2 | `claimToken(address)` | — (C-5: add) | claims | APPROVED (C-5) |
| 18 | RetroPickBuybackVaultV2 | `release(address)` | `prepareBuybackRelease` | claims | APPROVED |
| 19 | RetroPickLauncherTokenV2 | `approve(address,uint256)` *(spender ∈ {curve, margin})* | approval pipeline | trade, kuru | APPROVED (C-8) |
| 20 | ERC20MetadataInterface | `approve(address,uint256)` *(spender = launch curve)* | approval pipeline | trade | APPROVED (C-8) |

Rejections: **none**. Phase-3 gate `FRONTEND_WRITE_SECURITY`: **PASS for the allowlist decision**; SDK conditions
C-1/C-5/C-6 tracked for Phase 5 (SDK write engine) clearance.
