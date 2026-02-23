# "Users Get Routed" Paper Reproduction Experiment

**Paper**: Johnson et al., "Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries",
ACM CCS 2013.

**Experiment Date**: 2025-02-20 ~ 2025-02-22
**Experiment ID**: `users-get-routed-v1`
**Status**: Complete (2 experiment sets: network adversary + relay adversary)

---

## Overview

This experiment reproduces the core findings of Johnson et al. using our AS-level
Tor simulator. The paper introduced the concept of realistic AS-level adversaries
who can correlate Tor traffic by observing entry and exit segments at the network
layer (BGP routing). It also modeled relay-level adversaries who run malicious
guard and exit relays.

### Experiment Sets

| Set | Description | Scenarios | Paper Reference |
|-----|-------------|-----------|-----------------|
| **A** | Network adversary (AS-level) | 4 defense strategies | Figures 2a, 3 |
| **B** | Relay adversary (malicious relays) | 1 baseline | Figures 2a-c, 3 |

### Defense Strategies (Set A)

| Scenario | Defense | Paper Reference |
|----------|---------|-----------------|
| Vanilla | No defense (baseline) | Original paper model |
| Counter-RAPTOR | Guard weight rebalancing by AS resilience | Sun et al. 2015 |
| Astoria | Entry/exit transit AS overlap avoidance | Nithyanand et al. 2016 |
| Combined | Counter-RAPTOR + Astoria | Novel combination |

## Quick Links

| Document | Description |
|----------|-------------|
| [PROTOCOL.md](PROTOCOL.md) | Exact reproduction protocol (commands, parameters, timing) |
| [RESULTS.md](RESULTS.md) | Detailed numerical results with paper comparison |
| [ENVIRONMENT.md](ENVIRONMENT.md) | Hardware, software, data provenance |
| [configs/](configs/) | All 5 YAML simulation configs (copies) |
| [results/](results/) | JSON reports (network + relay adversary) |
| [plots/](plots/) | 11 publication-quality figures |

## Key Findings Summary

### Set A: Network Adversary

| Scenario | Client Compromise | Stream Compromise | Reduction |
|----------|-------------------|-------------------|-----------|
| Vanilla | 34/50 (68.0%) | 1.93% | baseline |
| Counter-RAPTOR | 34/50 (68.0%) | 1.84% | -4.6% streams |
| Astoria | 9/50 (18.0%) | 0.001% | -73.5% clients |
| Combined | 5/50 (10.0%) | 0.0003% | -85.3% clients |

### Set B: Relay Adversary

| Metric | Value |
|--------|-------|
| Clients compromised | 200/200 (100%) |
| First compromise | Day 57.1 |
| 50% compromised | Day 59.7 |
| 100% compromised | Day 60.0 |
| Guard lifetime correlation | Exact match (30-60 day range) |

## Directory Structure

```
.experiments/users_get_routed/
├── README.md                   # This file
├── PROTOCOL.md                 # Step-by-step reproduction protocol
├── RESULTS.md                  # Detailed numerical results
├── ENVIRONMENT.md              # Hardware, software, data provenance
├── configs/                    # Simulation config copies
│   ├── bgp_attack.yaml           # Set A: Vanilla
│   ├── counter_raptor_defense.yaml  # Set A: Counter-RAPTOR
│   ├── astoria_defense.yaml       # Set A: Astoria
│   ├── combined_defense.yaml      # Set A: Combined
│   └── relay_adversary.yaml       # Set B: Relay adversary
├── results/
│   ├── network_defense_comparison_report.json
│   └── relay_adversary_report.json
└── plots/
    ├── network/                # Set A visualizations
    │   ├── time_to_first_compromise_cdf.png
    │   ├── stream_compromise_over_time.png
    │   ├── correlation_comparison.png
    │   ├── temporal_curves.png
    │   ├── cumulative_compromise.png
    │   ├── attack_impact.png
    │   ├── as_risk_heatmap.png
    │   └── guard_distribution_shift.png
    └── relay_adversary/        # Set B visualizations
        ├── relay_compromise_cdf.png
        ├── stream_compromise_over_time.png
        └── time_to_first_compromise_cdf.png
```

## Citation

```bibtex
@inproceedings{johnson2013users,
  title={Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries},
  author={Johnson, Aaron and Wacek, Chris and Jansen, Rob and
          Sherr, Micah and Syverson, Paul},
  booktitle={ACM Conference on Computer and Communications Security (CCS)},
  pages={337--348},
  year={2013}
}
```
