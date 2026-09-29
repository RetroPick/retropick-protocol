# Core V2 Factory authority and quote-asset matrix — 2026-09-29

**Baseline for this increment:** `229987541fa7b907a34706a8897d0b850220972a` on `codex/launchpad-v2-core-qualification`; `origin/main` matched. Verified 2026-09-29 16:06 UTC. **Production Solidity changed:** NO. **Verdict:** `CORE_BASELINE_QUALIFIED = BLOCKED`.

The real current Factory/Deployer/Token/Curve path is exercised in `contracts/test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol` (SHA-256 `007bc19898c1f65865595697a7999d7cf41175d643b3db10bcf1a44710d9928d`). V4-only singleton getters and the fee escrow are test doubles, so none of these results qualifies a live destination or production fee escrow.

## New authority cases

| Behavior | Executable result | Classification |
| --- | --- | --- |
| Non-recipient attempts creator-fee transfer | Reverts; Factory recipient unchanged | `SUPPORTED_BY_EXECUTABLE_TEST_WITHIN_DECLARED_FIXTURE` |
| Owner proposes recipient override | Immediate permissionless execute reverts; creator can transfer during delay; matured owner proposal supersedes that transfer and updates Factory and Curve | `SUPPORTED_BY_EXECUTABLE_TEST_WITHIN_DECLARED_FIXTURE`; owner override is a real, broad fee-routing power |
| Owner attempts buyback enable | Reverts; creator can enable; owner can disable; Curve and Factory flags agree | `SUPPORTED_BY_EXECUTABLE_TEST_WITHIN_DECLARED_FIXTURE` |

The owner override is not a narrow lost-key recovery guarantee: it can replace a valid creator transfer after the delay. UI/admin disclosure and the remainder of the authorization/timelock matrix remain pending.

## New quote-asset cases

| Approved six-decimal quote behavior | Observed result | Consequence |
| --- | --- | --- |
| Exact-transfer ERC20 | Buy/sell preserve `physicalBalance == trackedQuote` | Positive control, scoped to this token and path |
| `transferFrom` returns false | Buy reverts with `SafeERC20FailedOperation`; reserve, supply allocation and buyer balance remain unchanged | Failure is atomic in this fixture; admission itself still succeeds |
| Callback on inbound `transferFrom` attempts nested buy | Nested call fails; outer buy succeeds with physical balance equal to tracked balance | Scoped `nonReentrant` evidence, not general callback safety |
| Sender-side surcharge on outbound transfer | After sell, `trackedQuote - physicalBalance == floor(payout / 10) > 0` | `COUNTEREXAMPLE_FOUND` to arbitrary approved-asset solvency; [minimal evidence](quote-surcharge-counterexample-2026-09-29.md) |
| External balance reduction after buy | A test token burns `1e6` units from the Curve; `trackedQuote - physicalBalance == 1e6` while `realQuoteReserve() > 0` | `COUNTEREXAMPLE_FOUND` to solvency under externally reducible/rebasing quote assets |

These negative controls do not establish that an exact-transfer stable asset is unsafe. They establish that current Factory code/decimals/economics checks are insufficient to prove the [P0 quote policy](../../../development/launchpad/contracts/QUOTE_ASSETS.md). Asset-specific admission evidence and external-state assumptions are required; approving an address is not the qualification.

## Reproduction and invariant mapping

- `cd contracts && forge test --match-path test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol -vv` — 13 pass, zero fail.
- `cd contracts && forge test --summary` — 75 pass, zero fail (45 Doorway, 30 Core V2 qualification). A passing negative-control test records a violated broad solvency proposition; it does not clear a gate.
- `cd contracts && forge build --sizes` — pass; Factory V2 runtime 24,106 B, 470 B below 24,576 B EIP-170 threshold for this unchanged production build profile.
- `cd contracts && forge fmt --check test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol` — pass.
- Foundry `forge 1.8.3` (`cae51ad458f6abb64852b7709eb784352429825d`), compiler `Solc 0.8.26` in test compilation; production source unchanged.

`LP-I-002` gains exact-transfer physical-balance positive evidence but fails if arbitrary owner-approved nonstandard quotes are in scope. `LP-I-005` and `LP-I-011` gain partial fee-controller/recipient ACL evidence. `LP-I-010` gains admission-positive and adversarial-negative evidence, not a full PASS. No LP-I row is promoted to full PASS. Full fee/buyback execution, expired/cancelled overrides, successful graduation/retry, live Kuru target, and comprehensive stateful integration remain open.
