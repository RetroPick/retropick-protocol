# ADR-CE01 — experimental community curve entitlements

Status: PROPOSED. Experiment authorization only; not an accepted change to canonical V2 economics or a release authorization.

Question: can a new opt-in V2 launch allocate legitimate creator-domain trading fees among bounded beneficiaries while retaining protocol entitlement, unchanged trader fee rates, and immutable rights to old earnings?

Candidate decision: retain F/T trade arithmetic and protocol P=floor(F*protocolShareBps/10000) in existing escrow. Allocate only C=F-P+T through a per-launch, immutable-source router. Disable legacy source buyback and recipient override only in CE mode. Bind the entire configuration at new launch; no deployed retrofit. Old pending F/T must be atomically funded under the active old policy before delayed activation. No admin rescues or claim reassignments. Separate controller and economic beneficiary.

Alternatives: gross-fee routing adds a second protocol-entitlement boundary; shared custody increases cross-launch blast radius; per-trade recipient allocation adds trade-path gas; a mere epoch mapping without authentic checkpoint permits retroactive allocation. Selected aggregate checkpoint bounds work to one curve and ten recipients, with no discretionary conversion/strategy dependency.

Consequences: per-launch deployment cost; fixed treasury receives allocation dust; unsupported nonstandard assets fail closed; destroyed token backing cannot be repaired by accounting. Curve-stage fee cap does not cap venue LP fees. Declared creator-category cap does not identify beneficial ownership. EOA treasury is disclosed, not a qualified timelock. v4 CE hook revenue is disabled pending a real adapter. Kuru fee rights remain blocked.

Evidence and limitations: research/launchpad/community-economy-v2/iterations/002-real-curve-accounting.md and scoped run evidence. Local tests are neither audit nor real venue qualification. Production adoption requires explicit owner acceptance, complete LP/CE qualification, independent review and migration approval. No canonical financial semantics are changed by this candidate record.
