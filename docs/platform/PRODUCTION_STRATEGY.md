# Production Strategy

The production-engineering priority is the established Launchpad Core plus shared RetroPick platform infrastructure.

PRISM remains outside the normal production track until module admission.

## Launchpad Core gates

Preserve:
- DEVELOPMENT_READY;
- HACKATHON_READY;
- STAGING_READY;
- MAINNET_CANDIDATE;
- MAINNET_AUTHORIZED.

Production research supplies evidence to these gates but does not replace them.

## Environment model

~~~text
LOCAL
CI
FORK
TESTNET_STAGING
PREPROD
MAINNET_CANDIDATE
MAINNET_AUTHORIZED
~~~

Environment qualification is module-aware. A staging environment can be qualified for Launchpad Core while PRISM remains NOT_ADMITTED.

MAINNET_AUTHORIZED always requires explicit human authorization.
