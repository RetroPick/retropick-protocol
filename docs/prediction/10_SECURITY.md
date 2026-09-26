# Security

Threats use the kernel and the reference model as they exist. No mainnet deployment is authorized.

| ID | Severity | Issue | Status |
|---|---|---|---|
| S-P1 | Critical | Unbacked mint or admin withdrawal of live collateral | No function. User mint reverts. Not closed by an audit |
| S-P2 | High | Fee-on-transfer credited in full | Kernel reverts on shortfall. Tested |
| S-P3 | High | Rebasing collateral | Disqualified. Not supported. A downward rebase is a counterexample to snapshot accounting |
| S-P4 | High | INVALID half-up insolvency | Rejected by cumulative floor. Tested in model and kernel |
| S-P5 | High | Resolver pauses redemption | `openRedemption` is permissionless. No pause |
| S-P6 | Medium | Resolver sets a false result | Accepted trust for Phase 1. Not mitigated by cryptography in this kernel |
| S-P7 | Medium | Dust sink receives `C mod 2` | Explicit and immutable. Bounded for the qualified INVALID policy |
| S-P8 | Low | Slither missing-zero-check | Constructor now reverts on zero collateral, resolver, or dust sink |
| S-P9 | Informational | Slither 0.11.6 failed to build IR for several functions (`Failed to resolved name`, missing inheritance). It reported uninitialized `yesRedeemed` because the failed IR did not see `_redeem` | Tool limitation. Those variables are written in `_redeem`. Not treated as a code defect, and not treated as a clean Slither pass |
| S-P10 | High | Kuru inventory or a Kuru price treated as prediction collateral | Open. No book was deployed. Redeem does not call Kuru |
| S-P11 | High | Outcome token deposited into PRISM before the source interface is frozen | Open. The freeze document is `proposed_not_frozen`. No deposit harness |
| S-P12 | Medium | ERC-1167 clone of `OutcomeToken` sharing immutable market, index, and decimals | Measured. The kernel still deploys two full tokens. Not closed as a future-schema risk |
| S-P13 | Low | `cancelDraft` is absent, so a draft cannot be archived by that operation | Open as a missing operation. P-I05's hash immutability is tested without it |
| S-P14 | Informational | Foundry issuance invariant now also calls `closeMint` and `beginResolution` | `forge test` 2026-09-26: 256 runs, 128000 calls, 48023 handler reverts, invariant held. Reverts are allowed by `fail_on_revert = false` |

Echidna, Medusa, Halmos, Mythril, semgrep, and solhint were not installed. Classification: BLOCKED_TOOL.

S-P1 stays open. It is Critical and has not been closed by an audit. S-P3 stays open as a disqualification: rebasing collateral is not supported, and a downward rebase is still a counterexample to snapshot accounting. S-P6 stays an accepted trust assumption. The resolver can still report a false result. That blocks any claim of trustless resolution. S-P10 and S-P11 stay open. PRED-CONTRACT-1 does not PASS. This table is not an admission claim.
