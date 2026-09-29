#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
profile="${1:-fast}"

if [[ "$profile" != "fast" && "$profile" != "stateful" ]]; then
  printf 'usage: %s [fast|stateful]\n' "$0" >&2
  exit 2
fi

for required in python3 forge; do
  if ! command -v "$required" >/dev/null 2>&1; then
    printf 'missing required command: %s\n' "$required" >&2
    exit 127
  fi
done

cd "$repo_root"
printf '%s\n' '== Hackathon P0 environment =='
python3 --version
forge --version

printf '%s\n' '== Python semantic models =='
python3 -m unittest discover -s research/hackathon-p0/tests -p 'test_*.py' -v

cd "$repo_root/research/contract-kernels"
printf '%s\n' '== Prediction unit + differential =='
forge test --match-path test/hackathon/PredictionP0.t.sol -vv
forge test --match-path test/hackathon/PredictionP0Differential.t.sol -vv

printf '%s\n' '== PRISM unit + differential =='
forge test --match-path test/hackathon/PrismP0.t.sol -vv
forge test --match-path test/hackathon/PrismP0Differential.t.sol -vv

printf '%s\n' '== Prediction to PRISM lifecycle =='
forge test --match-path test/hackathon/CrossModuleP0.t.sol -vv

if [[ "$profile" == "stateful" ]]; then
  for seed in 1 2 3; do
    printf '== Prediction stateful seed %s ==\n' "$seed"
    forge test --match-path test/hackathon/PredictionP0Invariant.t.sol \
      --fuzz-seed "$seed" --fuzz-runs 256 --invariant-depth 100 -vv
  done
  for seed in 1 2 3; do
    printf '== PRISM stateful seed %s ==\n' "$seed"
    forge test --match-path test/hackathon/PrismP0Invariant.t.sol \
      --fuzz-seed "$seed" --fuzz-runs 256 --invariant-depth 100 -vv
  done
fi

printf 'Hackathon P0 %s profile: PASS\n' "$profile"
