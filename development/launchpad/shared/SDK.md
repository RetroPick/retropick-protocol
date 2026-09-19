---
id: LP-SDK
type: normative_implementation
status: ready
owner: launchpad-integrations
product: launchpad
version: v2
---

# SDK

Target `packages/sdk`.

Responsibilities:
- typed contract reads;
- transaction builders for create/approve/buy/sell/graduation operations exposed to users/operators;
- receipt/event parsing;
- deployment-address resolution;
- Kuru client boundary after official API pin;
- quote helpers only where exact parity with Solidity is tested.

SDK does not become an alternative protocol implementation.
