# Failure Modes, Kill Criteria, and Operational Risks

**Status:** CANONICAL  
**Scope:** RetroPick native markets + PRISM Phase 1

A failure mode is not merely an implementation bug. It includes any sequence where the economic semantics, solvency assumptions, lifecycle, or evidence claims no longer match what the protocol actually guarantees.

---

# 1. MATH-1 kill criteria

## KILL-01 Unbacked PRISM mint

A legal/reachable action sequence produces:

```math
B_i<Sx_i
```

for any required component.

**Result:** `MATH-1 = FAIL`.

## KILL-02 Over-redemption

A holder can receive more than:

- proportional in-kind basket entitlement before final settlement; or
- deterministic final settlement entitlement after resolution.

**Result:** `MATH-1 = FAIL`.

## KILL-03 Double allocation

The same reserved balance units can simultaneously satisfy two independent liabilities.

The same token address being used by multiple series is not itself a failure.

**Result:** `MATH-1 = FAIL`.

## KILL-04 False replication acceptance

Admission accepts target `h` even though no canonical exact non-negative solution exists:

```math
Gx=h,\quad x\ge0
```

**Result:** `MATH-1 = FAIL`.

## KILL-05 Terminal insolvency

An admitted exact-backed series can become insolvent in any valid terminal world under the model assumptions.

**Result:** `MATH-1 = FAIL`.

## KILL-06 Illegal lifecycle path

A reachable sequence allows any of:

- mint after final resolution;
- `RESOLVED -> ACTIVE`;
- payoff mutation after finalization;
- settlement redemption before funding;
- backing release without liability reduction;
- archived liability resurrection.

**Result:** `MATH-1 = FAIL`.

## KILL-07 Settlement underfunding

A series can enter `REDEEMABLE` while:

```math
SettlementBalance<OutstandingSupply\times FinalPayout
```

**Result:** `MATH-1 = FAIL`.

## KILL-08 Precision extraction

Repeated valid fixed-point operations allow positive-value extraction beyond the accepted rounding bound.

**Result:** redesign MATH-1E precision policy before Solidity authorization.

## KILL-09 Native complete-set drift

A valid native-market action can cause complete-set accounting to diverge without an explicitly modelled resolution/redemption reason:

```math
YES_{supply}\ne NO_{supply}
```

or locked collateral no longer covers the complete set.

**Result:** native-market accounting design fails.

---

# 2. Market-thesis failure criteria

These do not automatically mean protocol insolvency, but they can invalidate the product thesis.

## MARKET-01 PRISM NAV dislocation does not converge

Under realistic simulated/live conditions, large persistent price deviations remain even when create/redeem is technically available.

Possible causes:

- insufficient capital;
- insufficient component depth;
- high execution costs;
- inventory constraints;
- poor market-maker incentives;
- operational latency.

**Result:** accounting may remain safe, but PRISM market thesis becomes `CONDITIONAL` or requires redesign.

## MARKET-02 Complete-set parity arbitrage is uneconomic

Executable Kuru depth/fees make both:

```math
Bid_Y+Bid_N>1+costs
```

and:

```math
Ask_Y+Ask_N<1-costs
```

rare or untradeable even when displayed mid-prices suggest mispricing.

**Result:** revise liquidity strategy; do not claim parity bots can maintain price quality.

## MARKET-03 Resolution jump destroys maker economics

Market makers experience unacceptable stale-order or inventory losses around resolution/maturity.

**Result:** require cancellation/requote policy, wider risk bands, inventory controls, or different liquidity design.

## MARKET-04 No demand

Technically correct assets receive negligible user interest, volume or retention.

**Result:** product validation failure, not mathematical failure.

---

# 3. Execution and backing risks

## RISK-01 Partial multi-leg fill

An AP/creator attempts to acquire multiple backing components and only some legs fill.

**Required behavior:**

- do not mint PRISM;
- cancel remaining orders where possible;
- unwind or hold the filled component under an explicit inventory policy;
- never count an intended but unfilled component as backing.

## RISK-02 Stale exchange quote

A quote used for component acquisition becomes stale before execution.

**Mitigation:** max cost, deadline, executable-side orderbook reads, explicit slippage/inventory policy.

## RISK-03 Backing/LP accounting collision

The same component units are treated as both PRISM backing and Kuru LP/market-maker inventory.

**Mitigation:** separate custody/accounting domains and explicit events.

## RISK-04 Fee-on-transfer / non-standard ERC-20

A component transfer results in less vault balance than requested.

**Mitigation:** allowlist supported component semantics or verify balance delta rather than trusting requested transfer amount.

## RISK-05 Reentrancy on redemption/settlement

External token transfer or callback re-enters before liability/accounting is safely updated.

**Mitigation:** checks-effects-interactions, reentrancy guard where appropriate, pull-oriented settlement patterns.

---

# 4. Resolution risks

## RISK-06 Resolver outage

The event has ended but the accepted resolver path does not finalize.

**Consequence:**

```text
secondary trading may continue
final payout is not yet canonical
final cash redemption is blocked
```

Safe pre-resolution in-kind redemption may remain available only if lifecycle rules explicitly permit it.

## RISK-07 Wrong or mutable ResolutionSpec

A market is activated with ambiguous resolution semantics or those semantics can later change.

**Mitigation:** immutable/pinned ResolutionSpec before users acquire claims; test resolution fixtures.

## RISK-08 Duplicate finalization

A second result can overwrite the first.

**Mitigation:** one-time finalization state and invariant tests.

## RISK-09 Partial-resolution transform mismatch

A resolved component is converted to settlement value incorrectly, changing remaining PRISM payoff.

**Mitigation:** require payoff-equivalence rule and differential fixture before transformation support is authorized.

---

# 5. Exchange and post-resolution risks

## RISK-10 Stale orders at resolution

After final outcome becomes known, existing Kuru maker orders may be far from fixed redemption value.

**Consequence:** arbitrageurs can pick off stale liquidity.

**Mitigation:** market makers cancel/requote around maturity/resolution; RetroPick UI marks state clearly. RetroPick cannot assume it controls an external immutable market's entire orderbook.

## RISK-11 Losing token continues to trade

A zero-payout token may still have dust/speculative orders.

**Interpretation:** technical transferability does not imply protocol redemption value.

## RISK-12 Quote-token volatility after resolution

A fixed-value PRISM claim can continue moving against a volatile quote ERC-20.

This is expected relative-value behavior, not renewed event uncertainty.

---

# 6. Outage distinctions

## Kuru unavailable

Likely effects:

- secondary trading unavailable;
- exchange-based component acquisition unavailable;
- direct protocol redemption may remain available.

## Resolver unavailable

Likely effects:

- canonical final result delayed;
- final settlement blocked;
- safe pre-resolution paths depend on lifecycle state.

## Envio unavailable

Likely effects:

- read model/UI analytics degraded;
- contracts remain authoritative;
- protocol safety must not depend on indexer availability.

## CRE unavailable

Likely effects:

- automated resolution orchestration delayed;
- fallback resolver path, if any, must be explicitly documented and constrained.

---

# 7. Scope risks

## SCOPE-01 Reintroducing BackingMirror into Phase 1

Same-chain Monad backing already has an authoritative onchain state.

Adding an oracle-fed mirror creates unnecessary stale-state and trust surfaces.

**Phase-1 decision:** reject.

## SCOPE-02 Per-state runtime mint checks

Enumerating all terminal states in Solidity is unnecessary for exact-admitted non-negative replication and scales poorly.

**Phase-1 decision:** admission proves `h=Gx`; runtime enforces `B_i>=Sx_i`.

## SCOPE-03 Cross-chain backing before native kernel is stable

External custody/wrapping adds replay, bridge, settlement-transport and custody risk.

**Phase-1 decision:** defer.

## SCOPE-04 Treating retail BUY as primary CREATE

Forcing every user through multi-leg component acquisition makes the product unnecessarily complex.

**Phase-1 decision:** retail BUY uses Kuru secondary market; CREATE is separate.

---

# 8. Evidence and claim risks

## CLAIM-01 Unverified sponsor API

Documentation may contain illustrative pseudocode that does not match the current sponsor SDK.

**Rule:** mark examples conceptual until verified against current official API and test evidence.

## CLAIM-02 Overstated arbitrage certainty

Do not write "price must stay in the band".

Use:

> deviations outside executable bounds create arbitrage incentives under sufficient capital/liquidity/execution assumptions.

## CLAIM-03 Unsupported legal conclusion

Do not assume:

- a passkey is legal identity/KYC;
- a disclaimer makes a market compliant;
- a market category is exempt without jurisdiction-specific analysis.

Hackathon docs should describe technical controls and defer production legal conclusions.

## CLAIM-04 Unsupported community eligibility

Community bounty eligibility must be proven by actual official evidence. Do not infer eligibility from informal affiliation.

---

# 9. Future cross-chain risk namespace

External wrapped prediction assets are out of Phase 1.

A later design must separately analyze:

- locked-underlying versus wrapped-supply solvency;
- deposit/mint/burn/unlock message lifecycle;
- replay protection;
- reorg/finality;
- custody failure;
- settlement asset transport;
- bridge/oracle trust assumptions.

Attestation alone must never be described as backing.
