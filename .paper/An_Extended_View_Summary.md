# An Extended View on Measuring Tor AS-level Adversaries

**요약 작성일**: 2026-02-21
**원문**: Gegenhuber, Maier, Holzbauer, Mayer, Merzdovnik, Weippl, Ullrich (Computers & Security, 2023)
**소속**: University of Vienna / SBA Research / Christian Doppler Laboratory
**DOI**: 10.1016/j.cose.2023.103302

---

## 1. 핵심 기여 (One-line)

RIPE Atlas 프레임워크(11,000+ 프로브)를 활용한 **실측 기반 traceroute**로 Tor AS-level 적대자의 트래픽 상관 가능성을 정량화하고, 2020→2022 시간 변화, IPv6 영향, 러시아 검열 시나리오를 분석한 논문.

---

## 2. 연구 동기

- 기존 연구(Feamster & Dingledine 2004, Edman & Syverson 2009, Nithyanand et al. 2016)는 **BGP 업데이트와 경로 예측**에 의존 → BGP 기반 접근은 위험을 **과대평가**하는 것으로 알려짐 (Juen et al. 2015)
- 실측(traceroute)이 더 신뢰성 있지만, 측정 노드 부족으로 "infeasible"하다는 가정이 있었음
- **RIPE Atlas 프레임워크**(11,000+ 프로브, 3,600+ AS 배치)의 등장으로 이 가정이 더 이상 유효하지 않음
- 선행 연구(Mayer et al. 2020)에서 독일/미국 IPv4 클라이언트에 대한 측정 방법론을 개발
- 본 논문은 이를 확장하여:
  - (a) 2020→2022 시간 변화 관찰
  - (b) **IPv6** 환경에서의 위협 분석 (최초)
  - (c) **러시아** 검열 강화 상황에서의 익명성 분석

---

## 3. 방법론

### 3.1 위협 모델 (Threat Model)

- **수동적 AS-level 관찰자**: client→guard 경로(entry path)와 exit→destination 경로(exit path) 양쪽에 동시 존재하면 트래픽 상관 공격 가능
- Sun et al. (2015, RAPTOR)의 역방향 경로(reverse path) 상관도 고려 → forward/reverse 양방향 traceroute 측정

### 3.2 RIPE Atlas 기반 능동 측정

4방향 ICMP traceroute 측정:
1. **D1**: Client AS → Guard relay AS (모든 client에서)
2. **D2**: Exit relay AS (프로브 보유) → Destination AS
3. **D3**: Destination AS → Exit relay AS (역방향)
4. **D4**: Guard relay AS (프로브 보유) → Client AS (역방향)

커버리지 (IPv4 기준):
- D1: 100%, D2: ~43%, D3: 100%, D4: ~80% (경로 확률 기준)
- IPv6: D1: 100%, D2: ~52%, D3: 100%, D4: ~85%

### 3.3 데이터 소스

| 데이터 소스 | 용도 |
|-----------|------|
| Tor consensus (onionoo) | 릴레이 IP, 플래그, 대역폭, guard/exit 확률 |
| RIPE Atlas 프로브 통계 | AS 매핑, 프로브 선택 |
| ip2asn 데이터베이스 | IP → ASN 매핑 |
| RIPE Atlas traceroute 결과 | 실제 경로 측정 |
| Tranco top sites list | 목적지 AS 결정 |

### 3.4 클라이언트/목적지 AS 선정

- **클라이언트**: 독일/미국/러시아 각각 RIPE Atlas 프로브가 가장 많은 10개 AS
- **목적지 (Tranco)**: Tranco top 100(IPv4) / top 250(IPv6) 도메인 → AS 변환 → RIPE 프로브 보유 AS만 선택
- **목적지 (러시아 차단)**: Roskomnadzor 차단 웹사이트 목록 → 러시아/우크라이나 소재 AS 필터링

### 3.5 상관 확률 계산

- 각 traceroute에서 경유하는 모든 AS를 해당 경로의 guard/exit 확률로 표시
- Entry side: D1 + D4 결합, Exit side: D2 + D3 결합
- **P_guard ∩ P_exit**: entry와 exit 양쪽에 동시 출현하는 AS의 결합 확률

---

## 4. 주요 결과

### 4.1 Tor 네트워크 현황 (2020 vs 2022)

| 지표 | 2020 | 2022 | 변화 |
|------|------|------|------|
| 전체 릴레이 | 6,509 | 6,559 | +1% |
| Exit 릴레이 | 1,000 | 1,597 | **+60%** |
| Guard 릴레이 | 2,415 | 2,272 | -6% |
| 전체 대역폭 | 418 Gbit/s | 694 Gbit/s | **+66%** |
| Exit AS 다양성 | 275 | 222 | **-19%** |
| Guard AS 다양성 | 470 | 469 | -0% |

핵심 관찰:
- 네트워크 규모와 대역폭은 성장했으나 **AS 다양성은 감소** (중앙집중화)
- IPv4 기준 **5개 AS가 exit 확률 50% 이상**, **6개 AS가 guard 확률 50% 이상** 차지
- IPv6: **3개 AS만으로 guard/exit 확률 50% 이상** (더 심각한 중앙집중화)
- 독일+미국이 전체 릴레이의 **47% 이상** 차지
- 러시아는 릴레이 297개→65개로 급감 (6위→18위)

### 4.2 IPv6 지원 현황

| 지표 | 전체 | IPv6 | 비율 |
|------|------|------|------|
| 릴레이 | 6,559 | 2,924 | 45% |
| Exit 릴레이 | 1,597 | 1,083 | 68% |
| Guard 릴레이 | 2,272 | 951 | 42% |
| Exit 대역폭 | 181 Gbit/s | 128 Gbit/s | 71% |

### 4.3 Entry Path (클라이언트→Guard) 결과

주요 중간 경유 AS (모든 국가에서 일관):
- **AS174 COGENT**, **AS1299 TWELVE99**, **AS3356 LEVEL3** — 거의 모든 클라이언트 AS에서 경로에 출현
- 2020→2022: 전반적 구도 변동 없음, 일부 AS 진입/퇴출 (AS1200 AMS-IX1 사라짐, AS44530 HOPUS 새로 등장)
- IPv4 vs IPv6: **AS6939 HURRICANE**이 미국 IPv6에서 지배적, AS174/AS1299/AS3257은 IPv6에서 빈도 감소
- 국가별 차이: 미국이 고확률 transit AS를 경유하는 비율이 가장 높음 → 미국 라우팅이 더 중앙집중적

### 4.4 Exit Path (Exit→목적지) 결과

**Tranco 목적지:**
- 2020→2022: 전반적으로 유사, AS6461 ZAYO/AS1200 AMS-IX1 사라짐
- IPv6에서 대부분 AS의 최대 확률이 IPv4보다 낮음, 단 **AS6939 HURRICANE**은 IPv6에서 더 강함
- 5개 새 AS 발견

**러시아 차단 웹사이트:**
- Tranco 결과와 유사한 AS 패턴, 유일한 예외: **AS3223 VOXILITY** (UK 인프라 제공자)
- 차단 웹사이트로의 exit 경로에 등장하는 AS는 모두 **서방 기업** (미국, 스웨덴, 영국, 오스트리아, 독일)

### 4.5 트래픽 상관 가능 AS (Entry + Exit 결합)

**단일 클라이언트/목적지 예시** (AS1764 NEXTLAYER → AS24940 HETZNER):
- HETZNER: P_guard = 0.224, P_exit = 1.000 → **P = 22.4%** 상관 가능

**전체 결과:**

| AS | 역할 | 2020 IPv4 P& | 2022 IPv4 P& | 2022 IPv6 P& |
|----|------|-------------|-------------|-------------|
| AS24940 HETZNER | 목적지+Guard 호스팅 | 0.199 | 0.224 | **0.350** |
| AS1200 AMS-IX1 | Transit | 0.012 | — | — |
| AS16276 OVH | Transit | 0.010 | — | — |
| AS6939 HURRICANE | Transit | — | — | 0.034 |
| AS47147 AS-ANX | Transit | — | — | 0.024 |

**HETZNER의 이중 역할 문제:**
- 목적지 호스팅(주요 웹사이트) → exit path에 높은 확률로 등장
- Guard 대역폭의 **22.4%** 차지 → entry path에 높은 확률로 등장
- HETZNER 기반 guard 릴레이 운영자가 발견: 릴레이 트래픽의 **15%가 같은 AS 내 릴레이로 전달**
- IPv6에서 guard 릴레이 후보 감소 → HETZNER의 guard 확률이 **35%로 증가**

**러시아 사용자:**
- 독일/미국 사용자보다 **상관 위험이 낮음**
- 상관 가능한 소수의 AS는 모두 서방 기업이 운영 → 러시아 국가 행위자의 위협 더욱 감소
- 지역 공격자(국가 수준)는 로컬 Tor 클라이언트의 entry/exit 패킷을 매칭할 수 **없는 것으로 판단**

### 4.6 핵심 발견 요약

1. **시간적 안정성**: 2020→2022 전반적 구도 변동 없음, Tor는 일관된 품질의 익명성 제공
2. **프로토콜 독립성**: IPv4 vs IPv6 — 유의미한 차이 없음
3. **러시아 안전**: 러시아 사용자의 비익명화 위험은 서방 민주주의 국가보다 **오히려 낮음**
4. **중앙집중화 문제**: 소수 AS(특히 HETZNER)의 이중 역할이 가장 큰 위협
5. **실측 vs BGP 예측**: 능동 traceroute가 BGP 기반 예측보다 더 현실적인 위험 추정 제공

---

## 5. 방어 제안

| 제안 | 설명 |
|------|------|
| **Guard/Exit 릴레이 배치 최적화** | Guard는 클라이언트에 가까운 ISP에, Exit는 목적지에 가까운 데이터센터에 배치 → HETZNER은 exit 운영에 적합, guard 운영은 비최적 |
| **AS 다양성 증대** | Tor 릴레이 분포가 편중되어 있음 → 더 다양한 AS에 릴레이 배치 필요 |
| **AS-aware 회로 선택** | 목적지 AS를 경로 선택에 반영하여 HETZNER 같은 이중 역할 AS 회피 (단, 클라이언트 위치 노출 위험 존재) |
| **RIPE Atlas 프로브 추가** | Exit 릴레이 AS에 프로브 5개만 추가해도 exit 확률 커버리지 43%→81%로 증가 |
| **대형 릴레이 운영자의 측정 참여** | 오픈소스 코드를 활용하여 자체 측정 수행 권장 |

---

## 6. 프로젝트 연관성

이 논문은 본 프로젝트의 **실측 기반 검증 참조 논문**:

| 논문 개념 | 프로젝트 구현 |
|----------|-------------|
| AS-level 적대자 모델 (수동적 관찰) | `next-simulate/internal/asgraph/` — AS 그래프, 관계 모델링 |
| Entry/Exit path 확률 계산 | `next-simulate/internal/circuit/` — 3-hop 회로 생성, Guard/Exit 대역폭 가중치 |
| AS 경로 추론 (traceroute 기반) | `next-simulate/internal/asgraph/path.go` — AS 경로 추론 (본 논문은 실측, 프로젝트는 시뮬레이션) |
| 4종 적대자 모델 | `configs/bgp_attack.yaml` — SingleAS, Colluding, StateLevel, Tier1 |
| Guard/Exit 확률 분포 | `tor-anal/output/as_path_probabilities.json` — AS별 p_entry/p_exit |
| AS 다양성 분석 (릴레이 분포 편중) | `tor-anal/output/as_model_simplified.json` — 727 AS 노드 + guard/exit 가중치 |
| 러시아 검열 시나리오 | `configs/` — StateLevel 적대자로 국가 수준 공격 시뮬레이션 가능 |
| IPv4/IPv6 비교 | 현재 미구현 (IPv4만 지원) — 향후 확장 가능 |
| HETZNER 이중 역할 문제 | `next-simulate/internal/defense/` — Counter-RAPTOR/Astoria가 이런 중앙집중화 위험을 부분적으로 완화 |
| 시간 안정성 (2020 vs 2022) | `next-simulate/internal/asgraph/temporal.go` — CAIDA 스냅샷 기반 동적 토폴로지 전환으로 시간 변화 시뮬레이션 |

### 본 논문과 RAPTOR (Sun et al. 2015)의 차이

| 비교 항목 | An Extended View (본 논문) | RAPTOR |
|---------|------------------------|--------|
| 적대자 유형 | **수동적** AS-level 관찰자 | **능동적** BGP 공격자 (hijack/interception) |
| 방법론 | **실측** (RIPE Atlas traceroute) | **시뮬레이션** + BGP 경로 예측 |
| 경로 추론 | 실제 패킷이 이동하는 경로 관찰 | BGP 테이블 기반 경로 추론 (과대평가 가능) |
| 시간 분석 | 2020→2022 스냅샷 비교 | 단일 시점 |
| 프로젝트 구현 | 네트워크 적대자 관찰 모델 | M5: BGP 공격 시뮬레이션 |

### 본 논문과 Users Get Routed (Johnson et al. 2013)의 차이

| 비교 항목 | An Extended View | Users Get Routed |
|---------|-----------------|-----------------|
| 경로 결정 | **실측** (traceroute) | **시뮬레이션** (TorPS + BGP/Qiu 알고리즘) |
| 적대자 | AS-level 중간 경유자 | 릴레이 + AS + IXP + IXP 조직 |
| 시간 모델 | 2개 스냅샷 비교 | 시간 경과에 따른 침해 확률 CDF |
| 국가 | 독일, 미국, 러시아 | 위치 무관 (글로벌) |
| IPv6 | 최초 IPv6 분석 | IPv4만 |

---

## 7. 한계 및 후속 연구

- **RIPE Atlas 커버리지 제한**: 서방 국가 커버리지 양호(독일 92%, 미국 86%), 러시아 26%(2020년 60%에서 하락)
- **클라이언트/목적지 AS 선정의 한계**: 모든 AS를 측정할 수 없어 서브셋으로 제한, 실제 Tor 사용자 분포와 차이 가능
- **적대자 세분화 미흡**: 단일 AS 단위만 분석, 한 조직이 여러 AS를 통제하는 경우 확률 누적 필요, 국가 수준 강제 협력 미고려
- **단일 traceroute**: AS 쌍당 1회 traceroute만 실행 → 동일 AS 내 다른 프리픽스/지역에서의 경로 변동 미반영
- **단순화된 Tor 모델**: 공개 guard/exit 릴레이만 고려, pluggable transports (obfs4 bridges, Snowflake proxies) 미포함
- **IXP 미분석**: AS 수준만 분석, IXP(인터넷 교환점) 수준의 적대자는 제외
- **중국 후속 연구 가능**: RIPE Atlas 커버리지 83%로 양호, 향후 연구 대상

---

## 8. 참고 수치 요약

```
Tor 네트워크 (2022년 9월):
  - 릴레이: 6,559개 (981 AS에 분포)
  - Exit 릴레이: 1,597개 (222 AS)
  - Guard 릴레이: 2,272개 (469 AS)
  - 총 대역폭: 694 Gbit/s (+66% from 2020)
  - IPv6 지원: 45% 릴레이, 71% exit 대역폭

AS 중앙집중화 (IPv4):
  - 5개 AS → exit 확률 50% 이상
  - 6개 AS → guard 확률 50% 이상
  - 43개 AS → exit 확률 90% 이상

AS 중앙집중화 (IPv6):
  - 3개 AS → guard/exit 확률 각각 50% 이상

HETZNER (AS24940) 이중 역할:
  - Guard 대역폭 비중: 22.4%
  - 트래픽 상관 확률: 22.4% (2022 IPv4) → 35.0% (2022 IPv6)
  - 릴레이 트래픽의 15%가 같은 AS 내부로 전달

러시아 사용자:
  - 검열 우회 시 비익명화 위험: 독일/미국보다 낮음
  - 상관 가능 AS: 모두 서방 기업 운영
  - 지역 공격자(국가)의 entry+exit 매칭: 불가능으로 판단

RIPE Atlas 커버리지:
  - 11,000+ 프로브, 3,600+ AS
  - Guard relay AS 커버리지: ~80%
  - Exit relay AS 커버리지: ~43% (프로브 5개 추가 시 81%로 증가 가능)

국가별 릴레이 분포:
  - 독일+미국: 전체 릴레이의 47% 이상
  - 러시아: 297개(2020) → 65개(2022), 6위→18위로 하락
```
