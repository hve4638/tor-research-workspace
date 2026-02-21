# Measuring and Mitigating AS-level Adversaries Against Tor

**요약 작성일**: 2026-02-21
**원문**: Nithyanand, Starov, Zair, Gill, Schapira (NDSS 2016)
**소속**: Stony Brook University / Hebrew University of Jerusalem
**DOI**: 10.14722/ndss.2016.23322

---

## 1. 핵심 기여 (One-line)

AS-level 비대칭 라우팅 공격(forward + reverse path)에 대한 Tor 회로의 취약성을 10개국에서 실증 측정하고, 이를 방어하기 위한 AS-aware Tor 클라이언트 **Astoria**를 설계/구현하여 취약 회로를 40% → 2%로 감소시킨 논문.

---

## 2. 연구 동기

- Tor는 entry/exit 양측 트래픽을 관찰하는 적대자에게 취약 (traffic correlation attack)
- NSA/GCHQ가 ISP와 공모하여 실제로 트래픽 상관 공격을 구현 중임이 밝혀짐
- 기존 연구의 한계:
  - **비대칭 라우팅 미고려**: forward path만 고려 → RAPTOR (Sun et al. 2015)가 reverse path의 TCP ACK를 통한 상관 공격이 가능함을 보임
  - **공모 AS 미고려**: 동일 조직 소유의 sibling AS 간 공모 가능성 무시
  - **국가급 적대자 미고려**: 국가 내 모든 AS 트래픽을 감시하는 state-level 적대자
  - **기존 AS-aware 클라이언트 (LASTor)의 문제**: 릴레이 용량 미고려로 네트워크 과부하, HTTP HEAD만으로 평가, 공모/비대칭 공격 미고려
- 따라서 (1) 비대칭 경로를 포함한 위협의 정량적 측정과 (2) 이를 방어하는 실용적 클라이언트가 필요

---

## 3. 방법론

### 3.1 적대자 모델 (Adversary Model)

| 적대자 유형 | 설명 |
|-----------|------|
| **Single AS** | 하나의 AS가 forward/reverse path 양쪽을 관찰 |
| **Sibling AS (Colluding)** | 동일 조직 소유의 sibling AS끼리 공모 (예: Level 3 + Global Crossing) |
| **State-level** | 국가 내 모든 AS의 트래픽을 감시 |

회로 취약성 판정 조건: entry 측 path-set과 exit 측 path-set에 공통 AS가 존재하면 취약

```
A_i ∈ {P_src↔entry ∩ P_exit↔dst}
```

- **비대칭 경로 고려**: forward path (src→entry, exit→dst) + reverse path (entry→src, dst→exit) 모두 검사
- Reverse path에서 TCP ACK 필드의 패킷 크기/타이밍 정보로 상관 공격 가능 (RAPTOR)

### 3.2 AS 경로 예측 (Path Prediction)

- **AS 토폴로지**: CAIDA의 경험적 AS-level 인터넷 토폴로지 사용
  - customer-provider, peer-peer 관계 모델링
  - partial transit, hybrid relationship 고려
  - IXP는 제외 (과대 추정 방지)
- **라우팅 정책**: Gao-Rexford 모델
  - Local Preference (LP): customer > peer > provider
  - Shortest Paths (SP): 동일 LP 중 최단 경로
  - Tie Break (TB): hash 기반 무작위 타이브레이크
  - Export Policy (EP): customer를 위한 transit만 제공
- **경로 계산**: O(|V|+|E|) 알고리즘적 시뮬레이션 (Gill et al. 2012)
- **검증**: LP와 SP를 만족하는 모든 경로의 합집합 사용 (65-85% 정확도, Anwar et al. 2015)
- **Sibling AS 탐지**: Anwar et al. (2015) 기법 활용

### 3.3 실험 설정

- **10개국**: BR, CN, DE, ES, FR, GB, IR, IT, RU, US
  - Tor 사용자 수와 Freedom House 인터넷 자유도 지수 교차 고려
- **웹사이트**: 각 국가별 200개 (Alexa Top 100 + Citizen Lab sensitive 100)
- **5가지 실험** (E1~E5):

| 실험 | 질문 | 설정 |
|------|------|------|
| **E1** | 비대칭 상관 공격에 회로가 얼마나 취약? | VPN, Live (3 guards) |
| **E2** | 각 국가에서 공격자 없는 경로가 몇 개나 가용? | 100 ASes/국가, Simulation |
| **E3** | Sibling AS 공모의 위협은? | VPN, Live (3 guards) |
| **E4** | State-level 적대자의 위협은? | VPN, Live (3 guards) |
| **E5** | Guard 수가 안전 경로 가용성에 영향? | 100 ASes/국가, Simulation |

### 3.4 Astoria 설계

Astoria는 AS-aware이면서 용량(capacity)-aware한 Tor 클라이언트:

**핵심 알고리즘 — Linear Program (LP):**
- 목적: 가장 유리한 적대자의 관찰 확률을 최소화
- 변수: 각 (entry, exit) 쌍의 선택 확률 P_{i,j}
- 제약: 모든 적대자에 대해 관찰 확률 ≤ z, 확률 합 = 1

```
minimize z
subject to: z ≥ Σ_{i,j} (P_{i,j} * X_{i,j,A})  ∀A
            P_{i,j} ∈ [0,1], Σ P_{i,j} = 1
```

**회로 구성 절차:**
1. 안전한 (entry, exit) 조합이 있으면 → 대역폭 분포(D_bw)에 따라 선택 (부하 분산)
2. 안전한 조합이 없으면 → LP 분포(D_lp)에 따라 선택 (적대자 정보 최소화)

**설계 목표 5가지:**
1. 비대칭 공격자 방어
2. 공모 공격자 방어 (sibling AS, state-level)
3. 최악의 경우에도 적대자 정보 최소화 (LP)
4. 성능 영향 최소화
5. 네트워크 부하 분산 (good citizen)

**구현 세부사항:**
- IP→ASN 오프라인 매핑 (9MB DB 다운로드, 목적지 노출 없음)
- 목적지별 on-demand 회로 구성 (pre-construction 불가)
- 경로 캐싱으로 성능 개선

---

## 4. 주요 결과

### 4.1 Vanilla Tor 취약성 측정

**E1: 비대칭 상관 공격 취약성**

| 메트릭 | Vanilla Tor | Uniform Tor |
|--------|-------------|-------------|
| 취약 웹사이트 (메인 요청) | **37%** | 35% |
| 취약 웹사이트 (모든 요청) | 53% | 69% |
| 취약 회로 (전체) | **40%** | 39% |

- 국가별 편차 큼: CN, RU, US가 가장 취약 (로컬 콘텐츠 비율 높음)
  - US 95%, RU 57%, CN 47% 요청이 국내 AS로 향함
- Vanilla Tor는 회로 재사용으로 "완전 안전 or 거의 전부 취약"한 양극화 패턴

**E2: 안전 경로 가용성**
- CN, IR이 가장 위험: source-destination 쌍의 **8%**가 안전 옵션 10% 미만
- **18%**의 source-destination 쌍은 알려진 공격자 없음 → 국가 내에서도 비균일
- Alexa Top 100 로컬 사이트가 Citizen Lab 사이트보다 안전 옵션 적음 (로컬 호스팅)
- CN, IR에서 source-destination 쌍의 **8% 이상**이 안전 회로 옵션 5% 미만

**E3: Sibling AS 공모 영향**
- 전체적으로 **3% 추가** 웹사이트만 취약 → 영향 미미
- 단, BR과 DE는 **8-10% 증가** (Telefonica, Durand 등 대형 통신 그룹)
- 전체: 42% 회로 취약 (sibling 포함)

**E4: State-level 적대자**
- **82%** 웹사이트의 메인 페이지가 취약 회로로 전송
- **85%** 전체 회로 취약
- BR, CN, FR, IR, US: **95% 이상** 메인 요청 취약

**E5: Guard 수의 영향**
- Guard 1개: source-destination 쌍의 **15% 이상**이 안전 옵션 0개
- Guard 2~3개: 차이 미미
- **핵심 발견**: relay-level 방어 (guard 줄이기)와 network-level 방어가 **상충**
  - guard 적으면 relay 공격에 강하나 network 공격에 약함

### 4.2 Astoria 보안 성능

| 적대자 유형 | 메트릭 | Vanilla Tor | Astoria |
|-----------|--------|-------------|---------|
| **Network-level (E1)** | 취약 웹사이트 (메인) | 37% | **3%** |
| | 취약 웹사이트 (모든) | 53% | **8%** |
| | 취약 회로 (전체) | 40% | **2%** |
| **Colluding (E3)** | 취약 웹사이트 (메인) | 40% | **6%** |
| | 취약 웹사이트 (모든) | 56% | **13%** |
| | 취약 회로 (전체) | 42% | **5%** |
| **State-level (E4)** | 취약 웹사이트 (메인) | 82% | **27%** |
| | 취약 웹사이트 (모든) | 88% | **34%** |
| | 취약 회로 (전체) | 85% | **25%** |

- BR, FR, IR에서는 network-level 메인 요청 위협 **완전 제거**
- DE에서 sibling 공모 시 취약 회로 증가 → LP로 정보 최소화

### 4.3 Astoria 성능 평가

| 메트릭 | Vanilla Tor | Astoria | Uniform Tor |
|--------|-------------|---------|-------------|
| **중앙값 페이지 로드** | 5.9초 | **8.3초** | 15.6초 |

- 성능 저하 원인: (1) pre-construction 불가, (2) 경로 예측 오버헤드
- **부하 분산**: Vanilla Tor와 동등 수준 — 보안 향상이 부하 불균형 없이 달성
- **경로 예측 오버헤드**: 50% 사이트에서 무시할 수준 (캐시 히트), 86% 사이트에서 4초 미만

### 4.4 Middle-relay 위협 분석

- Astoria가 AS-aware 회로를 구성하므로 middle-relay가 (source, destination) 쌍을 추론할 가능성
- 통계적 분석 결과: 완전 de-anonymization 확률이 **10^{-13} ~ 10^{-22}** 수준으로 **무시 가능**
- 가장 높은 대역폭 릴레이의 middle 선택 확률 0.007 기준으로도 극히 낮음

---

## 5. 방어 제안 / 완화 전략

### 5.1 Astoria의 핵심 방어 메커니즘

| 메커니즘 | 설명 |
|---------|------|
| **AS-aware relay selection** | forward + reverse path 양쪽의 공통 AS 회피 |
| **LP 기반 확률적 선택** | 안전 경로 없을 때 적대자 관찰 확률 최소화 |
| **Sibling AS 탐지** | 동일 조직 AS 간 공모 방어 |
| **대역폭 기반 부하 분산** | 안전 경로 중 relay 용량 비례 선택 |
| **On-demand circuit construction** | 목적지 AS별 맞춤 회로 구성 |

### 5.2 Guard 설정 권고

- Guard 1개는 network-level 공격에 매우 취약 → **2~3개 guard 유지** 권장
- Guard 수 감소는 relay-level 방어에 유리하나 network-level 방어와 **상충**

### 5.3 향후 방어 방향

- 실시간 BGP hijack 탐지 시스템 (Argus 등) 통합으로 RAPTOR 공격 대응
- Reverse Traceroute 등 정밀 경로 측정 도구 통합
- 안전 경로 임계값(threshold) 설정: relay-level vs network-level 방어 균형

---

## 6. 프로젝트 연관성

이 논문은 본 프로젝트(project-tor)의 **Astoria 방어 구현의 직접적 근거**:

| 논문 개념 | 프로젝트 구현 |
|----------|-------------|
| AS-level 적대자 모델 (Single, Colluding, State-level) | `next-simulate/internal/observer/` — 4종 적대자 모델 (SingleAS, Colluding, StateLevel, Tier1) |
| 비대칭 라우팅 (forward + reverse path) | `next-simulate/internal/asgraph/path.go` — 비대칭 경로 추론, A→B ≠ B→A |
| AS 토폴로지 + Gao-Rexford 라우팅 정책 | `next-simulate/internal/asgraph/` — CAIDA 기반 AS 그래프, customer-provider/peer 관계 |
| 3-hop 회로 구성 + 대역폭 가중치 선택 | `next-simulate/internal/circuit/` — Guard/Middle/Exit 대역폭 가중치 기반 확률적 선택 |
| **Astoria 방어**: entry/exit transit AS 교집합 검사 | `next-simulate/internal/defense/astoria.go` — AS 교집합 검사 기반 안전 회로 선택 |
| LP 기반 확률적 릴레이 선택 | `next-simulate/internal/defense/` — Astoria 안전 경로 없을 시 최적화 |
| Sibling AS 공모 | `configs/bgp_attack.yaml` — Colluding 적대자 모델로 시뮬레이션 |
| State-level 적대자 (국가 내 모든 AS) | `configs/bgp_attack.yaml` — StateLevel 적대자 모델 |
| 회로 취약성 정량 측정 (%) | `tor-anal/analysis/` — 상관율 계산, 방어 전/후 비교, 6종 시각화 |
| 10개국 지역별 위협 차이 | `tor-anal/output/as_geo_map.json` — ASN → 국가 코드 매핑 |
| 대역폭 기반 부하 분산 | `next-simulate/internal/circuit/` — consensus 대역폭 가중치 반영 |
| Counter-RAPTOR와의 비교 | `configs/counter_raptor_defense.yaml`, `configs/combined_defense.yaml` — CR + Astoria 조합 시뮬레이션 |

### 본 논문과 RAPTOR (Sun et al. 2015), Users Get Routed (Johnson et al. 2013)의 관계

| 논문 | 초점 | 적대자 유형 |
|------|------|-----------|
| **Users Get Routed** (2013) | 시간 경과에 따른 수동적 관찰 위험 정량화 | 릴레이 + AS/IXP (수동적) |
| **RAPTOR** (2015) | BGP hijack/interception을 통한 능동적 경로 조작 | AS (능동적) |
| **본 논문** (2016) | 비대칭 라우팅 포함 위협 측정 + **Astoria 방어 클라이언트** | AS/Sibling/State-level (수동적) |

- 프로젝트는 세 논문의 위협 모델을 모두 통합:
  - M5: RAPTOR의 BGP hijack/interception
  - M6: Counter-RAPTOR (RAPTOR 방어) + Astoria (본 논문 방어)
  - `configs/combined_defense.yaml`: Counter-RAPTOR + Astoria 동시 적용

---

## 7. 한계 및 후속 연구

- **능동적 BGP 공격 미대응**: Astoria는 정적 경로 속성만 고려, BGP hijack/interception 같은 동적 공격 미방어
  - → 실시간 BGP hijack 탐지 (Argus) 통합 계획 언급
- **경로 예측 정확도 한계**: LP+SP 모델이 실측 경로의 65-85%만 포괄 → "추정값"
  - Juen et al. (2015)도 BGP 기반 예측과 traceroute 기반 예측의 괴리 지적
- **IXP 미포함**: 과대 추정 방지를 위해 제외했으나, IXP도 상관 공격 가능
- **Relay-level vs Network-level 방어 상충**:
  - Guard 수 감소 → relay 공격 방어 ↑, network 공격 방어 ↓
  - 안전 옵션 부재 시 relay-level 공격 취약 (적대자가 "안전한" AS에 릴레이 배치)
  - 임계값 결정이 미해결 연구 문제
- **Pre-construction 불가**: 목적지별 on-demand 회로 → 성능 저하 불가피 (5.9초 → 8.3초)
- **2015년 데이터 기반**: Tor 네트워크 및 AS 토폴로지가 시간에 따라 변화
- **단일 VPN vantage point**: Live 실험이 국가 내 특정 위치에 한정 (시뮬레이션으로 보완)
- Hidden Service, Bridge 미고려

---

## 8. 참고 수치 요약

```
Vanilla Tor 취약성:
  - 전체 회로 취약률: 40% (single AS), 42% (colluding), 85% (state-level)
  - 웹사이트 취약률 (메인 요청): 37% (single AS), 40% (colluding), 82% (state-level)
  - CN에서 최대 86% 회로, 56% 메인 요청 취약 (colluding)
  - CN/IR에서 8% 요청이 가능 회로의 95% 이상이 취약

Astoria 방어 효과:
  - 취약 회로: 40% → 2% (single AS), 42% → 5% (colluding), 85% → 25% (state-level)
  - 취약 웹사이트 (메인): 37% → 3% (single AS), 40% → 6% (colluding), 82% → 27% (state-level)

성능:
  - 중앙값 페이지 로드: Vanilla 5.9초, Astoria 8.3초, Uniform 15.6초
  - 경로 예측: 86% 사이트에서 4초 미만
  - 부하 분산: Vanilla Tor와 동등 수준

Guard 설정 영향:
  - 1 guard: 15% 이상 source-destination 쌍에 안전 옵션 없음
  - 2 vs 3 guards: 차이 미미

Middle-relay 위협:
  - 완전 de-anonymization 확률: 10^{-13} ~ 10^{-22} (무시 가능)

실험 규모:
  - 10개국, 각 200 웹사이트 (Alexa 100 + Citizen Lab 100)
  - 시뮬레이션: 국가별 100 source AS
  - ~6,000 Tor 릴레이, ~1,000 exit 릴레이
```
