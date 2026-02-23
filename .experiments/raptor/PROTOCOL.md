# RAPTOR Reproduction Protocol

Exact step-by-step protocol to reproduce all four RAPTOR sub-experiments.
Every command, parameter, and expected output is documented for reproducibility.

---

## Prerequisites

1. **Go simulation engine** built and tested:
   ```bash
   cd /playground/00_active/project-tor/next-simulate
   go build ./...
   go test ./...
   ```

2. **Python analysis environment** ready:
   ```bash
   cd /playground/00_active/project-tor/tor-anal
   uv sync
   ```

3. **CAIDA snapshots** available (7 monthly snapshots):
   ```bash
   ls tor-anal/output/snapshots/as_model_simplified_2025*.json
   # Expected: 20250101, 20250201, ..., 20250701 (minimum)
   ls tor-anal/data/model_edges_2025*.json
   # Same dates
   ```

4. **Disk space**: ~50 GB free (simulation outputs total ~42 GB)

---

## Phase A: R1 + R3 Simulations (Parallel, ~25 min total)

### A1. R1 Symmetric Baseline

```bash
cd /playground/00_active/project-tor/next-simulate
go run ./cmd/next-simulate -config configs/raptor_baseline_sym.yaml
```

| Parameter | Value |
|-----------|-------|
| Config | `configs/raptor_baseline_sym.yaml` |
| Duration | 90 days (129,600 ticks) |
| Clients | 200 |
| Asymmetric routing | **false** |
| Temporal snapshots | 3 (2025-01, 02, 03) |
| BGP attacks | none |
| Output obs | `output/raptor/obs_sym.ndjson` (~2.5 GB) |
| Output gt | `output/raptor/gt_sym.ndjson` (~1.7 GB) |
| Wall time | ~10 minutes |
| Total circuits | 7,776,600 |

**Verification**:
```bash
wc -l output/raptor/obs_sym.ndjson output/raptor/gt_sym.ndjson
# obs: ~17.6M lines, gt: ~7.8M lines
head -1 output/raptor/obs_sym.ndjson | python3 -m json.tool
# Should contain: circuit_id, asn, is_entry, is_exit, tick
```

### A2. R1 Asymmetric Comparison

```bash
go run ./cmd/next-simulate -config configs/raptor_baseline_asym.yaml
```

| Parameter | Value |
|-----------|-------|
| Config | `configs/raptor_baseline_asym.yaml` |
| Duration | 90 days |
| Clients | 200 |
| Asymmetric routing | **true** |
| Output obs | `output/raptor/obs_asym.ndjson` (~2.6 GB) |
| Output gt | `output/raptor/gt_asym.ndjson` (~1.7 GB) |
| Wall time | ~15 minutes |
| Total circuits | 7,776,600 |

**Verification**: Same as A1 but with asymmetric file paths.

### A3. R3 Entity Threat

```bash
go run ./cmd/next-simulate -config configs/raptor_entity_threat.yaml
```

| Parameter | Value |
|-----------|-------|
| Config | `configs/raptor_entity_threat.yaml` |
| Duration | 90 days |
| Clients | **500** (larger for statistical significance) |
| Asymmetric routing | true |
| Temporal snapshots | disabled |
| Output obs | `output/raptor/obs_entity.ndjson` (~7.7 GB) |
| Output gt | `output/raptor/gt_entity.ndjson` (~4.3 GB) |
| Wall time | ~25 minutes |
| Total circuits | 19,441,500 |

**Note**: 500 clients (vs 200) produces more circuits for reliable per-AS threat scoring.

---

## Phase B: R2 Temporal Simulations (Parallel, ~35 min total)

Run after Phase A is verified.

### B1. R2 Symmetric + Long-Term Churn

```bash
go run ./cmd/next-simulate -config configs/raptor_temporal_sym.yaml
```

| Parameter | Value |
|-----------|-------|
| Config | `configs/raptor_temporal_sym.yaml` |
| Duration | **180 days** (259,200 ticks) |
| Clients | 200 |
| Asymmetric routing | false |
| Temporal snapshots | **7** (2025-01 through 2025-07) |
| Output obs | `output/raptor/obs_temporal_sym.ndjson` (~5.3 GB) |
| Output gt | `output/raptor/gt_temporal_sym.ndjson` (~3.4 GB) |
| Wall time | ~25 minutes |
| Total circuits | ~15.5M |

### B2. R2 Asymmetric + Long-Term Churn

```bash
go run ./cmd/next-simulate -config configs/raptor_temporal_asym.yaml
```

| Parameter | Value |
|-----------|-------|
| Config | `configs/raptor_temporal_asym.yaml` |
| Duration | 180 days |
| Clients | 200 |
| Asymmetric routing | **true** |
| Temporal snapshots | 7 |
| Output obs | `output/raptor/obs_temporal_asym.ndjson` (~5.4 GB) |
| Output gt | `output/raptor/gt_temporal_asym.ndjson` (~3.4 GB) |
| Wall time | ~35 minutes |
| Total circuits | ~15.5M |

---

## Phase C: R4 Interception Simulation (~20 min)

Run after Phase A (needs R1 asymmetric baseline as comparison).

### C1. R4 BGP Interception

```bash
go run ./cmd/next-simulate -config configs/raptor_interception.yaml
```

| Parameter | Value |
|-----------|-------|
| Config | `configs/raptor_interception.yaml` |
| Duration | 90 days |
| Clients | 200 |
| Asymmetric routing | true |
| Temporal snapshots | 3 |
| BGP attacks | **3 interception attacks** |
| Output obs | `output/raptor/obs_intercept.ndjson` (~2.6 GB) |
| Output gt | `output/raptor/gt_intercept.ndjson` (~1.7 GB) |
| Wall time | ~20 minutes |

**BGP Attack Schedule**:

| Attack | Attacker | Target | Start Day | Duration | Adversary Type |
|--------|----------|--------|-----------|----------|---------------|
| 0 | AS174 (Cogent) | AS24940 (Hetzner) | Day 10 | 7 days | single |
| 1 | AS3356 (Level3/Lumen) | AS60729 | Day 30 | 7 days | tier1 |
| 2 | AS6939 (Hurricane Electric) | AS16276 (OVH) | Day 50 | 7 days | single |

Attack selection rationale: These ASes are the top-ranked Tier-1 threats in both
the RAPTOR paper and our R3 entity threat analysis. Targets are major hosting
providers with significant Tor relay presence (guard/exit nodes).

---

## Phase D: Python Analysis (~10 min)

### D1. Run Streaming Analysis

```bash
cd /playground/00_active/project-tor/tor-anal

uv run python -m analysis.run_raptor_analysis \
  --sym-obs ../next-simulate/output/raptor/obs_sym.ndjson \
  --sym-gt ../next-simulate/output/raptor/gt_sym.ndjson \
  --asym-obs ../next-simulate/output/raptor/obs_asym.ndjson \
  --asym-gt ../next-simulate/output/raptor/gt_asym.ndjson \
  --temporal-sym-obs ../next-simulate/output/raptor/obs_temporal_sym.ndjson \
  --temporal-sym-gt ../next-simulate/output/raptor/gt_temporal_sym.ndjson \
  --temporal-asym-obs ../next-simulate/output/raptor/obs_temporal_asym.ndjson \
  --temporal-asym-gt ../next-simulate/output/raptor/gt_temporal_asym.ndjson \
  --entity-obs ../next-simulate/output/raptor/obs_entity.ndjson \
  --entity-gt ../next-simulate/output/raptor/gt_entity.ndjson \
  --intercept-obs ../next-simulate/output/raptor/obs_intercept.ndjson \
  --intercept-gt ../next-simulate/output/raptor/gt_intercept.ndjson \
  --output-dir output/raptor_analysis
```

**Processing details**:
- Uses streaming NDJSON processing (`analysis/raptor_streaming.py`)
- Integer-encoded `(circuit_id, asn)` pairs: `circuit_id * 1_000_000 + asn_int`
- Peak RAM: ~2 GB (vs ~20 GB if loaded as DataFrames)
- Processes ~55M observation records across all experiments
- Produces JSON report + 4 PNG visualizations

**Expected outputs**:
```
output/raptor_analysis/
├── raptor_reproduction_report.json    # 9.6 KB
└── plots/
    ├── asymmetric_comparison.png      # 61 KB
    ├── temporal_churn_curves.png      # 73 KB
    ├── entity_threat_comparison.png   # 97 KB
    └── interception_impact.png        # 59 KB
```

### D2. Verify Results

```bash
# Check report exists and is valid JSON
python3 -c "import json; d=json.load(open('output/raptor_analysis/raptor_reproduction_report.json')); print(list(d.keys()))"
# Expected: ['R1_asymmetric_routing', 'R2_temporal_churn', 'R3_entity_threat', 'R4_interception']

# Check all plots generated
ls -la output/raptor_analysis/plots/
# Expected: 4 PNG files
```

---

## Timing Summary

| Phase | Simulations | Wall Time | Parallelizable |
|-------|-------------|-----------|----------------|
| A | R1-sym, R1-asym, R3-entity | ~25 min | Yes (3 parallel) |
| B | R2-temporal-sym, R2-temporal-asym | ~35 min | Yes (2 parallel) |
| C | R4-interception | ~20 min | No (depends on A) |
| D | Python analysis | ~10 min | No (sequential R1-R4) |
| **Total** | 6 simulations + analysis | **~90 min** | |

**Actual execution (2025-02-22)**:
- Phase A start: 02:40 UTC → complete: 02:57 UTC (17 min)
- Phase B start: 02:57 UTC → complete: 03:10 UTC (13 min)
- Phase C start: 03:10 UTC → complete: 03:23 UTC (13 min)
- Phase D start: 03:23 UTC → complete: 03:47 UTC (24 min, includes OOM retry with streaming)
- **Total wall time: ~67 minutes**

---

## Troubleshooting

### OOM on Analysis (Exit Code 137)

The initial analysis attempted to load full NDJSON files into pandas DataFrames,
causing OOM with ~20 GB RAM usage. Solution: `raptor_streaming.py` uses
integer-encoded compact sets, reducing peak RAM to ~2 GB.

If you still hit OOM, reduce client counts or use `--skip-viz` to avoid pandas
import for R3 entity threat visualization.

### Missing Snapshots

If temporal simulation fails with "snapshot not found", verify:
```bash
ls tor-anal/output/snapshots/as_model_simplified_*.json
ls tor-anal/data/model_edges_*.json
```

Generate missing snapshots:
```bash
cd tor-anal
uv run python -m pipeline --step 7 --snapshot YYYYMMDD
```

### Zero Correlation Rate

If correlation rate is 0.0%, check:
1. Observation file has both `is_entry: true` and `is_exit: true` records
2. Same ASN appears as both entry and exit for at least one circuit
3. Ground truth file has matching circuit IDs

```bash
# Quick check
grep '"is_entry":true' output/raptor/obs_sym.ndjson | head -1
grep '"is_exit":true' output/raptor/obs_sym.ndjson | head -1
```
