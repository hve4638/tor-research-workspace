# 논문별 재현 가능성 및 연구 활용도 분석

**작성일**: 2026-02-21
**목적**: 7개 참조 논문 중 시뮬레이터(next-simulate)로 실험을 재현하여 현실성을 입증할 수 있는 대상을 식별하고 우선순위를 매긴다.

---

## 시뮬레이터 현재 능력 요약

| 기능 | 구현 위치 |
|------|----------|
| 3-hop 회로 생성 (대역폭 가중치) | `internal/circuit/` |
| 동적 AS 토폴로지 (CAIDA 스냅샷, 30일 주기) | `internal/asgraph/temporal.go` |
| BGP Hijack (prefix 탈취) | `internal/bgp/hijack.go` |
| BGP Interception (경로 삽입) | `internal/bgp/interception.go` |
| 4종 적대자 모델 (SingleAS, Colluding, StateLevel, Tier1) | `internal/adversary/`, `configs/*.yaml` |
| 비대칭 경로 (A→B ≠ B→A) | `internal/asgraph/path.go` |
| Counter-RAPTOR 방어 | `internal/defense/counter_raptor.go` |
| Astoria 방어 | `internal/defense/astoria.go` |
| Python 분석 (상관율, 방어 비교, 시각화) | `tor-anal/analysis/` |

---

## Tier 1: 직접 재현 가능 — 시뮬레이터 검증의 핵심

### 1. RAPTOR: Routing Attacks on Privacy in Tor (Sun et al., USENIX Security 2015)

프로젝트의 M5 BGP 공격 모델이 이 논문에 직접 기반하므로 **가장 높은 재현 우선순위**.

#### 재현 가능한 실험

| 재현 대상 | 논문 원본 결과 | 시뮬레이터 대응 |
|----------|--------------|---------------|
| 비대칭 경로 고려 시 취약 회로 증가 | 순방향만 12.8% → 양방향 21.3% (1일) | `asgraph/path.go` 비대칭 경로 + `observer/` 양방향 판정 |
| BGP Churn에 의한 시간적 취약성 증가 | 21일간 12.8% → 31.8% (~3배) | `asgraph/temporal.go` CAIDA 스냅샷 30일 전환 |
| Top AS 관찰 범위 | NTT 91%, Level3 88% 회로 관찰 | `configs/bgp_attack.yaml` Tier1 적대자 모델 |
| BGP Interception 비익명화 | 90% 정확도 | `bgp/interception.go` 경로 삽입 시뮬레이션 |
| 릴레이 집중도 (6개 AS에 30% 릴레이) | OVH 10.5%, Hetzner 6.3% 등 | `as_model_simplified.json` 727 AS 가중치 |

#### 입증 전략

시뮬레이터에서 동일 조건(비대칭 on/off, 시간 경과)을 설정하고, 취약 회로 비율의 **증가 경향(trend)**이 논문과 일치하는지 비교한다. 절대값보다 **상대적 증가 비율** (2배, 3배)이 일치하면 모델의 현실성을 주장할 수 있다.

- 비대칭 on/off 토글 → 취약 회로 비율이 약 2배 증가하는지 확인
- 다중 스냅샷(30일 × N) 누적 → 시간에 따른 취약성 증가 곡선이 논문의 3배 경향과 유사한지 확인
- Tier1 적대자(Level3, NTT 등) 시뮬레이션 → 단일 AS의 최대 관찰 범위가 논문의 88~91%와 같은 규모인지 확인

---

### 2. Measuring and Mitigating AS-level Adversaries Against Tor (Nithyanand et al., NDSS 2016)

Astoria 방어의 원본 논문. 프로젝트 M6에서 직접 구현했으므로 **방어 효과 재현이 핵심**.

#### 재현 가능한 실험

| 재현 대상 | 논문 원본 결과 | 시뮬레이터 대응 |
|----------|--------------|---------------|
| Vanilla Tor 취약 회로율 | 40% (single AS) | `configs/bgp_attack.yaml` 실행 |
| Astoria 방어 효과 | 40% → **2%** | `configs/astoria_defense.yaml` 실행 |
| State-level 적대자 | 85% → **25%** (Astoria 적용) | StateLevel 적대자 + Astoria |
| Colluding AS 공모 영향 | +3% 추가 취약 (전체), BR/DE에서 +8~10% | Colluding 적대자 모델 |
| Counter-RAPTOR vs Astoria 비교 | 논문에는 없음 (별도 연구) | `configs/combined_defense.yaml` — **프로젝트 고유 기여** |

#### 입증 전략

4개 시나리오(Vanilla / CR / Astoria / Combined) 비교에서 Astoria의 상관율 감소 패턴이 논문의 40% → 2% 경향과 일치하는지 확인한다.

- **Single AS**: Vanilla 대비 Astoria의 상관율 감소가 ~95% (40→2) 수준인지
- **State-level**: 감소폭이 ~70% (85→25) 수준인지
- **Colluding**: Sibling AS 추가 시 소폭(~3%) 증가하는지
- **Combined (CR+Astoria)**: 논문에 없는 조합이므로, 개별 방어보다 우수함을 보이면 프로젝트 고유 기여로 제시 가능

---

## Tier 2: 실측 데이터와의 교차 검증 — 시뮬레이터 현실성의 결정적 증거

### 3. An Extended View on Measuring Tor AS-level Adversaries (Gegenhuber et al., Computers & Security 2023)

**시뮬레이터 현실성 입증에 가장 가치 있는 논문**. BGP 예측이 아닌 **RIPE Atlas 실측 traceroute**(11,000+ 프로브) 데이터를 사용하므로, 시뮬레이터 결과와 비교하면 "시뮬레이션 vs 현실" 격차를 정량화할 수 있다.

#### 교차 검증 가능 항목

| 교차 검증 대상 | 논문 실측값 | 시뮬레이터 비교 방법 |
|--------------|-----------|-------------------|
| HETZNER(AS24940) 이중 역할 상관 확률 | **22.4%** (IPv4), 35% (IPv6) | AS24940의 p_guard × p_exit 계산 |
| AS 중앙집중화: 5개 AS = exit 50% | 구체적 AS 목록 제공 | `as_path_probabilities.json`에서 상위 5개 exit AS 확률 합산 |
| Top transit AS (COGENT, LEVEL3, TWELVE99) | 거의 모든 entry path에 출현 | 시뮬레이터의 AS 경로 추론 결과에서 동일 AS 출현 빈도 |
| 2020→2022 시간 안정성 | 전반적 구도 변동 없음 | `temporal.go` 다중 스냅샷 결과의 변동폭 비교 |
| 러시아 사용자 안전성 | 서방(DE/US)보다 낮은 위험 | StateLevel(RU) 시뮬레이션 vs StateLevel(US/DE) |

#### 입증 전략

1. 시뮬레이터의 AS 경로 추론 결과에서 **상위 transit AS**를 추출하여 논문의 RIPE Atlas 결과와 비교
2. **상관 확률 상위 AS 랭킹**이 일치하면 → 시뮬레이터의 AS 그래프 + 경로 추론이 현실적
3. 절대값 차이가 있더라도 **순위 상관(Spearman rank correlation)**이 높으면 모델 타당성 주장 가능
4. "BGP 예측이 아닌 실측 traceroute와 비교했다"는 점이 **논문 리뷰어에게 가장 설득력 있는 근거**

> **핵심**: 이 논문은 기존 연구(RAPTOR, Astoria 등)가 BGP 기반 경로 예측에 의존하여 위험을 **과대평가**한다고 지적한다. 시뮬레이터 결과가 이 실측값에 근접하면 "과대평가 경향을 인지하고 보정한 시뮬레이터"로 포지셔닝 가능.

---

### 4. Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries (Johnson et al., CCS 2013)

TorPS 방법론의 원본. 시뮬레이터가 유사한 몬테카를로 접근을 취하므로 **방법론적 일관성** 검증에 활용.

#### 교차 검증 가능 항목

| 교차 검증 대상 | 논문 결과 | 비교 포인트 |
|--------------|---------|-----------|
| 단일 AS 최악 위치: 1일 내 침해율 | 45.9% (Typical), 76.4% (BT) | Tier1 적대자 시뮬레이션 |
| 3개월 내 침해율 | >98% 샘플 최소 1회 침해 | 시간 경과 CDF 비교 |
| 2개 AS 공모 시 30일 내 침해 증가 | 156% (BT), 122% (Typical) 증가 | Colluding 적대자 모델 |
| 릴레이 vs 네트워크 적대자 패턴 반전 | 목적지 다양성 ↑ → 네트워크 위험 ↓ | 다양한 destination 분포로 시뮬레이션 |

#### 입증 전략

- **방법론 비교**: TorPS는 실제 Tor consensus 데이터를 사용하는 반면, 프로젝트는 AS-level 모델을 사용. 결과의 **경향성 일치**가 핵심
- Tier1/Colluding 적대자 결과가 논문의 규모(수십 % 단위)와 유사하면 모델 타당성 입증
- 논문이 지적한 "릴레이 적대자 vs 네트워크 적대자의 반대 패턴"이 시뮬레이터에서도 재현되는지 확인

---

## Tier 3: 이론적 보완 — 부분적 활용

### 5. TOAR: Toward Resisting AS-Level Adversary Correlation Attacks Optimal Anonymous Routing (Zhao & Song, Mathematics 2024)

SDN 기반 접근이라 직접 재현은 불가하지만, **보안 정책 함수**가 이론적 도구로 활용 가능.

| 활용 가능 요소 | 활용 방법 |
|--------------|---------|
| 보안 정책 함수 `d(p,k,m,n) = 1+(1-p)^(m+n-k)-(1-p)^m-(1-p)^n` | observer의 교집합 판정을 공유 AS 수(k)로 정량화하여, 이론적 침해 확률과 시뮬레이터 실제 상관율 비교 |
| 비대칭 경로의 4가지 관찰 시나리오 | 프로젝트의 비대칭 모델이 이론적으로 정당함을 확인하는 근거 |
| CAIDA 63,361 노드 토폴로지 규모 | 프로젝트의 727 AS 서브셋이 전체 대비 어느 정도 대표성을 갖는지 비교 참조 |

---

### 6. An Anonymity Vulnerability in Tor (Tan et al., IEEE/ACM ToN 2022)

Trapper Attack은 릴레이 수준(node-level) 공격이라 AS-level 시뮬레이터로 직접 재현 불가. 하지만 Guard 선택 모델의 검증에 간접 활용 가능.

| 활용 가능 요소 | 활용 방법 |
|--------------|---------|
| Guard 선택 확률 모델 `P_G(b) = b/(B_G + B_GE*W_E)` | 시뮬레이터의 Guard 선택 확률 분포가 이 수식과 일치하는지 검증 |
| Honey relay의 guard 장악 속도 (47회 시도) | 대역폭 가중치 기반 선택이 특정 AS에 편향되는 정도를 측정하여 간접 비교 |
| Guard 갱신 메커니즘 악용 (3~6개월 → 3분) | 프로젝트의 Guard 만료/갱신 로직의 현실성 확인 참조 |

---

## Tier 4: 향후 참조

### 7. Tor Hidden Services: A Systematic Literature Review (Huete Trujillo & Ruiz-Martínez, J. Cybersecur. Priv. 2021)

M7 Hidden Service v3 (현재 보류 상태)의 참고 문헌. 현재 단계에서는 재현 대상이 아니다.

- 6-hop 회로 구조, Introduction Point / Rendezvous Point 선택, Vanguards 방어 등은 M7 재개 시 활용
- SLR(체계적 문헌 고찰)이므로 재현할 실험이 아닌 **연구 맥락 참조용**

---

## 종합: 권장 재현 실험 로드맵

```
우선순위 1 — 시뮬레이터 핵심 검증 (RAPTOR + Astoria 재현)
├── [R1] RAPTOR 재현: 비대칭 경로 on/off → 취약 회로 비율 ~2배 증가 확인
├── [R2] RAPTOR 재현: BGP Churn (다중 스냅샷) → 시간에 따른 ~3배 증가 경향 확인
├── [R3] Astoria 재현: Vanilla 40% → Astoria 2% 감소 경향 확인
└── [R4] Astoria 재현: State-level 85% → 25% 감소 확인

우선순위 2 — 실측 데이터 교차 검증 (Extended View 비교, 가장 강력한 입증)
├── [V1] Extended View 비교: 상위 transit AS 랭킹 일치 여부 (Spearman 상관)
├── [V2] Extended View 비교: HETZNER 이중 역할 상관 확률 비교
└── [V3] Extended View 비교: AS 중앙집중화 패턴 일치 여부

우선순위 3 — 추가 검증 (Users Get Routed + TOAR 이론)
├── [A1] Users Get Routed: Tier1 적대자 1일 내 침해율 비교
├── [A2] Users Get Routed: Colluding AS 공모 효과 비교
└── [A3] TOAR: d(p,k,m,n) 함수로 상관율의 이론적 하한/상한 검증
```

---

## 논문-시뮬레이터 매핑 요약표

| 논문 | Tier | 재현 유형 | 핵심 비교 지표 | 기대 입증 |
|------|------|----------|--------------|----------|
| RAPTOR (Sun et al., 2015) | 1 | 직접 재현 | 비대칭 2배, Churn 3배, Interception 90% | 공격 모델 정확성 |
| Measuring & Mitigating (Nithyanand et al., 2016) | 1 | 직접 재현 | Vanilla 40%, Astoria 2%, State 85→25% | 방어 효과 정확성 |
| An Extended View (Gegenhuber et al., 2023) | 2 | 실측 교차 검증 | Transit AS 랭킹, HETZNER 22.4%, AS 집중도 | **시뮬레이터 현실성** |
| Users Get Routed (Johnson et al., 2013) | 2 | 방법론 비교 | 1일 내 45~76%, 3개월 98%, Colluding 효과 | 방법론 일관성 |
| TOAR (Zhao & Song, 2024) | 3 | 이론 검증 | d(p,k,m,n) 함수, 공유 AS 수(k) | 이론적 타당성 |
| Anonymity Vulnerability (Tan et al., 2022) | 3 | 간접 검증 | Guard 선택 확률 P_G(b) | Guard 모델 정확성 |
| HS SLR (Huete Trujillo et al., 2021) | 4 | 향후 참조 | — | M7 재개 시 활용 |
