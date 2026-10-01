# Factory V2 code-size measurement — 2026-10-01

**Status:** reproducible measurement; no architecture change made.

**Branch / HEAD:** `codex/kuru-freeze-smart-contract-spec` / `1dd9868bc4623d6e3af644c0950618a986c4dae8`

**Toolchain:** Foundry `1.8.3` (`cae51ad458f6abb64852b7709eb784352429825f`), solc `0.8.26`, optimizer runs `200`, `via_ir = true`.

**Command, from `contracts/`:**

```bash
forge build --sizes --skip test --skip script
```

**Result:** compiler successful with only the two pre-existing v1/v2 `exemptFromSnipeTax` mutability warnings.

| Contract | Runtime bytes | Explicit EIP-170 margin |
| --- | ---: | ---: |
| `RetroPickLaunchFactoryV2` | 24,565 | 11 |
| `RetroPickGraduationExecutorV2` | 4,402 | 20,174 |
| `RetroPickBondingCurveV2` | 10,711 | 13,865 |
| `RetroPickLaunchLockerV2` | 1,969 | 22,607 |

The table compares runtime bytes directly with the EIP-170 limit of 24,576; Foundry's displayed runtime-margin column uses a different chain-specific cap and is not used here.

## Consequence

The Factory has effectively zero implementation headroom. DEV-4 must remove venue execution, authoritative secured-asset custody, and destination verification from the Factory. It must not gain a parallel graduation ledger or a second writable phase. The accepted extraction target remains a Factory runtime no greater than approximately 23.5 KB; that target is not met by this measurement.

This file does not accept an ADR, promote a gate, or authorize production implementation.
