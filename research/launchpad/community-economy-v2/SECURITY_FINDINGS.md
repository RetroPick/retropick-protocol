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

## Executable rights reproduction — iteration 001

BaselineRightsConflict.t.sol demonstrates CE-B-001/002 using explicit canonical reference fixtures: testAccruedUnsweptFeesFollowReplacement and testUnreleasedVestingFollowsReplacementButEscrowCreditDoesNot both pass. These confirm intended existing powers that conflict with the proposed CE temporal guarantee; they are not arbitrary-attacker exploits. Already credited native escrow rights remain unchanged.

Registry independent review: creator cap limits declared creator-category BPS, not beneficial ownership. Pinned module addresses do not prove module behavior. These remain nonproduction qualification limits; see iteration evidence review.

## Iteration 002 investigations and fixes

| ID | Severity / classification | Preconditions and result | Reproducer / remedy |
|---|---|---|---|
| CE-M2-001 | High integration conflict, FIXED_EXPERIMENT | New CE pool could otherwise inherit legacy creator fees outside its checkpoint scope; no deployed exploit alleged | CommunityV4RegistrationTest exercises actual executor and real hook; zero CE hookFee/tax, buyback disabled; permanent NFT custody and snapshot nonretroactivity checked |
| CE-M2-002 | Medium liveness defect, FIXED_EXPERIMENT | Expired recovery proposal could prevent voluntary scheduling after guardian inactivity | testCEExpiredRecoveryCanBeClearedWithoutGuardian; permissionless nonce-checked expired cleanup changes no controller or credits |
| CE-M2-003 | High external trust limit, UNSUPPORTED | Admitted token destroys router backing or changes transfer behavior | Failure/deficit, surcharge, receiver-tax, false-return and two-launch isolation tests; fail closed, never mint replacement claims or borrow another router's backing |
| CE-M2-004 | Qualification hazard, MITIGATED | Compiler artifact basename can refer to canonical curve after a mixed build | Experimental source-only ABI/size build; metadata compilationTarget identity checked; tests use fully qualified identities |
| CE-M2-005 | Test harness defect, FIXED_EXPERIMENT | Invariant fixture inherited unit tests whose fresh-launch assumptions conflicted with seeded invariant state | Failed broad run retained; reusable abstract fixture separated from executable flow tests; final 22-test campaign passes |

CE-B-001/002 remain canonical intended authority, not arbitrary attacker exploits. CE mode experimentally rejects owner/creator legacy override and buyback toggles; real controller and beneficiary rotation tests preserve old credits. CE-B-003/004 remain unavailable CREATE2/anti-snipe disclosure issues; no new implementation claim. CE-B-005 uses source-qualified fixtures. CE-B-006 stays blocked. CE-B-007 is bounded by chain/asset identity, original registry admission and exact sender/receiver checks; negative rebases remain an external solvency assumption.

Independent agent static review found no remaining critical/high financial correctness defect in the narrowly scoped curve path. It did not run tests or audit the whole system. Slither reports 49 results, including high labels on arbitrary-from transfer helper and OpenZeppelin modular-inverse xor. Each result has a disposition in slither-triage.json: immutable source authentication, guarded checkpoint with post-authority validation, intentional zero-initialized numeric sums, expected pull-call/timestamp semantics, and upstream arithmetic/assembly notices. Semgrep ran 50 rules over 36 files, yielding 123 performance suggestions, zero parser errors; individual locations/dispositions preserved. Neither scan is a clean external audit.

Controller recovery-priority/cancellation races and exact timing boundaries need broader sequence tests. Full CE-I-001–028, every LP invariant, actual v4 integration, live Kuru entitlement, four-archetype economic viability, full deployment qualification and independent audit remain open. No fork PASS is claimed.
