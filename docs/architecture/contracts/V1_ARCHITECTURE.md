# V1 Launchpad Architecture

## Inventory and dependency boundary

V1 comprises the ten contracts, three interface files, and two libraries in [SOURCE_MAP.md](SOURCE_MAP.md). The first-party runtime is a launch-token bonding curve that graduates into a permanently locked, full-range **Uniswap V4** position. The Factory orchestrates deployment and phase changes; the Deployer exists to keep Factory deployed bytecode below EIP-170; the Executor isolates Permit2/PositionManager minting.

External dependencies are OpenZeppelin, Uniswap V4, Permit2, ERC-20 quote assets, native ETH, and ABI-only `IRetroPickFeeEscrowV1`. Kuru, prediction-market, and PRISM code are not imported or called by V1. Product target documentation must not be read as an implemented edge.

## Launch, trade, fee, buyback, and graduation flows

1. A creator or configured forwarder calls Factory `launchToken*`. The Factory validates a config, pinned economics digest when supplied, quote approval/decimals, dependency wiring, and seedability; it pays the fixed launch fee to the hook's protocol fee recipient.
2. Factory calls Deployer `deployLaunch`, which deploys Curve then Token. Factory calls Curve `initialize(token)` and records `NotGraduated` state.
3. Traders call Curve `buy` or `sell` against native ETH (`pairToken == address(0)`) or the configured ERC-20. The Curve tracks quote/token reserves and fee buckets. Trading ends once `sellableTokens() == 0`; the Curve attempts Factory graduation without relying on a router or price oracle.
4. Curve fee sweep splits quote-denominated buckets: protocol/creator credits use the external escrow ABI; a bounded internal buyback can acquire launch tokens which BuybackVault locks. Creator tax is a distinct bucket.
5. Permissionlessly, Factory `graduate` checks readiness and Guard seedability, then drains Curve assets to Factory and records `Swept`. `createGraduatedPool` is separately permissionless and retryable: it initializes V4, registers the Hook, funds Executor, mints the full-range position, and Locker receives the LP NFT. The launch becomes `PoolCreated`.
6. Post-graduation V4 swaps invoke the Hook, which accrues and can sweep/rescue fees under the same snapshot policy. Hook buyback tokens enter BuybackVault; the Vault releases vesting proceeds through the escrow ABI.

## Economics and custody

Before graduation, Curve custody is accounted by:

```text
realQuote      = trackedQuote - quoteFeeBalance - creatorTaxBalance
quoteReserve   = phantomQuote + realQuote
reservedTokens = floor(supply * phantomQuote / (phantomQuote + graduationThreshold))
```

Readiness is exactly `sellableTokens() == 0`. At sweep, Factory records received—not merely nominal—assets. The V4 token seed is:

```text
floor(sweptTokens * sweptQuote / (sweptQuote + phantomQuote))
```

The excess launch tokens are permanently locked. This preserves the terminal-curve/opening-pool price-continuity objective without introducing a new economic constant. Accounting domains stay separate: curve reserves, protocol/creator fee credits, BuybackVault vesting balances, Factory swept reserves, and V4 LP NFT are not interchangeable custody.

## Lifecycle, roles, recovery, and trust boundaries

`NotGraduated → Swept → PoolCreated` is the normal launch path. `createGraduatedPool` is retryable during `Swept`. If a ready launch fails the viability preflight, owner-only `forceSweptGraduation` opens the same delayed recovery state; after `GRADUATION_RESCUE_DELAY`, owner-only `rescueSweptGraduation` can send the tracked assets to a recipient and marks `Rescued`. Curve fees have a factory-only rescue; Hook fees have an owner recovery path for unsupported/inexact asset conditions.

- Protocol owner: configures dependencies/terms, whitelisting and launch forwarding, reserves delayed creator-recipient override and rescue powers.
- Factory: only source that initializes Curve, deploys through Deployer, changes launch-recorded policy surfaces, and calls locker/executor paths.
- Creator recipient: controls its fee recipient transfer and may enable buyback; owner may only disable buyback directly.
- Permissionless: Curve trades, normal `graduate`, V4 pool creation, and matured creator-recipient-change execution.
- External protocols: ERC-20/native quote transfer behavior, V4 PoolManager/PositionManager/Hook callback behavior, Permit2 approvals, external escrow credit semantics.

## Doorway: reference-only machine

Doorway records a Monad↔Solana request/attestation/execution/cancellation lifecycle. It does **not** pull ERC-20s, mint/burn representations, settle a bridge, or call a token adapter. `ATTESTATION_DELAY` is declared but unused. For Monad→Solana migrations the request has a zero source hash; the current `processedAttestations[bytes32(0)]` latch means one such attestation consumes that shared key. This is a documented gap, not a settlement claim.

## External calls and source/documentation gaps

External calls include ERC-20 transfers/approvals, escrow credits, V4 initialize/swap/take/settle/position mint, Permit2 approval, native ETH sends, and Doorway’s off-chain relayer/guardian boundary. Critical exact-transfer checks exist in selected paths; arbitrary ERC-20 behavior remains an explicit trust surface.

Source-backed gaps:

- Factory stores snipe-tax configuration and calls Curve exemption, but Curve `exemptFromSnipeTax` is a stub and no runtime snipe-tax calculation exists.
- `TokenParams.salt` is documented CREATE2-related but Deployer takes no salt and deploys with `new`.
- No launchpad runtime tests exist beyond V1 Doorway coverage.
- No Kuru integration exists despite target product documents.

See `v1/01-architecture.*` through `v1/07-doorway.*` for source-to-diagram mapping. These source maps contradict any documentation that calls V1 a settled cross-chain bridge, a Kuru runtime, or a CREATE2 deployment system.
