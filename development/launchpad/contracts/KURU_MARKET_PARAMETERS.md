---
id: LP-SC-KURU-PARAMS
type: normative_implementation
status: blocked_external_verification
owner: launchpad-integrations
product: launchpad
version: v2
---

# Kuru Market Parameter Policy

Official Kuru material exposes pair-specific size/price precision, tick size, min/max size, maker/taker fee and AMM spread. Incorrect precision/min-size can make markets unusable or create DoS/economic problems.

## RetroPick policy target
Creators do not supply arbitrary raw values. A protocol-owned policy derives or selects parameters from:
1. base token decimals/supply;
2. quote token configuration;
3. expected graduated reserve ratio/price range;
4. Kuru-supported bounds;
5. approved fee/spread templates.

## Binding fields
- base asset;
- quote asset;
- sizePrecision;
- pricePrecision;
- tickSize;
- minSize;
- maxSize;
- makerFeeBps;
- takerFeeBps;
- kuruAmmSpread;
- initial liquidity/inventory.

## Blocker
Exact bounds and target deployment addresses remain blocked until the integration agent pins the concrete Kuru deployment/API for the hackathon environment and tests representative RetroPick launch sizes.
