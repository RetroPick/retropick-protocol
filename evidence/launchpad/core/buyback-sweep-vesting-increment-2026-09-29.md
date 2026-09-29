# Core V2 buyback sweep and vesting qualification — 2026-09-29

**Baseline:** `ece28568312b10820075bf5a4cd025852b39c287` on `codex/launchpad-v2-core-qualification`, matching `origin/main` at the start of this increment. **Status:** `CORE_BASELINE_QUALIFIED = BLOCKED`. No production Solidity changed.

`contracts/test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol::testTrustedFeeSweepLocksBuybackTokensAndPreservesQuoteAccounting` uses a real current Factory, Deployer, Token, Curve and BuybackVault. V4-only dependency getters, fee-policy getter and FeeEscrow are test doubles; this is a present-code behavioral characterization, not production FeeEscrow or Kuru qualification.

Sequence and observed assertions:

1. Launch with creator-selected buyback enabled and buy for 10 native quote units. The Curve accrues base fee, separate creator tax and a buyback earmark drawn from the creator's base-fee slice.
2. Creator sweep with pending buyback reverts `InternalSwapRequiresOperator`. The trusted operator's deliberately impossible minimum-output sweep reverts `SlippageExceeded`, preserving all fee buckets and leaving vault lock zero.
3. Trusted operator sweeps with a feasible floor. The Curve clears fee/tax/earmark buckets, physically retains the earmark as real quote reserve, credits the protocol and creator quote split to the test escrow, and transfers the internally purchased launch tokens to the real BuybackVault. `physicalQuote == trackedQuote`, and vault token balance equals its `totalLocked` accounting.
4. After the vault's five-year vesting duration, an unrelated caller cannot release. The creator can release the full locked amount; vault accounting and token balances reconcile, and protocol/creator test-escrow token credits match the frozen 30/70 split.

The fixture does not prove all buyback cases: multiple overlapping deposits, intermediate vesting/rounding, fold-back near graduation, failed real escrow callbacks, or post-graduation hook swaps. The test escrow uses a simplified per-recipient ledger and does not prove asset-segregated production accounting; a production FeeEscrow implementation is absent locally. The launch token is fixed code, so a fee-on-transfer launch token is outside this fixture. The `buybackQuoteBalance` subset is not double-deducted from the real quote reserve.

**Reproduction:** `cd contracts && forge test --match-test testTrustedFeeSweepLocksBuybackTokensAndPreservesQuoteAccounting -vv` — pass. Fixture SHA-256: `9e9e8cec3bab8e290a11be6682d1cbb08b50a6b733ee37e8aece13070cd5723f`. This adds partial evidence to `LP-I-002`, `LP-I-004`, `LP-I-005` and `LP-I-011`; no full invariant PASS follows.
