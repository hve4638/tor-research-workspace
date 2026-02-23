#!/bin/bash
# Custom multi-seed runner for validation experiments.
# Uses pre-built binary and absolute paths.
#
# Usage:
#   ./scripts/run_multi_seed.sh NUM_SEEDS CONFIG_PATH SCENARIO_NAME
#
# Output goes to: next-simulate/output/multi_seed/<scenario_name>/seed_N/

set -euo pipefail

SEEDS=${1:?Usage: $0 NUM_SEEDS CONFIG_PATH SCENARIO_NAME}
CONFIG_PATH=$(realpath "${2:?Need CONFIG_PATH}")
SCENARIO=${3:?Need SCENARIO_NAME}

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM_DIR="$PROJECT_ROOT/next-simulate"
BINARY="$SIM_DIR/next-simulate"
BASE_OUTPUT_DIR="$SIM_DIR/output/multi_seed/$SCENARIO"

if [ ! -f "$BINARY" ]; then
    echo "ERROR: Binary not found at $BINARY"
    echo "Build first: cd $SIM_DIR && go build -o next-simulate ./cmd/next-simulate"
    exit 1
fi

echo "=== Multi-seed simulation: $SCENARIO ==="
echo "Seeds: $SEEDS"
echo "Config: $CONFIG_PATH"
echo "Output: $BASE_OUTPUT_DIR"
echo ""

cd "$SIM_DIR"

for seed in $(seq 1 "$SEEDS"); do
    OUTPUT_DIR="${BASE_OUTPUT_DIR}/seed_${seed}"
    mkdir -p "$OUTPUT_DIR"

    # Create temp config with overridden seed and output paths
    TEMP_CONFIG=$(mktemp /tmp/sim_config_XXXXXX.yaml)
    sed \
        -e "s/seed: [0-9]*/seed: ${seed}/" \
        -e "s|observation_log:.*|observation_log: \"${OUTPUT_DIR}/observations.ndjson\"|" \
        -e "s|ground_truth_log:.*|ground_truth_log: \"${OUTPUT_DIR}/ground_truth.ndjson\"|" \
        "$CONFIG_PATH" > "$TEMP_CONFIG"

    echo "[seed $seed/$SEEDS] Running..."
    START_TIME=$(date +%s)
    "$BINARY" -config "$TEMP_CONFIG" 2>/dev/null
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))

    rm -f "$TEMP_CONFIG"

    # Check output size
    OBS_SIZE=$(du -sh "$OUTPUT_DIR/observations.ndjson" 2>/dev/null | cut -f1 || echo "N/A")
    GT_SIZE=$(du -sh "$OUTPUT_DIR/ground_truth.ndjson" 2>/dev/null | cut -f1 || echo "N/A")
    echo "[seed $seed/$SEEDS] Done in ${ELAPSED}s → obs=$OBS_SIZE, gt=$GT_SIZE"
done

echo ""
echo "=== All $SEEDS seeds complete for $SCENARIO ==="
echo "Results in: $BASE_OUTPUT_DIR/"
