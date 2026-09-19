# Evidence Matrix

**Status:** ACTIVE  
**Owner:** Validation

| Claim | Required evidence |
|---|---|
| Launch creation works | factory address, creation tx/receipt/event, indexed Launch, UI assertion |
| Buy works | tx/receipt, pre/post balances/reserves, Trade event, indexed trade, UI assertion |
| Sell works | tx/receipt, balances/reserves, event/indexed trade |
| Fees reconcile | contract state/events plus arithmetic assertion |
| Graduation is safe | threshold state, secured assets, graduation tx(s), failure/retry test |
| Kuru handoff works | market identifier/address, creation/config tx or verified market lookup, usable trade evidence |
| Indexer is real | endpoint/config, sync height, entity records, rebuild/lag test |
| Full stack works | browser E2E report plus onchain assertions |
| Security gate passes | tool outputs, manual review, finding dispositions |
| Deployment is reproducible | commit, manifests, addresses, code hashes, smoke report |
