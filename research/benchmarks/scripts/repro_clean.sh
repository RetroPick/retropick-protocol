#!/usr/bin/env bash
# Reproduce committed financial research in a disposable, inspectable checkout.
# The original worktree is never the test output directory.
set -euo pipefail

qual_profile="${1:-default}"
if [[ "$qual_profile" != "default" && "$qual_profile" != "research" ]]; then
  echo "usage: bash research/benchmarks/scripts/repro_clean.sh [default|research]" >&2
  exit 2
fi

qual_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
qual_repo="$(cd "$qual_script_dir/../../.." && pwd)"
if [[ -n "$(git -C "$qual_repo" status --porcelain)" ]]; then
  echo "commit or set aside worktree changes before a clean-checkout reproduction" >&2
  exit 2
fi
command -v forge >/dev/null || { echo "forge is required; run bash .cursor/install.sh first" >&2; exit 2; }
command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 2; }

qual_sha="$(git -C "$qual_repo" rev-parse HEAD)"
qual_scratch="$(mktemp -d -t retropick-finance-repro.XXXXXXXX)"
qual_checkout="$qual_scratch/checkout"
echo "source_sha: $qual_sha"
echo "profile: $qual_profile"
echo "artifacts: $qual_scratch"

git clone --local --no-hardlinks "$qual_repo" "$qual_checkout" >"$qual_scratch/clone.log" 2>&1
git -C "$qual_checkout" checkout --detach "$qual_sha" >>"$qual_scratch/clone.log" 2>&1
git -C "$qual_checkout" submodule update --init --recursive >"$qual_scratch/submodule.log" 2>&1
python3 -m venv "$qual_scratch/venv"
qual_python="$qual_scratch/venv/bin/python"
"$qual_python" -m pip install --disable-pip-version-check -r "$qual_checkout/research/requirements-formal.txt" >"$qual_scratch/pip.log" 2>&1

"$qual_python" --version
forge --version | head -n 1
"$qual_python" -c 'import sympy,z3; print("sympy",sympy.__version__,"z3",z3.get_version_string())'
qual_failed=0

run_in() {
  local qual_name="$1"
  local qual_directory="$2"
  shift 2
  if (cd "$qual_directory" && "$@") >"$qual_scratch/$qual_name.log" 2>&1; then
    echo "$qual_name: PASS"
  else
    echo "$qual_name: FAIL (see $qual_scratch/$qual_name.log)"
    qual_failed=1
  fi
}

run_in prediction-unittest "$qual_checkout/research/prediction-model" "$qual_python" -m unittest discover -s tests -q
run_in prism-unittest "$qual_checkout/research/prism-model" "$qual_python" -m unittest discover -s tests -q
run_in forge-build "$qual_checkout/research/contract-kernels" forge build
run_in forge-test "$qual_checkout/research/contract-kernels" forge test

if [[ "$qual_profile" == "research" ]]; then
  run_in prism-attack "$qual_checkout/research/prism-model" "$qual_python" cumulative_settlement_attack.py
  run_in holder-fairness "$qual_checkout/research/prism-model" "$qual_python" holder_fairness_attack.py
  run_in candidate-telescope "$qual_checkout/research/prism-model" "$qual_python" candidate_telescope_proof.py
  run_in prism-exhaustive "$qual_checkout/research/prism-model" "$qual_python" -m unittest tests.test_extended_domains -v
  run_in candidate-fixtures "$qual_checkout/research/prism-model" "$qual_python" generate_candidate_fixtures.py
  run_in precision-fixtures "$qual_checkout/research/prism-model" "$qual_python" generate_precision_boundary_fixtures.py
  run_in backing-fixtures "$qual_checkout/research/prism-model" "$qual_python" generate_backing_fixtures.py
  run_in partial-fixtures "$qual_checkout/research/prism-model" "$qual_python" generate_partial_resolution_fixtures.py
  run_in prediction-fixtures "$qual_checkout/research/prediction-model" "$qual_python" fixtures_build.py
  run_in reference-benchmarks "$qual_checkout" "$qual_python" research/benchmarks/time_reference_models.py
  run_in prediction-compositions "$qual_checkout/research/contract-kernels" env FOUNDRY_PROFILE=invalid_floor_compositions forge test --match-contract PredictionInvalidFloorCompositionsTest
fi

echo "generated_or_rewritten_paths_in_temporary_checkout:"
git -C "$qual_checkout" status --short
echo "repro_exit: $qual_failed"
exit "$qual_failed"
