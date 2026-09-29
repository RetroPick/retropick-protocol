# Kuru P0 parameter packet — 2026-09-29

Status: `PREPARED_NOT_DEPLOYED`. No transaction was sent. This packet narrows
the deployment inputs for a future authorized demo; it does not certify live
Kuru compatibility or authorize use of a signer.

## Verified protocol inputs

Read current official Kuru pages on 2026-09-29:

- [Contract addresses](https://docs.kuru.io/contracts/Contract-addresses):
  Monad testnet Router `0x7EFbE105Ca7415dE98F96622173458ac1c054630`, Margin
  Account `0xd029C2D98ff85D8F64799017fE00a59B1159CE02`, and testnet USDC
  `0x3bA3d39AFcf8bb994f7964B3e0171Ea2Ba361570`.
- [Router](https://docs.kuru.io/contracts/Router): `deployProxy` accepts the
  market type, base/quote addresses, size and price precision, tick, min/max
  size, maker/taker fees, and AMM spread; `NO_NATIVE` denotes ERC20/ERC20.
- [SDK deploy-market guide](https://docs.kuru.io/sdk/deploy-market) and the
  official [`ParamCreator` implementation](https://github.com/Kuru-Labs/kuru-sdk/blob/main/src/create/market.ts):
  the helper computes precision inputs and submits Router `deployProxy`; the
  live package/source revision must be pinned and rechecked at execution time.

The Router, Margin Account, and USDC were checked read-only at the recorded
RPC in the companion testnet verification artifact. The helper is advisory,
not a protocol constraint. It uses JavaScript `number` arithmetic and should
not be treated as an exact financial oracle. These proposed decimals and
integer parameters are simple enough to independently recompute exactly.

## Demo-only parameter choice

Assume each base token has 6 decimals (the P0 Prediction outcome tokens and
P0 PRISM series inherit the 6-decimal collateral scale). For a harmless
orderbook demonstration, choose the demonstration price of 0.50 USDC per base
token, cap the represented price range at 1.00 USDC, permit a minimum order of
1.00 base token, and use a 100-bps tick. These are `HACKATHON_DEMO_PARAMETER`
choices only; they are not claims about fair value, expected payout, liquidity,
or a market-maker quote. Revisit them after actual tokens, intended sides,
funding, and risk limits are known.

Applying the official helper's documented precision algorithm to
`currentQuote=0.5`, `currentBase=1`, `maxPrice=1`, `minSize=1`,
`tickSizeBps=100` gives:

| Router input | Candidate value | Interpretation |
| --- | ---: | --- |
| type | `0` (`NO_NATIVE`) | ERC20 / ERC20 |
| base decimals | `6` | Verify deployed token onchain before use |
| quote | testnet USDC | Official testnet address above; 6 decimals to verify again |
| pricePrecision | `10000` | Four decimal price units |
| sizePrecision | `10000` | 10,000 size units per human base token |
| tickSize | `50` | 50 / 10,000 = 0.005 USDC/base (one percent of the 0.50 reference) |
| minSize | `10000` | 1.00 base token at sizePrecision 10,000 |
| maxSize | `1000000000` | 100,000 base tokens at sizePrecision 10,000; demo range only |
| takerFeeBps | `0` | Demo choice; no fee-revenue assumption |
| makerFeeBps | `0` | Demo choice; no rebate assumption |
| kuruAmmSpread | `0` | No AMM-vault spread assumption; confirm Router accepts this value |

The precision derivation is: reference price 0.5 and tick 0.005 require four
price decimals under the SDK minimum; therefore price precision is 10^4 and
tick size is 0.005 × 10^4 = 50. The helper's size rule chooses 10^4 size
precision from `maxPrice × pricePrecision = 10^4`; min size is 1 × 10^4.
Its `getMaxSizeAtPrice` computes
`floor((2^32−1)×10^4/5000) = 8,589,934,590`, then rounds down to the
highest power of ten, yielding 10^9. All arithmetic here is integral after
the stated decimal inputs. Still, Router deployment/reverts are the final
compatibility check and require a live transaction; none was attempted.

The same parameter set is only a neutral *orderbook mechanics* candidate for
YES/USDC, NO/USDC, and PRISM/USDC. A market price of 0.50 does not imply that
YES, NO, or PRISM is worth 0.50. Before deploying any market, identify the
actual PRISM series and confirm the instrument label; currently there is no
deployed P0 Prediction or PRISM token address in this evidence set.

## Transaction path and stop conditions

The documented SDK path calls Router `deployProxy(0, base, quote,
sizePrecision, pricePrecision, tickSize, minSize, maxSize, takerFeeBps,
makerFeeBps, kuruAmmSpread)` and obtains the market address from the
`MarketRegistered` event. A future operator must verify the selected wallet's
chain ID, token addresses/decimals, Router's current `marginAccountAddress`,
balances, allowances, and estimated gas before submitting. If those checks or
the intended candidate inputs do not match, stop and recompute. Never place a
private key in a committed script, report, command line, or output log.

Live H2–H7 remain blocked until an authorized funded signer and actual P0
tokens exist, and the operator explicitly approves testnet transactions.
Required evidence is still separate for deployment, three distinct markets,
small liquidity, order placement, a genuine fill, and cancellation of a
remaining order. These parameters do not make those gates pass.
