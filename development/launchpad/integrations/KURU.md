---
id: LP-INT-KURU
type: normative_implementation
status: blocked_external_verification
owner: launchpad-integrations
product: launchpad
version: v2
---

# Kuru Integration

Verified source pins:
- Kuru SDK main: `636509c2eafd63479d3f399703354e0d09f51e18` (2026-04-15 commit; message bumps package to 0.0.97).
- Kuru contracts public main: `2060bb2736080c175d80d568bfdb6226bb5abd04`.

Public Kuru architecture is an onchain orderbook with backstop AMM liquidity. SDK market creation exposes pair-specific size/price precision, tick size, min/max size, maker/taker fee and AMM spread.

Required before READY:
- target Monad router/deployer/market addresses;
- exact market-deploy ABI/SDK method;
- base/quote ordering;
- approval/transfer flow;
- market verification/read path;
- parameter bounds;
- initial backstop-liquidity flow;
- failure/retry behavior.

Do not implement against guessed addresses or interfaces.