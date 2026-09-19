# Product Architecture

**Status:** CANONICAL PLATFORM PRODUCT MODEL

## Product identity

RetroPick is a programmable onchain Launchpad platform.

The current established Launchpad Core follows a modern launch lifecycle:

~~~text
create asset
-> primary market
-> liquidity/demand formation
-> graduation
-> mature secondary market
~~~

RetroPick extends that platform thesis toward additional independently qualified financial launch primitives.

## Current modules

### Launchpad Core

Current production-engineering target:
- fixed/capped ERC20 launch;
- bonding primary market;
- reserve/fee accounting;
- deterministic graduation;
- Kuru mature-market destination.

### Prediction Markets

Incubating module for event-linked outcome issuance and resolution.

### PRISM

Incubating structured-markets module that composes supported outcome assets into exact-backed structured ERC20 claims.

## Shared application

The long-term user surface is one RetroPick application:

~~~text
Explore
Launch
Trade
Portfolio
Activity
Analytics
~~~

Qualified launch templates may eventually include Token, Prediction and PRISM.

A module that has not passed its qualification gates must remain hidden, research-labelled, testnet-only or feature-gated.

## Non-negotiable boundary

Shared UX does not imply shared accounting.

The Launchpad Core bonding curve, Prediction complete-set model and PRISM backing/settlement model each retain their own state machines, invariants and security gates.
