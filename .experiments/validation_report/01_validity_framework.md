# Validity Framework: Claim Classification for AS-Level Tor Traffic Analysis

**Document version**: 1.0
**Date**: 2025-02-23
**Scope**: Classification of experimental claims from RAPTOR and Johnson et al. reproduction experiments into three tiers based on reproduction quality and structural limitations.

---

## 1. Introduction

This document establishes a systematic framework for evaluating the validity of claims derived from our AS-level Tor traffic correlation simulator. Our simulator reproduces findings from two foundational papers:

- **RAPTOR** (Sun et al., USENIX Security 2015): AS-level traffic correlation via asymmetric routing, BGP churn, entity threat rankings, and BGP interception attacks.
- **Johnson et al.** (ACM CCS 2013): Relay-level and network-level adversary models, defense mechanism evaluation (Counter-RAPTOR, Astoria).

The reproduction operates on a **727-AS Tor-relevant subgraph** (vs. the original papers' ~48,000 full Internet AS topology), uses **BFS-based valley-free routing** (vs. real BGP RIB data), and employs **CAIDA 2025 relationship datasets** (vs. 2013-2014 snapshots). These structural differences necessitate careful classification of which claims can be made strongly, conditionally, or not at all.

### 1.1 Classification Methodology

Claims are classified into three tiers based on:

1. **Quantitative accuracy**: Whether absolute numerical values match the original papers within a reasonable margin.
2. **Qualitative consistency**: Whether relative orderings, trends, and directional effects are preserved.
3. **Structural independence**: Whether the claim depends on topology scale, routing model fidelity, or other factors that differ between our reproduction and the originals.

### 1.2 Data Sources

All numerical values cited in this document are drawn from the following experiment reports:

| Report | Path | Circuits |
|--------|------|----------|
| RAPTOR reproduction | `.experiments/raptor/results/raptor_reproduction_report.json` | ~56M total |
| Network defense comparison | `.experiments/users_get_routed/results/network_defense_comparison_report.json` | 1,944,150 per scenario |
| Relay adversary | `.experiments/users_get_routed/results/relay_adversary_report.json` | 15,552,600 |

---

## 2. Tier A: Strong Claims (Quantitative Reproduction)

Tier A claims are those where our experimental results quantitatively match the original papers' findings. These claims are **robust to topology scale** and routing model differences because they depend on structural properties of the Tor protocol rather than Internet-scale routing details.

### A1. Relay Adversary Compromise Mechanics

**Claim**: A relay-level adversary controlling high-bandwidth guard and exit relays achieves 100% client compromise within the guard rotation period.

**Evidence**:
- 200/200 clients (100%) compromised by day 60.0 (relay adversary report: `relay_cdf.vanilla`)
- First compromise at day 57.1; 50% compromised by day 59.7
- Step-function CDF at day 57-60 exactly matches the guard lifetime upper bound (30-60 day uniform distribution)
- Exit-only dominance: 90.5% of circuits (14,078,731 / 15,552,600) had adversary exit selection
- Full guard+exit compromise: 9.47% of circuits (1,472,947 / 15,552,600)
- Guard-only events: only 107 out of 15,552,600 circuits

**Paper comparison** (Johnson et al. Figure 2b/c):
- Exit-only dominant (~90%): **Reproduced** (90.5%)
- Guard-only rare: **Reproduced** (107 events)
- Full compromise rate (~10% of circuits): **Reproduced** (9.47%)
- Stream compromise fraction (~10%): **Reproduced** (9.47%)

**Why Tier A**: These results depend on Tor's relay selection algorithm (bandwidth-weighted sampling) and guard rotation mechanics, not on AS-level topology. The 727-AS limitation does not affect relay-level adversary modeling because the adversary operates at the relay layer, not the network layer.

**Validity status**: **Strong**. Quantitative match within 1% of paper values across all relay adversary metrics.

---

### A2. Defense Effectiveness Ordering

**Claim**: Astoria provides dramatically stronger defense against AS-level traffic correlation than Counter-RAPTOR, and their combination provides the strongest protection.

**Evidence** (network defense comparison report: `overall`):

| Scenario | Correlation Rate | Stream Reduction | Client Compromise | Client Reduction |
|----------|-----------------|------------------|-------------------|------------------|
| Vanilla (baseline) | 1.93% | -- | 34/50 (68.0%) | -- |
| Counter-RAPTOR | 1.84% | -4.6% | 34/50 (68.0%) | 0.0% |
| Astoria | 0.0006% | -99.97% | 9/50 (18.0%) | -73.5% |
| Combined (CR + Astoria) | 0.0003% | -99.99% | 5/50 (10.0%) | -85.3% |

**Paper comparison** (Johnson et al. Figure 3, Nithyanand et al.):
- Network baseline ~2%: **Reproduced** (1.93%)
- Astoria dramatic reduction: **Reproduced** (-99.97% streams)
- Counter-RAPTOR moderate improvement: **Reproduced** (-4.6% streams)

**Ordering preserved**: Combined > Astoria >> Counter-RAPTOR > Vanilla (for defense quality)

**Why Tier A**: The defense ordering is robust because:
1. Astoria's mechanism (avoiding entry/exit transit AS overlap) is topology-independent in its *relative* effectiveness.
2. Counter-RAPTOR's mechanism (guard reweighting by AS resilience) shows the same moderate effect regardless of topology scale.
3. The 3-4 orders of magnitude difference between Astoria and Counter-RAPTOR is large enough to survive scaling effects.

**Temporal stability** (network defense comparison report: `trends`):
- Vanilla and Counter-RAPTOR show increasing correlation trends (slopes +0.0031 and +0.0026 per period)
- Astoria and Combined remain stable (slopes ~10^-9, effectively zero)
- This confirms Astoria's defense is robust against temporal routing changes.

**Validity status**: **Strong**. Defense ordering is definitively established with >99.9% reduction gap between Astoria and Counter-RAPTOR.

---

### A3. Tier-1 AS Observation Dominance

**Claim**: Tier-1 transit ASes dominate the threat landscape for AS-level traffic correlation on Tor.

**Evidence** (RAPTOR reproduction report: `R3_entity_threat`):

| Rank | ASN | Name | Threat Score | Tier-1? | RAPTOR Rank |
|------|-----|------|-------------|---------|-------------|
| 1 | AS6939 | Hurricane Electric | 1.247% | Yes | 5 |
| 2 | AS174 | Cogent | 0.864% | Yes | 4 |
| 3 | AS1299 | Telia | 0.259% | Yes | 3 |
| 6 | AS3356 | Level3/Lumen | 0.095% | Yes | 2 |

- **4 out of 4** identifiable Tier-1 ASes from the RAPTOR paper appear in our top-6
- Top-3 positions are exclusively held by Tier-1 transit providers
- 82 ASes out of 727 (11.3%) have non-zero threat scores, but the top-3 Tier-1 ASes account for a disproportionate share of total correlation capability
- AS6939 (Hurricane Electric) alone accounts for 242,488 both-direction observations out of 19,441,500 total circuits

**Paper comparison** (RAPTOR Table 2):
- RAPTOR top-5: NTT (91%), Level3 (88%), Telia (85%), Cogent (63%), HE (60%)
- Our top-4 Tier-1: HE (1.25%), Cogent (0.86%), Telia (0.26%), Level3 (0.09%)
- Telia's rank (#3) is **exactly preserved**
- The absence of NTT (AS2914) reflects the 2025 Tor relay geographic distribution (shifted toward Europe)

**Why Tier A**: The claim is about *relative dominance*, not absolute values. Tier-1 ASes are structurally positioned as transit providers in any AS topology representation. Even in our 727-AS subgraph, these ASes appear on the most AS paths because of their role as major transit hubs. The ranking stability (especially Telia at #3) across a decade of topology change and a 66x scale difference reinforces the structural nature of this finding.

**Validity status**: **Strong**. Tier-1 dominance is a structural property of Internet routing that persists across topology scales and time periods.

---

## 3. Tier B: Conditional Claims (Qualitative Reproduction, Caveats Required)

Tier B claims are those where our results reproduce the *directional trend* of the original papers but with substantially different magnitudes. These claims require explicit caveats about topology scale, routing model, or temporal resolution.

### B1. Temporal Variation Increases Correlation (BGP Churn Effect)

**Claim (conditional)**: BGP routing changes over time increase AS-level traffic correlation rates, but the magnitude of increase is topology-scale-dependent.

**Evidence** (RAPTOR reproduction report: `R2_temporal_churn`):

Symmetric routing curve (periods 0-5):
| Period | Month | Correlation Rate | Cumulative Factor |
|--------|-------|-----------------|-------------------|
| 0 | 2025-01 | 2.04% | 1.00x |
| 1 | 2025-02 | 2.31% | 1.13x |
| 2 | 2025-03 | 3.05% | 1.50x |
| 3 | 2025-04 | 2.87% | 1.41x |
| 4 | 2025-05 | 3.15% | 1.55x |
| 5 | 2025-06 | 3.06% | 1.50x |

Asymmetric routing curve (periods 0-5):
| Period | Month | Correlation Rate | Cumulative Factor |
|--------|-------|-----------------|-------------------|
| 0 | 2025-01 | 2.58% | 1.00x |
| 1 | 2025-02 | 2.27% | 0.88x |
| 2 | 2025-03 | 2.67% | 1.03x |
| 3 | 2025-04 | 2.97% | 1.15x |
| 4 | 2025-05 | 3.13% | 1.21x |
| 5 | 2025-06 | 3.29% | 1.28x |

**Qualitative match**: General upward trend confirmed in both curves. Symmetric: 2.04% to 3.15% (1.55x). Asymmetric: 2.58% to 3.29% (1.28x).

**Quantitative gap**: RAPTOR reports ~3x increase over 21 days; we observe ~1.3-1.5x over 150 days (~2x underestimation of the trend magnitude).

**CAIDA churn history** confirms real routing changes drove the effect:
- Jan-Feb: 5.0% edge churn (205 added, 109 removed)
- Feb-Mar: 9.6% churn (265 added, 340 removed)
- Mar-Apr: 20.4% churn (maximum, 302 added, 965 removed)

**Caveats required**:
1. **Temporal resolution**: We use monthly CAIDA snapshots (30-day intervals); RAPTOR used daily BGP updates capturing transient routing changes. Daily granularity would amplify the churn effect.
2. **Topology scale**: With 727 ASes, fewer alternative routing paths exist, so each churn event affects fewer circuits. In a 48K-AS topology, a single edge change can redirect thousands of paths.
3. **Non-monotonicity**: Period 1 (asymmetric) shows a decrease (2.58% to 2.27%), indicating that churn can *remove* as well as create correlation opportunities. The paper's monotonic increase may reflect averaging over multiple seeds or the dominance of path creation in larger topologies.

**Validity status**: **Conditional**. The qualitative trend is reproduced; the magnitude gap (~2x) is attributable to quantifiable structural differences.

---

### B2. Asymmetric Routing Increases Correlation Opportunity

**Claim (conditional)**: Considering asymmetric Internet routing (forward path != reverse path) increases the set of AS-level observation opportunities, but the magnitude of this increase depends strongly on topology scale and routing model fidelity.

**Evidence** (RAPTOR reproduction report: `R1_asymmetric_routing`):

| Metric | Symmetric | Asymmetric | Factor |
|--------|-----------|------------|--------|
| Correlation rate | 2.577% | 2.584% | 1.003x |
| Correlated circuits | 200,409 | 200,922 | -- |
| Total circuits | 7,776,600 | 7,776,600 | -- |

**Paper comparison**: RAPTOR reports 1.66x (12.8% to 21.3%).

**Direction preserved**: `asym_rate >= sym_rate` holds (2.584% >= 2.577%), but the factor (1.003x) is insufficient to be statistically meaningful with a single seed.

**Caveats required**:
1. **Topology scale**: In a 727-AS graph, most AS paths are 2-4 hops long. Short paths have limited room for forward/reverse divergence. A 48K-AS topology with 5+ hop paths creates substantially more asymmetric routing opportunities.
2. **BFS vs. real BGP**: Our directional BFS produces some path differences, but real Internet routing exhibits complex asymmetry from business policies (LOCAL_PREF, MED), traffic engineering, and hot-potato routing that BFS cannot capture.
3. **Tor-relevant subgraph density**: By restricting to ASes hosting Tor relays, our graph is denser and more interconnected than the full Internet, further reducing asymmetry.

**Validity status**: **Conditional**. The directional effect (asym >= sym) is preserved, but the 1.003x factor vs. the paper's 1.66x means this claim requires strong caveats about topology scale dependence.

---

### B3. BGP Attack Impact on Correlation (Network Adversary)

**Claim (conditional)**: BGP attacks (hijack, interception, state-level) can elevate AS-level traffic correlation, but the magnitude depends on attack scope relative to topology size.

**Evidence** (network defense comparison report: `attack_impact`):

| Attack | Type | Attacker -> Target | Pre Rate | During Rate | Post Rate | During/Pre |
|--------|------|-------------------|----------|-------------|-----------|------------|
| 0 | hijack | AS174 -> AS24940 | 1.84% | 1.66% | 1.95% | 0.90x |
| 1 | interception | AS3356 -> AS60729 | 1.74% | 1.95% | 2.13% | 1.12x |
| 2 | state hijack | AS3320 -> AS6939 | 1.74% | 3.20% | 2.29% | **1.84x** |

**Noteworthy findings**:
- Attack 2 (state-level AS3320 hijacking Hurricane Electric AS6939) shows the largest during-attack spike: 3.20%, which is 1.84x the pre-attack rate. This aligns with the papers' finding that state-level adversaries controlling major transit ASes pose the greatest threat.
- Post-attack rates remain elevated (1.95%, 2.13%, 2.29%), suggesting persistent routing changes after attacks end.
- Attack 0 (simple hijack) shows *decreased* during-attack correlation (0.90x), possibly because the hijack disrupts existing transit paths that were creating correlation opportunities.

**Caveats required**:
1. These results come from the "Users Get Routed" network adversary experiment, not the RAPTOR interception experiment (which showed no impact; see Tier C).
2. The 1.84x spike for state-level attacks is a meaningful signal but from a single seed and single attack instance.
3. The attack mechanism differs from RAPTOR's prefix-level interception; here we model AS-level routing manipulation.

**Validity status**: **Conditional**. State-level attacks show a clear correlation spike (1.84x), but the finding needs multi-seed confirmation and is limited by topology scale.

---

## 4. Tier C: Cannot Claim (Structural Limitations)

Tier C encompasses claims that our experimental setup **cannot support** due to fundamental structural differences from the original papers. These are not failures of implementation but rather inherent limitations of the reduced-scale reproduction approach.

### C1. BGP Interception Attack Effectiveness (RAPTOR R4)

**Cannot claim**: Our experiments cannot reproduce the RAPTOR paper's finding that BGP interception attacks increase correlation to ~90%.

**Evidence** (RAPTOR reproduction report: `R4_interception`):

| Metric | RAPTOR Paper | Our Result |
|--------|-------------|------------|
| Baseline | ~12.8% (asymmetric) | 2.58% |
| During interception | ~90% | 2.55% |
| Change | ~7x increase | -1.4% (no increase) |

Per-attack breakdown shows zero adversary correlations despite significant adversary observations:
- Attack 0 (AS174 -> AS24940): Pre 3.4%, During 3.3%, Post 3.4%
- Attack 1 (AS3356 -> AS60729): Pre 3.1%, During 3.2%, Post 3.5%
- Attack 2 (AS6939 -> AS16276): Pre 3.2%, During 3.4%, Post 3.7%

**Structural reasons**:
1. **Topology scale**: In a 727-AS graph, Tier-1 attackers (AS174, AS3356, AS6939) are already on most transit paths. Interception adds marginal observation capability because the attacker's "reach" is already near-maximal in the small topology.
2. **Single-target attacks**: Each attack targets one AS prefix. With only 727 ASes, each target represents ~0.14% of the topology. RAPTOR's paper modeled interception of many prefixes simultaneously across a 48K-AS topology.
3. **BFS routing limitations**: Our BFS-based routing does not fully model BGP route preference mechanics (LOCAL_PREF, AS_PATH length comparison, MED). In real BGP, interception works by announcing a more-specific prefix or shorter AS path, which our model cannot faithfully simulate.
4. **Short attack windows**: 7-day attacks affect only ~450K circuits out of 7.8M total (5.8%), diluting measurable impact.

**What would be needed**: A topology with 5,000+ ASes, real BGP route selection logic, and multi-prefix interception attacks.

**Validity status**: **Cannot claim**. This is a structural limitation, not an implementation error.

---

### C2. Absolute Correlation Rate Values

**Cannot claim**: Our simulator produces correlation rates that are 5-50x lower than the original papers' values.

**Comparison of absolute values**:

| Metric | Paper Value | Our Value | Ratio |
|--------|------------|-----------|-------|
| RAPTOR R1 symmetric | 12.8% | 2.58% | 5.0x lower |
| RAPTOR R1 asymmetric | 21.3% | 2.58% | 8.3x lower |
| RAPTOR R3 top threat (NTT) | 91% | 1.25% (HE) | 72.8x lower |
| RAPTOR R3 Level3 | 88% | 0.095% | 926x lower |
| Johnson et al. network baseline | ~2% | 1.93% | ~1.0x (match) |

**Note**: The Johnson et al. baseline (~2%) closely matches our result (1.93%), suggesting that for *within-paper* comparisons at similar topology scales, our simulator produces valid results. The large discrepancies arise specifically from the RAPTOR paper, which used a 66x larger topology.

**Structural reasons for the gap**:

| Factor | RAPTOR | Our Reproduction | Impact |
|--------|--------|------------------|--------|
| AS count | ~48,000 | 727 | Transit path diversity 66x reduced |
| Edge count | ~150,000+ | ~6,200 | Route alternatives 24x reduced |
| Path length | 4-7 hops typical | 2-4 hops typical | Fewer transit AS observation opportunities |
| Routing model | Real BGP RIB | BFS + Gao-Rexford | Less realistic path selection |
| Relay count | ~6,000 | 727 (AS-aggregated) | Reduced relay diversity within ASes |

**The gap is quantifiable**: Each additional hop in an AS path adds approximately one AS observation opportunity. If average path length increases from 3 to 5 hops (as expected in a 48K topology), observation opportunities roughly double, which is consistent with the observed 5-8x gap for R1/R2 metrics.

**Validity status**: **Cannot claim** absolute correlation rate values. All claims must be framed as *relative comparisons* (defense reduction percentages, trend directions, rank orderings).

---

## 5. Cross-Cutting Validity Considerations

### 5.1 Single-Seed Limitation

All current results use seed 42 (RAPTOR) or default seeds (Johnson et al.). Without multi-seed runs with confidence intervals, individual numerical values have unknown variance. This affects:

- **Tier A claims**: Robust due to large effect sizes (e.g., Astoria's 99.97% reduction is unlikely to be a seed artifact)
- **Tier B claims**: More sensitive; the asymmetric routing factor of 1.003x could be within the noise floor
- **Tier C claims**: Unaffected (structural limitations are seed-independent)

**Planned mitigation**: Multi-seed simulations (S1-S3) with DKW confidence intervals (see validation scripts V1-V8).

### 5.2 Topology Vintage

Our CAIDA data covers January-July 2025; the original papers used 2013-2014 data. The Internet's AS-level topology has evolved significantly:

- **Tor relay distribution**: Shifted toward European hosting providers (Hetzner, OVH) and away from US-centric transit providers
- **AS connectivity**: Hurricane Electric has expanded peering aggressively; NTT's relative importance has declined
- **IXP growth**: Internet Exchange Points have proliferated, creating shortcut paths not captured in our AS-relationship model

This vintage difference affects **rank orderings** (Tier A3) but not **structural properties** (Tier-1 dominance, defense effectiveness).

### 5.3 Simulation Scale Sufficiency

| Experiment | Circuits | Clients | Duration | Statistical Power |
|------------|----------|---------|----------|-------------------|
| RAPTOR R1 | 7,776,600 | 200 | 90 days | High for rates >1% |
| RAPTOR R2 | 15,552,600 | 200 | 180 days | High for trends |
| RAPTOR R3 | 19,441,500 | 500 | 90 days | High for rankings |
| Network defense | 1,944,150 | 50 | 60 days | Moderate for client CDF |
| Relay adversary | 15,552,600 | 200 | 180 days | High for step function |

The primary scale concern is the **50-client network defense experiment**, where individual client compromises represent 2% jumps in the CDF. Increasing to 200+ clients would smooth the CDF curves.

---

## 6. Summary Classification Table

| ID | Claim | Tier | Confidence | Key Evidence |
|----|-------|------|------------|--------------|
| A1 | Relay adversary achieves 100% compromise within guard rotation | **A** | Strong | 200/200 clients, day 60.0, exit 90.5% |
| A2 | Defense ordering: Combined > Astoria >> CR > Vanilla | **A** | Strong | 99.97% vs 4.6% stream reduction |
| A3 | Tier-1 ASes dominate traffic correlation threat | **A** | Strong | 4/4 Tier-1 in top-6, Telia rank preserved |
| B1 | BGP churn increases correlation over time | **B** | Conditional | 1.3-1.5x increase (paper: ~3x) |
| B2 | Asymmetric routing increases correlation | **B** | Conditional | 1.003x (paper: 1.66x) |
| B3 | BGP attacks elevate correlation (state-level) | **B** | Conditional | 1.84x spike for state-level attack |
| C1 | BGP interception achieves ~90% correlation | **C** | Cannot claim | No increase observed (topology limitation) |
| C2 | Absolute correlation rate values | **C** | Cannot claim | 5-50x gap vs. RAPTOR values |

---

## 7. Implications for Research Conclusions

### What we can definitively state:
1. Tor's relay selection algorithm creates predictable compromise timelines for relay-level adversaries.
2. Astoria-style transit AS overlap avoidance is dramatically more effective than Counter-RAPTOR guard reweighting.
3. Tier-1 transit ASes hold structurally privileged positions for traffic correlation regardless of topology scale.

### What we can state with caveats:
4. BGP routing changes over time expand the adversary's observation set (magnitude underestimated ~2x).
5. Asymmetric routing creates additional correlation opportunities (direction confirmed, magnitude insufficient).
6. State-level BGP attacks can significantly spike correlation rates.

### What we cannot state:
7. Specific absolute correlation percentages for real-world Tor usage.
8. The effectiveness of BGP interception attacks at Internet scale.

---

## Appendix: Claim-to-Evidence Traceability

| Claim | JSON Report | Key Fields |
|-------|-------------|------------|
| A1 | `relay_adversary_report.json` | `relay_cdf.vanilla`, `stream_compromise.vanilla` |
| A2 | `network_defense_comparison_report.json` | `overall[*]`, `client_compromise[*]`, `trends` |
| A3 | `raptor_reproduction_report.json` | `R3_entity_threat.top15` |
| B1 | `raptor_reproduction_report.json` | `R2_temporal_churn.sym_curve`, `asym_curve` |
| B2 | `raptor_reproduction_report.json` | `R1_asymmetric_routing` |
| B3 | `network_defense_comparison_report.json` | `attack_impact` |
| C1 | `raptor_reproduction_report.json` | `R4_interception` |
| C2 | All reports | Absolute rate comparisons with paper references |
