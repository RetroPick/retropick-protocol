# Core V2 crossing-buy and failed V4 seed — 2026-09-29

**Classification:** `SUPPORTED_BY_EXECUTABLE_TEST_WITHIN_DECLARED_FIXTURE` for one current-code native-quote failure path; `NOT_YET_VALIDATED` for a live V4 market, full retry, rescue, or Kuru destination. No production Solidity changed.

`contracts/test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol::testCrossingBuySweepsAssetsAndFailedMockV4SeedPreservesThem` launches through the real Factory/Deployer/Curve/Token stack. The external V4-only singleton getters are mocked; the destination has no functioning pool implementation.

A 150 ETH buy reaches the 500,000-token sellable cap. The actual charged input is smaller and the remainder is refunded. The Curve's automatic graduation succeeds through the *sweep* step: the Curve is marked graduated, Factory phase becomes `Swept`, and Factory physical native quote/token balances equal its recorded `sweptQuote`/`sweptTokens`. Subsequent Curve buy and sell both reject. `createGraduatedPool` then reverts against the nonfunctional V4 destination, and the Factory's physical balances and `Swept` phase remain unchanged. This validates atomic rollback of this mocked failed destination call, not live position minting, destination verification, or a successful retry.

**Reproduction:** `cd contracts && forge test --match-test testCrossingBuySweepsAssetsAndFailedMockV4SeedPreservesThem -vv` — pass. Fixture SHA-256: `a0d1cff1e846ff9d727682d4bbc6f288c0fbe9d96274f28e7e2cf6ee67ea5de7`. LP-I-006..009 gain partial evidence; none is a full PASS. Kuru target remains blocked on concrete parameter, custody, verification and retry decisions.
