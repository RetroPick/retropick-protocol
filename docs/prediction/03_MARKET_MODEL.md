# Market model

Reference code: `research/prediction-model/market.py`.  
Prototype: `research/contract-kernels/src/prediction/PredictionMarket.sol`.

Operations: `create` / `activate`, `split`, `merge`, `closeMint`, `beginResolution`, `resolve`, `openRedemption`, `redeemYes`, `redeemNo`, `burnWorthless`, `archive`.

`split(q)` requires the collateral balance of the market to increase by exactly `q`. A smaller increase reverts and the transaction rolls back. That is the qualified response to fee-on-transfer. It does not admit fee-on-transfer tokens.

`merge(q)` is allowed in OPEN and LOCKED. It is the inverse of split in the zero-fee model.

`burnWorthless` burns a side whose numerator is 0. It does not release collateral. INVALID has no worthless side.

Archive requires zero supply and zero liability. Residual raw units, which are `C mod 2` after a full INVALID redemption when supplies equalled `C`, transfer to the immutable dust sink. There is no other withdrawal.

## CTF invariants kept, and what is not copied

Kept, from the Gnosis conditional-token developer guide retrieved 2026-09-26 (`https://ct-docs.gnosis.io/conditionaltokens/docs/devguide05` and the `ConditionalTokens.sol` redeem path): collateral is locked on split, merge returns collateral, redemption waits for a payout vector, and the binary payouts are complementary for a valid YES/NO result.

Not copied: ERC-1155 position ids, parent collections, combinatorial partitions, redeem-the-entire-balance as the only API, and UMA as the resolver. Partial redemption is allowed because the cumulative floor defines the payout of a partial amount. Polymarket's docs (retrieved 2026-09-26, `https://docs.polymarket.com/concepts/resolution`) say an official UMA "Unknown/50-50" vote redeems each token for $0.50. That is their resolution policy. It is evidence that a 1/2 payout exists in the wild. It is not an automatic RetroPick rule. RetroPick encodes INVALID only when the committed resolver reports it.
