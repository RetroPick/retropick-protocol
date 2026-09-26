# Kuru

See `research/integration/kuru/KURU_TOKEN_COMPATIBILITY.md` for sources, retrieval dates, and classifications.

Phase-1 outcome tokens are ERC-20s, so the documented Kuru type-0 router path is the relevant shape: one YES/quote book and one NO/quote book. Decimals are the token's own decimals. A 18-decimal assumption belongs to Kuru's own token deployer, not to every listed ERC-20.

Listing is not liquidity. Margin-account inventory is not protocol collateral. The protocol redeem path does not call Kuru. If Kuru is down, winners still redeem against the market contract.

No book was deployed. A local parameter worksheet is in `research/integration/kuru/PARAMETER_WORKSHEET.md`. Published `calculatePrecisions` examples were executed with Node 22.14.0 and checked against ethers 5.7.1. A later primary-source pass re-read the router, SDK, OrderBook, vault, fee, contract-address, and Monad Kuru Flow pages. Those pages still do not set RetroPick decimals, price precision, size precision, tick, min size, max size, maker/taker fees, or an allowance spender. PRED-KURU-1 stays blocked. A market simulation was not run: this repo has no Kuru router bytecode, no accepted router, and no configured fork. ADR-021 remains a proposed Launchpad decision and does not set prediction parameters.
