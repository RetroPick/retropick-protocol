# Token Metadata Integration

**Status:** DRAFT  
**Owner:** Frontend + Backend  
**Authority:** Integration specification

## Purpose

Define metadata fields/storage/validation and failure behavior for launched tokens.

## Requirements

- Specify name, symbol, image, description and social fields supported by the product template.
- Validate length/format and sanitize offchain rendering.
- Contract-critical identity must not depend on mutable untrusted metadata.

## Non-goals

- Metadata service is not token ownership/economic authority.

## Acceptance criteria

- Broken/unavailable media does not break trading UI.

## Evidence required

- Metadata fixtures and security tests.
