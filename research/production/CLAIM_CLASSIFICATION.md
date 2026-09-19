# Claim Classification

Allowed classifications:

- VERIFIED_CURRENT_FACT
- VERIFIED_PINNED_FACT
- MEASURED_LOCAL
- MEASURED_CI
- MEASURED_TESTNET
- MEASURED_STAGING
- SIMULATED
- INFERRED
- RECOMMENDATION
- UNVERIFIED
- BLOCKED
- COUNTEREXAMPLE_FOUND

A claim should include claim_id, statement, platform/module, classification, source/evidence, retrieval/run date, environment, limitations, reverification trigger and implementation consequence.

Never promote SIMULATED into VERIFIED_CURRENT_FACT without new evidence.
