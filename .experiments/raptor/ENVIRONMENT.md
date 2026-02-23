# Experiment Environment

## Hardware

| Component | Specification |
|-----------|--------------|
| Platform | Linux 5.15.0-164-generic (x86_64) |
| Available disk | ~400 GB (used ~42 GB for outputs) |
| RAM usage peak | ~2 GB (streaming analysis), ~4 GB (Go simulation) |

## Software Versions

| Tool | Version | Purpose |
|------|---------|---------|
| Go | 1.23+ | Simulation engine (`next-simulate`) |
| Python | 3.12+ (via `uv`) | Analysis pipeline (`tor-anal`) |
| uv | latest | Python package management |
| matplotlib | 3.x | Visualization (Agg backend) |
| pandas | 2.x | DataFrame operations (entity threat only) |

## Data Provenance

### AS Topology

| Source | Details |
|--------|---------|
| Provider | CAIDA AS-Relationships |
| Format | `.as-rel2.txt` (peer/provider-customer) |
| Snapshots used | 2025-01 through 2025-07 (7 monthly) |
| Initial graph | 727 nodes, 6,191 edges (2025-01-01) |
| Node scope | Tor-relevant ASes only (hosting guard/middle/exit relays) |

### Tor Relay Data

| Source | Details |
|--------|---------|
| Provider | Tor Project Onionoo API |
| Collection date | 2025-01 (pipeline Step 01) |
| Relay count | Aggregated to 727 unique ASes |
| Guard ASes | 704 |
| Exit ASes | 220 |

### Snapshot Evolution

| Date | Nodes | Edges | Churn from Previous |
|------|-------|-------|---------------------|
| 2025-01-01 | 727 | 6,191 | - (baseline) |
| 2025-02-01 | 727 | 6,287 | +205/-109 (5.0%) |
| 2025-03-01 | 727 | 6,212 | +265/-340 (9.6%) |
| 2025-04-01 | 727 | varies | ~20.4% |
| 2025-05-01 | 727 | varies | ~5.9% |
| 2025-06-01 | 727 | varies | ~8.5% |
| 2025-07-01 | 727 | varies | ~10.2% |

### Bandwidth Weights (Tor Directory Consensus)

All simulations use identical weights derived from Tor consensus:

```yaml
weights:
  wgg: 0.5869    # Guard in Guard position
  wgm: 1.0       # Guard in Middle position
  wgd: 0.5869    # Guard in Guard+Exit position
  wee: 0.5869    # Exit in Exit position
  wem: 0.0       # Exit in Middle position
  weg: 0.4131    # Exit in Guard position
  wed: 0.5869    # Exit in Guard+Exit position
  wmg: 0.4131    # Middle in Guard position
  wme: 0.4131    # Middle in Exit position
  wmm: 1.0       # Middle in Middle position
  wmd: 0.4131    # Middle in Guard+Exit position
```

## Simulation Engine Configuration

### Common Parameters (All Experiments)

| Parameter | Value | Notes |
|-----------|-------|-------|
| `seed` | 42 | Deterministic PRNG for reproducibility |
| `tick_interval_ms` | 60,000 | 1-minute simulation ticks |
| `time_scale` | 0 | No real-time pacing (fast-forward) |
| `mode` | "longitudinal" | Full temporal simulation |
| `observer.mode` | "passive" | No active probing |
| `observer.scope` | "global" | AS-level global adversary |

### Client Configuration (All Experiments)

| Parameter | Value | Notes |
|-----------|-------|-------|
| `distribution` | "uniform" | Clients uniformly distributed |
| `guard.init_mode` | "fresh_start" | New guard selection at t=0 |
| `guard.max_sample_size` | 60 | Guard candidate pool size |
| `guard.lifetime_days_min` | 30 | Minimum guard tenure |
| `guard.lifetime_days_max` | 60 | Maximum guard tenure |
| `guard.n_primary_guards` | 3 | Primary guards per client |
| `circuit.max_dirtiness_sec` | 600 | Circuit rotation interval (10 min) |
| `circuit.circuits_per_client` | 3 | Concurrent circuits per client |

## Random Seed Reproducibility

All experiments use `seed: 42`. The Go PRNG (deterministic) ensures:
- Identical guard selection across runs with same config
- Identical circuit path selection
- Identical client distribution

To verify reproducibility, re-run any config and compare `wc -l` on output files.
Line counts should match exactly.

## File Integrity

Simulation outputs are not committed to git (too large). To verify data integrity
after reproduction, compare these line counts:

| File | Expected Lines |
|------|----------------|
| `obs_sym.ndjson` | ~17.6M |
| `gt_sym.ndjson` | ~7.8M |
| `obs_asym.ndjson` | ~17.9M |
| `gt_asym.ndjson` | ~7.8M |
| `obs_entity.ndjson` | ~43.5M |
| `gt_entity.ndjson` | ~19.4M |
| `obs_temporal_sym.ndjson` | ~36.3M |
| `gt_temporal_sym.ndjson` | ~15.6M |
| `obs_temporal_asym.ndjson` | ~37.0M |
| `gt_temporal_asym.ndjson` | ~15.6M |
| `obs_intercept.ndjson` | ~17.9M |
| `gt_intercept.ndjson` | ~7.8M |
