# Resolution

**Status:** CANONICAL RESOLUTION SEMANTICS  
**Lifecycle source:** `../protocol/STATE_MACHINE.md`

Resolution determines terminal component payoffs. `RESOLVED` and `REDEEMABLE` are distinct states.

---

## 1. Native market resolution

Every native prediction market must have an immutable or otherwise protocol-constrained `ResolutionSpec` defining at minimum:
- question/condition;
- source(s);
- resolution timestamp/window;
- outcome mapping;
- invalid/cancelled-event behavior;
- resolver/orchestration authority;
- dispute/finality assumptions where applicable.

A creator may define the market, but may not arbitrarily rewrite payoff semantics after activation.

---

## 2. CRE role

Chainlink CRE may orchestrate observation and onchain writes where appropriate.

CRE is not Phase-1 backing authority.

Do not use:

```text
same-chain BackingVault
-> offchain CRE observation
-> BackingMirror
-> mint authorization
```

for balances already authoritative on Monad.

---

## 3. Native binary terminal values

For a valid ordinary binary resolution:

```text
YES wins -> YES=1, NO=0
NO wins  -> YES=0, NO=1
```

The complete-set collateral remains the source of redemption value.

---

## 4. PRISM partial resolution

A PRISM series may contain components with different resolution times.

If component `i` resolves to terminal value `r_i`, its uncertain contribution:

```math
x_i P_i(t)
```

becomes fixed:

```math
x_i r_i
```

while unresolved components remain live.

Canonical partial-resolution valuation identity:

```math
NAV_t=\sum_{i\in R}x_i r_i+\sum_{j\in U}x_jP_j(t)
```

If resolved component tokens can be redeemed for settlement asset, backing may be transformed from resolved token units into equivalent cash only when payoff equivalence is preserved and accounting remains solvent.

No PRISM supply change is required merely because one component resolved.

---

## 5. Correct `pFEDBTC` example

Canonical series:

```math
pFEDBTC=0.6\,FED\_YES+0.4\,BTC\_NO
```

Terminal payouts:

| Fed outcome | BTC condition outcome | FED_YES | BTC_NO | PRISM payout |
|---|---|---:|---:|---:|
| No | No | 0 | 1 | 0.40 |
| No | Yes | 0 | 0 | 0.00 |
| Yes | No | 1 | 1 | 1.00 |
| Yes | Yes | 1 | 0 | 0.60 |

The historical report example that assigned `0.60` to `Fed=YES, BTC=NO` is superseded.

---

## 6. Final PRISM resolution

When every payoff-relevant component is final:

```math
R=h(\omega^*)
```

The protocol can transition to:

```text
RESOLVED
```

meaning final payout is immutable and known.

This does NOT yet imply users can be paid.

---

## 7. Settlement funding gate

Before entering:

```text
REDEEMABLE
```

require:

```math
SettlementBalance\ge OutstandingSupply\times R
```

within the accepted fixed-point policy.

Then final redemption is:

```text
burn Q PRISM
-> transfer Q * R settlement asset
```

This gate prevents a protocol from knowing the correct payout while lacking the assets required to honor it.

---

## 8. Zero-payout claims

If:

```math
R=0
```

the claim is economically worthless after finality but may remain technically transferable until burned/archived.

The UI should show final loss and make redemption/burn semantics explicit rather than continuing to present the token as an unresolved prediction.

---

## 9. Post-resolution trading

Resolved ERC-20 claims may remain transferable and can continue trading.

For fixed payout `R` against quote token `Q`:

```math
P_{PRISM/Q}\approx R/P_{Q/USD}
```

before fees/risk.

Thus event uncertainty disappears but quote-asset volatility can remain.

---

## 10. Failure behavior

Distinguish operational failures:

```text
Kuru unavailable
-> secondary trading unavailable
-> protocol mint/redeem may remain available

resolver unavailable
-> resolution delayed
-> final cash settlement blocked
-> safe pre-resolution in-kind paths may remain available according to lifecycle policy
```

Never claim final redemption remains possible when the canonical outcome is not yet known.
