#!/bin/bash
# Run all validation simulations: S1 (multi-seed), S2 (client sensitivity), S3 (guard lifetime)
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM_DIR="$PROJECT_ROOT/next-simulate"
BINARY="$SIM_DIR/next-simulate"
MS_BASE="$SIM_DIR/output/multi_seed"
NUM_SEEDS=${1:-5}

if [ ! -f "$BINARY" ]; then
    echo "ERROR: Binary not found at $BINARY"
    exit 1
fi

cd "$SIM_DIR"

run_sim() {
    local CONFIG_PATH="$1"
    local OUTPUT_DIR="$2"
    local LABEL="$3"

    mkdir -p "$OUTPUT_DIR"
    local START_TIME=$(date +%s)
    "$BINARY" -config "$CONFIG_PATH" 2>/dev/null
    local END_TIME=$(date +%s)
    local ELAPSED=$((END_TIME - START_TIME))

    local OBS_SIZE=$(du -sh "$OUTPUT_DIR/observations.ndjson" 2>/dev/null | cut -f1 || echo "N/A")
    echo "  [$LABEL] Done in ${ELAPSED}s, obs=$OBS_SIZE"
}

run_scenario_seeds() {
    local ORIG_CONFIG="$1"
    local SCENARIO_NAME="$2"
    local SEEDS="$3"

    echo ""
    echo "=== S1: $SCENARIO_NAME ($SEEDS seeds) ==="
    for seed in $(seq 1 "$SEEDS"); do
        local OUTPUT_DIR="${MS_BASE}/${SCENARIO_NAME}/seed_${seed}"
        mkdir -p "$OUTPUT_DIR"

        local TEMP_CONFIG=$(mktemp /tmp/sim_XXXXXX.yaml)
        sed \
            -e "s/seed: [0-9]*/seed: ${seed}/" \
            -e "s|observation_log:.*|observation_log: \"${OUTPUT_DIR}/observations.ndjson\"|" \
            -e "s|ground_truth_log:.*|ground_truth_log: \"${OUTPUT_DIR}/ground_truth.ndjson\"|" \
            "$ORIG_CONFIG" > "$TEMP_CONFIG"

        run_sim "$TEMP_CONFIG" "$OUTPUT_DIR" "seed $seed/$SEEDS"
        rm -f "$TEMP_CONFIG"
    done
}

echo "============================================"
echo "  Validation Simulation Suite"
echo "  Seeds per scenario: $NUM_SEEDS"
echo "  Binary: $BINARY"
echo "============================================"

# ===== S1: Multi-seed (4 scenarios) =====
run_scenario_seeds "$PROJECT_ROOT/.experiments/raptor/configs/raptor_baseline_asym.yaml" "raptor_asym" "$NUM_SEEDS"
run_scenario_seeds "$PROJECT_ROOT/.experiments/users_get_routed/configs/bgp_attack.yaml" "bgp_attack" "$NUM_SEEDS"
run_scenario_seeds "$PROJECT_ROOT/.experiments/users_get_routed/configs/astoria_defense.yaml" "astoria" "$NUM_SEEDS"
run_scenario_seeds "$PROJECT_ROOT/.experiments/users_get_routed/configs/relay_adversary.yaml" "relay_adversary" "$NUM_SEEDS"

# ===== S2: Client count sensitivity =====
echo ""
echo "=== S2: Client count sensitivity ==="
BASE_BGP="$PROJECT_ROOT/.experiments/users_get_routed/configs/bgp_attack.yaml"
for COUNT in 50 100 200 500 1000; do
    OUTPUT_DIR="${MS_BASE}/s2_clients_${COUNT}/seed_1"
    mkdir -p "$OUTPUT_DIR"

    TEMP_CONFIG=$(mktemp /tmp/sim_s2_XXXXXX.yaml)
    sed \
        -e "s/seed: [0-9]*/seed: 42/" \
        -e "s/count: [0-9]*/count: ${COUNT}/" \
        -e "s|observation_log:.*|observation_log: \"${OUTPUT_DIR}/observations.ndjson\"|" \
        -e "s|ground_truth_log:.*|ground_truth_log: \"${OUTPUT_DIR}/ground_truth.ndjson\"|" \
        "$BASE_BGP" > "$TEMP_CONFIG"

    run_sim "$TEMP_CONFIG" "$OUTPUT_DIR" "clients=$COUNT"
    rm -f "$TEMP_CONFIG"
done

# ===== S3: Guard lifetime sensitivity =====
echo ""
echo "=== S3: Guard lifetime sensitivity ==="
BASE_RELAY="$PROJECT_ROOT/.experiments/users_get_routed/configs/relay_adversary.yaml"

# S3-1: uniform[30,60] (default)
OUTPUT_DIR="${MS_BASE}/s3_guard_30_60/seed_1"
mkdir -p "$OUTPUT_DIR"
TEMP_CONFIG=$(mktemp /tmp/sim_s3_XXXXXX.yaml)
sed \
    -e "s/seed: [0-9]*/seed: 42/" \
    -e "s|observation_log:.*|observation_log: \"${OUTPUT_DIR}/observations.ndjson\"|" \
    -e "s|ground_truth_log:.*|ground_truth_log: \"${OUTPUT_DIR}/ground_truth.ndjson\"|" \
    "$BASE_RELAY" > "$TEMP_CONFIG"
run_sim "$TEMP_CONFIG" "$OUTPUT_DIR" "guard U[30,60]"
rm -f "$TEMP_CONFIG"

# S3-2: uniform[60,90]
OUTPUT_DIR="${MS_BASE}/s3_guard_60_90/seed_1"
mkdir -p "$OUTPUT_DIR"
TEMP_CONFIG=$(mktemp /tmp/sim_s3_XXXXXX.yaml)
sed \
    -e "s/seed: [0-9]*/seed: 42/" \
    -e "s/lifetime_days_min: [0-9]*/lifetime_days_min: 60/" \
    -e "s/lifetime_days_max: [0-9]*/lifetime_days_max: 90/" \
    -e "s|observation_log:.*|observation_log: \"${OUTPUT_DIR}/observations.ndjson\"|" \
    -e "s|ground_truth_log:.*|ground_truth_log: \"${OUTPUT_DIR}/ground_truth.ndjson\"|" \
    "$BASE_RELAY" > "$TEMP_CONFIG"
run_sim "$TEMP_CONFIG" "$OUTPUT_DIR" "guard U[60,90]"
rm -f "$TEMP_CONFIG"

# S3-3: uniform[30,150] (wide spread to approximate exponential)
OUTPUT_DIR="${MS_BASE}/s3_guard_30_150/seed_1"
mkdir -p "$OUTPUT_DIR"
TEMP_CONFIG=$(mktemp /tmp/sim_s3_XXXXXX.yaml)
sed \
    -e "s/seed: [0-9]*/seed: 42/" \
    -e "s/lifetime_days_min: [0-9]*/lifetime_days_min: 30/" \
    -e "s/lifetime_days_max: [0-9]*/lifetime_days_max: 150/" \
    -e "s|observation_log:.*|observation_log: \"${OUTPUT_DIR}/observations.ndjson\"|" \
    -e "s|ground_truth_log:.*|ground_truth_log: \"${OUTPUT_DIR}/ground_truth.ndjson\"|" \
    "$BASE_RELAY" > "$TEMP_CONFIG"
run_sim "$TEMP_CONFIG" "$OUTPUT_DIR" "guard U[30,150]"
rm -f "$TEMP_CONFIG"

echo ""
echo "============================================"
echo "  All validation simulations complete!"
echo "  Output: $MS_BASE/"
echo "============================================"
echo ""
echo "Directories:"
ls -d "$MS_BASE"/*/ 2>/dev/null || echo "(none)"
echo ""
echo "Next: run analysis"
echo "  cd $PROJECT_ROOT/tor-anal"
echo "  uv run python -m analysis.validation.multi_seed_analysis --experiment all"
