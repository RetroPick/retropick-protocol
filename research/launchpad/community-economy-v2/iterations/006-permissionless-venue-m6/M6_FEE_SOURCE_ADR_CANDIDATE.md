# Candidate — new V2 in-kind community venue revenue

Status: PROPOSED FOR CANONICAL ADOPTION; experimental implementation authorized, not a release/deployment decision.

The reviewable implementation is `contracts/src/v2-research-experiment/m6/`. It adds a versioned Hook, Executor, Router, two-asset Treasury, separate creation helpers and Builder. Existing Factory/Curve financial source and deployed instances remain unchanged. No proxies or dependency upgrade are introduced.

## Economic consent boundary

Old community launches deliberately charge **zero community hook fees** after graduation. This candidate enables the launch-snapshotted hook fee and creator tax only for a **fresh deployment family with explicit ConfigV2 opt-in**. Although rates reuse existing legacy V2 snapshot fields and ceilings, activation is a real change relative to the old zero-fee community mode. It must not be described as financially identical to that mode. Old Curve-only Routers remain on the zero-fee branch; existing pools cannot change their immutable hook identity.

The original economics commitment and versioned Builder configuration bind the consent. Clients must display both Curve fees and the new venue fee/tax, their basis and denomination before signing; the old SDK's zero-fee assumption cannot authorize new-mode writes. Registry `tradeFeeBps` discloses the maximum of the two stage totals for constitutional-cap enforcement. Stage-specific actual rates are separately available from the Curve and new Router.

## Custody and rights

Curve deposits are pre-separated community value C. Venue deposits are gross G=F+T in the swap's actual unspecified asset. Protocol P=floor(F*share/10000) is remitted once into the existing pull escrow; C=G-P is allocated synchronously to the active policy. Native/quote and launch-token quantities remain separate. No conversion, extra swap, LP fee harvesting or LP principal withdrawal is authorized.

The Router binds the real factory-recorded Curve, Hook/codehash, pool ID, Coordinator packet and locked position. Venue funding requires terminal graduation, matching receipt, actual NFT ownership and unchanged liquidity. Each asset has independent credit, funding, payment, liability and replay counters. Donations do not create revenue. Controller changes cannot redirect old credits. A Registry checkpoint cannot advance during funding or claims.

The Treasury claims only its own Router credit in each asset and spends earned balances only through the unchanged qualified 72-hour Timelock. Surplus remains quarantined. Creation helpers make each actual token/Router/Vault binding unique atomically; no shared predicted destination or public initializer is used.

## Qualification and adoption gate

Local genuine venue tests use pinned PoolManager, PositionManager and Permit2, with actual CREATE/CREATE2, swaps and NFT custody. Modeled quote tokens and EOA proposer tests do not prove live Circle, a fork or Safe governance. See the raw evidence and qualification status; mocks are explicitly identified in accounting tests.

Canonical adoption requires explicit acceptance of this concrete fee-activation/source/accounting model, completed adversarial review and applicable implementation qualification. Live release additionally requires current dependency/compiler advisory review, real fork qualification, Safe validation, independent audit and separate deployment authorization. No candidate may be self-marked accepted.
