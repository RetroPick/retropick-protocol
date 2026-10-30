# Baseline findings and investigation queue

Severity describes potential impact in the proposed constitution-enabled mode; it is not proof of an existing exploit.

| ID | Severity | Impact / precondition | Source | Reproducer / result | Required next action |
|---|---|---|---|---|---|
| CE-B-001 | High design conflict | Protocol owner can redirect future creator revenue after delay | Factory setCreatorFeeRecipient / executeCreatorFeeRecipientChange | Existing testCreatorFeeRecipientOverrideIsDelayedAndSupersedesInterveningTransfer; new reproducer pending | CE launches must reject this bypass and use declared controller recovery |
| CE-B-002 | High rights conflict | Factory handoff also redirects vested but unreleased buyback tokens | Factory _setCreatorFeeRecipient; BuybackVault updateCreatorRecipient | Source-confirmed behavior; dedicated old-rights test pending | Freeze old CE beneficiaries independently of controller identity |
| CE-B-003 | Medium disclosure defect | Users may believe salt determines launch addresses | Factory TokenParams.salt; LaunchDeployer deployLaunch | Existing testCurrentSaltDoesNotAffectAddressesFromIdenticalPrelaunchState inventoried | Preserve production; correct experimental disclosure, avoid accidental CREATE2 migration |
| CE-B-004 | Medium disclosure defect | Claimed anti-snipe exemptions have no effect | Curve exemptFromSnipeTax | Planning no-op unit test passed | Mark unavailable; auction/anti-snipe work deferred |
| CE-B-005 | Qualification blocker | Same contract names make basename deployCode ambiguous | test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol:159,177,180 | Planning run: 32 passed, two setup failures; isolated run captured separately | Separate canonical build; new fixtures use full source paths |
| CE-B-006 | High economic integration risk | Kuru trading volume mistaken for collectible community income | KuruLiquidityLock; IKuruV2; pinned upstream fee collector | Source evidence only, no live claim test | Reject unsupported revenue claims |
| CE-B-007 | High external trust risk | Owner-admitted asset changes balances or transfer behavior | QuoteAssetRegistry _validateIdentity; Curve _requireQuoteBacking | Existing exact-transfer/deficit tests partially reproduced | Restrict experiment profiles and retain fail-closed physical backing checks |

Preserve every future failing trace, seed, command and source hash. A passing unit test is not an audit. No reserve theft or exploitable loss is claimed by this checkpoint.
