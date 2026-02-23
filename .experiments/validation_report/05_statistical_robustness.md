# Statistical Robustness: Multi-Seed Variance Analysis

**Validation tests**: S1 (Multi-Seed Correlation Variance), S2 (Client Sensitivity)
**Data sources**: `data/s1_multi_seed_stats.json`, `data/s2_client_sensitivity.json`

---

## 1. S1: Multi-Seed Correlation Variance

### 1.1 Methodology

Multiple simulation runs with different random seeds were executed using identical configurations to quantify the variance in correlation rate estimates. This addresses the question: how stable are our correlation measurements across independent random trials?

Each seed produces a different sequence of:
- Client AS assignments
- Guard sample selections
- Circuit construction (middle/exit relay choices)
- BGP attack timing (within configured windows)

### 1.2 Results

#### Raptor Asymmetric Baseline (3 seeds, 200 clients, 90 days)

| Seed | Correlation Rate | Correlated Circuits | Total Circuits |
|------|-----------------|--------------------:|---------------:|
| 1 | 0.02796 | 217,467 | 7,776,600 |
| 2 | 0.02834 | 220,391 | 7,776,600 |
| 3 | 0.02675 | 208,030 | 7,776,600 |

| Statistic | Value |
|-----------|-------|
| Mean | 0.02769 |
| Std Dev | 0.00083 |
| CV | 3.0% |
| 95% CI | [0.02562, 0.02975] |
| Min | 0.02675 |
| Max | 0.02834 |

#### BGP Attack Vanilla (3 seeds, 50 clients, 90 days)

| Seed | Correlation Rate | Correlated Circuits | Total Circuits |
|------|-----------------|--------------------:|---------------:|
| 1 | 0.02176 | 42,295 | 1,944,150 |
| 2 | 0.02572 | 49,995 | 1,944,150 |
| 3 | 0.02139 | 41,576 | 1,944,150 |

| Statistic | Value |
|-----------|-------|
| Mean | 0.02295 |
| Std Dev | 0.00240 |
| CV | 10.5% |
| 95% CI | [0.01699, 0.02892] |
| Min | 0.02139 |
| Max | 0.02572 |

#### Astoria Defense (1 seed available, 50 clients, 90 days)

| Seed | Correlation Rate | Correlated Circuits | Total Circuits |
|------|-----------------|--------------------:|---------------:|
| 1 | 0.0000067 | 13 | 1,944,150 |

Astoria reduces the correlation rate from ~2.30% (vanilla) to 0.00067%, a reduction factor of ~3,400x. Only 13 out of 1,944,150 circuits were correlated, demonstrating Astoria's near-complete elimination of AS-level traffic correlation opportunities.

*Additional seeds pending (simulations in progress).*

### 1.3 Interpretation

The raptor_asym scenario with 3 seeds shows a **CV of 3.0%**, well below the 10% threshold, indicating that correlation rate estimates are highly stable across random seeds. The narrow 95% confidence interval [2.56%, 2.97%] further supports the reliability of single-run experiments for this metric.

Key observations:
- The spread between min (2.68%) and max (2.83%) is only 0.16 percentage points
- All three seeds produce rates within a tight band around 2.77%
- This stability is expected because the correlation rate aggregates over millions of circuits, smoothing per-circuit randomness

The bgp_attack scenario with 3 seeds shows a CV of 10.5%, higher than raptor_asym's 3.0%. This is expected given the smaller client count (50 vs 200) that produces fewer circuits per tick and thus more sampling variance. The mean correlation rate (2.30%) is lower than raptor_asym (2.77%), likely due to different scenario configurations (client count and adversary model). The 95% CI [1.70%, 2.89%] is wider but still informative, and additional seeds would narrow it further.

---

## 2. S2: Client Sensitivity Analysis

### 2.1 Methodology

Varying the number of simulated clients (and thus the number of circuits per tick) tests whether our correlation metrics are sensitive to simulation scale.

### 2.2 Results

*Pending completion of multi-seed simulations (Task #3). Results will be populated from `data/s2_client_sensitivity.json` when available.*

Expected metrics:
- Correlation rate as a function of client count
- Convergence behavior (do rates stabilize above a threshold?)
- Per-client compromise probability distribution

---

## 3. Summary

| Test | Status | Key Finding |
|------|--------|-------------|
| S1 Multi-Seed | PARTIAL (3 scenarios, 7 seeds total) | raptor_asym CV=3.0% (stable), bgp_attack CV=10.5%, Astoria ~0% correlation |
| S2 Client Sensitivity | PENDING | Awaiting simulation completion |

**Note**: S1 results cover 3 scenarios — raptor_asym (3 seeds), bgp_attack (3 seeds), astoria (1 seed). Relay_adversary scenario and additional astoria seeds are pending Task #3 completion. S2 client sensitivity analysis awaits dedicated simulation runs.
