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

## Remaining Core blockers

Successful native and Circle V4 graduation/retry/replay, wider fee/buyback/failure branches, a comprehensive Factory/escrow/custody stateful invariant matrix, and a meaningful Factory code-size extraction remain open. `CORE_BASELINE_P0_QUALIFIED` stays **BLOCKED**. The Circle issuer's freeze/blacklist powers remain an external liveness risk, not a solvency test result.
