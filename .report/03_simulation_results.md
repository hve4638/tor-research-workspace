# 시뮬레이션 + 분석 결과

> 실행일: 2026-02-20
> 조건: 90일, 50 클라이언트, 3개 CAIDA 스냅샷, 3건 BGP 공격, seed=42

---

## 1. 전체 상관율 비교

| 시나리오 | 상관 회로 | 전체 회로 | 상관율 | Vanilla 대비 감소 |
|----------|----------|----------|--------|-------------------|
| **Vanilla** (방어 없음) | 37,572 | 1,944,150 | **1.93%** | — |
| **Counter-RAPTOR** | 35,856 | 1,944,150 | **1.84%** | -4.6% |
| **Astoria** | 12 | 1,944,150 | **~0.00%** | **-99.97%** |
| **Combined** (CR+Astoria) | 5 | 1,944,150 | **~0.00%** | **-99.99%** |

### 핵심 관찰

- **Counter-RAPTOR 단독**: Guard 재가중만으로는 상관율 감소가 미미 (4.6%)
- **Astoria 단독**: entry/exit transit 교집합 검사가 상관을 거의 완전히 제거 (99.97%)
- **Combined**: Astoria가 이미 상관을 제거하므로 CR 추가 효과는 미미하나, fallback 회로에서 미세한 추가 감소 (12→5건)

---

## 2. 클라이언트 침해율

| 시나리오 | 침해 클라이언트 | 침해율 | 감소 |
|----------|----------------|--------|------|
| Vanilla | 34/50 | **68%** | — |
| Counter-RAPTOR | 34/50 | **68%** | 0% |
| Astoria | 9/50 | **18%** | -73.5% |
| Combined | 5/50 | **10%** | -85.3% |

- 90일 동안 Vanilla에서 50명 중 34명(68%)이 최소 1개 회로에서 상관됨
- CR은 침해 클라이언트 수를 줄이지 못함 (상관율은 낮추나 분포가 넓음)
- Astoria는 18%로 대폭 감소, Combined는 10%까지 감소

---

## 3. BGP 공격 영향 (Vanilla 기준)

| 공격 | 유형 | 적대자 | 공격 전 | 공격 중 | 공격 후 | 배율 |
|------|------|--------|---------|---------|---------|------|
| #0 | Hijack | AS174 (Cogent, 단일) | 1.84% | 1.66% | 1.95% | 0.90x |
| #1 | Interception | AS3356 (Level3, Tier-1) | 1.74% | 1.95% | 2.13% | 1.12x |
| #2 | Hijack (국가) | AS3320 (DE, 73 AS) | 1.74% | **3.20%** | 2.29% | **1.84x** |

### 핵심 관찰

- **단일 AS hijack** (#0): 공격 효과 미미. 단일 AS가 경로를 장악해도 전체 상관에 큰 영향 없음
- **Tier-1 interception** (#1): 소폭 상관율 증가 (1.12배). Interception은 은밀하지만 효과도 제한적
- **국가 수준 hijack** (#2): **1.84배 상관율 증가** (1.74% → 3.20%). AS6939(Hurricane Electric, transit의 17.7%)을 장악하여 대규모 경로 변경 유발
- **공격 후에도 상관율 상승 지속**: 공격 전 대비 공격 후 상관율이 높음 — 스냅샷 전환(토폴로지 변경)의 영향

---

## 4. 시간 추세 분석

| 시나리오 | 평균 | 표준편차 | 추세 |
|----------|------|---------|------|
| Vanilla | 1.93% | 0.34% | **증가** (slope +0.0031) |
| Counter-RAPTOR | 1.84% | 0.32% | **증가** (slope +0.0026) |
| Astoria | ~0.00% | ~0.00% | **안정** |
| Combined | ~0.00% | ~0.00% | **안정** |

- Vanilla/CR: 시간이 지남에 따라 상관율이 증가하는 추세 — 토폴로지 churn(edge 변동)이 새로운 관찰 경로를 생성
- Astoria/Combined: 시간 경과와 무관하게 안정적으로 0%에 가까움

---

## 5. Astoria 방어 통계

| 지표 | Astoria 단독 | Combined |
|------|-------------|----------|
| 총 검사 횟수 | 1,980,422 | 1,979,350 |
| 안전한 회로 | 1,944,149 | 1,944,149 |
| 거부된 위험 회로 | 36,273 | 35,201 |
| Fallback 회로 | 1 | 1 |
| **안전율** | **98.2%** | **98.2%** |

- 회로의 98.2%가 첫 시도 또는 5회 이내 재시도에서 안전한 회로를 찾음
- Fallback(모든 재시도 실패)은 전체 시뮬레이션에서 단 1건

---

## 6. Transit AS 분포 (Vanilla)

| AS | 관찰 비율 | 정체 |
|----|----------|------|
| AS6939 | 17.7% | Hurricane Electric (글로벌 transit) |
| AS24875 | 8.6% | NovoServe |
| AS50629 | 6.8% | LWLcom |
| AS199524 | 5.7% | G-Core Labs |
| AS49544 | 4.7% | i3D.net |
| AS174 | 4.0% | Cogent Communications |

- AS6939(HE)이 전체 transit 관찰의 17.7%를 차지 — BGP 공격 #2의 주요 타겟
- 상위 6개 AS가 전체 관찰의 47.5%를 점유

---

## 7. 생성된 산출물

### JSON 리포트
- `tor-anal/output/analysis/defense_comparison_report.json`

### 시각화 (6개 PNG)
- `tor-anal/output/analysis/plots/correlation_comparison.png` — 시나리오별 상관율 바 차트
- `tor-anal/output/analysis/plots/temporal_curves.png` — 시간별 상관율 변화
- `tor-anal/output/analysis/plots/cumulative_compromise.png` — 누적 상관율 곡선
- `tor-anal/output/analysis/plots/attack_impact.png` — 공격 전/중/후 비교
- `tor-anal/output/analysis/plots/as_risk_heatmap.png` — Top AS entry/exit 히트맵
- `tor-anal/output/analysis/plots/guard_distribution_shift.png` — Guard 분포 변화
