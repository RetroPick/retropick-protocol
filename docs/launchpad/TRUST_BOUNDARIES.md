---
id: LP-TRUST
type: normative
product: launchpad
version: v2
status: active
---

# Trust Boundaries

## User wallet
Owns user signatures. The backend does not impersonate normal user transactions.

## RetroPick contracts
Custody/define launch inventory, primary reserves, fees and lifecycle. Privileged roles are explicit.

## Kuru
External mature execution venue. Its market state does not become RetroPick primary reserve authority.

## Indexer
May be delayed/reorged. It is never the source of solvency or authorization.

## Backend/storage
May be compromised/unavailable without changing onchain economics. Untrusted metadata must be sanitized.

## RPC/provider
May fail or return stale/inconsistent reads; critical state supports provider fallback/receipt verification.

## Operator keys
May only exercise documented capabilities. Mainnet authorization is human/security controlled.
