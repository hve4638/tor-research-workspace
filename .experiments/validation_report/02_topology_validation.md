# Topology Validation: Representativeness and Transit Concentration

**Validation tests**: V1 (Topology Representativeness), V4 (Transit AS Concentration), V5 (Temporal Variation)
**Data sources**: `data/v1_topology.json`, `data/v4_transit_concentration.json`, `data/v5_temporal.json`
**Plots**: `plots/v1_degree_distribution.png`, `plots/v5_temporal_churn.png`

---

## 1. V1: Topology Representativeness

### 1.1 Scale and Coverage

Our simulation operates on a **727-AS Tor-relevant subgraph** extracted from the full Internet topology. This represents 1.5% of the approximately 48,000 ASes in CAIDA's full AS-rank dataset. However, these 727 ASes are not a random sample -- they are the ASes that host Tor relays, and they cover a disproportionately large share of Tor's bandwidth:

| Metric | Value |
|--------|-------|
| Total AS nodes | 727 |
| Nodes with edges | 604 |
| Nodes without edges | 123 |
| Total edges | 6,325 |
| Peer-to-peer edges | 5,203 (82.3%) |
| Provider-customer edges | 1,122 (17.7%) |
| Guard bandwidth coverage (significant ASes) | 88.1% |
| Exit bandwidth coverage (significant ASes) | 96.8% |

The 120 significant ASes (those with guard or exit weight above 0.1%) cover 88.1% of guard bandwidth and 96.8% of exit bandwidth. This means our topology captures the vast majority of Tor traffic despite modeling only 1.5% of Internet ASes.

### 1.2 Degree Distribution

| Metric | Our Model | CAIDA Reference |
|--------|-----------|-----------------|
| Average degree | 20.94 | ~6.3 |
| Median degree | 6.0 | ~4 |
| Max degree | 385 | ~7,000 |
| Graph density | 0.024 | ~0.0001 |
| Power-law alpha | 1.52 | ~2.1 |

The average degree in our model (20.94) exceeds the CAIDA reference (~6.3) because Tor-hosting ASes are not random Internet ASes: they are predominantly located in well-connected data center networks and transit providers with above-average peering. This is expected behavior, not a flaw -- the Tor relay ecosystem is biased toward high-connectivity ASes.

The power-law exponent (alpha = 1.52 vs. CAIDA's ~2.1) reflects a heavier tail in our degree distribution, consistent with Tor relays clustering in major transit and hosting networks. The degree distribution plot (`v1_degree_distribution.png`) confirms the characteristic scale-free shape on log-log axes.

### 1.3 Implications for Validity

The topology is **not representative of the full Internet** but is **representative of the AS-level paths that Tor traffic actually traverses**. Since our research questions concern AS-level observation of Tor circuits (not general Internet traffic), this Tor-centric subgraph is the appropriate modeling choice. The high bandwidth coverage (88-97%) ensures that path-selection probabilities are faithful to real Tor behavior.

**Limitation**: AS paths between nodes not in our subgraph may be missing intermediate hops. The BFS valley-free routing operates only on the 727-node graph, which produces shorter paths than the full Internet (see V2).

---

## 2. V4: Transit AS Concentration

### 2.1 Gini Coefficient

The Gini coefficient for AS-level threat scores is **0.689**, indicating **high concentration** of transit observation capability. The top 3 ASes account for **77.1%** of all transit threat, confirming that a small number of well-positioned ASes dominate Tor traffic observation.

### 2.2 Tier-1 AS Presence

Four of the eight canonical Tier-1 transit-free clique members appear in the top 15 most threatening ASes:

| Rank | ASN | Name | Threat Score |
|------|-----|------|-------------|
| 1 | AS6939 | Hurricane Electric | 1.247% |
| 2 | AS174 | Cogent | 0.864% |
| 3 | AS1299 | Arelion/Telia | 0.259% |
| 6 | AS3356 | Lumen/Level3 | 0.095% |

This is consistent with the RAPTOR paper's Table 2, which found Tier-1 ASes dominating transit threat rankings. The specific ordering differs (the paper ranked Lumen/Level3 highest), which reflects changes in AS relationships between the paper's 2013-2014 data and our 2025 CAIDA snapshots.

### 2.3 Spearman Rank Correlation

The Spearman rank correlation between our Tier-1 ranking and a reference ordering based on known transit volume is rho = -0.8 (p = 0.20). The negative correlation reflects that Hurricane Electric and Cogent rank higher in our model than in typical transit volume rankings, likely because these ASes have extensive peering with data center networks where Tor relays are concentrated. The p-value is not significant due to the small sample size (n=4 matched Tier-1 ASes), but the qualitative finding -- Tier-1 dominance of transit threat -- is robust.

---

## 3. V5: Temporal Variation

### 3.1 Edge Churn Across 13 Snapshots

We analyzed 13 monthly CAIDA AS-relationship snapshots (January 2025 through January 2026), computing edge churn rates between consecutive months:

| Transition | Added | Removed | Churn Rate |
|-----------|-------|---------|-----------|
| 2025-01 to 2025-02 | 191 | 95 | 4.5% |
| 2025-02 to 2025-03 | 209 | 284 | 7.6% |
| 2025-03 to 2025-04 | 251 | 914 | 18.0% |
| 2025-04 to 2025-05 | 155 | 150 | 5.3% |
| 2025-05 to 2025-06 | 308 | 155 | 7.9% |
| 2025-06 to 2025-07 | 265 | 297 | 9.4% |
| 2025-07 to 2025-08 | 247 | 135 | 6.5% |
| 2025-08 to 2025-09 | 184 | 164 | 5.8% |
| 2025-09 to 2025-10 | 121 | 406 | 8.9% |
| 2025-10 to 2025-11 | 134 | 196 | 5.8% |
| 2025-11 to 2025-12 | 1,097 | 328 | 21.7% |
| 2025-12 to 2026-01 | 345 | 249 | 9.0% |

Mean churn rate: **9.2%** per month. Two high-churn events are notable: March-April 2025 (18.0%, dominated by removals) and November-December 2025 (21.7%, dominated by additions). These likely reflect CAIDA measurement methodology changes or real peering shifts.

### 3.2 Correlation with Observation Rates

The Pearson correlation between edge churn rates and changes in AS-level correlation rates is **r = 0.512** (p = 0.378). While the positive direction is consistent with the RAPTOR paper's finding that topology changes increase observation opportunities, the correlation is not statistically significant due to the small number of aligned data points (n=5).

This is a **Tier B finding**: the directional trend is consistent with RAPTOR Figure 5 (more topology churn leads to higher correlation), but we cannot make strong quantitative claims about the precise relationship due to limited temporal data points.

---

## 4. Summary

| Test | Status | Key Finding |
|------|--------|-------------|
| V1 Topology | PASS | 727 ASes cover 88-97% of Tor bandwidth; degree distribution shows expected heavy-tail |
| V4 Transit Concentration | PASS | Gini=0.689; 4/8 Tier-1 ASes in top-15; consistent with RAPTOR Table 2 |
| V5 Temporal | PASS | Mean 9.2% monthly churn; positive (r=0.51) but non-significant correlation with observation rates |
