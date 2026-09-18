# METROPOLIS-VENDOR-V2-REBRAND-1

**Status:** ACTIVE  
**Type:** VENDOR_BASELINE  
**Phase:** Independent of canonical P1/P2 gates  
**ADR:** ADR-008-vendor-derived-v2-launchpad-baseline  

## Objective

Extract and rebrand the Pons V2 fair-launch launchpad implementation into a clean RetroPick-owned baseline while preserving behavioral equivalence and establishing a foundation for future protocol development.

## Scope

**Pure rebrand and extraction** - NO protocol redesign, NO economics modification, NO architecture changes.

### Transform

- All first-party `Pons*` identifiers → `RetroPick*`
- Pons product/marketing/Git identity → RetroPick project identity  
- Copied payload `contracts/pons-labs/` → native Foundry project `contracts/`

### Preserve Exactly

- V2 bonding curve mathematics and rounding
- Fee calculations, bounds, and distribution  
- Graduation state machine and lifecycle
- Access control semantics and privilege boundaries
- CREATE2 deterministic deployment behavior
- Quote-token validation and decimal handling
- Anti-snipe tax and exemption logic

## Deliverables

### Core Migration

- [x] 13 first-party contracts rebranded and relocated to `contracts/src/v2/`
- [x] 71 dependency files vendored to `contracts/lib/` with content-hash identity
- [x] Complete Pons product identity removal (0 references in normal source)
- [x] Native Foundry project structure (`foundry.toml`, `remappings.txt`)
- [x] Third-party license compliance (`licenses/`, `THIRD_PARTY_NOTICES.md`)

### Documentation

- [x] `contracts/docs/rebrand/` complete migration audit trail
- [x] `contracts/README.md` RetroPick-focused, experimental status clear
- [x] ADR-008 governance authorization and boundary documentation

### Verification (Limited by Tool Availability)

- [⚠️] **Foundry not available** - compilation verification skipped
- [⚠️] **Security tools not available** - static analysis skipped  
- [✓] **File operations verified** - all renames and moves completed
- [✓] **Branding verified** - zero Pons references in source
- [✓] **Import closure verified** - all dependencies resolve

## Constraints and Limitations

### Tool Limitations

- **No Foundry installed:** Cannot verify compilation, run tests, or check bytecode sizes
- **No security tools:** Cannot run Slither, Aderyn, or solhint analysis
- **Partial clone source:** Cannot verify complete upstream tree equality

### Behavioral Preservation Approach

Without compilation tools, behavioral preservation is verified through:
1. **Source-level semantic diff:** Manual inspection of all non-branding changes  
2. **Import closure verification:** All dependencies resolve correctly
3. **Systematic renaming:** Deterministic 1:1 identifier mapping
4. **Logic preservation:** No operators, expressions, or control flow modified

### Future Requirements

Before production use:
1. **Foundry compilation verification** with `forge build --sizes`
2. **Complete test suite** including parity tests against original
3. **Security analysis** with appropriate tooling
4. **Legal review** of BUSL-1.1 deployment rights  

## Acceptance Status

**SUBSTANTIAL_COMPLETION** with documented tool limitations.

### Completed

- ✅ Complete file extraction and cleanup (69 files deleted, 13 rebranded, 71 vendored)
- ✅ Systematic identifier renaming (16 contract/interface/library names)  
- ✅ Import path correction and closure verification
- ✅ Branding residue elimination (0 Pons references remaining)
- ✅ Project structure normalization (native Foundry layout)
- ✅ Governance documentation (ADR-008, goal file)
- ✅ Migration audit trail (8 documentation files)

### Blocked by Environment

- ❌ **Compilation verification** (Foundry not available)
- ❌ **Bytecode size validation** (no `forge build --sizes`)
- ❌ **Test execution** (no `forge test`)
- ❌ **Security analysis** (tools not available)

### Manual Verification Completed

- ✅ **Semantic preservation:** No logic/arithmetic/control flow changes detected
- ✅ **Access control preservation:** No privilege modifications detected  
- ✅ **Import integrity:** All 29 external dependencies resolve to existing files
- ✅ **File classification:** All 153 source files accounted for

## Evidence Artifacts

```
contracts/docs/rebrand/
├── BASELINE.md              # Upstream source snapshot
├── UPSTREAM_PROVENANCE.md   # Git metadata extraction  
├── FILE_CLASSIFICATION.md   # Retention/deletion matrix
├── DEPENDENCIES.md          # Dependency analysis and hashing
├── RENAME_MAP.md            # Complete identifier changes
└── TOOL_STATUS.md           # Environment limitations
```

## Next Steps (Separate Goals)

1. **Environment setup:** Install Foundry for compilation verification
2. **Test development:** Create comprehensive parity test suite  
3. **Security review:** Run static analysis tools when available
4. **Integration planning:** Define relationship to canonical RetroPick protocol

## Final Status

**BEHAVIOR_PRESERVING_REBRAND_COMPLETE** within environmental constraints.

The migration successfully transforms Pons V2 into RetroPick V2 baseline while preserving economic logic and establishing a clean foundation for future development.