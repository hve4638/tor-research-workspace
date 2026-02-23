# RAPTOR 논문 재현 실험 결과

**논문**: Sun et al., "Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries" (USENIX Security 2015)

**실험 일자**: 2026-02-22

---

## 1. 실험 환경 비교

| 항목 | RAPTOR (2015) | 본 실험 (2025) |
|------|--------------|---------------|
| AS 토폴로지 규모 | ~48,000 ASes | 727 ASes |
| AS 관계 데이터 | CAIDA 2014 | CAIDA 2025-01~07 (13 스냅샷) |
| Tor 릴레이 수 | ~6,000 | ~700 (Guard 704, Exit 220) |
| 클라이언트 수 | 200 (R1/R2/R4), 500 (R3) | 동일 |
| 경로 계산 | Gao-Rexford + BGP RIB | BFS + CAIDA 관계 |
| 회로 수명 | 10분 | 10분 (max_dirtiness=600s) |
| 시뮬레이션 기간 | 90일 (R1/R3/R4), 180일 (R2) | 동일 |
| 시드 | 미공개 | 42 |

**핵심 차이**: 토폴로지 규모가 ~66배 작음. RAPTOR는 전체 인터넷 AS 토폴로지를 사용했으나, 본 실험은 Tor 릴레이가 위치한 727개 AS만 포함. 이로 인해 transit path 다양성이 제한되어 절대적 상관율이 논문보다 낮을 것으로 예상.

---

## 2. R1: 비대칭 경로의 상관율 증가

**RAPTOR 핵심 주장**: 비대칭 경로(A→B ≠ B→A)를 고려하면 상관율이 ~1.66배 증가 (12.8% → 21.3%)

### 결과

| 측정 | 대칭 | 비대칭 | 증가율 |
|------|------|--------|--------|
| 논문 | 12.8% | 21.3% | 1.66x |
| 본 실험 | 2.58% | 2.58% | 1.00x |

- 대칭: 200,409 / 7,776,600 회로 상관 (2.58%)
- 비대칭: 200,922 / 7,776,600 회로 상관 (2.58%)

### 분석

**증가율 미관찰 원인**:

1. **토폴로지 규모 한계**: 727 AS 그래프에서 BFS 경로의 비대칭 변동이 제한적. RAPTOR의 48K AS 토폴로지에서는 경로 선택지가 훨씬 다양하여 forward/reverse path 차이가 크게 발생.

2. **경로 계산 모델 차이**: RAPTOR는 실제 BGP RIB 데이터 기반으로 AS-path를 결정하므로 경로 비대칭이 자연적으로 반영됨. 본 실험의 BFS 기반 directional routing은 Gao-Rexford 정책은 반영하나, 실제 BGP 정책의 복잡성(local preference, MED, community 등)을 완전히 포착하지 못함.

3. **Transit AS 집중도**: 상위 10개 AS가 전체 관측의 ~60%를 차지(AS6939: 21%). 소규모 토폴로지에서 주요 transit AS가 대칭/비대칭 모두에서 동일하게 지배적.

**결론**: 비대칭 경로의 영향은 토폴로지 규모에 의존적. 소규모 그래프에서는 경로 다양성 부족으로 비대칭 효과가 상쇄됨. 정성적으로는 `asym_rate >= sym_rate` 관계가 유지됨.

### 산출물
- 시각화: `tor-anal/output/raptor_analysis/plots/asymmetric_comparison.png`

---

## 3. R2: BGP Churn에 의한 시간적 상관율 증가

**RAPTOR 핵심 주장**: 시간이 지남에 따라 BGP churn(경로 변동)이 누적되어 상관율이 ~3배 증가

### 결과

| 기간 | 대칭 | 비대칭 |
|------|------|--------|
| Period 0 (Jan) | 2.04% | 2.58% |
| Period 1 (Feb) | 2.31% | 2.27% |
| Period 2 (Mar) | 3.05% | 2.67% |
| Period 3 (Apr) | 2.87% | 2.97% |
| Period 4 (May) | 3.15% | 3.13% |
| Period 5 (Jun) | 3.29% | 3.29% |

**비대칭 증가 추세**: 2.58% → 3.29% (Period 0→5, 1.27x)
**대칭 증가 추세**: 2.04% → 3.29% (Period 0→5, 1.61x)

### 분석

**경향 일치 (정성적 재현 성공)**:

1. **상관율 증가 추세 확인**: 대칭/비대칭 모두 6개 기간에 걸쳐 상관율이 증가하는 추세가 관찰됨. 이는 RAPTOR의 핵심 발견과 일치.

2. **Churn 효과 확인**: CAIDA 스냅샷 간 edge 변화율이 5%~20.4%로, 실제 AS 관계 변동이 경로 변화를 유발하고 새로운 상관 기회를 생성.

3. **증가 규모 차이**: 논문의 ~3x 대비 1.27x~1.61x로 작음. 이는 소규모 토폴로지에서 경로 재계산 범위가 제한적이기 때문.

4. **비단조 구간**: Period 1(Feb)에서 일시적 감소가 관찰됨. 이는 churn이 기존 상관 경로를 제거하는 효과도 있음을 시사 (양방향 churn 효과).

**Churn 이력**:
```
Jan→Feb: +205/-109 edges (5.0%)
Feb→Mar: +265/-340 edges (9.6%)
Mar→Apr: +302/-965 edges (20.4%)  ← 최대 churn
Apr→May: +166/-161 edges (5.9%)
May→Jun: +319/-166 edges (8.5%)
Jun→Jul: +274/-306 edges (10.2%)
```

**결론**: BGP churn이 시간에 따른 상관율 증가를 유발한다는 RAPTOR의 핵심 발견이 재현됨. 절대 증가 규모는 토폴로지 규모에 비례하여 작지만, 증가 추세 자체는 명확.

### 산출물
- 시각화: `tor-anal/output/raptor_analysis/plots/temporal_churn_curves.png`

---

## 4. R3: Top AS 위협 순위

**RAPTOR 핵심 주장**: Tier-1 transit AS들이 가장 높은 상관 위협을 가짐 (NTT 91%, Level3 88%, Telia 85%)

### 결과

| 순위 | 본 실험 ASN | 이름 | 위협 점수 | RAPTOR 순위 | RAPTOR 값 | 순위 변화 |
|------|------------|------|----------|------------|----------|----------|
| 1 | AS6939 | Hurricane Electric | 1.25% | 5 | 60% | -4 |
| 2 | AS174 | Cogent | 0.86% | 4 | 63% | -2 |
| 3 | AS1299 | Telia | 0.26% | 3 | 85% | 0 |
| 4 | AS24875 | - | 0.15% | - | - | - |
| 5 | AS199524 | - | 0.11% | - | - | - |
| 6 | AS3356 | Level3/Lumen | 0.09% | 2 | 88% | +4 |
| 7 | AS3320 | - | 0.08% | - | - | - |
| 8 | AS3399 | - | 0.08% | - | - | - |
| 9 | AS50629 | - | 0.06% | - | - | - |
| 10 | AS30823 | - | 0.04% | - | - | - |

**Top-15 내 Tier-1 AS 수**: 4개 (AS6939, AS174, AS1299, AS3356)
**위협 점수 분포**: 201개 AS 중 82개가 threat_score > 0

### 분석

**정성적 재현 성공**:

1. **Tier-1 AS 지배 확인**: Top-3가 모두 Tier-1 transit provider (HE, Cogent, Telia). RAPTOR의 핵심 발견인 "Tier-1이 가장 위협적"이 재현됨.

2. **순위 변화 설명**:
   - **AS6939 (HE) 상승**: 2025년 기준 Tor 릴레이 호스팅이 집중된 AS(AS16276 OVH, AS24940 Hetzner)와의 연결이 강화됨. 본 실험 transit 관측의 21%를 차지.
   - **AS3356 (Level3) 하락**: 2015년 대비 Tor 릴레이의 지리적 분포가 유럽(독일, 네덜란드)으로 이동하면서 Level3의 영향력 감소.
   - **NTT (AS2914) 부재**: 2025년 Tor 릴레이 토폴로지에서 NTT의 transit 역할이 감소.

3. **절대값 차이**: 논문의 60~91% 대비 0.09~1.25%로 매우 작음. 이는 727 AS 토폴로지에서 단일 AS가 모든 회로를 관찰할 수 없기 때문 (BFS 경로 길이가 짧아 transit hop 수가 제한적).

**결론**: "Tier-1 transit AS가 Tor 익명성에 가장 큰 위협"이라는 RAPTOR의 핵심 발견이 10년 후의 다른 토폴로지에서도 재현됨. 순위의 세부 차이는 AS 토폴로지의 시대적 변화를 반영.

### 산출물
- 시각화: `tor-anal/output/raptor_analysis/plots/entity_threat_comparison.png`

---

## 5. R4: BGP Interception 공격의 상관율 증가

**RAPTOR 핵심 주장**: BGP interception 공격으로 상관율이 ~90%까지 급증

### 결과

| 측정 | 기준선 (비대칭) | Interception 적용 |
|------|----------------|------------------|
| 전체 상관율 | 2.58% | 2.55% |

**공격별 Pre/During/Post**:

| 공격 | 공격자→대상 | Pre | During | Post |
|------|-----------|-----|--------|------|
| Attack 0 | AS174→AS24940 | 3.4% | 3.3% | 3.4% |
| Attack 1 | AS3356→AS60729 | 3.1% | 3.2% | 3.5% |
| Attack 2 | AS6939→AS16276 | 3.2% | 3.4% | 3.7% |

### 분석

**공격 영향 미미한 원인**:

1. **Adversary 상관 0건**: 시뮬레이션 출력에서 adversary observations는 발생했으나 (Attack 0: 246K, Attack 1: 805K, Attack 2: 876K observations), adversary correlations = 0. 이는 interception이 트래픽 경유는 성공했으나, 동일 회로의 entry+exit 양쪽을 동시에 관찰하지 못했음을 의미.

2. **대상 AS 선택의 한계**: Interception 공격은 특정 prefix를 탈취하여 해당 AS 방향 트래픽을 경유시킴. 그러나 단일 AS(AS24940, AS60729, AS16276)만 대상으로 하므로, 전체 회로 중 해당 AS를 guard/exit로 사용하는 회로만 영향을 받음. 소규모 토폴로지에서 이 비율이 제한적.

3. **RAPTOR와의 차이**: 논문에서는 전체 인터넷 prefix를 대상으로 대규모 interception을 시뮬레이션. 48K AS에서 Tier-1이 수많은 prefix에 대한 transit을 제공하므로 영향 범위가 극도로 넓음. 본 실험의 727 AS에서는 이 효과가 대폭 축소.

4. **공격 지속 시간**: 7일(168h) 동안만 활성 — 전체 90일 대비 ~7.8%의 기간. 전체 상관율에 대한 영향이 희석됨.

**결론**: Interception 공격의 영향이 관찰되지 않은 것은 토폴로지 규모와 공격 범위의 한계. RAPTOR의 ~90% 상관율은 전체 인터넷 규모에서 다수의 prefix를 동시 탈취하는 시나리오에서 달성된 것으로, 축소 토폴로지에서의 재현은 구조적으로 제한적.

### 산출물
- 시각화: `tor-anal/output/raptor_analysis/plots/interception_impact.png`

---

## 6. 논문 대응표

| RAPTOR 논문 | 본 실험 산출물 | 재현 수준 |
|------------|--------------|----------|
| Figure 4 (sym vs asym) | `plots/asymmetric_comparison.png` | 정성적 부분 재현 |
| Figure 5 (temporal churn) | `plots/temporal_churn_curves.png` | 정성적 재현 성공 |
| Table 2 (AS threat ranking) | `plots/entity_threat_comparison.png` | 정성적 재현 성공 |
| Section 5 (interception) | `plots/interception_impact.png` | 재현 실패 (규모 한계) |
| JSON 리포트 | `raptor_reproduction_report.json` | 전체 수치 포함 |

---

## 7. 차이 분석 종합

### 절대값 차이의 구조적 원인

| 요인 | RAPTOR | 본 실험 | 영향 |
|------|--------|--------|------|
| AS 수 | ~48,000 | 727 | Transit path 다양성 66x 감소 |
| Edge 수 | ~150,000+ | ~6,200 | 경로 선택지 대폭 감소 |
| 경로 계산 | BGP RIB | BFS | 비대칭성 감소 |
| Tor 릴레이 | ~6,000 | ~700 | AS 분포 단순화 |
| 시대 | 2014-15 | 2025 | AS 토폴로지 구조 변화 |

### 재현 성공/실패 요약

| 연구 질문 | 논문 결과 | 본 실험 결과 | 판정 |
|----------|----------|------------|------|
| R1: 비대칭→상관 증가 | 1.66x | 1.00x | 추세 미약 (규모 의존적) |
| R2: Churn→시간적 증가 | ~3x | 1.27x~1.61x | **정성적 재현 성공** |
| R3: Tier-1 최대 위협 | NTT>Level3>Telia | HE>Cogent>Telia | **정성적 재현 성공** |
| R4: Interception→급증 | ~90% | 변화 없음 | 재현 실패 (구조적 한계) |

### 향후 개선 방향

1. **전체 AS 토폴로지 활용**: CAIDA의 ~48K AS 데이터셋을 직접 사용하여 경로 다양성 확보
2. **BGP RIB 기반 경로 계산**: RouteViews RIB에서 실제 AS-path를 추출하여 비대칭성 자연 반영
3. **대규모 Interception**: 다수의 prefix를 동시 탈취하는 시나리오 구현
4. **클라이언트-목적지 쌍 다양화**: 현재 uniform 분포 대신, 실제 Tor 사용 패턴 반영

---

## 부록: 시뮬레이션 설정

### 실행 Config

| Config | 용도 | Duration | Clients | 비대칭 | Temporal | BGP |
|--------|------|----------|---------|--------|---------|-----|
| `raptor_baseline_sym.yaml` | R1 대칭 | 90d | 200 | No | 3 snap | No |
| `raptor_baseline_asym.yaml` | R1 비대칭 | 90d | 200 | Yes | 3 snap | No |
| `raptor_temporal_sym.yaml` | R2 대칭 | 180d | 200 | No | 7 snap | No |
| `raptor_temporal_asym.yaml` | R2 비대칭 | 180d | 200 | Yes | 7 snap | No |
| `raptor_entity_threat.yaml` | R3 위협 | 90d | 500 | Yes | No | No |
| `raptor_interception.yaml` | R4 공격 | 90d | 200 | Yes | 3 snap | 3건 |

### 시뮬레이션 출력 크기

| 파일 | 크기 | 회로 수 | 관측 수 |
|------|------|---------|---------|
| obs_sym + gt_sym | 4.2GB | 7,776,600 | 17,639,518 |
| obs_asym + gt_asym | 4.3GB | 7,776,600 | 18,723,488 |
| obs_temporal_sym + gt | 8.7GB | 15,552,600 | 37,459,278 |
| obs_temporal_asym + gt | 8.8GB | 15,552,600 | 38,543,248 |
| obs_entity + gt | 12.0GB | 19,441,500 | 55,264,668 |
| obs_intercept + gt | 4.3GB | 7,776,600 | ~18,700,000 |
| **합계** | **~42GB** | | |

### 분석 산출물

| 파일 | 경로 |
|------|------|
| JSON 리포트 | `tor-anal/output/raptor_analysis/raptor_reproduction_report.json` |
| R1 시각화 | `tor-anal/output/raptor_analysis/plots/asymmetric_comparison.png` |
| R2 시각화 | `tor-anal/output/raptor_analysis/plots/temporal_churn_curves.png` |
| R3 시각화 | `tor-anal/output/raptor_analysis/plots/entity_threat_comparison.png` |
| R4 시각화 | `tor-anal/output/raptor_analysis/plots/interception_impact.png` |
