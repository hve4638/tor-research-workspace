# RAPTOR Paper Reproduction Experiment

**Paper**: Sun et al., "Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries",
USENIX Security Symposium, 2015.

**Experiment Date**: 2025-02-22
**Experiment ID**: `raptor-reproduction-v1`
**Status**: Complete (4/4 sub-experiments)

---

## Overview

This experiment reproduces the four core findings of the RAPTOR paper using our
AS-level Tor simulator (`next-simulate`) and Python analysis pipeline (`tor-anal`).

| ID | Finding | RAPTOR Reference | Reproduced |
|----|---------|-----------------|------------|
| R1 | Asymmetric routing increases traffic correlation | Figure 4 | Qualitative (trend weak) |
| R2 | BGP churn increases correlation over time | Figure 5 | Qualitative |
| R3 | Tier-1 ASes dominate threat rankings | Table 2 | Qualitative |
| R4 | BGP interception attacks spike correlation | Section 5 | Partial (structural limitation) |

## Quick Links

| Document | Description |
|----------|-------------|
| [PROTOCOL.md](PROTOCOL.md) | Exact reproduction protocol (commands, parameters, timing) |
| [RESULTS.md](RESULTS.md) | Detailed numerical results with paper comparison |
| [ENVIRONMENT.md](ENVIRONMENT.md) | Hardware, software, data provenance |
| [configs/](configs/) | All 6 YAML simulation configs (copies) |
| [results/](results/) | JSON report + derived tables |
| [plots/](plots/) | 4 publication-quality figures |

## Key Differences from Original Paper

| Aspect | RAPTOR (2015) | This Reproduction (2025) |
|--------|---------------|--------------------------|
| AS topology | ~48,000 ASes (CAIDA 2013) | 727 ASes (CAIDA 2025, Tor-relevant) |
| Relay count | ~5,000 relays | 727 AS-aggregated nodes |
| BGP routing | Real BGP feeds (RouteViews) | Simulated BFS on AS graph |
| Asymmetric routing | Real traceroute data | Directional BFS (forward != reverse) |
| Simulation period | Historical (2013) | 90-180 days (2025-01 to 2025-07) |
| Client count | Full Tor user base estimation | 200-500 simulated clients |
| Path computation | Real BGP RIB entries | AS-relationship valley-free routing |

These differences mean **absolute correlation rates differ substantially** (ours: 2-3%
vs paper: 12-21%). The experiment validates **relative trends and qualitative patterns**,
not absolute values.

## Directory Structure

```
.experiments/raptor/
├── README.md                  # This file
├── PROTOCOL.md                # Step-by-step reproduction protocol
├── RESULTS.md                 # Detailed numerical results
├── ENVIRONMENT.md             # Hardware, software, data provenance
├── configs/                   # Simulation config copies
│   ├── raptor_baseline_sym.yaml
│   ├── raptor_baseline_asym.yaml
│   ├── raptor_temporal_sym.yaml
│   ├── raptor_temporal_asym.yaml
│   ├── raptor_entity_threat.yaml
│   └── raptor_interception.yaml
├── results/
│   └── raptor_reproduction_report.json
└── plots/
    ├── asymmetric_comparison.png
    ├── temporal_churn_curves.png
    ├── entity_threat_comparison.png
    └── interception_impact.png
```

## Reproduction Command (Single-Line)

After completing all simulations (see PROTOCOL.md):

```bash
cd tor-anal && uv run python -m analysis.run_raptor_analysis \
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

## Citation

```bibtex
@inproceedings{sun2015raptor,
  title={Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries},
  author={Sun, Yixin and Edmundson, Anne and Vanbever, Laurent and Li, Oscar
          and Rexford, Jennifer and Chiang, Mung and Mittal, Prateek},
  booktitle={24th USENIX Security Symposium},
  pages={337--352},
  year={2015}
}
```
