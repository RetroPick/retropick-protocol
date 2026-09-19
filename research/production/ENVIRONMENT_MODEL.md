# Environment Model

~~~text
LOCAL
CI
FORK
TESTNET_STAGING
PREPROD
MAINNET_CANDIDATE
MAINNET_AUTHORIZED
~~~

Environment qualification is module-aware.

~~~yaml
environment: staging-01
modules:
  launchpad_core:
    enabled: true
    qualification: STAGING_READY
  prism:
    enabled: false
    qualification: RESEARCH
~~~

Environment readiness never implies module readiness. MAINNET_AUTHORIZED always requires explicit human authorization.
