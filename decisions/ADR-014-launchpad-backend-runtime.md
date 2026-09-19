# ADR-014: Launchpad Backend Runtime and Database

**Status:** PROPOSED  
**Date:** 2026-09-20  
**Scope:** RetroPick Launchpad V2

## Proposal

Use one non-custodial TypeScript API service with PostgreSQL for application metadata/profiles/search/ranking state. Candidate frameworks include Fastify and a typed ORM/schema layer.

Redis/Valkey is not automatically required; introduce only for a measured cache/job/rate-limit need.

## Hard boundary

Backend never owns reserves, canonical launch state, token minting, graduation or normal user trade signing.

