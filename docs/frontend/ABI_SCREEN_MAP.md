# ABI → Screen Map (Phase 2 — FRONTEND_CONTRACT_MAPPING)

Inverse index of the 11 priority contracts: for each user-facing read/write from the capability map, which screen(s)/component(s) consume it, via which planned hook, and which current fixture it replaces. Anything not reachable from any screen is marked **NOT_SURFACED** with the reason.
Deployed target: Monad Testnet chain 10143, addresses from `deployments/monad-testnet/v2.json` (factory `0xa7f18b9e…682454`, quoteRegistry `0xd12112…B23B9B40`, coordinator `0xaD62309…AF738F`, feeEscrow `0xb0312b…01c2D96`, buybackVault `0x2D7466…95BE09`, kuruEnvironment `0xAD59b3…b1E1Ba1` → router/marginAccount `0xd029C2…159CE02`, orderBook impl `0x72caE0…9c9374`). ABIs from `apps/abi/*.json`.

Planned hooks are **proposals** for Phase 4/6 (names not yet implemented). Screens reference `docs/frontend/RETRO_UI_REVERSE_MAP.md` §3.

---

## 1. RetroPickLaunchFactoryV2 (`0xa7f18b9e…682454`)

| Function | R/W | Screen / component | Planned hook | Replaces (current fixture) |
|---|---|---|---|---|
| `launchToken(TokenParams,uint256,address)` / `(…,uint8 venue)` | write | `/launchpad/create` `TokenLaunchWizard` submit (`create-launch.tsx:74-90,97`) | `useLaunchToken()` (tx) | localStorage draft `retropick-token-launch-draft`; hardcoded ETH economics copy |
| `launchFee()` | read | `/launchpad/create` rail + info line (`create-launch.tsx:14,97`) | `useLaunchConfig()` | `LAUNCH_FEE='0.0005 ETH'` |
| `launchConfigCount()` + `getLaunchConfig(id)` | read | `/launchpad/create` (config picker/labels) | `useLaunchConfig()` | `SUPPLY/GRADUATES_AT/CURVE_FEE` constants |
| `maxCreatorTaxBps()` | read | `/launchpad/create` fee field validation/copy | `useLaunchConfig()` | hardcoded 10% cap (`create-launch.tsx:68`) |
| `canLaunch(address)` (+`launchEnabled()`) | read | `/launchpad/create` submit gate; sidebar wallet state | `useCanLaunch(address)` | `demo.connected` fake gate |
| `previewLaunchEconomics(id,quote)` / `previewVenueEconomics(id,quote,venue)` | read | `/launchpad/create` review step (economics pin shown to user, submitted as `expectedEconomics`) | `usePreviewEconomics()` | static economics copy |
| `quoteRegistry()` | read | composition seam for quote list | inside `useAdmittedQuotes()` | — (fixture list today) |
| `feeEscrow()` / `buybackVault()` / `graduationCoordinator()` / `launchDeployer()` / `locker()` / `memeHook()` / `poolManager()` / `positionManager()` / `permit2()` | read | wiring context for hooks (escrow/buyback/graduation surfaces) | SDK registry bootstrap | `verified-deployments.ts` single-entry map |
| `getLaunchedToken(address)` | read | `/launchpad/token/:id` (resolve launch record), `/creator/:address` (creator's tokens), `/launchpad` feed enrichment | `useLaunchRecord(token)` | fixture `tokenLaunches` rows |
| `graduate(address)` | write | `/launchpad/token/:id` lifecycle action when `readyToGraduate` (**needs a new control** — none exists) | `useGraduate()` | fixture `lifecycle: 'GRADUATION_READY'` copy only |
| `snipeTaxSeconds()` / `snipeTaxStartBps()` | read | token-detail disclosure (launch-window tax) — optional | `useLaunchConfig()` | none |
| `whitelistedLaunchers(address)` | read | create gate fallback detail | inside `useCanLaunch` | none |
| `getLaunchFeePolicy(address)` | read | token-detail Protocol tab (fee split display) | `useFeePolicy()` | "Fees: Protocol configured" stub (`token-detail.tsx:33`) |
| `secureCurve` / `rescueCurveFees` / `createGraduatedPool` / `addLaunchConfig` / `updateLaunchConfig` / `setLaunchFee` / `setMaxCreatorTaxBps` / `setLaunchEnabled` / `setWhitelistedLauncher` / `setLaunchDeployer` / `setLaunchForwarder` / `configureVenueExecutor` / `setSnipeTax*` / `setBuybackEnabled` / `transferCreatorFeeRecipient` / `setCreatorFeeRecipient` / `cancelCreatorFeeRecipientChange` / `executeCreatorFeeRecipientChange` / `transferOwnership` / `acceptOwnership` / `renounceOwnership` + constant views (`CREATOR_FEE_RECIPIENT_*`, `GRADUATION_RESCUE_DELAY`) | write/read | — | — | **NOT_SURFACED**: owner/admin operations; no admin console exists and none is planned in this campaign (security scope: user writes only) |
| `launchTokenFor(…)` | write | — | — | **NOT_SURFACED**: forwarder-only atomic launch-and-buy entry (`NotLaunchForwarder`); out of user scope |
| `launchToken(…,address[] snipeTaxExemptions)` (F3) | write | — | — | **NOT_SURFACED**: organized-team exemption pathway; no form field; candidate for a later creator-teams feature |
| events `TokenLaunched`, `PoolGraduated`, `LaunchSwept`, `LaunchForceSwept`, config/admin events | read | `/activity` feed (indexer), tx receipts | indexer client | fixture `activities` rows |

## 2. RetroPickQuoteAssetRegistryV2 (`0xd1211276869ec55CAF302E22371D2005B23B9B40`)

| Function | R/W | Screen / component | Planned hook | Replaces |
|---|---|---|---|---|
| `admitted(address,uint8 venue)` → `{enabled,decimals,venueMask,…,phantomQuote,graduationThreshold,graduationQuoteCeiling}` | read | `/launchpad/create` pair selector + economics display | `useAdmittedQuotes(venue)` | `approvedPairAssets` fixture (`launchpad-fixtures.ts:12-18`) + hardcoded ETH (`create-launch.tsx:42`) |
| `isSupportedQuote(address)` / `validateQuote(address,uint8)` | read | form submit precheck / SDK encode guard | inside `useAdmittedQuotes` / SDK `prepare.ts` | client fixture membership test |
| `getConfig(address)` (unversioned lookup) | read | — | — | **NOT_SURFACED**: venue-specific `admitted()` is the user-facing read; `getConfig` adds no screen value |
| `CIRCLE_TEST_USDC()` / `TARGET_CHAIN_ID()` | read | — | SDK environment validation | **NOT_SURFACED**: environment-attestation values (consumed by Kuru `validate()` chain, not by a screen) |
| `configure` / ownership set | write | — | — | **NOT_SURFACED**: admin |

## 3. RetroPickLauncherTokenV2 (per-launch instance)

| Function | R/W | Screen / component | Planned hook | Replaces |
|---|---|---|---|---|
| `getTokenInfo()` / `name()` / `symbol()` / `logo()` / `description()` / `socials()` | read | `/launchpad/token/:id` heading + Overview tab (`token-detail.tsx:25-33`) | `useTokenMeta(token)` | fixture name/symbol/icon/description; demo-pill "Address not deployed" |
| `totalSupply()` | read | token-detail market-cap stat | `useTokenMeta`/`useCurveState` | fixture `marketCap` |
| `balanceOf(address)` | read | `/portfolio` positions (wallet holdings), trade ticket "Available" line | `useTokenBalance(token,address)` | `demo.positions` quantity |
| `allowance` / `approve` / `transfer` / `transferFrom` / `burn` / `burnFrom` | write/read | approvals needed before `Curve.sell` (or Kuru ops); plain transfers not a campaign flow | SDK approval step ("Approval preview" phase exists in `ticket.tsx:15`) | none (demo has no approvals) — **NOT_SURFACED as UI**: approval is a hidden tx-engine step, surfaced only as a ticket phase |
| `curve()` / `launchFactory()` / `deployer()` / `decimals()` | read | SDK derivation of the curve address for reads | SDK `registry.ts` | hardcoded fixture route `token.pair` |

## 4. RetroPickBondingCurveV2 (per-launch instance)

| Function | R/W | Screen / component | Planned hook | Replaces |
|---|---|---|---|---|
| `buy(uint256 minTokens, uint256 deadline, address recipient)` payable | write | `/launchpad/token/:id` inline ticket (replacing the disabled button, `token-detail.tsx:33`) | `useCurveBuy()` (tx via ticket chassis) | disabled "{side} unavailable"; demo `trade()` |
| `sell(uint256 tokenAmount, uint256 minQuote, address recipient)` | write | same ticket, Sell side | `useCurveSell()` | demo `sell()` |
| `getReserves()` / `quoteReserve()` / `tokenReserve()` / `realQuoteReserve()` / `phantomQuote()` / `trackedQuote()` / `trackedTokens()` / `reservedTokens()` / `sellableTokens()` | read | token-detail Liquidity stat + progress bar; discovery feed `liquidity` column; quote math for the ticket | `useCurveState(token)` | fixture `liquidity`, `curveProgressBps`, hardcoded 43,000 target (`token-detail.tsx:33`) |
| `completionQuote()` / `completionTerminalQuote()` / `graduationThreshold()` / `graduationQuoteCeiling()` / `readyToGraduate()` / `graduated()` | read | token-detail "Launch progress" panel + graduation-CTA visibility | `useCurveState` | fixture `lifecycle` (`CURVE/GRADUATION_READY/…`) |
| `feeBps()` / `creatorTaxBps()` / `protocolFeeShareBps()` / `buybackBurnBps()` / `maxInternalPriceImpactBps()` | read | ticket fee lines (replacing "Fees: Protocol configured"), token-detail Protocol tab | `useCurveState` | "Demo fee 0.10%" line (`ticket.tsx:16`) |
| `feeEscrow()` / `buybackVault()` / `factory()` / `token()` / `pairToken()` / `feePolicy()` / `deployer()` / `isNativeQuote()` / `protocolFeeRecipient()` / `buybackQuoteBalance()` / `creatorTaxBalance()` / `quoteFeeBalance()` | read | SDK wiring + protocol-tab display | SDK registry | — |
| `graduate(address)` | write | token-detail graduation CTA (new; or factory `graduate`) | `useGraduate()` | fixture copy "Destination setup is pending" |
| `setBuybackEnabled` / `setCreatorFeeRecipient` / `sweepFees` / `rescueFees` / `exemptFromSnipeTax` / `initialize` | write | — | — | **NOT_SURFACED**: creator/admin/ops operations (`exemptFromSnipeTax` is consumed via the factory F3 path, not a screen) |
| events `CurveBuy/CurveSell/CurveBuyRefunded/CurveCompleted` + fee events | read | `/activity`, token-detail Trades tab, tx receipts | indexer | fixture `trades24h`, illustrative chart |

## 5. GraduationCoordinatorV2 (`0xaD62309242EA65BB07C833669EC6a4ED23AF738F`)

| Function | R/W | Screen / component | Planned hook | Replaces |
|---|---|---|---|---|
| `packet(address)` | read | token-detail Protocol tab (graduation packet: venue, policy hash) | `useGraduationPacket(token)` | "Mature venue: Kuru · planned / no adapter" copy |
| `ledger(address)` / `receipt(address)` / `available(address)` | read | token-detail post-graduation state; `/portfolio` graduated-position context | `useGraduationState` | fixture `lifecycle: 'GRADUATED'` copy |
| `previewEconomics(id,quote,venue)` | read | create-form economics pin (factory proxies it) | via `usePreviewEconomics` | static economics copy |
| `quoteLiability(address)` | read | token-detail Protocol tab disclosure | `useGraduationPacket` | none |
| `executors(uint8)` | read | venue selector availability (is KURU executor wired) | `useAdmittedQuotes` context | none |
| `complete` / `secure` / `registerLaunch` / `bindFactory` / `configureExecutor` / ownership | write | — | — | **NOT_SURFACED**: protocol-internal transitions driven by factory/executors, never direct user actions |

## 6. KuruEnvironmentV2 (`0xAD59b3ff498d76DbC68351DaD4391D250b1E1Ba1`)

| Function | R/W | Screen / component | Planned hook | Replaces |
|---|---|---|---|---|
| `validate()` | read | SDK boot-time environment integrity check (hashes vs manifest) | SDK `registry.ts` (not a screen) | liquidity-source row "Kuru · DEMO" (`markets/detail.tsx:14` venue list upgrades to verified) |
| `MARGIN()` / `ROUTER()` / `ORDERBOOK_IMPL()` / `VAULT_IMPL()` / hash constants | read | SDK derivation of margin/router addresses | SDK registry | none |

**NOT_SURFACED** as interactive surface: the environment contract is pure attestation; it feeds trust displays (e.g. a "Kuru environment verified" badge on graduated token details — optional Phase 6).

## 7. MarginAccount (`0xd029C2D98ff85D8F64799017fE00a59B1159CE02`)

| Function | R/W | Screen / component | Planned hook | Replaces |
|---|---|---|---|---|
| `deposit(address token, uint256 amount)` payable | write | graduated-token trade ticket funding step (deposit quote/collateral before Kuru orders) | `useMarginDeposit()` | none (demo pretends balances exist) |
| `withdraw(uint256, address)` / `batchWithdrawMaxTokens(address[])` | write | `/portfolio` margin-balance withdrawal action (new control) | `useMarginWithdraw()` | none |
| `getBalance(address user, address token)` / `balances(bytes32)` | read | ticket "Available" line for Kuru trading; `/portfolio` balances | `useMarginBalance` | `demo.balance` (10,000 fake USDC) |
| `verifiedMarket(address)` | read | ticket guard (only trade via verified books) | SDK guard | none |
| `deposit`-side event `Deposit`/`Withdrawal` | read | `/activity` | indexer | none |
| `creditUser` / `creditUsersEncoded` / `debitUser` / `creditFee` / `setFeeCollector` / `toggleProtocolState` / `updateMarkets` / ownership/upgrade | write | — | — | **NOT_SURFACED**: orderbook-internal settlement + admin |

## 8. OrderBook (per-market proxy, impl `0x72caE0a99C19B574e8a6De558F43fc1D019c9374`)

| Function | R/W | Screen / component | Planned hook | Replaces |
|---|---|---|---|---|
| `placeAndExecuteMarketBuy(uint96, uint256, bool, bool)` payable / `placeAndExecuteMarketSell(uint96, uint256, bool, bool)` | write | graduated-token ticket (Kuru market leg) — reuses `TradeTicket` Market mode | `useKuruMarketOrder()` | demo `simulate()` (`ticket.tsx:15`) |
| `addBuyOrder(uint32,uint96,bool)` / `addSellOrder(uint32,uint96,bool)` | write | ticket Limit mode on a graduated token | `useKuruLimitOrder()` | demo `addOrder()` (session-only) |
| `batchCancelOrders(uint40[])` (+ noRevert/flip variants) | write | `/portfolio` open-orders cancel | `useKuruCancel()` | demo `cancelOrder()` |
| `getL2Book([uint32,uint32])` | read | order-book panel on graduated token detail (pattern exists at `markets/detail.tsx:14` Order book tab) | `useKuruBook()` | fabricated ladder (`detail.tsx:14`) |
| `bestBidAsk()` / `s_buyPricePoints` / `s_sellPricePoints` / `vaultBestAsk` / `vaultAskOrderSize` | read | ticket quote lines, book header | `useKuruBook` | demo `demoVenue.quote()` |
| `getMarketParams()` / `getVaultParams()` / `marketState()` / `s_orders(uint40)` / `s_orderIdCounter()` | read | ticket guard rails (tick/size limits), portfolio order rows | `useKuruBook`/`useKuruOrders` | none |
| `addFlip*` / `addPairedLiquidity` / `batch*` liquidity ops, `collectFees`, `toggleMarket`, `updateVaultOrdSz`, `transferOwnership`, upgrade | write | — | — | **NOT_SURFACED**: LP and admin operations; no LP screen exists in retro-ui (Kuru AMM vault LP is out of campaign user flows) |
| event `Trade` / `OrderCreated` / `OrdersCanceled` | read | `/activity`, portfolio history | indexer | fixture activity rows |

## 9. KuruLiquidityLockV2 (per-graduation instance)

| Function | R/W | Screen / component | Planned hook | Replaces |
|---|---|---|---|---|
| `protectedBalances()` / `launchToken()` / `quoteToken()` / `market()` / `vault()` | read | graduated token-detail Protocol tab (locked graduation liquidity disclosure) | `useLiquidityLock(token)` | none — currently zero rendering; fixture "Graduated · Kuru is the intended mature venue" copy (`token-detail.tsx:11`) is the placeholder |

Read-only contract; nothing NOT_SURFACED except that no screen renders it today (fix lands with Phase 6 graduated-detail).

## 10. RetroPickFeeEscrowV2 (`0xb0312b0412c3BAa11895A6c4FeeC7CD9A01c2D96`)

| Function | R/W | Screen / component | Planned hook | Replaces |
|---|---|---|---|---|
| `balanceOf(address)` / `balanceOfToken(address,address)` | read | `/earn` Creator-fees panel "Available to claim"; `/portfolio` | `useEscrowBalance(address)` | `EARN.creatorFees = 0` constant (`earn.tsx:13`) |
| `claim(uint256)` / `claim()` / `claimToken(address,uint256)` / `claimToken(address)` | write | `/earn` "Claim all" + token-detail creator view | `useEscrowClaim()` | toast stub (`earn.tsx:39`) |
| `totalNativeLiability()` / `totalTokenLiability(address)` | read | protocol disclosure (optional) | inside escrow hook | none |
| `credit()` / `creditToken(address,address,uint256)` | write/payable | — | — | **NOT_SURFACED**: curve/factory sweep destinations (protocol-internal callers); users never credit the escrow directly |
| events `NativeCredited/TokenCredited/…Claimed` | read | `/activity`, claim receipts | indexer | none |

## 11. RetroPickBuybackVaultV2 (`0x2D746643E0BA37F127b38A4C04866a123895BE09`)

| Function | R/W | Screen / component | Planned hook | Replaces |
|---|---|---|---|---|
| `releasable(address token)` | read | `/earn` buyback-vest row; token-detail creator view | `useBuybackVesting(token)` | `EARN.solAvailable '0 SOL'` placeholder (`earn.tsx:17`) |
| `release(address token)` | write | `/earn` claim action (vested portion) | `useBuybackRelease()` | toast stub |
| `vestedAmount` / `totalLocked` / `totalReleased` / `vestingStart` / `vestingTerms` / `VESTING_DURATION` | read | vesting schedule display (create-form buyback copy + earn panel) | `useBuybackVesting` | hardcoded "5 years" copy (`create-launch.tsx:21`) |
| `lock(...)` | write | — | — | **NOT_SURFACED**: called by the curve during buyback settlement; never a user action |
| `updateCreatorRecipient` / `setFactory` / ownership | write | — | — | **NOT_SURFACED**: admin/creator ops without screens in scope |

---

## 12. Coverage summary

- **Write flows with a designated screen + chassis**: `launchToken` (create wizard), curve `buy/sell` + `graduate` (token-detail ticket), Kuru market/limit orders + cancels (graduated ticket + portfolio), escrow `claim*` + buyback `release` (earn), margin `deposit/withdraw` (portfolio/ticket funding).
- **Write paths deliberately NOT_SURFACED**: all owner/admin setters on every contract; protocol-internal transitions (coordinator `secure/complete/registerLaunch`, escrow `credit*`, buyback `lock`, margin `credit/debit`, orderbook LP ops); forwarder-only `launchTokenFor`; the F3 snipe-exemption overload.
- **Reads with no screen today** (backlog for Phase 6 polish): KuruEnvironment attestation badge, KuruLiquidityLock disclosure, coordinator `quoteLiability`, escrow liability totals.
- Fixture inventory replaced by LIVE reads: `tokenLaunches` (4), `markets` (8), `prismSeries` (1), `initialPositions` (5), `activities` (16), `approvedPairAssets` (5), `EARN` snapshot, `SNAPSHOT` timestamps — PRISM/prediction fixtures stay demo per scope.
