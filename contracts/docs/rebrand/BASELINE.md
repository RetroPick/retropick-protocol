# Baseline Snapshot

## Source Identity

**Upstream Repository:** `git@github.com:ponsdotdev/pons-labs.git`  
**Commit SHA:** `162310fbd1217717e2f5e4cde794d6a11322b469`  
**Branch:** `main`  
**Clone Type:** Shallow clone with `blob:none` partial clone filter  
**Clone Timestamp:** 2025-01-18 06:27:04 +0700  

## Limitations

- **Partial clone:** `partialclonefilter = blob:none` means not all git objects are available locally
- **Shallow clone:** Limited history prevents full offline verification against upstream
- **No build system:** Upstream ships source only - no `foundry.toml`, test files, or build configuration
- **No LICENSE files:** Missing from copied payload despite SPDX headers in source

## Snapshot Location

**Immutable reference copy:** `/tmp/retropick-v2-baseline/pons-labs/`  
**File count:** 153 files  
**SHA-256 manifest:** `/tmp/retropick-v2-baseline/pons-labs-sha256-manifest.txt`  

This snapshot serves as the authoritative baseline for all rebrand operations and behavioral parity verification.

## Migration Identity

The rebrand preserves behavior based on **content hash identity**, not upstream commit identity, due to the partial clone limitation. All file transformations are verified against this snapshot.

Generated: 2026-09-18T13:47:00+07:00