# Definitions

Amounts in the exact model are rational numbers (`fractions.Fraction`). Amounts in the integer model and in Solidity are raw token units, represented as Python `int` or Solidity `uint256`. Float equality is not a protocol check.

| Term | Meaning |
|---|---|
| Collateral | The single approved standard ERC-20 locked by a split |
| YES, NO | The two outcome ERC-20s. Index 0 and 1 |
| Complete set | `q` collateral claims `q` YES and `q` NO before resolution |
| Liability | Collateral the protocol must still be able to pay |
| YES_WIN | YES redeems 1, NO redeems 0 |
| NO_WIN | YES redeems 0, NO redeems 1 |
| INVALID | Each side redeems 1/2 before rounding |
| Resolution spec | Frozen `market_id`, collateral, resolver, `spec_hash`. Free text is not an input |
| Kuru | Secondary order book. Not collateral and not a resolver |

Before resolution, zero fees:

```text
YES_supply = NO_supply = CollateralLocked
```

After redemptions, supply equality is not the solvency check. The check is `CollateralLocked >= Liability`.

Launchpad's `RetroPickLauncherTokenV2` is a different asset. A PRISM series token is a different asset.
