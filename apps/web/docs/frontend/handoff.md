# RetroPick Launchpad frontend handoff

## Goal and phase

This is the PRODUCT-1-facing UI prototype for RetroPick + PRISM. It is a `SUPPORTED_BY_SIMULATION` frontend artifact, not a protocol deployment or a claim that integration gates are complete. The controlling dependency order remains `SPEC-1 -> MATH-1 -> CONTRACT-ARCH-1 -> CONTRACT-1 -> INTEGRATION-1 / PRODUCT-1 -> E2E-1 -> SUBMISSION-1`.

## Commands and evidence

Run from the repository root with Node 22.13+ and pnpm 11.25.0:

```sh
pnpm install --frozen-lockfile
pnpm typecheck:web
pnpm lint:web
pnpm test:web
pnpm build:web
```

The application packages its own bounded math tests in `apps/web/tests/domain.test.mjs`. They cover canonical pFEDBTC payoff/backing, malformed normalized baskets, invalid supply, `RESOLVED` versus `REDEEMABLE`, settlement coverage, and amount validation. Browser QA covers discovery, separate YES/NO routing, demo buy/sell ledger updates, funded redemption review, negative-basket rejection, and embedded-width layout checks at 390, 768, 1024, 1440 and 1920 px.

## Boundaries that may not change

- Native complete set: 1 collateral unit ⇄ 1 YES + 1 NO; do not report OI as YES supply + NO supply.
- Native and PRISM lifecycle vocabulary must remain separate.
- PRISM v1 remains a nonnegative exact-backed basket: `h = Gx`, `x >= 0`, `B_i >= S*x_i`.
- Retail PRISM purchase is secondary trading; it cannot mint or change backing.
- `RESOLVED` is not `REDEEMABLE`; payout must also be funded.
- Protocol backing, order reservations, LP inventory, fees and settlement funds are distinct domains.

## Live integration checklist

Before replacing mock mode, a reviewed integration must provide admitted deployment configuration, immutable market `ResolutionSpec` commitments, verified wallet/chain checks, actual venue quote freshness, receipt/indexer reconciliation, exact vault/supply backing state, final settlement funding, and evidence IDs. Do not manufacture addresses, hashes, transaction receipts, balances or a best-route claim. Kuru is presented as the future execution venue; Uniswap v4 and Polymarket remain explicitly planned, separate sources.

## Residual risks

The browser session is a presentation ledger only. It is reset on reload, uses illustrative pricing and cannot serve as financial accounting, a proof, an oracle, a wallet integration or a settlement system. The local normalized basket builder is intentionally not a general nonlinear payoff solver.
