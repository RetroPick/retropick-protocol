# ADR-017: Launchpad Metadata and Media Storage

**Status:** PROPOSED  
**Date:** 2026-09-20  
**Scope:** RetroPick Launchpad V2

## Proposal

Use a durable object/media storage layer behind the API with strict file/content validation and graceful unavailable-media behavior. Exact provider remains undecided.

Onchain economic state is never moved into metadata storage.

