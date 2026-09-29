# Kuru P0 specification

Status: NOT_VERIFIED

Kuru is secondary execution infrastructure for Hackathon P0. It is not
Prediction backing, PRISM backing, resolution authority, or redemption
authority.

## Network verification

Before any transaction, verify from current official Kuru/Monad sources:

- network;
- chain ID;
- Router address;
- MarginAccount address;
- official quote/stable token;
- quote decimals;
- current SDK or Router path;
- bytecode at relevant addresses;
- retrieval timestamp and source URL/document.

Do not reuse stale addresses from old reports.

## Required markets

All are ERC20 / quote markets:

- YES / quote;
- NO / quote;
- PRISM / quote.

Market price does not alter Prediction payout, PRISM backing, or PRISM
redemption.

## Parameter policy

For every P0 market record:

- base token;
- quote token;
- base decimals;
- quote decimals;
- bootstrap reference price;
- max price;
- min size;
- tick BPS;
- pricePrecision;
- sizePrecision;
- tickSize;
- minSize;
- maxSize;
- maker fee;
- taker fee;
- AMM or vault spread if used.

Unless a parameter comes directly from immutable Kuru constraints, classify it
as `HACKATHON_DEMO_PARAMETER`.

Current official Router/SDK constraints and a reproducible, demo-only candidate
parameter set are recorded in:
`evidence/hackathon-p0/kuru/kuru-p0-parameter-packet-2026-09-29.json` and
`research/hackathon-p0/KURU_P0_PARAMETER_PACKET.md`. The candidate is not an
approved price, market deployment, or live-market qualification. Recompute and
review it against the actual deployed token decimals and intended demonstration
before sending any transaction.

## Live evidence gates

Local simulation is not live Kuru qualification. P0 Kuru readiness requires
timestamped live testnet evidence for market deployment, small liquidity,
order placement, fill, and cancellation. If RPC, wallet funds, faucet, quote
tokens, or Kuru infrastructure are unavailable, use `BLOCKED_EXTERNAL` with the
exact missing prerequisite and command ready to run.
