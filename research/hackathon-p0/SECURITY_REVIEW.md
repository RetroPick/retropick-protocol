# Hackathon P0 security review

Status: local research review; not an audit or production approval.

Scope reviewed on 2026-09-29:

- `PredictionFactoryP0`, `PredictionMarketP0`, and `OutcomeTokenP0`;
- `PrismFactoryP0` and `PrismSeriesP0`;
- caller-funded issuance, transfer, merge, resolution, winner redemption, and
  PRISM in-kind redemption;
- local unit, differential, stateful, and cross-module evidence linked from
  `research/reports/HACKATHON_P0_GATE.md`.

## Assets and authority

Prediction P0 controls one factory-configured ERC-20 collateral and creates
YES/NO claims only as complete sets. The resolver may close issuance and commit
one binary result. It cannot mint outcomes or remove collateral. PRISM P0 holds
the exact Prediction outcome tokens required by each outstanding PRISM unit.
PRISM redemption burns the caller's claim before transferring those tokens.
Neither module calls Kuru, an indexer, or a frontend in a solvency path.

`PredictionFactoryP0` and `PrismFactoryP0` addresses are deployment trust roots.
The PRISM factory binds one Prediction factory; its series creator is fixed at
deployment. Series creation records payoff, replication, and source-set hashes.
The creator must exact-recheck the off-chain certificate before admission; the
kernel does not prove general `h = Gx` certificates onchain. The local 50/50
demo fixture does pass exact rational recheck.

## Attack review

| Threat | P0 control and evidence | Result |
| --- | --- | --- |
| One-sided Prediction issuance | `split` pulls exact collateral, checks balance delta, then mints equal YES/NO; unit and stateful supply-conservation evidence | No counterexample in declared domain |
| Callback changes lifecycle during split | Shared reentrancy guard and post-transfer state check; historical callback witness remains a negative regression | Rejected with state preservation |
| Winner payout overflow or double pay | Winner formula pays exactly the burned raw amount; uint128 supply bound; repeated redemption requires remaining token balance | Bounded local evidence passes |
| PRISM mint consumes another user's prefunding | No standalone deposit; each mint pulls the minter's exact component amounts and checks received deltas | Bounded local evidence passes |
| Unregistered or cloned outcome token | Market must be in the configured factory registry and token address must equal that market's canonical YES/NO token | Clone regression rejects |
| PRISM holder-order rounding | Only exact rational lots are accepted; no floor/ceil or settlement cursor | Exact-lot proof and differential evidence pass |
| Reentrancy during PRISM transfers | Non-reentrant mint/redeem; admitted source code is the standard P0 OutcomeToken | No callback path in admitted source domain |
| Admin/resolver drains backing | No backing withdrawal, cash settlement, or dust-sweep method exists | No drain path in P0 ABI |
| Direct donations assigned to a minter | Donations remain unassigned surplus and cannot replace the minter-funded transfer | Negative control passes; donation may remain stranded |
| False payoff/replication metadata | Fixed series creator and immutable hashes; exact certificate review is an explicit off-chain admission assumption | Residual trust assumption, not onchain proof |
| Direct PRISM-series constructor bypass | Historical kernel allowed arbitrary callers to deploy a series directly, bypassing the pinned `PrismFactoryP0` creator and its canonical `isSeries` registry | `CX-HACK-PRISM-DIRECT-DEPLOY-001` was found at `da723095`; repaired at `4f3c70b` by requiring constructor caller/factory identity and matching Prediction factory. `test_directSeriesDeploymentCannotBypassCanonicalFactory` passes. The witness created an unregistered misleading asset; no direct backing theft was demonstrated. |
| Non-exact outbound value | Market and series compare both contract debit and recipient credit; fee-on-transfer Prediction collateral rejects atomically; PRISM self-receivers reject | Deterministic tests and 256-case winner/lot fuzz regressions pass |

## Tool findings and limitations

- Slither 0.11.6 on the Foundry project exits 255 while resolving inheritance
  and IR references. The isolated PRISM target also reports missing IR for
  `PredictionMarketP0.split`, `merge`, and redemption paths. Its dead-code
  reports for internal functions reached through those failed IR paths are not
  treated as confirmed findings.
- Aderyn 0.6.8 crashes while ingesting the five Hackathon Solidity files with
  `content not found` (exit 101).
- Solhint 6.2.4 completes with exit 0, zero errors, and 203 warnings under the
  checked-in recommended profile after the latest hardening. Warnings are primarily missing NatSpec,
  lower-case immutable naming, gas-style suggestions, and import aliases that
  Solhint does not resolve through Foundry remappings.

These limitations are recorded as `BLOCKED_TOOL`; passing unit or invariant
counts do not repair them. The independent evidence here is direct Solidity
execution, Python/Solidity fixtures, deterministic fuzzing, bounded stateful
invariants, and manual path review. The historical direct-constructor admission
gap has a permanent regression and is repaired in the current kernel. No
Critical or High defect is currently identified in the enabled local P0 paths
under the stated factory, token, resolver, and certificate assumptions; this
remains a scoped research review, not an audit.

## Deployment boundary

The local review uses standard test collateral. Live Monad testnet verification
found the documented USDC token has code and 6 decimals, and Kuru's documented
Router/MarginAccount addresses have code. No deployment or trading transaction
was sent. This environment exposed no testnet private-key or RPC credential
variables; live deployment, liquidity, order, fill, and cancel gates remain
`BLOCKED_EXTERNAL` pending a funded, authorized testnet wallet and P0
deployment.

This review applies only to the Hackathon P0 research profile. It does not alter
production Prediction/PRISM gates and does not establish an audit, production,
or mainnet status.
