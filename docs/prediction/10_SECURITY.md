# Security

Threats use the kernel and the reference model as they exist. No mainnet deployment is authorized.

| ID | Severity | Issue | Status | Evidence |
|---|---|---|---|---|
| S-P1 | Critical | Unbacked mint or admin withdrawal of live collateral | Open. No admin mint function. User mint reverts. Not closed by an audit | `test_user_cannot_mint_outcome`; Python `admin_mint` rejection in `research/prediction-model/adversarial.py`. Audit: NOT_YET_VALIDATED |
| S-P2 | High | Fee-on-transfer credited in full | Open as a High until an audit. The kernel reverts on shortfall in the tested case | `test_fee_on_transfer_split_reverts` and `prediction_rejections.json` `fee_on_transfer` |
| S-P3 | High | Rebasing collateral | Open. Disqualified. A downward rebase remains a counterexample to snapshot accounting | Python `rebasing_collateral` rejection. No rebase harness: NOT_YET_VALIDATED |
| S-P4 | High | INVALID half-up insolvency | Open as a High until an audit. The qualified path uses the cumulative floor | `prediction_invalid_rounding.json`; `docs/prediction/07_ROUNDING.md` |
| S-P5 | High | Resolver pauses redemption | Open as a High until an audit. `openRedemption` is permissionless and the kernel has no pause | `PredictionMarket.openRedemption`. No pause-bypass proof beyond the missing function |
| S-P6 | Medium | Resolver sets a false result | Accepted trust for Phase 1. Not mitigated by cryptography in this kernel | `docs/prediction/06_RESOLUTION.md` |
| S-P7 | Medium | Dust sink receives `C mod 2` | Explicit for the qualified INVALID policy. Not a general dust theorem | `prediction_archive_invalid.json` residual 1 on supply 5 |
| S-P8 | Low | Slither missing-zero-check | Constructor reverts on zero collateral, resolver, or dust sink. Slither itself did not finish | `evidence/research/prediction/slither-2026-09-26.txt` |
| S-P9 | Informational | Slither 0.11.6 failed to build IR for several functions | Tool limitation. Not a clean Slither pass | `evidence/research/prediction/slither-2026-09-26.txt` |
| S-P10 | High | Kuru inventory or a Kuru price treated as prediction collateral | Open. No book was deployed. Redeem does not call Kuru | `research/integration/kuru/PARAMETER_WORKSHEET.md` |
| S-P11 | High | Outcome token deposited into PRISM before the source interface is frozen | Open. No deposit harness | `docs/prism/04-architecture/SOURCE_ASSET_INTERFACE.md` is `proposed_not_frozen` |
| S-P12 | Medium | ERC-1167 clone of `OutcomeToken` sharing immutable market, index, and decimals | Measured. The kernel still deploys two full tokens | `evidence/research/prediction/outcome-token-gas-2026-09-26.txt` |
| S-P13 | Low | `cancelDraft` is absent | Open. P-I05 cancelled-draft branch is NOT_YET_VALIDATED in the kernel | `docs/prediction/09_INVARIANTS.md` |
| S-P14 | Informational | Foundry issuance invariant calls `closeMint` and `beginResolution` | Held on the recorded run. Reverts are allowed by `fail_on_revert = false` | `evidence/research/prediction/invariant-ids-2026-09-26.txt` cites the full-suite figure 48023 handler reverts |
| S-P15 | Medium | `PredictionMarket.sol` branch coverage is 94.44% (34/36) | Open. `Underfunded` and `LiveLiability` true branches were taken 0 times. Not an audit close | `evidence/research/prediction/kernel-coverage-fuzz64-2026-09-26.txt` |

Echidna, Medusa, Halmos, Mythril, semgrep, and solhint were not installed. Classification: BLOCKED_TOOL.

S-P1 stays open. It is Critical and has not been closed by an audit. S-P2, S-P3, S-P4, S-P5, S-P10, and S-P11 stay open. A passing unit test is not an audit close. S-P6 stays an accepted trust assumption. The resolver can still report a false result. That blocks any claim of trustless resolution. S-P15 stays open. The remeasurement is 94.44% (34/36) branches, 100.00% (119/119) lines, and 98.75% (158/160) statements. The two remaining branches are the true side of `collateralLocked < liability()` in `openRedemption` (`Underfunded`) and the true side of `liability() != 0` in `archive` (`LiveLiability`). The earlier 30.56% (11/36) file is the prior run. PRED-CONTRACT-1 does not PASS. This table is not an admission claim.
