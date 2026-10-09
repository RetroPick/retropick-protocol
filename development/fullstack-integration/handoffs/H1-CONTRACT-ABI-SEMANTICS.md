# H1 — Contract ABI Semantics Handoff

```text
HANDOFF_ID: H1-CONTRACT-ABI-SEMANTICS
FROM: CONTRACT_AGENT (SOLIDITY_FOUNDRY)
TO: SECURITY_AGENT + SDK_AGENT + FRONTEND_AGENT
PRODUCT: RetroPick Launchpad Core V2 (Monad Testnet)
GOAL_ID: RETROPICK-V2-FULLSTACK-INTEGRATION
REQUIREMENTS: Phase 1 gate ABI_SEMANTICS_MAPPED — every ABI item across the deployed
  V2 catalog receives an explained application disposition; provide the contract
  interaction graph and the frontend write candidate allowlist downstream agents build on.
COMMIT/REF: branch codex/v2-fullstack-integration, baseline 8d8650a (campaign baseline 41df325)
```

## Capability / skill used

SOLIDITY_FOUNDRY — `evm-foundry`, `solidity-foundry`, `contract-verification`. Semantics read from the pinned Solidity source, not from names; selectors verified with Foundry `cast sig` / `cast sig-event`.

## INPUTS_CONSUMED

- `apps/abi/manifest.json` (schema v2) + all 27 `apps/abi/*.json` artifact ABIs
- `deployments/monad-testnet/abi/function-event-map.json` + `FUNCTIONS.md` (mechanical inventory backbone)
- Pinned Solidity source `contracts/src/v2/**` (authoritative semantics; deployed source SHA `f0363249`)
- Pinned Kuru upstream at `/tmp/retropick-kuru-contracts` (`MarginAccount.sol`, `OrderBook.sol`, `KuruAMMVault.sol`, `Router.sol`, interfaces) — present and used
- `deployments/monad-testnet/v2.json` (release bundle: addresses, kuruEnvironment, monLaunch/marketUsability evidence)
- `.agent/HANDOFFS.md` (field contract for this document)

## OUTPUTS_PRODUCED

1. `docs/contracts/V2_APPLICATION_CAPABILITY_MAP.md` — human map: inventory & provenance, contract interaction graph (7 edge families), 11 priority-contract deep analyses, 16 remaining contracts, frontend write allowlist, semantics cheat-sheet.
2. `development/fullstack-integration/generate_abi_capabilities.py` — deterministic generator embedding the hand-authored classification; hard-fails (non-zero exit) on any missing disposition.
3. `development/fullstack-integration/abi-capabilities.json` — machine map, schema-stable for Phase 7 (`meta` / `dispositionLegend` / `contracts` / `frontendWrites`), sorted keys, no timestamps.
4. This handoff; plus two status rows in `development/fullstack-integration/README.md`.

## INVARIANTS_NOT_CHANGED

- No Solidity source, deployment, apps/, or packages/ files touched. No git write commands run.
- Catalog artifacts (`apps/abi/**`, `deployments/**`) read-only; the generator only reads them.
- No protocol semantics redefined: dispositions classify existing ABIs; code did not change.

## VERIFICATION

- Recount from the 27 artifact ABIs: **27 contracts / 517 functions / 147 events / 325 errors** — exact match with `apps/abi/manifest.json` (also 21 constructors + 11 receive entries excluded by the catalog convention; one byte-identical duplicate `InsufficientBalance()` declaration inside KuruAMMVault collapses to one disposition key). Recorded in `meta.verifiedAgainst`.
- `python3 development/fullstack-integration/generate_abi_capabilities.py` → **exit 0**, prints counts `{contracts: 27, functions: 517, events: 147, errors: 325}`, 100% coverage enforced bi-directionally (no missing disposition AND no classification targeting an absent item AND per-contract manifest count equality).
- Determinism: two consecutive runs produce byte-identical output (SHA-256 `e3647c20ce051b0993cb1e422dfb26152353f1768d695ae2a12ef11050104149`).
- Selector/topic spot checks with `cast` (all match `function-event-map.json`):
  `launchToken((string,string,string,string,(string,string,string,string,string),address,uint16,bool,bytes32,bytes32),uint256,address,uint8)` = `0x41c0731e`;
  `launchToken(...,uint256,address,address[])` = `0xa72101af`;
  `secureCurve(address)` = `0x758a47ea`;
  `registerLaunch(address,address,uint8,uint24,int24)` = `0xf9c10291`;
  `getL2Book(uint32,uint32)` = `0xe7e10737`;
  `OrderCreated(uint40,address,uint96,uint32,bool)` topic0 = `0xb81bbaf1...`;
  `CurveBuy(address,address,uint256,uint256,uint256,uint256)` topic0 = `0xec36bf57...`.

## EVIDENCE

- Machine map: `development/fullstack-integration/abi-capabilities.json`
- Human map (incl. cheat-sheet and allowlist): `docs/contracts/V2_APPLICATION_CAPABILITY_MAP.md`
- Deployment bundle: `deployments/monad-testnet/v2.json` (MON launch graduated: securedQuote 1000000000000000002, securedLaunchTokens 500e18, protectedLP 15811388300841895683, excess 249999999999999999751)

## Exact ABI functions involved (frontend write candidates — the allowlist input to SECURITY_AGENT)

| Contract | Canonical signature |
|---|---|
| RetroPickLaunchFactoryV2 | `launchToken((string,string,string,string,(string,string,string,string,string),address,uint16,bool,bytes32,bytes32),uint256,address,uint8)` (venue: UNISWAP_V4=0 / KURU=1) |
| RetroPickLaunchFactoryV2 | `launchToken((string,string,string,string,(string,string,string,string,string),address,uint16,bool,bytes32,bytes32),uint256,address,address[])` (exemptions; v4 only) |
| RetroPickLaunchFactoryV2 | `graduate(address)` · `createGraduatedPool(address)` (permissionless lifecycle/recovery) |
| RetroPickBondingCurveV2 | `buy(uint256,uint256,address)` (payable; native msg.value==quoteIn) · `sell(uint256,uint256,address)` |
| MarginAccount | `deposit(address,address,uint256)` (payable; native token=0x0, value==amount) · `withdraw(uint256,address)` · `batchWithdrawMaxTokens(address[])` |
| OrderBook | `addBuyOrder(uint32,uint96,bool)` · `addSellOrder(uint32,uint96,bool)` · `batchCancelOrders(uint40[])` · `batchCancelOrdersNoRevert(uint40[])` · `placeAndExecuteMarketBuy(uint96,uint256,bool,bool)` (payable exact bracket) · `placeAndExecuteMarketSell(uint96,uint256,bool,bool)` |
| RetroPickFeeEscrowV2 | `claim()` · `claim(uint256)` · `claimToken(address)` · `claimToken(address,uint256)` |
| RetroPickBuybackVaultV2 | `release(address)` (beneficiary-only) |
| RetroPickLauncherTokenV2 | `approve(address,uint256)` (spender: curve / MarginAccount / market) |
| ERC20MetadataInterface (USDC) | `approve(address,uint256)` (spender: the launch's curve) |

Explicitly excluded from the surface: all admin/config/ownership ops, `launchTokenFor`, curve `sweepFees`/`rescueFees`, coordinator `secure`/`registerLaunch`, both executors' `execute`, hook sweeps/admin, Permit2/PoolManager/PositionManager surfaces, Kuru Router `anyToAnySwap` (future candidate), OrderBook MM primitives (`addFlip*`, `addPairedLiquidity`, `batch*` variants beyond cancel, `batchUpdate`), token `burn`/`burnFrom`, WETH wrap/unwrap, every `initialize`/`upgradeToAndCall`.

## Assumptions resolved (for downstream agents)

1. `MarginAccount.deposit` is `(address user, address token, uint256 amount)`; the 3-uint256 payable `deposit(uint256,uint256,uint256,address)` belongs to **KuruAMMVault** (executor-only seed path). The campaign brief's example conflated them.
2. `coordinator.secure` is `onlyFactory` (user path = `factory.graduate`); `coordinator.complete` is permissionless but the app wraps it via `factory.createGraduatedPool` (works for both venues, returns positionId).
3. MON-native Kuru markets are `OrderBookType.NATIVE_IN_QUOTE` (=2, deployed by the executor when `quoteAsset == address(0)`): market **buys** pay `msg.value` in an exact bracket `[cost(size), cost(size+1))`; market **sells** take value 0.
4. Kuru grid (pinned policy; read live via `getMarketParams()`): pricePrecision=sizePrecision=1e8, tickSize=1, minSize=1e6, maxSize=1e16, taker 30 bps / maker 0, vault spread 100 (1%); 18/18 markets convert `quoteWei = price*size*100` (rounded up) and `sizeWei = size*1e10`.
5. `OrderCreated` fires only for the resting remainder; fully-matching placements emit only `Trade`s. Order fill state is inferred from price-point heads via `s_orders`/`s_*PricePoints`.
6. The curve's deployed `exemptFromSnipeTax` is a factory-gated no-op stub in the pinned source: launch-time exemption lists are recorded but do not change onchain tax behavior in this build; do not surface exemption management.
7. `launchToken` plain 3-arg overload is valid but subsumed by the venue overload (venue=0); classified NOT_SURFACED_WRITE to keep one canonical path.
8. Snipe-tax terms (9900 bps / 15 s) and maxCreatorTaxBps (1000) are factory globals snapshotted per launch at creation.

## Security considerations (for SECURITY_AGENT)

- The `frontendWrites` array is the candidate surface; every entry carries caller/target/access/asset/payable rule/allowance target/native-vs-ERC20/slippage/events/errors/retry. Verify against the cheat-sheet invariants: exact `msg.value` rules (launch fee, curve native buy, margin native deposit, market-buy bracket), exact allowance spenders, and the exclusion list above.
- `PROTOCOL_INTERNAL` entries must be rejected when user-originated (notably `secureCurve`, `launchTokenFor`, both executors' `execute`, `PositionManager.unlockCallback`, hook callbacks).
- `PhysicalBalanceDeficit` / `QuoteBackingDeficit` / `EnvironmentDrift` / `*ImplementationUpdated`+`Upgraded` are halt-and-report signals, not retries.
- Kuru ABIs are pinned-source, not verified-bytecode matches; runtime identity is enforced by `KuruEnvironmentV2` codehash pins — call `KuruEnvironmentV2.validate()` (eth_call) before enabling Kuru flows and after any Kuru upgrade event.
- USDC coverage is a qualified 9-function interface only; treat the proxy conservatively (no assumptions about its full surface).

## OPEN_BLOCKERS

None for Phase 1. Downstream notes: (a) SECURITY_AGENT must ratify or trim the 20-entry allowlist; (b) indexer will need the event `consumedBy` tags from the machine map; (c) `executeCreatorFeeRecipientChange` and creator self-service ops are deliberately unsurfaced in v1 (candidates for a creator-settings screen later).

## STATUS

READY — Phase 1 artifacts complete and verified; machine map consumable at `development/fullstack-integration/abi-capabilities.json`.
