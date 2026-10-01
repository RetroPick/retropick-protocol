# Core P0 quote-accounting qualification increment

**Status:** scoped executable evidence, not `CORE_BASELINE_P0_QUALIFIED = PASS`.  **Branch:** `codex/kuru-freeze-smart-contract-spec`.  **Fork:** Monad Testnet chain 10143, block 66752717.  **Compiler:** solc 0.8.26 through the current Foundry configuration.  Tests were run with `MONAD_TESTNET_RPC_URL` loaded from `contracts/.env.local`; no signing key or live transaction was used.

## Closed counterexample: surcharge on Factory payout

Earlier Curve and FeeEscrow balance-delta guards rejected a quote token whose sender loses more than the recipient gains, but `RetroPickLaunchFactoryV2._transferExact` checked only the recipient. An asset could behave exactly during bonding and become sender-surcharge-bearing before the V4 seed transfer. With a surplus balance at the Factory, the recipient would receive `amount`, while Factory would spend `amount + surcharge`; the old check would pass and silently reduce secured backing.

The Factory now compares its own pre/post balance as well as the recipient's. The regression fixture toggles the surcharge only after a real launch/buy/sweep, adds enough surplus for the malformed transfer to execute, drives the V4 path to the payout, and requires `InexactTransfer(token, amount, amount + surcharge)`. The transaction rolls back; swept quote and the `Swept` phase remain unchanged. A token whose sender balance unexpectedly *increases* also fails closed through checked subtraction. This is an adversarial negative, not an admitted P0 quote asset.

The Factory was already close to EIP-170. Two redundant admission checks were removed to accommodate the sender check: the constructor still invokes `quoteAssetPolicy.isSupportedQuote(address(0))` (an EOA or invalid interface fails decoding), while non-native launch still requires `approvedPairTokens[pairToken]` and its economically pinned configuration was validated by the quote policy when set. The runtime is now **24,565 bytes**, only **11 bytes** below the 24,576-byte EIP-170 ceiling. Further Factory feature additions are unsafe without extracting code. See `factory-bytecode-budget-2026-09-30.md`.

## Canonical Circle Core fork slice

The pinned-fork test uses the actual chain-10143 Circle test USDC address from the P0 policy, not Kuru-listed test USDC. It creates a launch with the production quote policy, buys across the graduation threshold using the real token, then checks:

- Curve quote backing is zero after sweep; Factory physical quote equals recorded secured quote.
- Creator, Factory and FeeEscrow physical balances conserve the test's 150e6 funded units; FeeEscrow physical balance equals its token liability.
- A deliberately unconfigured V4 completion reverts; Factory secured quote and launch phase are unchanged.

This proves a **real-token Core launch/buy/sweep plus failed-V4 rollback** at one block. It does not prove successful V4 graduation, Kuru completion, issuer liveness, or all Circle behaviors across time.

## Reproduction

From `contracts/`:

```bash
set -a; source .env.local; set +a
forge test --match-path test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol --summary
forge test --match-path 'test/v2/unit/*' --summary
forge test --match-path test/v2/invariant/RetroPickCurrentCurveV2Invariant.t.sol -vv
forge build --sizes --skip test
```

Observed in this increment: Factory integration **17/17 PASS**, unit suites **20/20 PASS** (including two 256-run math fuzz cases), default Curve invariant **64 runs × 64 depth = 4,096 calls**, 0 reverts, 0 discards, 2/2 test functions PASS. The default invariant run took 4,626.44 seconds; it was allowed to finish rather than replaced by a smaller smoke profile. The invariant handler covered buy (1,048 calls), sell (1,057), sweep (1,003), and unauthorized mutation (988). These are tests of a bounded handler, not a proof of every Core branch.

## Supported-asset buyback and vesting extension

Four later tests extend the same real Factory/Deployer/Token/Curve/FeeEscrow/BuybackVault path to the missing near-terminal and repeated-sweep branches for both P0 quote classes:

- `testNativeNearGraduationBuybackFoldsIntoCreatorFees`
- `testPinnedCircleNearGraduationBuybackFoldsIntoCreatorFees`
- `testNativeRepeatedBuybackSweepsAndPartialFullVest`
- `testPinnedCircleRepeatedBuybackSweepsAndPartialFullVest`

The near-terminal fixture buys to 101.3 quote units with sellable tokens remaining, then sweeps. Because an internal near-terminal swap would consume the reserved pool allocation, the pending buyback earmark folds into creator fees rather than reducing real quote reserve. Curve fee, tax and buyback buckets clear; Curve physical quote remains exactly `trackedQuote`; and the production FeeEscrow records the exact protocol/creator split for native balance or the actual chain-10143 Circle token.

The repeated-sweep fixture performs a second buy and sweep over the same launch, then checks partial release at the half-way vesting point and full release at the end. Across both sweeps, Curve fee/tax/earmark buckets clear to zero while physical quote equals tracked quote. BuybackVault custody equals `totalLocked`; partial release is strictly between zero and locked; final release makes creator-received tokens plus prior release equal locked; vault token custody reaches zero; and FeeEscrow launch-token custody equals `totalTokenLiability`.

Observed with Foundry 1.8.3, solc 0.8.26, Monad Testnet fork block 66752717 and the canonical Circle address:

```text
forge test --match-path test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol --summary
  21/21 PASS

forge test --match-path test/v2/integration/RetroPickV4GraduationBehavior.t.sol --summary
  12/12 PASS
```

Representative new gas costs were 4,040,927 (native fold-back), 20,112,711 (Circle fold-back), 5,371,965 (native repeated sweep/vest), and 21,578,690 (Circle repeated sweep/vest). These are local fork measurements, not network SLOs.

This closes the previously listed multiple-sweep, intermediate-vesting and near-graduation fold-back test gaps for both supported quote classes. It does not prove successful supported-asset V4 graduation/retry, every fee escrow callback fault, post-graduation hook swaps, a full stateful Factory/escrow/custody campaign, or Factory extraction.

## Remaining Core blockers

Factory extraction/code-size qualification and a comprehensive Factory/escrow/custody stateful invariant matrix remain open; any remaining FeeEscrow-callback or accepted-P0 post-graduation-hook gap must be named specifically. Native and Circle V4 success/failure/retry/replay behavior is now covered by `contracts/test/v2/integration/RetroPickV4GraduationBehavior.t.sol`, and the named FeeEscrow callback/fault matrix is covered by `contracts/test/v2/unit/RetroPickFeeEscrowV2Qualification.t.sol`. `CORE_BASELINE_P0_QUALIFIED` stays **BLOCKED**. The Circle issuer's freeze/blacklist powers remain an external liveness risk, not a solvency test result.
