# Validation Report: AS-Level Tor Traffic Analysis Simulator

This report provides a comprehensive validity assessment of the AS-level Tor traffic correlation simulator developed for studying global observer threats against Tor anonymity. The simulator reproduces findings from RAPTOR (Sun et al., USENIX Security 2015) and Johnson et al. (ACM CCS 2013), operating on a 727-AS Tor-relevant subgraph with BFS-based valley-free routing, dynamic CAIDA topology snapshots, and defense mechanisms (Counter-RAPTOR, Astoria).

## Key Findings

- **8/8 validation tests pass** (V1-V8): topology, routing, guard selection, transit concentration, temporal variation, defense audit, correlation audit, and relay theory
- **3 Tier-A claims** (high confidence): relay compromise mechanics, defense ordering, and correlation logic correctness
- **4 Tier-B claims** (moderate confidence): Tier-1 dominance, asymmetric routing effect, temporal threat growth, and conservative path estimation
- **Systematic conservative bias**: shorter AS-paths (mean 3.54 vs. 4.2 hops) mean correlation estimates represent a lower bound on real-world threat
- **Defense implementations verified**: Counter-RAPTOR (1/p_entry) and Astoria (transit overlap) match paper specifications (11/11 code checks pass)

## Table of Contents

| Section | Document | Description |
|---------|----------|-------------|
| 01 | [Validity Framework](01_validity_framework.md) | Claim classification methodology (Tier A/B/C) |
| 02 | [Topology Validation](02_topology_validation.md) | V1 + V4 + V5: degree distribution, transit concentration, temporal churn |
| 03 | [Routing Validation](03_routing_validation.md) | V2: AS-path length distribution vs. RIPE RIS |
| 04 | [Tor Mechanics Validation](04_tor_mechanics_validation.md) | V3 + V6 + V7 + V8: guard selection, defense audit, correlation audit, relay theory |
| 05 | [Statistical Robustness](05_statistical_robustness.md) | S1 + S2: multi-seed statistics, client sensitivity (pending S1-S3 data) |
| 06 | [Sensitivity Analysis](06_sensitivity_analysis.md) | S3: guard lifetime sensitivity analysis (pending S1-S3 data) |
| 07 | [Gap Analysis](07_gap_analysis.md) | Identified gaps between simulator and reality |
| 08 | [Threats to Validity](08_threats_to_validity.md) | Internal, external, construct, and statistical threats |
| 09 | [Defensible Claims](09_defensible_claims.md) | Final claim summary with evidence and caveats |

### Korean Versions

| Document | Korean Version |
|----------|---------------|
| 01 Validity Framework | [01_validity_framework.ko.md](01_validity_framework.ko.md) |
| 02 Topology Validation | [02_topology_validation.ko.md](02_topology_validation.ko.md) |
| 03 Routing Validation | [03_routing_validation.ko.md](03_routing_validation.ko.md) |
| 04 Tor Mechanics Validation | [04_tor_mechanics_validation.ko.md](04_tor_mechanics_validation.ko.md) |
| 05 Statistical Robustness | [05_statistical_robustness.ko.md](05_statistical_robustness.ko.md) |
| 06 Sensitivity Analysis | [06_sensitivity_analysis.ko.md](06_sensitivity_analysis.ko.md) |
| 07 Gap Analysis | [07_gap_analysis.ko.md](07_gap_analysis.ko.md) |
| 08 Threats to Validity | [08_threats_to_validity.ko.md](08_threats_to_validity.ko.md) |
| 09 Defensible Claims | [09_defensible_claims.ko.md](09_defensible_claims.ko.md) |

### Data and Plots

- **JSON data**: `data/` directory contains machine-readable validation results
  - `validation_report.json` — combined V1-V8 results
  - `v1_topology.json` through `v8_relay_theory.json` — individual test results
  - `s1_multi_seed_stats.json` — multi-seed correlation variance (partial)
- **Plots**: `plots/` directory contains visualization outputs
  - `v1_degree_distribution.png` — log-log degree distribution
  - `v2_path_length_histogram.png` — AS-path length histogram
  - `v5_temporal_churn.png` — edge churn vs. correlation rate over time
  - `s1_multi_seed_correlation.png` — multi-seed correlation rates with 95% CI

## How to Reproduce

### Prerequisites

- Go 1.21+ (for simulator)
- Python 3.12+ with `uv` package manager (for analysis)
- CAIDA AS-relationship data (already in `tor-anal/data/`)

### Run Simulations

```bash
cd next-simulate

# Build and run 4 scenarios
go run ./cmd/next-simulate -config configs/bgp_attack.yaml
go run ./cmd/next-simulate -config configs/counter_raptor_defense.yaml
go run ./cmd/next-simulate -config configs/astoria_defense.yaml
go run ./cmd/next-simulate -config configs/combined_defense.yaml
```

### Run V1-V8 Validation Suite

```bash
cd tor-anal
uv sync
uv run python -m analysis.validation.run_all
```

Output: `.experiments/validation_report/data/validation_report.json`

### Run RAPTOR Reproduction Analysis

```bash
cd tor-anal
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
  --output-dir .experiments/raptor/results
```
