---
id: LP-GRAD
type: normative
product: launchpad
version: v2
status: active
---

# Graduation

Graduation transitions a launch from RetroPick primary price discovery to Kuru mature trading.

```text
ACTIVE
-> GRADUATION_READY
-> secure/finalize curve assets
-> GRADUATING
-> create/configure Kuru market
-> verify destination
-> GRADUATED
```

## Required properties

- threshold condition is explicit and deterministic;
- same quote asset by default;
- assets are secured before external venue work;
- Kuru failure cannot lose secured assets;
- external step is safely retryable;
- duplicate graduation is impossible;
- terminal graduated launch does not resume normal curve trading;
- recovery is explicit, delayed/bounded as accepted, and observable;
- destination market parameters follow protocol policy, not arbitrary creator values.

The current code is V4-oriented; Kuru is TARGET until implementation/evidence closes the integration gate.
