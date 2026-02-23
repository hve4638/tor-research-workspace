# "Users Get Routed" Reproduction Protocol

Exact step-by-step protocol to reproduce both experiment sets.

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

3. **CAIDA snapshots** available (3 monthly):
   ```bash
   ls tor-anal/output/snapshots/as_model_simplified_202501*.json
   ls tor-anal/data/model_edges_202501*.json
   # Expected: 20250101, 20250201, 20250301
   ```

4. **AS path probabilities** (for Counter-RAPTOR):
   ```bash
   ls tor-anal/output/as_path_probabilities.json
   ```

5. **Disk space**: ~15 GB free

---

## Set A: Network Adversary (4 Defense Scenarios)

### Phase A1: Simulations (Parallel, ~15 min total)

All 4 scenarios can run in parallel on separate terminals.

#### A1-1. Vanilla (No Defense)

```bash
cd /playground/00_active/project-tor/next-simulate
go run ./cmd/next-simulate -config configs/bgp_attack.yaml
```

| Parameter | Value |
|-----------|-------|
| Config | `configs/bgp_attack.yaml` |
| Duration | 90 days (129,600 ticks) |
| Clients | 50 |
| Defense | none |
| BGP attacks | 3 (hijack + interception + state-level) |
| Temporal | 3 snapshots (2025-01, 02, 03) |
| Output obs | `output/observations_bgp.ndjson` (~586 MB) |
| Output gt | `output/ground_truth_bgp.ndjson` (~432 MB) |
| Total circuits | 1,944,150 |
| Wall time | ~5 minutes |

#### A1-2. Counter-RAPTOR Defense

```bash
go run ./cmd/next-simulate -config configs/counter_raptor_defense.yaml
```

| Parameter | Value |
|-----------|-------|
| Config | `configs/counter_raptor_defense.yaml` |
| Defense | Counter-RAPTOR (weight_factor=1.0, max_cap=100.0) |
| Output obs | `output/observations_cr.ndjson` (~586 MB) |
| Output gt | `output/ground_truth_cr.ndjson` (~432 MB) |
| Wall time | ~5 minutes |

Same BGP attacks, temporal, client config as Vanilla.

#### A1-3. Astoria Defense

```bash
go run ./cmd/next-simulate -config configs/astoria_defense.yaml
```

| Parameter | Value |
|-----------|-------|
| Config | `configs/astoria_defense.yaml` |
| Defense | Astoria (max_retries=5) |
| Output obs | `output/observations_astoria.ndjson` (~574 MB) |
| Output gt | `output/ground_truth_astoria.ndjson` (~432 MB) |
| Wall time | ~5 minutes |

#### A1-4. Combined Defense (Counter-RAPTOR + Astoria)

```bash
go run ./cmd/next-simulate -config configs/combined_defense.yaml
```

| Parameter | Value |
|-----------|-------|
| Config | `configs/combined_defense.yaml` |
| Defense | Counter-RAPTOR + Astoria |
| Output obs | `output/observations_combined.ndjson` (~566 MB) |
| Output gt | `output/ground_truth_combined.ndjson` (~432 MB) |
| Wall time | ~5 minutes |

### Phase A2: Network Analysis (~3 min)

```bash
cd /playground/00_active/project-tor/tor-anal

uv run python -m analysis.run_analysis \
  --vanilla-obs ../next-simulate/output/observations_bgp.ndjson \
  --vanilla-gt ../next-simulate/output/ground_truth_bgp.ndjson \
  --cr-obs ../next-simulate/output/observations_cr.ndjson \
  --cr-gt ../next-simulate/output/ground_truth_cr.ndjson \
  --astoria-obs ../next-simulate/output/observations_astoria.ndjson \
  --astoria-gt ../next-simulate/output/ground_truth_astoria.ndjson \
  --combined-obs ../next-simulate/output/observations_combined.ndjson \
  --combined-gt ../next-simulate/output/ground_truth_combined.ndjson \
  --cdf --tick-interval-ms 60000 \
  --output-dir output/analysis_m6_cdf
```

**Expected outputs**:
```
output/analysis_m6_cdf/
├── defense_comparison_report.json     # Full metrics + CDF data
└── plots/
    ├── time_to_first_compromise_cdf.png   # Figure 2a equivalent
    ├── stream_compromise_over_time.png    # Figure 3 equivalent
    ├── correlation_comparison.png         # Defense comparison bar chart
    ├── temporal_curves.png                # Per-period correlation trends
    ├── cumulative_compromise.png          # Cumulative compromise curves
    ├── attack_impact.png                  # BGP attack pre/during/post
    ├── as_risk_heatmap.png               # Per-AS threat heatmap
    └── guard_distribution_shift.png       # Guard selection distribution
```

**Verification**:
```bash
python3 -c "
import json
d = json.load(open('output/analysis_m6_cdf/defense_comparison_report.json'))
for s in d['overall']:
    print(f\"{s['scenario']:>15}: {s['correlation_rate']*100:.4f}% ({s['correlated_circuits']}/{s['total_circuits']})  reduction={s['reduction_pct']:.1f}%\")
"
```

---

## Set B: Relay Adversary

### Phase B1: Simulation (~20 min)

```bash
cd /playground/00_active/project-tor/next-simulate
go run ./cmd/next-simulate -config configs/relay_adversary.yaml
```

| Parameter | Value |
|-----------|-------|
| Config | `configs/relay_adversary.yaml` |
| Duration | **180 days** (259,200 ticks) |
| Clients | **200** |
| Adversary bandwidth | 100 MiB/s (102,400 KB) |
| Guard:Exit ratio | 5:1 (Guard 83.3%, Exit 16.7%) |
| Asymmetric routing | true |
| BGP attacks | none |
| Temporal | disabled |
| Output obs | `output/observations_relay_adv.ndjson` (~6.2 GB) |
| Output gt | `output/ground_truth_relay_adv.ndjson` (~3.5 GB) |
| Total circuits | 15,552,600 |
| Wall time | ~20 minutes |

**Relay adversary mechanics**:
- Synthetic guard ASN (`_ADV_GUARD`) and exit ASN (`_ADV_EXIT`) injected into
  directory service
- Guard receives 83.3% of 100 MiB/s bandwidth, Exit receives 16.7%
- Compromise detected when circuit's guard AND exit are both adversary-controlled
- `relay_compromise` markers emitted to observation log

### Phase B2: Relay Adversary Analysis (~5 min)

Uses streaming CDF analysis for large output files:

```bash
cd /playground/00_active/project-tor/tor-anal

uv run python -m analysis.streaming_cdf \
  --obs ../next-simulate/output/observations_relay_adv.ndjson \
  --gt ../next-simulate/output/ground_truth_relay_adv.ndjson \
  --tick-interval-ms 60000 \
  --output-dir output/analysis_relay_adv
```

**Expected outputs**:
```
output/analysis_relay_adv/
├── defense_comparison_report.json     # Relay compromise metrics + CDF
└── plots/
    ├── relay_compromise_cdf.png           # Figure 2a equivalent
    ├── stream_compromise_over_time.png    # Figure 3 equivalent
    └── time_to_first_compromise_cdf.png   # Network-level CDF overlay
```

**Verification**:
```bash
python3 -c "
import json
d = json.load(open('output/analysis_relay_adv/defense_comparison_report.json'))
rc = d.get('relay_cdf', {})
if rc:
    print(f\"Full compromises: {rc.get('full_count', 'N/A')}\")
    print(f\"Guard-only: {rc.get('guard_only_count', 'N/A')}\")
    print(f\"Exit-only: {rc.get('exit_only_count', 'N/A')}\")
"
```

---

## Timing Summary

| Phase | What | Wall Time | Parallelizable |
|-------|------|-----------|----------------|
| A1 | 4 network simulations | ~15 min | Yes (all 4 parallel) |
| A2 | Network analysis + CDF | ~3 min | No |
| B1 | Relay adversary simulation | ~20 min | Yes (parallel with A1) |
| B2 | Relay adversary analysis | ~5 min | No |
| **Total** | 5 simulations + 2 analyses | **~25 min** (parallel) | |

**Actual execution (2025-02-20 ~ 2025-02-22)**:
- Set A simulations: ~15 min (4 parallel Go processes)
- Set A analysis: ~3 min
- Set B simulation: ~20 min
- Set B analysis: ~5 min (streaming for 6.2 GB obs)
- **Total wall time: ~25 minutes** (with parallelization)

---

## Troubleshooting

### OOM on Relay Adversary Analysis

The relay adversary produces ~6.2 GB of observation data (43.5M lines). Use the
streaming CDF analysis module (`analysis.streaming_cdf`) instead of the standard
`analysis.run_analysis` which loads full DataFrames.

### Missing AS Path Probabilities

Counter-RAPTOR requires `tor-anal/output/as_path_probabilities.json`. Generate it:
```bash
cd tor-anal
uv run python -m pipeline --step 5
```

### Defense Has No Effect (Same Correlation)

Counter-RAPTOR only reweights guard selection. If the compromising AS is already
the dominant transit provider, reweighting may not help (this is expected — see
Results for analysis). Astoria should show dramatic reduction.

### Relay Adversary: 0% Compromise for 57 Days

This is expected behavior. Guard lifetime is 30-60 days. Until the initial guards
expire and are re-selected, the adversary's guard relay cannot be chosen. Once
guard rotation occurs around day 57-60, compromise happens rapidly.
