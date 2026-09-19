# ADR-018: Launchpad Administration and Key Model

**Status:** PROPOSED  
**Date:** 2026-09-20  
**Scope:** RetroPick Launchpad V2

## Proposal

Separate deployer, owner/configuration, fee/recovery and any operational signer roles by explicit capability and environment. Use least privilege and explicit transfer/recovery procedures.

No server-side key may sign normal user economic transactions.

