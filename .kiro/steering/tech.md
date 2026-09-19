---
inclusion: always
---

# Technology Steering

Technology decisions have three states: CANDIDATE, DECIDED, IMPLEMENTED.

Current implemented core:
- Solidity/Foundry under `contracts/`.
- no committed full-stack TypeScript runtime yet.

Candidate target architecture includes a strict TypeScript workspace, web/API/indexer apps, shared domain/ABI/SDK/config/UI/test packages. Do not treat candidate tools/frameworks as accepted until an ADR or implementation file makes them binding.

External integrations such as Kuru, Monad RPC/indexer providers and wallet libraries require current-source verification before binding implementation.
