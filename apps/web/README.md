# RetroPick Launchpad frontend

A responsive, explicitly simulated prediction-asset launchpad. Built with React 19, TypeScript, App Router conventions, Vinext/Vite, Tailwind, Radix primitives and Recharts.

## Run

Requires Node 22.13+ and pnpm 11.25.0.

```sh
pnpm install --frozen-lockfile
pnpm dev
pnpm typecheck
pnpm lint
pnpm test
pnpm build
```

The standard dev entry uses port 5173; managed Sites uses its supervised preview. Production build emits a Cloudflare Worker under `dist/server` and browser assets under `dist/client`. `pnpm start` previews that build locally. No database or credentials are required.

## Product routes

- `/markets`: event discovery, URL search/filter/sort, table/cards, persistent watchlist
- `/markets/[marketId]`: independent YES/NO chart/books, resolution specification, demo market/limit ticket
- `/create`: six-step native-market draft wizard
- `/prism`, `/prism/pfedbtc`, `/prism/create`: series exploration, exact payoff/backing, normalized basket draft
- `/portfolio`: session positions, orders, cancellation, funded demo redemption, history
- `/activity`: searchable feed and loading/stale/error scenarios
- `/creator/retropick-research`, `/docs`: demo creator and protocol guide

All prices, books, balances and activity are labeled fixtures. Wallet connection, approval, execution and redemption are simulations. Session financial state resets on reload. Only watchlists and saved drafts persist in browser storage. Setting `NEXT_PUBLIC_DATA_MODE` to anything other than `mock` fails closed.

See [frontend handoff](docs/frontend/handoff.md), [architecture](docs/frontend/architecture.md), and [competitive audit](docs/frontend/competitive-ui-audit.md). No production Solidity or live integration is introduced.
