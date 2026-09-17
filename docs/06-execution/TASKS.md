# Execution Tasks

`goals/active/` is the task-of-record. This file is the human-readable dependency rollup.

## Now — finish P1/P2

- [x] Reconcile the historical 40-page architecture report.
- [x] Correct canonical `pFEDBTC` payoff table.
- [x] Remove BackingMirror from Phase-1 target architecture.
- [x] Separate native market creation from PRISM creation.
- [x] Separate retail PRISM BUY from primary PRISM CREATE.
- [x] Freeze `RESOLVED != REDEEMABLE`.
- [x] Define component-wise runtime invariant `B_i >= S*x_i`.
- [x] Correct complete-set open-interest semantics in docs.
- [ ] Add executable complete-set/market math helpers to `research/prism-model/`.
- [ ] Add tests for bid/ask parity, open interest, PRISM create/redeem band, post-resolution quote pair.
- [ ] Add exhaustive bounded transition exploration.
- [ ] Add adversarial randomized action sequences.
- [ ] Add deterministic partial-resolution transformation fixtures.
- [ ] Define fixed-point numeric policy and rounding tests.
- [ ] Evaluate SymPy/Z3 proof assistance for core theorems.
- [ ] Produce final `MATH-1` verdict artifact.

## Next — CONTRACT-ARCH-1

Blocked until MATH-1 permits implementation.

- [ ] Contract/storage responsibility map.
- [ ] Native market interfaces.
- [ ] PRISM interfaces.
- [ ] Authorization/role model.
- [ ] Event schemas.
- [ ] Precision library design.
- [ ] Foundry invariant mapping.
- [ ] Differential fixture format.
- [ ] Deployment topology.

## Then — Solidity kernel

- [ ] CompleteSetVault.
- [ ] OutcomeToken.
- [ ] PredictionMarketFactory/market lifecycle.
- [ ] Resolution module.
- [ ] PrismSeriesFactory.
- [ ] PrismSeriesERC20.
- [ ] PrismBackingVault.
- [ ] PrismMintController.
- [ ] PrismRedemptionRouter.
- [ ] PrismSettlementEngine.
- [ ] Unit/fuzz/invariant/differential tests.

## Integration wave

Can begin against stable interfaces/mocks, but cannot redefine protocol accounting.

- [ ] Kuru token-pair deployment and liquidity scripts.
- [ ] Kuru trade execution evidence.
- [ ] Envio event schema/indexer.
- [ ] CRE resolution workflow against immutable ResolutionSpec.
- [ ] Alchemy transport/failover.
- [ ] Mera account integration if current SDK capability is verified.
- [ ] Aurora Intents funding flow if current capability is verified.
- [ ] MetaMask Agent automation after P0 user flows work.
- [ ] Nansen analytics after token addresses/liquidity exist.

## Product wave

- [ ] Browse markets.
- [ ] YES/NO detail + orderbook.
- [ ] Buy/sell outcome.
- [ ] Portfolio.
- [ ] Resolution/redeem.
- [ ] PRISM detail + payoff visualization.
- [ ] Retail PRISM trade.
- [ ] Advanced PRISM basket create.
- [ ] Evidence dashboard/admin.

## Submission wave

- [ ] Golden-path deployment.
- [ ] Evidence manifest.
- [ ] Tx hashes/addresses/market IDs.
- [ ] Test outputs.
- [ ] Demo video.
- [ ] Demo script.
- [ ] Bounty-specific evidence map.
- [ ] Final limitations/non-goals audit.
