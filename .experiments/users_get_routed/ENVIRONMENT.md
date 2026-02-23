# Experiment Environment

## Hardware

| Component | Specification |
|-----------|--------------|
| Platform | Linux 5.15.0-164-generic (x86_64) |
| Available disk | ~400 GB (used ~12 GB for outputs) |
| RAM usage peak | ~2 GB (streaming analysis), ~4 GB (Go simulation) |

## Software Versions

| Tool | Version | Purpose |
|------|---------|---------|
| Go | 1.23+ | Simulation engine (`next-simulate`) |
| Python | 3.12+ (via `uv`) | Analysis pipeline (`tor-anal`) |
| uv | latest | Python package management |
| matplotlib | 3.x | Visualization (Agg backend) |
| pandas | 2.x | DataFrame operations |

## Data Provenance

### AS Topology

| Source | Details |
|--------|---------|
| Provider | CAIDA AS-Relationships |
| Format | `.as-rel2.txt` (peer/provider-customer) |
| Snapshots used | 2025-01-01, 2025-02-01, 2025-03-01 |
| Initial graph | 727 nodes, 6,191 edges |
| Node scope | Tor-relevant ASes only |

### Tor Relay Data

| Source | Details |
|--------|---------|
| Provider | Tor Project Onionoo API |
| Collection date | 2025-01 (pipeline Step 01) |
| Relay count | Aggregated to 727 unique ASes |
| Guard ASes | 704 |
| Exit ASes | 220 |

### Bandwidth Weights (Tor Directory Consensus)

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

### Common Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| `seed` | 42 | Deterministic PRNG |
| `tick_interval_ms` | 60,000 | 1-minute ticks |
| `time_scale` | 0 | Fast-forward (no real-time pacing) |
| `mode` | "longitudinal" | Full temporal simulation |
| `observer.mode` | "passive" | No active probing |
| `observer.scope` | "global" | AS-level global adversary |

### Client Configuration

| Parameter | Set A (Network) | Set B (Relay) |
|-----------|-----------------|---------------|
| `count` | 50 | 200 |
| `distribution` | "uniform" | "uniform" |
| `guard.init_mode` | "fresh_start" | "fresh_start" |
| `guard.max_sample_size` | 60 | 60 |
| `guard.lifetime_days_min` | 30 | 30 |
| `guard.lifetime_days_max` | 60 | 60 |
| `guard.n_primary_guards` | 3 | 3 |
| `circuit.max_dirtiness_sec` | 600 | 600 |
| `circuit.circuits_per_client` | 3 | 3 |

### Set A: BGP Attack Schedule

All 4 network defense scenarios share the same attack schedule:

| Attack | Type | Attacker | Target | Start Day | Duration | Adversary |
|--------|------|----------|--------|-----------|----------|-----------|
| 0 | hijack | AS174 (Cogent) | AS24940 (Hetzner) | 15 | 6h | single |
| 1 | interception | AS3356 (Level3) | AS60729 | 45 | 12h | tier1 |
| 2 | hijack | AS3320 (DTAG) | AS6939 (HE) | 60 | 24h | state (DE) |

### Set A: Defense Configuration

| Scenario | Counter-RAPTOR | Astoria |
|----------|---------------|---------|
| Vanilla | disabled | disabled |
| Counter-RAPTOR | enabled (weight_factor=1.0, max_cap=100.0) | disabled |
| Astoria | disabled | enabled (max_retries=5) |
| Combined | enabled | enabled |

Counter-RAPTOR uses AS path probability data from `tor-anal/output/as_path_probabilities.json`.

### Set B: Relay Adversary Configuration

| Parameter | Value | Notes |
|-----------|-------|-------|
| `bandwidth_kb` | 102,400 | 100 MiB/s total |
| `guard_exit_ratio` | 5.0 | Guard 83.3%, Exit 16.7% |
| `asymmetric_routing` | true | Directional BFS |
| `duration` | 180 days | 6 months |
| `temporal` | disabled | Single snapshot |
| `bgp` | disabled | No BGP attacks |

## Random Seed Reproducibility

All experiments use `seed: 42`. The Go PRNG ensures identical results across runs
with the same config. To verify: re-run and compare `wc -l` on output files.

## Simulation Output Sizes

### Set A: Network Adversary

| File | Size |
|------|------|
| `observations_bgp.ndjson` | 586 MB |
| `ground_truth_bgp.ndjson` | 432 MB |
| `observations_cr.ndjson` | 586 MB |
| `ground_truth_cr.ndjson` | 432 MB |
| `observations_astoria.ndjson` | 574 MB |
| `ground_truth_astoria.ndjson` | 432 MB |
| `observations_combined.ndjson` | 566 MB |
| `ground_truth_combined.ndjson` | 432 MB |
| **Subtotal** | **~4.0 GB** |

### Set B: Relay Adversary

| File | Size |
|------|------|
| `observations_relay_adv.ndjson` | 6.2 GB |
| `ground_truth_relay_adv.ndjson` | 3.5 GB |
| **Subtotal** | **~9.7 GB** |
