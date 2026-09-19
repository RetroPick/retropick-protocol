# Launchpad Versioning

**Status:** ACCEPTED  
**Owner:** Smart Contracts  
**Authority:** ADR-008.

## V1

Stable/reference RetroPick generation. Feature-frozen except security and critical correctness maintenance.

## V2

Active modern-launchpad generation. New launchpad architecture, Monad integrations and Kuru graduation work belong here.

## Rules

- V2 changes require owning specs and V2-specific tests.
- Architectural changes require an ADR.
- A V1 test result does not automatically qualify divergent V2 behavior.
- Public ABI/storage changes must be documented before deployment.
- Deployment addresses are versioned and environment-specific.
