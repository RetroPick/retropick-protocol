---
id: LP-PROTO
type: normative
product: launchpad
version: v2
status: active
---

# Protocol

A Launch binds:
- token/supply policy;
- primary bonding mechanism;
- quote asset/economics;
- fee policy;
- creator configuration;
- graduation threshold/state;
- mature-market destination identity once complete.

## Creation

Factory validates launch configuration, quote policy, token metadata/economic bounds and deterministic deployment requirements. Per-launch economic fields that must not change underneath users are snapshotted.

## Active trading

The curve owns primary buy/sell arithmetic and real reserve accounting. All transfers reconcile explicit reserves and fee destinations.

## Graduation

Graduation is a state transition, not merely a UI/listing event. The protocol first secures assets/terminates the active curve path, then executes a retryable external Kuru destination step.

## Post-graduation

The mature market is Kuru for P0. Ordinary bonding trading cannot silently resume after terminal successful graduation.

## Authority

Owners/operators may only exercise enumerated bounded configuration/recovery capabilities. Creator settings do not bypass protocol fee/quote/market-parameter policy.
