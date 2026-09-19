# Architecture Diagrams

**Status:** ACTIVE  
**Owner:** Architecture

## Launch lifecycle

```mermaid
flowchart LR
  C[Create] --> A[Active Bonding Market]
  A --> R[Graduation Ready]
  R --> G[Graduating]
  G --> K[Kuru Market]
  K --> D[Graduated]
```

## Read/write topology

```mermaid
flowchart TD
  U[User] --> W[RetroPick Web]
  W -->|reads| I[Indexer/API]
  W -->|signs| X[Wallet]
  X --> M[Monad RPC]
  M --> C[RetroPick V2]
  C --> E[Events]
  E --> I
  C --> K[Kuru]
```

## Authority

Contracts own economics. Kuru owns mature-market execution. Indexer/API own read optimization. Frontend owns user interaction.
