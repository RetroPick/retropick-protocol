# Hackathon P0 scripts

`./research/hackathon-p0/scripts/test-p0.sh fast` runs the nine standard-library
Python model tests, Prediction and PRISM unit/differential suites, and the
Prediction-to-PRISM lifecycle harness.

`./research/hackathon-p0/scripts/test-p0.sh stateful` runs the same checks plus
three deterministic seeds for each stateful invariant handler (256 runs per
seed, depth 100).

Requirements: Python 3.10+ and Foundry `forge`. Python uses only the standard
library. Foundry resolves the checked-in `research/contract-kernels/foundry.toml`
configuration and pinned `foundry.lock`; its local library dependencies are
git submodules. For a fresh checkout, initialize submodules before testing:

```sh
git submodule update --init --recursive
./research/hackathon-p0/scripts/test-p0.sh fast
```

The script does not install toolchains, fetch RPC state, write deployment data,
run production research, or generate/overwrite evidence. Record tool versions,
source SHA, seeds, runtime, and outputs separately when producing a qualification
artifact. Security analyzers remain a separate, explicitly qualified lane.
