---
id: LP-BE-DB
type: normative_implementation
status: ready
owner: launchpad-backend
product: launchpad
version: v2
---

# Database Schema

Application DB stores only offchain application concerns, e.g. profiles, launch_metadata, media, moderation flags, ranking snapshots and optional analytics events.

Do not duplicate mutable contract reserves/supply/graduation as independently editable application truth.

Every table requires PK, unique constraints, indexes, retention and migration strategy.