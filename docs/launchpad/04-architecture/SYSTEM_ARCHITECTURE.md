# System Architecture

**Status:** DRAFT CANONICAL  
**Owner:** Architecture + Integrations

```text
                         USER
                           |
                           v
                    RetroPick Web
                           |
              +------------+------------+
              |                         |
            READS                      WRITES
              |                         |
          Indexer/API                 Wallet
              |                         |
              |                     Monad RPC
              |                         |
              +------------+------------+
                           |
                           v
                    RetroPick V2
                           |
              +------------+------------+
              |                         |
        Bonding Market              Graduation
                                        |
                                        v
                                      Kuru
```

## Authority

- Contracts: economic truth, reserves, fees and launch state.
- Kuru: mature secondary execution after successful graduation.
- Indexer: derived read model; never canonical for balances/economic state.
- Backend: metadata, cache, search, ranking and orchestration.
- Frontend: presentation and wallet transaction construction.

## Trust boundaries

Browser/backend/indexer failure must not alter contract truth. External venue failure must leave secured graduation assets in a recoverable/retryable state. Critical UI values should be attributable to contract reads or indexed events with freshness metadata.

## Acceptance

Every golden-path transaction can be traced from UI action to contract call/event, indexed update and post-transaction UI state.
