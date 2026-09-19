---
id: LP-FE-ARCH
type: normative_implementation
status: ready
owner: launchpad-frontend
product: launchpad
version: v2
---

# Application Architecture

CANDIDATE stack: current stable React/Next.js, TypeScript strict, viem/wagmi, TanStack Query, Zod and React Hook Form or justified equivalents. Lock via ADR/package manifests before coding.

Server-render public discovery/detail where useful; wallet/signing boundaries are client-side. Query/cache ownership distinguishes RPC, indexer and API data.