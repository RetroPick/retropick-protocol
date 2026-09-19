---
id: LP-IDX-REORG
type: normative_implementation
status: ready
owner: launchpad-indexer
product: launchpad
version: v2
---

# Reorg and Backfill

Requirements:
- deterministic start block/deployment manifest;
- idempotent event processing;
- rollback/replay strategy for reorgs;
- full rebuild from chain;
- no duplicate trade/activity rows;
- sync checkpoint/finality policy documented per environment.