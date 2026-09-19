# Technology Steering

Technology decisions have three states:

```text
CANDIDATE
DECIDED
IMPLEMENTED
```

Current implemented core:
- Solidity + Foundry under `contracts/`;
- Python exact PRISM model under `research/prism-model/`.

Launchpad full-stack target includes web/API/indexer/shared packages, but exact framework/provider choices remain governed by ADRs.

Never infer that a candidate framework, database, indexer, wallet library, or external provider is accepted without checking `decisions/`.

External mutable APIs and addresses require current verification before binding implementation.
