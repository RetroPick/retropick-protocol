# Commands and limits

Execution root: experiment worktree/contracts. Compiler: Solidity 0.8.26, Cancun, via IR, optimizer 200.

```sh
forge test --contracts src/v2 --match-path 'test/v2/research-experiment/*.t.sol' --match-test '^test(Registry|FuzzRegistry|AccruedUnswept|UnreleasedVesting)' --out /tmp/retropick-ce-m1-out --cache-path /tmp/retropick-ce-m1-cache --chain-id 10143 --code-size-limit 1048576 --fuzz-runs 10000
```

Source scope avoids scanning duplicate experiment copies, while registry tests explicitly import the new experiment source. BaselineRightsConflictTest intentionally imports canonical references and inherits their fixture; one matching inherited registry-admission test is included in the reported count. No production test was modified. Increased harness limit does not qualify deployable code size.

initial-tests.log: 12 passed, zero failed/skipped; one fuzz property 10000 cases. Two additional boundary tests were subsequently added; final-tests.log records their final result. All checkpoint/controller contracts used by registry tests are mocks. Neither run proves real fee settlement, custody or rewards. No fork, gas campaign or static-analysis qualification.

Protection: run tools/baseline.py --check from campaign root. Canonical/compiler reconciliation derives from the previous read-only fresh build: forge build --contracts src/v2 --skip test --skip script --ast --extra-output storageLayout --out /tmp/retropick-ce-g0-plan-bcu6qpx5/out --cache-path /tmp/retropick-ce-g0-plan-bcu6qpx5/cache. Static interfaces only; no deployed runtime verification.
