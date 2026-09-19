# Configuration and Secrets

**Status:** DRAFT  
**Owner:** Release + Security  
**Authority:** Operational policy

## Purpose

Separate public configuration from secret material.

## Requirements

- Public config: chain IDs, public contract addresses, indexer/API URLs, feature flags and supported quote assets.
- Secrets: deployer/operator keys, provider/API credentials, signing secrets and CI credentials.
- Secrets live in approved environment/secret stores and are never committed.
- Document rotation and least-privilege ownership.

## Non-goals

- Does not waive higher-authority safety requirements.

## Acceptance criteria

- Secret scan clean and environment variables documented without values.

## Evidence required

- CI secret configuration and scan output.
