# FeeEscrow financial-branch increment

**Scope:** production `RetroPickFeeEscrowV2` against unit fixtures; this is not full Core P0 qualification. **Branch:** `codex/kuru-freeze-smart-contract-spec`. **Toolchain:** Foundry, solc 0.8.26, current repository configuration.

From `contracts/`:

```bash
forge test --match-path test/v2/unit/RetroPickFeeEscrowV2Qualification.t.sol --summary
```

Result: **8/8 PASS**. New tests cover repeated native and ERC20 credits, partial then full claims, zero-credit double-claim rejection, an ERC20 that returns false only at payout time, a token that becomes sender-surcharge-bearing after credit (with surplus making the malformed payout executable), and a native recipient attempting to reenter its claim callback. Rejected payout paths preserve recipient credit, aggregate liability and physical assets. The reentrant callback cannot collect a second unit.

The tests extend the existing exact-receipt, donation segregation, externally reduced balance, and sender-surcharge-credit negatives. They do not prove Curve fee allocation, buyback vesting, successful V4 graduation, or all supported-asset end-to-end accounting. `CORE_BASELINE_P0_QUALIFIED` remains **BLOCKED**.
