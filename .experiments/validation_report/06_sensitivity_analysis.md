# Sensitivity Analysis: Guard Lifetime Parameter Sweep

**Validation tests**: S3 (Guard Lifetime Sensitivity)
**Data sources**: `data/s3_guard_lifetime.json` (pending S1-S3 simulation completion)

---

## 1. S3: Guard Lifetime Sensitivity

### 1.1 Methodology

The guard lifetime parameter (uniform distribution bounds) directly affects how frequently clients rotate their guard relay. Shorter lifetimes mean more frequent rotation, which increases the probability of selecting a compromised guard over time. This sensitivity analysis varies the guard lifetime bounds to quantify the impact on:

- Client compromise rate (relay adversary scenario)
- Time to first compromise
- Cumulative correlation rate (AS-level observer)

### 1.2 Parameter Space

The Tor specification uses a guard lifetime drawn from uniform[30, 60] days. Our sensitivity sweep tests:

- Shorter lifetimes: uniform[15, 30] days (faster rotation)
- Default: uniform[30, 60] days (baseline)
- Longer lifetimes: uniform[60, 120] days (slower rotation)

### 1.3 Results

*Pending completion of multi-seed simulations (Task #3). Results will be populated from `data/s3_guard_lifetime.json` when available.*

Expected findings:
- Shorter guard lifetimes should increase compromise probability (more rotation = more chances to select adversary guard)
- The relationship should be approximately linear for small adversary bandwidth shares
- Defense mechanisms should show differential sensitivity (Counter-RAPTOR more affected than Astoria)

---

## 2. Summary

| Test | Status | Key Finding |
|------|--------|-------------|
| S3 Guard Lifetime | PENDING | Awaiting simulation completion |

**Note**: This section will be updated when Task #3 (multi-seed simulations) completes and analysis data is available.
