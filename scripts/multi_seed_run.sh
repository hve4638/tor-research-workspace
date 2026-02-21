#!/bin/bash
# Multi-seed simulation runner for CDF confidence interval analysis.
# Runs N seeds of the same config, then aggregates results with Python.
#
# Usage:
#   ./scripts/multi_seed_run.sh [NUM_SEEDS] [CONFIG_PATH]
#
# Example:
#   ./scripts/multi_seed_run.sh 10 configs/relay_adversary.yaml
#   ./scripts/multi_seed_run.sh 100 configs/bgp_attack.yaml

set -euo pipefail

SEEDS=${1:-10}
CONFIG=${2:-"configs/relay_adversary.yaml"}
BASE_OUTPUT_DIR="output/multi_seed"

echo "=== Multi-seed simulation ==="
echo "Seeds: $SEEDS"
echo "Config: $CONFIG"
echo "Output: $BASE_OUTPUT_DIR"
echo ""

cd "$(dirname "$0")/../next-simulate"

for seed in $(seq 1 "$SEEDS"); do
    OUTPUT_DIR="${BASE_OUTPUT_DIR}/seed_${seed}"
    mkdir -p "$OUTPUT_DIR"

    # Create temp config with overridden seed and output paths
    TEMP_CONFIG=$(mktemp)
    sed \
        -e "s/seed: [0-9]*/seed: ${seed}/" \
        -e "s|observation_log:.*|observation_log: \"${OUTPUT_DIR}/observations.ndjson\"|" \
        -e "s|ground_truth_log:.*|ground_truth_log: \"${OUTPUT_DIR}/ground_truth.ndjson\"|" \
        "$CONFIG" > "$TEMP_CONFIG"

    echo "[seed $seed/$SEEDS] Running..."
    go run ./cmd/next-simulate -config "$TEMP_CONFIG" 2>/dev/null

    rm -f "$TEMP_CONFIG"
    echo "[seed $seed/$SEEDS] Done → $OUTPUT_DIR"
done

echo ""
echo "=== All seeds complete ==="
echo "Results in: $BASE_OUTPUT_DIR/seed_1/ ... $BASE_OUTPUT_DIR/seed_$SEEDS/"
echo ""
echo "To aggregate with CDF analysis:"
echo "  cd ../tor-anal"
echo "  uv run python -m analysis.run_analysis \\"
echo "    --vanilla-obs ../next-simulate/${BASE_OUTPUT_DIR}/seed_1/observations.ndjson \\"
echo "    --vanilla-gt ../next-simulate/${BASE_OUTPUT_DIR}/seed_1/ground_truth.ndjson \\"
echo "    --cdf --multi-seed-dirs $(for s in $(seq 1 "$SEEDS"); do echo -n "../next-simulate/${BASE_OUTPUT_DIR}/seed_${s} "; done)"
