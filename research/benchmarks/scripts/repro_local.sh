#!/usr/bin/env bash
# Rerun committed unit tests and Foundry kernel tests.
# This is not a clean checkout of the monorepo and not a fresh virtualenv.
set -u

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

echo "git_sha: $(git rev-parse HEAD)"
echo "python: $(python3 --version 2>&1)"
echo "forge: $(forge --version 2>&1 | head -n 1)"
echo "note: existing interpreter and existing Foundry install. No virtualenv was created. No fresh clone."

fail=0

echo "=== prediction-model unittest ==="
if python3 -m unittest discover -s research/prediction-model/tests; then
  echo "prediction_model: PASS"
else
  echo "prediction_model: FAIL"
  fail=1
fi

echo "=== prism-model unittest ==="
if python3 -m unittest discover -s research/prism-model/tests; then
  echo "prism_model: PASS"
else
  echo "prism_model: FAIL"
  fail=1
fi

echo "=== forge test (not coverage) ==="
if (cd research/contract-kernels && forge test); then
  echo "forge_test: PASS"
else
  echo "forge_test: FAIL"
  fail=1
fi

echo "repro_exit: ${fail}"
exit "${fail}"
