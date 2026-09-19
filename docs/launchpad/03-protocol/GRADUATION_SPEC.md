# Graduation Specification

**Status:** DRAFT CANONICAL  
**Owner:** Protocol + Integrations

Graduation is the transition from launch-specific primary price discovery to mature secondary trading.

```text
ACTIVE
-> threshold satisfied
-> GRADUATION_READY
-> secure graduation assets
-> GRADUATING
-> create/configure Kuru market
-> verify destination usable
-> GRADUATED
```

## Required properties

- same quote asset by default
- no hidden conversion during P0 graduation
- assets secured before external venue operations
- destination failure leaves assets recoverable and retryable
- no double graduation
- no normal primary trading after the terminal graduated state
- market parameters derived/validated rather than blindly creator-supplied
- explicit recovery authority and timelocks if recovery exists

## Acceptance

LP-KURU-1 must demonstrate a real supported-network destination market and transaction evidence before the product may claim Kuru graduation.
