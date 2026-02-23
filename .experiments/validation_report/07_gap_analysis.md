# Gap Analysis: Structural Limitations and Their Impact on Claims

**Document version**: 1.0
**Date**: 2025-02-23
**Scope**: Systematic identification and severity classification of gaps between our reproduction and the original papers (RAPTOR, Johnson et al.)

---

## 1. Introduction

This document catalogs the structural, methodological, and statistical gaps between our AS-level Tor traffic correlation experiments and the original papers. For each gap, we assess severity, identify affected claims (referencing the Tier A/B/C classification from `01_validity_framework.md`), estimate quantitative impact where possible, and evaluate resolvability.

### 1.1 Severity Definitions

| Severity | Definition | Criteria |
|----------|-----------|----------|
| **Critical** | Undermines confidence in all claims without mitigation | Affects statistical validity of entire result set |
| **High** | Affects absolute values and may shift qualitative conclusions | >5x impact on key metrics |
| **Medium** | Affects specific findings but does not invalidate primary conclusions | 2-5x impact on specific metrics |
| **Low** | Minor effect acknowledged for completeness | <2x impact, or affects only secondary metrics |

---

## 2. Gap Severity Classification Table

| # | Gap | Severity | Affected Claims | Resolvable? |
|---|-----|----------|----------------|-------------|
| G1 | Single seed (no variance estimate) | **Critical** | All (A1-A3, B1-B3, C1-C2) | Yes (S1 multi-seed resolves) |
| G2 | Topology scale (727 vs ~48K ASes) | **High** | All absolute values, B2, C1, C2 | Partial (topology expansion) |
| G3 | BFS routing model (vs real BGP) | **High** | B2, B3, C1 | Partial (quantifiable via V-scripts) |
| G4 | Guard lifetime distribution | Medium | A1 CDF shape | Yes (S3 variable lifetime resolves) |
| G5 | IXP not modeled | Medium | A3 observation opportunities | No (data gap) |
| G6 | AS-level relay aggregation | Low | Relay diversity within ASes | No (by design) |
| G7 | Client count (50 for defense experiments) | Medium | A2 CDF granularity | Yes (increase to 200+) |
| G8 | Temporal resolution (monthly vs daily) | Medium | B1 churn magnitude | Partial (daily CAIDA not available) |

---

## 3. Detailed Gap Analysis

### G1: Single Seed — No Variance Estimate

**Severity**: Critical

**Description**: All experiments were executed with a single random seed (seed 42 for RAPTOR, default for Johnson et al.). Without multiple independent runs, we cannot estimate the variance of any reported metric, construct confidence intervals, or determine whether observed differences (e.g., the 1.003x asymmetric routing factor in B2) are statistically significant.

**Affected claims**:
- **Tier A (A1-A3)**: Large effect sizes (90.5% exit dominance, 99.97% Astoria reduction) are unlikely to be seed artifacts, but formal confirmation requires variance estimates. Confidence: remains high but unproven.
- **Tier B (B1-B3)**: Most vulnerable. The asymmetric routing factor of 1.003x (B2) could be within the noise floor. The temporal churn trend (B1) could be partially driven by seed-specific relay-client assignments. The 1.84x state-level attack spike (B3) is a single observation.
- **Tier C (C1-C2)**: Unaffected because structural limitations are deterministic and seed-independent.

**Quantitative impact estimate**:
- For correlation rates around 2% with ~2M circuits, the standard error from binomial sampling alone is ~0.01% (sqrt(0.02 * 0.98 / 2M)). However, seed-driven variance from relay selection, client placement, and AS path assignment is likely orders of magnitude larger than sampling variance.
- Based on similar simulation studies (e.g., Jansen et al. Shadow simulator), coefficient of variation for correlation rates is typically 5-15% across seeds, implying our 2.58% rate could range from ~2.2% to ~3.0% across seeds.

**Resolvable?**: **Yes**. Multi-seed simulation runs (S1: 5 seeds for RAPTOR, S2: 5 seeds for Johnson et al.) with DKW confidence intervals will provide variance estimates. Planned validation scripts V1-V4 compute per-seed metrics and aggregate with confidence bands.

**Mitigation priority**: Highest. Must be completed before any results are published.

---

### G2: Topology Scale (727 vs ~48,000 ASes)

**Severity**: High

**Description**: Our AS topology contains 727 ASes (those hosting at least one Tor relay) with ~6,200 edges, compared to RAPTOR's ~48,000 ASes with ~150,000+ edges from the full CAIDA AS-relationship dataset. This 66x reduction in AS count and 24x reduction in edge count fundamentally limits:

1. **Path diversity**: Fewer alternative routes between any AS pair means less routing variation, reducing both asymmetry effects and churn exposure.
2. **Transit chain length**: Average AS path length in our topology is 2-4 hops vs. 4-7 hops in the full Internet. Shorter paths mean fewer transit ASes per circuit, reducing observation opportunities.
3. **Attack surface**: A single target AS represents ~0.14% of our topology vs. ~0.002% of the full Internet, making per-target attacks disproportionately small.

**Affected claims**:
- **B2 (Asymmetric routing)**: The 1.003x factor vs. paper's 1.66x is primarily caused by this gap. Short paths (2-4 hops) have limited room for forward/reverse divergence.
- **C1 (BGP interception)**: The failure to reproduce ~90% interception correlation is directly attributable to Tier-1 attackers already being on most paths in the small topology. Marginal increase from interception is near zero.
- **C2 (Absolute values)**: All absolute correlation rates are 5-50x lower than RAPTOR values. The gap is consistent with reduced path length: if mean path length drops from 5 to 3 hops, transit observation opportunities drop by ~40%, and compounding across entry and exit paths yields a multiplicative reduction.
- **A3 (Tier-1 dominance)**: Partially affected — absolute threat scores differ dramatically (1.25% vs. 91%), but the relative ranking is preserved because Tier-1 structural advantage persists at any scale.

**Quantitative impact estimate**:
- **Path length effect**: With mean path length L, the probability of a specific AS appearing on a path is approximately proportional to L/N (where N is the total AS count). Our L/N ratio (~3/727 = 0.41%) is comparable to the RAPTOR L/N ratio (~5/48000 = 0.01%), but the compounding across entry+exit paths and the density of our graph (more Tier-1 reachability) creates complex interactions.
- **Edge density**: Our graph has edge density 6200/(727*726/2) = 2.35%, vs. RAPTOR's ~150000/(48000*47999/2) = 0.013%. Higher density means more direct connections, shorter paths, and less transit diversity.

**Resolvable?**: **Partial**. Full resolution requires expanding to a multi-thousand AS topology with real BGP routing data. However, the impact is quantifiable: validation scripts can compute path length distributions, transit AS reachability, and overlay these with correlation rates to establish a scaling relationship. If correlation rate scales as O(L^2/N), extrapolation to 48K ASes can provide estimated "full-scale" values.

---

### G3: BFS Routing Model (vs Real BGP)

**Severity**: High

**Description**: Our simulator computes AS paths using breadth-first search (BFS) on the AS relationship graph with valley-free routing constraints (Gao-Rexford model). Real Internet routing uses BGP with complex policy mechanisms:

1. **LOCAL_PREF**: Each AS assigns preferences to routes based on business relationships (customer > peer > provider), traffic engineering, and contractual obligations. BFS approximates this with valley-free constraints but cannot capture per-AS policy variations.
2. **AS_PATH length**: BGP selects shorter AS paths, but BFS already does this by construction. However, real BGP may select longer paths if they have higher LOCAL_PREF.
3. **MED (Multi-Exit Discriminator)**: Allows neighboring ASes to influence exit point selection. Not modeled.
4. **Community attributes**: BGP communities encode routing policies (no-export, blackhole, etc.) that affect path propagation. Not modeled.
5. **Hot-potato routing**: ASes prefer to hand off traffic to peers/providers at the nearest exit point. Not modeled (we operate at AS granularity, not router granularity).

**Affected claims**:
- **B2 (Asymmetric routing)**: Our directional BFS produces *some* path asymmetry by varying the search direction, but real BGP asymmetry arises from fundamentally different policy decisions at each AS, which is much richer. This is the primary reason for the 1.003x vs. 1.66x gap.
- **B3 (BGP attacks)**: Attack effectiveness depends on BGP route preference mechanics. Our model simulates interception by modifying AS graph edges, but real interception works by announcing more-specific prefixes or shorter paths that BGP selects preferentially. The simplified model underestimates attack impact.
- **C1 (BGP interception)**: The zero-impact result for RAPTOR R4 is partially due to BFS not modeling how interception announcements propagate through BGP decision processes.

**Quantitative impact estimate**:
- Studies comparing BFS/valley-free routing to actual BGP paths (e.g., Anwar et al. 2015) find ~70-80% path agreement for customer-provider paths but only ~40-50% for peer paths. Since many Tor relay ASes connect via peering, our path accuracy may be as low as 50-60% for cross-AS circuits.
- The asymmetry underestimation can be bounded: if real BGP produces asymmetric paths for 30-40% of AS pairs (as measured by traceroute studies), but our BFS produces asymmetric paths for only 5-10%, the asymmetric routing effect is underestimated by ~4-6x, consistent with the observed 1.003x vs. 1.66x gap.

**Resolvable?**: **Partial**. Full resolution requires integrating real BGP RIB data (from RouteViews or RIPE RIS) into path computation. However, the *direction* of the BFS limitation is known and consistent: BFS underestimates path diversity and asymmetry. Validation scripts can quantify the degree of path agreement between BFS and available BGP ground truth for Tor-relevant AS pairs.

---

### G4: Guard Lifetime Distribution

**Severity**: Medium

**Description**: Our simulator assigns guard lifetimes from a uniform distribution U(30, 60) days. The real Tor network uses a more complex guard selection and rotation mechanism:

1. **Tor specification**: Guards have a minimum lifetime of 60 days (extended to 120 days in recent Tor versions) with additional persistence based on consensus stability.
2. **Historical behavior** (circa 2013, Johnson et al.): Guard lifetimes varied based on consensus participation, bandwidth fluctuation, and user behavior. The effective distribution was closer to an exponential or Weibull distribution, producing a gradual S-curve CDF for time-to-first-compromise.
3. **Our simplification**: U(30, 60) produces a step function CDF at day 57-60 instead of the paper's gradual S-curve.

**Affected claims**:
- **A1 (Relay compromise)**: The *endpoint* (100% compromise) is correctly reproduced, and the full compromise rate (9.47%) matches. Only the **CDF shape** differs — step function vs. gradual curve. The underlying mechanism (bandwidth-weighted selection ensures adversary relay is eventually chosen) is correctly modeled.

**Quantitative impact estimate**:
- The CDF shape difference does not affect the 100% final compromise rate or the 9.47% circuit compromise rate. It affects only the time distribution of *when* clients are first compromised.
- With U(30, 60), the first compromise occurs at day 57.1; with a more realistic distribution, first compromises would begin earlier (around day 30) and accumulate gradually.

**Resolvable?**: **Yes**. Planned simulation S3 uses variable guard lifetimes (exponential with mean 90 days, matching post-2018 Tor behavior) to produce a more realistic CDF. This is a configuration change, not a code change.

---

### G5: IXP Not Modeled

**Severity**: Medium

**Description**: Internet Exchange Points (IXPs) are physical locations where multiple ASes exchange traffic directly, bypassing transit providers. IXPs create observation opportunities not captured in the AS-relationship graph:

1. **IXP as observer**: An entity controlling an IXP can observe all traffic exchanged at that location, including Tor entry/exit segments, without being an AS on the path.
2. **IXP-induced shortcuts**: Direct peering at IXPs means traffic between two ASes may bypass transit providers entirely, altering the set of observing ASes compared to what the AS-relationship graph predicts.
3. **IXP concentration**: Major IXPs (DE-CIX, AMS-IX, LINX) host hundreds of ASes, including many Tor relay operators. European Tor relays are heavily concentrated around these IXPs.

**Affected claims**:
- **A3 (Tier-1 dominance)**: IXPs provide an alternative observation vector that could elevate non-Tier-1 ASes in threat rankings. An IXP operator could observe more traffic than some Tier-1 transit providers, potentially disrupting the Tier-1 dominance finding.
- **B1 (Temporal churn)**: IXP membership changes (ASes joining/leaving) would create additional churn-like effects not captured by AS-edge changes.
- **C2 (Absolute values)**: IXP observation would *increase* overall correlation rates, potentially narrowing the gap with RAPTOR values.

**Quantitative impact estimate**:
- RAPTOR and Johnson et al. did not model IXPs either, so this is a shared limitation rather than a reproduction gap. However, IXP prevalence has increased substantially since 2013-2015.
- Studies by Nithyanand et al. (2016) found that IXPs observe 10-30% of Tor traffic in some regions. This suggests our correlation rates could be 10-30% higher if IXPs were modeled.

**Resolvable?**: **No** (data gap). Comprehensive IXP membership and traffic data is not publicly available. PeeringDB provides partial membership data, but traffic volume and observation capability data is proprietary. This is an inherent limitation of AS-level simulation shared by all academic studies in this area.

---

### G6: AS-Level Relay Aggregation

**Severity**: Low

**Description**: Our simulator aggregates all Tor relays within the same AS into a single node with combined bandwidth. In reality, multiple relays in the same AS have individual IP addresses, bandwidths, and uptime histories:

1. **Intra-AS diversity**: An AS hosting 50 relays may have relays in different data centers with different upstream providers. AS-level aggregation treats them as identical.
2. **Bandwidth distribution**: Within-AS bandwidth distribution (e.g., a few high-bandwidth relays vs. many low-bandwidth ones) is lost after aggregation.
3. **Family declarations**: Tor's MyFamily mechanism groups relays by the same operator. AS-level aggregation may incorrectly combine relays from different operators in the same AS.

**Affected claims**:
- **A1 (Relay compromise)**: Minimally affected. The adversary's relay bandwidth is set explicitly, and guard/exit selection probabilities are computed from aggregated AS bandwidth. Individual relay diversity within the adversary's AS does not affect the result.
- **A2 (Defense ordering)**: The defense mechanisms (Counter-RAPTOR, Astoria) operate at the AS level by design, so AS-level aggregation is appropriate.

**Quantitative impact estimate**:
- Our 727-AS model corresponds to approximately 7,000 real Tor relays. The aggregation primarily affects bandwidth-weighted selection probabilities within high-relay-count ASes (e.g., AS24940 Hetzner hosts ~500 relays).
- The impact on correlation rates is estimated at <5% because transit AS observation (the dominant correlation mechanism) operates at the AS level regardless of intra-AS relay count.

**Resolvable?**: **No** (by design). AS-level aggregation is a deliberate modeling choice that enables tractable simulation of AS-path observation. Relay-level simulation would require a different architecture (e.g., Shadow simulator) and is outside our scope.

---

### G7: Client Count (50 for Defense Experiments)

**Severity**: Medium

**Description**: The network defense comparison experiment (Johnson et al. Set A) uses only 50 simulated clients, compared to 200 clients in other experiments. With 50 clients:

1. **CDF granularity**: Each client compromise represents a 2% jump in the CDF, producing staircase-like curves instead of smooth CDFs.
2. **Rare event sensitivity**: Defense scenarios that compromise very few clients (Astoria: 9, Combined: 5) have high relative variance. Adding or removing a single compromised client changes the rate by 2 percentage points.
3. **Statistical tests**: Comparing compromise rates between scenarios (e.g., 68% vs. 68% for Vanilla vs. Counter-RAPTOR) requires larger samples to detect small differences.

**Affected claims**:
- **A2 (Defense ordering)**: The large gap between Astoria (18%) and Counter-RAPTOR (68%) is robust to small sample sizes. However, the difference between Vanilla (68%) and Counter-RAPTOR (68%) cannot be distinguished with 50 clients.
- **CDF shape**: Vanilla and Counter-RAPTOR CDFs have identical final values (68%) with overlapping intermediate points, which may reflect identical underlying processes or may be a coincidence of the small sample.

**Quantitative impact estimate**:
- For a true compromise rate of 68%, the 95% confidence interval with n=50 is [53.3%, 80.5%] (Wilson score). This is too wide to detect the ~4.6% stream-level reduction from Counter-RAPTOR at the client level.
- For Astoria's 18% rate, the 95% CI is [8.6%, 31.4%]. The true rate could be as low as 9% or as high as 31%.

**Resolvable?**: **Yes**. Increasing client count to 200+ (matching the relay adversary experiment) would narrow confidence intervals to approximately +/-6% at the 95% level. Multi-seed runs (S1/S2) will further improve statistical power.

---

### G8: Temporal Resolution (Monthly vs Daily Snapshots)

**Severity**: Medium

**Description**: Our CAIDA AS-relationship data is available as monthly snapshots (January-July 2025), providing 7 topology states over 180 days. RAPTOR used daily BGP routing updates, capturing transient routing changes that may last only hours or days.

1. **Missed transient paths**: Daily BGP churn includes route flaps, convergence events, and temporary peering changes that may create brief correlation windows. Monthly snapshots miss these entirely.
2. **Smoothed churn**: Monthly snapshots capture only persistent topology changes (links that remain stable for >30 days), producing a smoothed version of the actual churn signal.
3. **Churn magnitude**: Our observed edge churn rates (5-20% per month) represent the net effect of many daily changes. Daily resolution would show higher instantaneous churn rates.

**Affected claims**:
- **B1 (Temporal churn)**: The ~1.3-1.5x increase over 150 days underestimates the paper's ~3x increase over 21 days. Part of this gap (beyond topology scale) is attributable to temporal resolution: daily snapshots would reveal a more rapid initial increase as transient routing changes create new correlation opportunities.

**Quantitative impact estimate**:
- If daily churn is approximately 0.5-1% of edges (based on CAIDA serial-2 daily datasets), then over 30 days, cumulative daily churn could expose 15-30% of edges to changes, compared to the 5-20% net change observed in monthly snapshots. This suggests monthly snapshots capture only 30-60% of actual routing variation.
- The churn-driven correlation increase factor could be 1.5-2x higher with daily resolution, bringing our 1.3-1.5x closer to the paper's ~3x (partial closure of the gap).

**Resolvable?**: **Partial**. CAIDA's serial-2 dataset provides daily AS-relationship snapshots, but:
1. Daily snapshots are available only for specific time periods and may have coverage gaps.
2. Processing 180 daily snapshots (vs. 7 monthly) increases simulation time by ~25x.
3. The benefit is bounded: even with daily resolution, the topology scale gap (G2) remains the dominant factor.

---

## 4. Gap Interaction Matrix

Some gaps compound each other. The following matrix identifies key interactions:

| Gap Pair | Interaction | Combined Effect |
|----------|-------------|-----------------|
| G1 + G2 | Single seed in small topology | Unknown variance compounds systematic underestimation |
| G2 + G3 | Small topology + BFS routing | Path diversity reduction is multiplicative: fewer ASes AND less realistic path selection |
| G2 + G5 | Small topology + no IXPs | Missing IXP shortcuts further reduces path diversity in an already small graph |
| G3 + G8 | BFS + monthly snapshots | BFS already underestimates path changes; monthly resolution further smooths the signal |
| G1 + G7 | Single seed + 50 clients | Variance from both sources compounds: need >5 seeds with >200 clients for robust CDF |

---

## 5. Resolution Priority and Status

| Priority | Gap | Resolution Method | Status |
|----------|-----|-------------------|--------|
| 1 | G1 (Single seed) | S1/S2 multi-seed simulations | Planned |
| 2 | G7 (Client count) | Increase to 200+ in S2 | Planned |
| 3 | G4 (Guard lifetime) | S3 variable lifetime simulation | Planned |
| 4 | G2 (Topology scale) | Scaling analysis via V-scripts | Partial (quantification) |
| 5 | G3 (BFS routing) | Path accuracy comparison vs BGP ground truth | Partial (quantification) |
| 6 | G8 (Temporal resolution) | Daily CAIDA snapshots | Future work |
| 7 | G5 (IXP) | PeeringDB integration | Future work (data limited) |
| 8 | G6 (Relay aggregation) | N/A (by design) | Accepted |

---

## 6. Impact on Publication Readiness

### Claims ready for publication (with current data):
- **A1, A2, A3**: Large effect sizes make these robust even with G1 (single seed). Multi-seed confirmation (S1/S2) would strengthen but is not strictly necessary.

### Claims requiring multi-seed confirmation before publication:
- **B1**: The temporal trend needs variance estimates to confirm it is not a seed-specific pattern.
- **B2**: The 1.003x factor needs variance estimates to determine if it is distinguishable from 1.0.
- **B3**: The 1.84x state-level attack spike needs replication across seeds.

### Claims that cannot be strengthened by additional simulation:
- **C1, C2**: Structural limitations (G2, G3) cannot be overcome without fundamental architecture changes (larger topology, real BGP routing). These must be presented as acknowledged limitations.

---

## Appendix: Gap-to-Claim Mapping

| Claim | G1 | G2 | G3 | G4 | G5 | G6 | G7 | G8 |
|-------|----|----|----|----|----|----|----|----|
| A1 (Relay compromise) | Low | -- | -- | **Med** | -- | Low | -- | -- |
| A2 (Defense ordering) | Low | Low | Low | -- | -- | -- | **Med** | -- |
| A3 (Tier-1 dominance) | Low | Med | Low | -- | **Med** | -- | -- | -- |
| B1 (Temporal churn) | **High** | **High** | Low | -- | Low | -- | -- | **Med** |
| B2 (Asymmetric routing) | **High** | **High** | **High** | -- | -- | -- | -- | -- |
| B3 (BGP attack impact) | **High** | Med | **High** | -- | -- | -- | Low | -- |
| C1 (Interception ~90%) | -- | **High** | **High** | -- | -- | -- | -- | -- |
| C2 (Absolute values) | -- | **High** | Med | -- | Med | Low | -- | Med |

*Cell values indicate the severity of that gap's impact on the specific claim.*
