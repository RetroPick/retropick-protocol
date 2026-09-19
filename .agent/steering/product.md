# Product Steering

RetroPick is one programmable onchain Launchpad platform.

## Launchpad Core

Current established financial launch primitive:

~~~text
create token
-> bonding primary market
-> buy/sell
-> graduation
-> Kuru mature market
~~~

Normal user economic actions are non-custodial.

Doorway/cross-chain migration is not Launchpad-Core P0.

## Prediction + PRISM

Prediction and PRISM are additional RetroPick platform modules.

They use separate collateral/backing/resolution/settlement semantics under docs/prism/ and do not inherit Launchpad-Core production status until their own gates pass.

## Rule

Shared UX/infrastructure may converge.

Never use one module's economic model as an implementation shortcut for another.
