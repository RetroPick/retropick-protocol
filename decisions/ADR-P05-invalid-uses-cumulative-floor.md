# ADR-P05: INVALID is explicit and uses a cumulative floor

**Status:** PROPOSED  
**Date:** 2026-09-26

## Decision

Phase 1 results are YES_WIN, NO_WIN, and INVALID. INVALID pays 1/2 before rounding. Integer payout is the delta of `floor(redeemed / 2)`. Dust after full redemption of an equal complete set `C` is `C mod 2` and is sent to the immutable dust sink only at archive.

## Options

Forbid INVALID. Copy Polymarket's 50/50 automatically. Use half-up. Use per-call floor. Use cumulative floor.

## Evidence

Half-up of one unit on both sides pays 2. Per-call floor of one-unit redemptions pays 0. Cumulative floor matches fixtures and the Foundry fuzz `amount % 2`. Polymarket's UMA Unknown/50-50 page was retrieved 2026-09-26 and is prior art, not a RetroPick default.

## Benchmark

Integer dust checks for amounts 1..32 in the reference tests, and Foundry fuzz up to 500.

## Security implications

Half-up is insolvent. Per-call floor lets a dust sink capture value that a batched redemption would have paid. Cumulative floor bounds that capture at one raw unit when supplies start equal to collateral.

## Tradeoffs

The order of 1-unit redemptions changes which holder receives the odd unit. That is the usual floor-delta fairness residue. It does not change the total.

## Recommendation

Adopt cumulative floor if INVALID is in Phase 1. Do not enable INVALID implicitly.

## Confidence

High for the insolvency counterexamples. Medium for product need of INVALID itself.

## What would falsify this

A conserved integer rule whose max holder loss is smaller than one unit without insolvency, or a decision to drop INVALID from Phase 1.
