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

Echidna, Medusa, Halmos, Mythril, semgrep, and solhint were not installed. Classification: BLOCKED_TOOL.

No open Critical or High issue is known inside the qualified standard-ERC-20, cumulative-floor policy. The resolver's authority to choose the result is an accepted High trust assumption, not an accidental bug. It blocks any claim of trustless resolution. PRED-CONTRACT-1 therefore does not PASS.
