# Dependency Analysis

## Import Closure Verification

✓ **Complete and closed** - All 29 external import paths resolve to existing dependency files  
✓ **No missing dependencies** - Every imported path found on disk  
✓ **No unreachable files** - All 71 vendored .sol files are reachable except 2 junk files  

## Required Remappings

```toml
@openzeppelin/contracts/ = lib/openzeppelin-contracts/contracts/
@uniswap/v4-core/src/ = lib/v4-core/src/
@uniswap/v4-periphery/src/ = lib/v4-periphery/src/
@uniswap/v4-hooks-public/src/ = lib/v4-hooks-public/src/
permit2/src/ = lib/v4-periphery/lib/permit2/src/
```

## Dependency Summary

| Package | Files | License | Status |
|---------|-------|---------|--------|
| OpenZeppelin Contracts | 20 | MIT | Complete subset |
| Uniswap V4 Core | 34 | MIT + BUSL-1.1 | Interface-only (no implementations) |
| Uniswap V4 Periphery | 15 | MIT | Interface + library subset |
| Permit2 | 1 | MIT | Interface-only |
| v4-hooks-public | 1 | MIT | BaseHook only |

**Total:** 71 Solidity files

## BUSL-1.1 Files (Deployment Rights Review Required)

1. `lib/v4-core/src/libraries/Pool.sol` - BUSL-1.1
2. `lib/v4-core/src/libraries/Position.sol` - BUSL-1.1

These files contain Uniswap V4 core logic under BUSL-1.1 + Additional Use Grant. Deployment rights require separate legal review.

## Missing Implementations (Testing Limitation)

The vendored V4 dependency set contains **only interfaces**, not implementations:
- No `PoolManager.sol` implementation
- No `PositionManager.sol` implementation  

**Impact:** Live V4 graduation testing requires mocks or external implementations. This migration preserves the exact upstream dependency scope without additions.

## Version Recovery Status

**NOT_RECOVERABLE** - The copied payload contains no:
- Git submodule metadata
- Package lock files  
- Version tags in source
- Build configuration with pinned versions

**Pinning Strategy:** Content-based identity using SHA-256 hashes of retained files.

## Junk Files (To Delete)

1. `contractsV2/lib/v4-core/src/interfaces/callback/oz.jpg` - Non-code binary
2. `contractsV2/lib/v4-core/src/interfaces/callback/ozz.md` - Non-code documentation

## SHA-256 Manifest

Dependency file hashes recorded in `/tmp/v2-dependencies-sha256.txt` (71 files).

Sample verification:
```bash
# Verify OpenZeppelin ERC20 integrity
sha256sum lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol
# Expected: [recorded hash from manifest]
```

## Upstream Fingerprinting Attempts

**OpenZeppelin:** Contract structure suggests v5.x series (StorageSlot, draft-IERC6093)  
**Uniswap V4:** Core types structure suggests post-launch v4 mainnet codebase  
**Permit2:** Interface matches canonical Uniswap Permit2  

**⚠️ These are inferences only** - exact upstream tags cannot be established without network verification against git repositories.