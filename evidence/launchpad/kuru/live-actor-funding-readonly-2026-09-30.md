# Live actor funding check — read-only, 2026-09-30

At approximately `2026-09-30 01:39:28 UTC`, Monad Testnet RPC reported chain ID `10143` and block `66842712`. Using only `cast chain-id`, `cast balance` and Circle-USDC `balanceOf(address)` calls after loading the existing `.env.local` into the command environment:

| Actor | Address | Native MON (wei) | Circle test USDC (raw, 6 decimals) |
| --- | --- | ---: | ---: |
| A | `0xB505cBaab3ACdF287af1366b9B1229404757913b` | `10000000000000000000` | `0` |
| B | `0x101212C52620ca00540ee04D1515E714e6368Fcd` | `5000000000000000000` | `0` |

Neither actor currently has Circle test USDC for a live Circle-quoted first deposit or independent Circle-side trade. That is an **exact funding blocker** for the Circle live path; the Kuru-listed `USDC`-symbol compatibility token must not be substituted as canonical Circle USDC. Native-MON balances are sufficient only to consider a carefully budgeted test later; Core and Kuru qualification gates still block broadcast. No keystore password/private key was read or printed, and no transaction was sent.
