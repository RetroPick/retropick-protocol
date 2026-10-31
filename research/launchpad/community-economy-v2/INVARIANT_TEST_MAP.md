# Scoped invariant map

TESTED means the cited local property/action sequence ran; it is not universal verification of the whole CE specification. `CommunityCurveFlowTest` uses actual experimental launch and trading sources. `CommunityAccountingInvariantTest` targets ten real economic actions; negative-only source impersonation uses prank explicitly. Destination seams and six-decimal Circle-address test code are mocks, not deployed identity evidence.

| ID | Local evidence | Remaining scope |
|---|---|---|
| CE-I-001 | totalFunded=totalPaid+totalLiability; actual trade fuzz | Other venue/strategy sources |
| CE-I-002 | Registry allocation validation; actual funded split | Beneficial ownership cannot be inferred |
| CE-I-003 | Protocol escrow vs community router vs net reserves | Executing rewards/LP/buyback modules absent |
| CE-I-004 | Native invariant; USDC funding/deficit/isolation tests | Unsupported rebases can destroy backing; no insurance |
| CE-I-005 | Policy activation and beneficiary rotation sequences | Full arbitrary historical-recipient ghost ledger |
| CE-I-006 | Registry bounds; CE owner override rejection | Declared categories only; complete governance review |
| CE-I-007 | Reverting beneficiary does not block treasury | Other asset-specific callback behaviors |
| CE-I-008 | Independent full/partial claim tests and conservation | Full claimant-address state space |
| CE-I-009 | BLOCKED: reward vault not implemented | M5 required |
| CE-I-010 | BLOCKED: no staking module | M5 required |
| CE-I-011 | CE legacy buyback disabled; reserves excluded | Executing strategy not implemented |
| CE-I-012 | Net reserve assertions; real graduation handoff | Future strategy path |
| CE-I-013 | Actual controller handoff preserves credit | Full recovery race campaign |
| CE-I-014 | Real source/coordinator handoff and local destination failure | Full destination retry/atomicity/fork qualification |
| CE-I-015 | CE v4 zero-fee snapshot; Kuru blocker retained | No live venue collector claimed |
| CE-I-016 | Existing quote admission; router chain/Circle identity; immutable source rates | Broader fee boundary sweep |
| CE-I-017 | Replay/auth/recipient reentry/transfer-failure tests | Broader malicious source factory implementation |
| CE-I-018 | Native/USDC legacy differential tests | Every legacy lifecycle transition |
| CE-I-019 | Registry nonce validation tests; source sequential settlement tests | Composite controller-policy replay sequences |
| CE-I-020 | Single pending policy; cancellation and delayed activation | Full recovery/proposal precedence campaign |
| CE-I-021 | Malicious receiver isolation | Additional external asset callback implementations |
| CE-I-022 | Direct donation and repeated settlement tests; invariant donate | Forced-native donation variant |
| CE-I-023 | CE buyback disabled at creation and administration rejected | Funded strategy budget shutdown semantics |
| CE-I-024 | Controller transition and beneficiary rotation preserve old claims | Legacy vest adapter not used in CE |
| CE-I-025 | Max10 recipients; aggregate credit O(1) claim; no epoch iteration | Long-history gas benchmark |
| CE-I-026 | Two USDC launch routers; one deficit cannot borrow the other's assets | Malicious asset balance reporting remains unsupported |
| CE-I-027 | Actual F/T swept before coordinator reserve handoff; claims survive | Live destination / multiple venue sources |
| CE-I-028 | Eight actual native/USDC legacy buy/sell cycles, fees/reserves/readiness | Full deployed/runtime equivalence is not established |

LP-I-001 through LP-I-012 remain canonical acceptance obligations in docs/launchpad/INVARIANTS.md. Their definitions and original tests were not edited. Canonical regression runs are separately captured, not replaced by CE conservation. No all-LP/all-CE qualification claim is made.

The handler catches failed economic calls; Foundry's outer `reverts=0` therefore does not mean every economic action succeeded. Final verbose invariant evidence includes successful-action counters and caught economic rejections, including deterministic reachability seeding. Seeded actions do not count toward the reported randomized 32,768 calls. The invariant does not test staking, strategy execution or live venue settlement.
