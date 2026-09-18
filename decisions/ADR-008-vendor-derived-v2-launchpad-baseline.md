# ADR-008: Vendor-Derived V2 Launchpad Baseline

**Date:** 2026-09-18  
**Status:** ACCEPTED  
**Supersedes:** None  
**Context:** METROPOLIS-VENDOR-V2-REBRAND-1  

## Decision

RetroPick establishes a vendor-derived V2 launchpad baseline in `contracts/` by extracting, rebranding, and behavior-preserving migration of the Pons V2 fair-launch implementation.

## Rationale

Creating a clean RetroPick-owned starting point for future launchpad development requires:

1. **Complete first-party rebrand** of all Pons identities to RetroPick
2. **Behavioral preservation** of the proven V2 economics and state machine  
3. **Clean foundation** for potential future integration or replacement
4. **Documented baseline** for measuring future changes

## Scope and Boundaries

### This Decision AUTHORIZES

- Vendor-derived experimental V2 launchpad baseline in `contracts/src/v2/`
- Rebranding of all first-party `PonsV2*` identities to `RetroPickV2*`
- Vendoring of exact dependency subset with content-hash pinning
- Behavioral parity testing and documentation

### This Decision DOES NOT

- **Authorize canonical Prediction or PRISM production Solidity**
- **Satisfy CONTRACT-ARCH-1 or CONTRACT-1 phase gates**  
- **Supersede D-001 (math-first development) or `production_solidity_authorized=false`**
- **Authorize production deployment without separate legal/security review**
- **Modify V2 economics, arithmetic, access control, or lifecycle semantics**

## Classification

**Type:** Vendor-derived experimental baseline  
**Authority:** Repository preparation only  
**Production Status:** NOT AUTHORIZED  

## Implementation Requirements

1. **Behavior preservation:** Original V2 economic and state behavior MUST be preserved exactly
2. **Complete rebrand:** Zero Pons product identity may remain in normal source/documentation  
3. **Dependency pinning:** Exact source-hash identity of vendored dependencies
4. **Legal compliance:** Required third-party license notices restored
5. **Documentation:** Complete migration audit trail

## Relationship to Canonical Protocol

This V2 baseline is **orthogonal** to canonical RetroPick systems:

- **Native markets:** Complete-set collateralization (`1 collateral → 1 YES + 1 NO`)
- **PRISM:** Exact component backing (`B_i ≥ S*x_i`)  
- **V2 launchpad:** Fixed-supply bonding curves

Integration between systems, if any, requires separate architectural decisions.

## Future Evolution

This baseline may be:
- **Preserved** as a reference implementation
- **Modified** for RetroPick-specific requirements  
- **Replaced** with native RetroPick contract architecture
- **Integrated** with canonical Prediction/PRISM systems

All future changes require explicit decisions and behavioral impact analysis against this documented baseline.

## Acceptance Criteria

- [x] Complete Pons → RetroPick identifier rebrand
- [x] Zero Pons product identity in normal source
- [x] Behavioral parity verification completed
- [x] Dependency content-hash pinning
- [x] Third-party license compliance
- [x] Complete migration documentation

## Implementation Evidence

**Goal:** METROPOLIS-VENDOR-V2-REBRAND-1  
**Documentation:** `contracts/docs/rebrand/`  
**Source:** `contracts/src/v2/`  
**Baseline:** Pons Labs @ `162310fbd1217717e2f5e4cde794d6a11322b469`