# RetroPick Platform

**Status:** CANONICAL PLATFORM ROUTER

RetroPick is one programmable onchain asset-launch platform.

Today the established core launches fixed/capped ERC20 assets through a bonding primary market and graduates successful launches to Kuru. Prediction Markets and PRISM are additional RetroPick financial launch modules that remain independently gated until their mechanisms are sufficiently validated.

## Platform model

~~~text
RetroPick Launchpad
|
+-- Launchpad Core
|   +-- fixed/capped ERC20
|   +-- bonding market
|   +-- graduation
|   +-- Kuru mature market
|
+-- Prediction Module
|   +-- event-linked outcome assets
|   +-- independently qualified
|
+-- PRISM Module
    +-- structured outcome assets
    +-- independently qualified
~~~

Shared infrastructure may include discovery, profiles, portfolio, activity, analytics, wallet interaction, indexed read models, metadata/search APIs, SDK/types, Kuru connectivity, environment/configuration and observability.

Financial semantics remain module-local.

## Read next

1. PRODUCT_ARCHITECTURE.md
2. ASSET_TAXONOMY.md
3. MODULE_MODEL.md
4. SHARED_PLATFORM.md
5. MODULE_PROMOTION.md
6. RESEARCH_STRATEGY.md
7. PRODUCTION_STRATEGY.md
