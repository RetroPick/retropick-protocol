# Kuru

See `research/integration/kuru/KURU_TOKEN_COMPATIBILITY.md` for sources, retrieval dates, and classifications.

Phase-1 outcome tokens are ERC-20s, so the documented Kuru type-0 router path is the relevant shape: one YES/quote book and one NO/quote book. Decimals are the token's own decimals. A 18-decimal assumption belongs to Kuru's own token deployer, not to every listed ERC-20.

Listing is not liquidity. Margin-account inventory is not protocol collateral. The protocol redeem path does not call Kuru. If Kuru is down, winners still redeem against the market contract.

No book was deployed. No quote, tick, or fee is accepted for RetroPick prediction markets. ADR-021 remains a proposed Launchpad decision and does not set prediction parameters.
