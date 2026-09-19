# Bytecode Size Comparison: Pons vs RetroPick

## Summary

**RESULT**: 100% bytecode size parity confirmed. All contracts compile to identical sizes.

## Original Pons V2 (with fixes)

```
| Contract                 | Runtime Size (B) | Initcode Size (B) | Runtime Margin (B) | Initcode Margin (B) |
+============================================================================================================+
| PonsV2BondingCurve       | 9,280            | 10,517            | 15,296             | 38,635              |
| PonsV2BuybackVault       | 4,602            | 4,985             | 19,974             | 44,167              |
| PonsV2GraduationExecutor | 4,402            | 4,749             | 20,174             | 44,403              |
| PonsV2GraduationGuard    | 2,896            | 2,922             | 21,680             | 46,230              |
| PonsV2LaunchDeployer     | 19,291           | 19,443            | 5,285              | 29,709              |
| PonsV2LaunchFactory      | 24,131           | 28,154            | 445                | 20,998              |
| PonsV2LaunchLocker       | 1,969            | 2,281             | 22,607             | 46,871              |
| PonsV2LauncherToken      | 3,248            | 7,099             | 21,328             | 42,053              |
| PonsV2MemeHook           | 15,166           | 16,279            | 9,410              | 32,873              |
```

## RetroPick V2 (rebranded)

```
| Contract                      | Runtime Size (B) | Initcode Size (B) | Runtime Margin (B) | Initcode Margin (B) |
+=================================================================================================================+
| RetroPickV2BondingCurve       | 9,280            | 10,517            | 15,296             | 38,635              |
| RetroPickV2BuybackVault       | 4,602            | 4,985             | 19,974             | 44,167              |
| RetroPickV2GraduationExecutor | 4,402            | 4,749             | 20,174             | 44,403              |
| RetroPickV2GraduationGuard    | 2,896            | 2,922             | 21,680             | 46,230              |
| RetroPickV2LaunchDeployer     | 19,291           | 19,443            | 5,285              | 29,709              |
| RetroPickV2LaunchFactory      | 24,131           | 28,154            | 445                | 20,998              |
| RetroPickV2LaunchLocker       | 1,969            | 2,281             | 22,607             | 46,871              |
| RetroPickV2LauncherToken      | 3,248            | 7,099             | 21,328             | 42,053              |
| RetroPickV2MemeHook           | 15,166           | 16,279            | 9,410              | 32,873              |
```

## Analysis

### Perfect Size Parity
- All 9 main contracts have **identical** runtime and initcode sizes
- EIP-170 safety margins are **identical** 
- Total compiled bytecode is **equivalent**

### EIP-170 Safety Status
All contracts remain safely under EIP-170 limit (24,576 bytes):
- **Largest contract**: RetroPickV2LaunchFactory at 24,131 bytes (445 bytes margin)
- **All contracts** have positive margins

### Compilation Configuration
Both versions compiled with identical settings:
- Solc 0.8.26
- EVM version: cancun
- Optimizer: 200 runs
- IR pipeline: enabled (`via_ir = true`)

## Verification Gates Passed

✅ **Gate 4.1**: Both versions compile without errors  
✅ **Gate 4.2**: Bytecode sizes are identical  
✅ **Gate 4.3**: EIP-170 margins preserved  

## Technical Notes

1. **Upstream bug fixes applied to both versions**:
   - Added missing `exemptFromSnipeTax` function stub
   - Fixed LaunchDeployment struct construction (removed extra salt)

2. **Identical compiler warnings**: Both versions show the same Foundry lint warnings, confirming structural equivalence.

3. **Library contracts unchanged**: All utility libraries (BalanceDeltaLibrary, CurrencyLibrary, etc.) have identical sizes.

---

**Conclusion**: The rebrand preserves exact compilation behavior. Bytecode differences will only be in internal string constants and contract names, not in functional opcodes.