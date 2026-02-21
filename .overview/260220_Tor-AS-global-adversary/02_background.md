# 02. 연구 배경

## Tor 프로토콜 기초

### 3-hop 회로 구조

Tor는 사용자의 트래픽을 3개의 릴레이를 통해 중계하여 익명성을 보장한다:

```
Client ──→ Guard ──→ Middle ──→ Exit ──→ Destination
  (1)        (2)       (3)       (4)        (5)

(1) Client: 사용자의 Tor 클라이언트
(2) Guard:  첫 번째 릴레이 — 클라이언트의 IP를 알지만 목적지는 모름
(3) Middle: 중간 릴레이 — 양쪽 모두 모름
(4) Exit:   마지막 릴레이 — 목적지를 알지만 클라이언트는 모름
(5) Destination: 최종 서버
```

- 각 hop 사이에 TLS + 셀 암호화 계층이 적용되어 단일 릴레이로는 전체 경로를 파악할 수 없다.
- 셀(cell)은 고정 512 bytes 크기로 전송되어, 패킷 크기 기반 트래픽 분석을 어렵게 한다.

### Guard 선택

Guard는 Tor 보안의 핵심이다. 클라이언트는 소수의 Guard를 장기간(30~60일) 유지한다:

- **Guard 샘플**: 최대 60개 후보 중 대역폭 가중치 기반 확률적 선택
- **Primary Guard**: 실제 사용하는 Guard (최대 3개)
- **수명 관리**: Proposal 271에 따라 30~60일 후 교체
- **가중치 행렬**: Wgg, Wgm, Wee, Weg 등 7개 가중치로 Guard/Middle/Exit 각 위치의 선택 확률 결정

### Exit 및 Middle 선택

- **Exit**: 대역폭 가중치 기반 확률적 선택 (Guard AS와 동일 AS 제외)
- **Middle**: Guard, Exit과 모두 다른 AS에서 선택
- **MaxCircuitDirtiness**: 10분마다 회로를 교체하여 장기 추적 방지

---

## AS-Level 위협 모델

### Transit AS와 트래픽 관찰

인터넷의 모든 트래픽은 AS(Autonomous System) 간 경로를 따라 전달된다. 특정 AS가 Tor 회로의 **진입 경로**(Client → Guard)와 **출구 경로**(Middle → Exit)를 모두 경유한다면, 해당 AS는 트래픽의 타이밍·볼륨을 상관하여 사용자를 식별할 수 있다:

```
Client_AS ──[transit AS X]──→ Guard_AS ──→ Middle_AS ──[transit AS X]──→ Exit_AS
                 ↑                                          ↑
                 └── 동일 AS가 양쪽 모두 관찰 → 상관 가능 ──┘
```

### 비대칭 경로 (RAPTOR 핵심)

실제 인터넷에서 A→B 경로와 B→A 경로는 다를 수 있다. AS 라우팅 정책(provider-customer, peer 관계)에 따라 uphill/downhill 분해가 방향별로 달라지기 때문이다. 이 비대칭성은 관찰 기회를 증가시킨다:

- **대칭 경로만 고려 시**: AS X가 entry에만 존재
- **비대칭 경로 고려 시**: AS X가 entry와 exit 모두 존재 가능 → 상관 기회 증가

RAPTOR(2015)는 비대칭 라우팅 고려 시 위협이 ~50% 증가한다고 보고했다.

### Valley-Free Routing

AS 간 경로는 "valley-free" 규칙을 따른다:

```
customer → provider (uphill)
provider → provider (peer, 최대 1번)
provider → customer (downhill)

유효 경로: uphill* → peer? → downhill*
무효 경로: downhill → uphill (valley)
```

본 시뮬레이터는 이 규칙을 BFS 기반으로 구현하여 현실적인 AS 경로를 계산한다.

---

## 관련 논문 정리 (7편)

### 1. Johnson et al. (2013) — 기준선

**"Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries"**, CCS 2013

- **핵심**: 현실적 AS-level 적대자가 vanilla Tor 회로의 **40%를 취약**하게 만든다.
- **방법**: AS 토폴로지 위에서 entry/exit 동시 관찰 확률 계산
- **의의**: AS-level 위협 연구의 기준선(baseline)을 수립. 이후 모든 방어 논문이 이 수치를 참조한다.

### 2. RAPTOR — Sun et al. (2015)

**"RAPTOR: Routing Attacks on Privacy in Tor"**, USENIX Security 2015

- **핵심**: BGP hijack/interception으로 **능동적 경로 조작**이 가능. 비대칭 라우팅 고려 시 위협 50% 증가.
- **공격 유형**:
  - BGP Hijack: 대상 Guard의 prefix를 announce → 모든 트래픽 탈취
  - BGP Interception: 대상을 경유하되 정상 전달 (은밀)
- **의의**: 수동 관찰 외에 능동적 BGP 공격이라는 새로운 위협 벡터를 제시.

### 3. Astoria — Nithyanand et al. (2016)

**"Measuring and Mitigating AS-level Adversaries Against Tor"**, NDSS 2016

- **핵심**: entry/exit transit AS 교집합이 없는 회로만 선택하는 **AS-aware 회로 생성**.
- **효과**: 취약 회로를 40% → **2%** (단일 AS 적대자)로 감소.
- **방법**: 회로 생성 시 transit AS 교집합 검사 → 교집합 있으면 재시도 (최대 N회)
- **의의**: 가장 효과적인 AS-level 방어 전략 중 하나.

### 4. Counter-RAPTOR — Sun et al. (2017)

**"Counter-RAPTOR: Safeguarding Tor Against Active Routing Attacks"**, IEEE S&P 2017

- **핵심**: Guard 선택 시 **resilience(BGP 회복탄력성)** 가중치를 적용.
- **수식**: `P(Guard_j) = bandwidth_j × (1/p_entry_j)^weight_factor`
- **효과**: 평균 36%, 최대 166% 보안 개선 (Guard 선택 수준에서)
- **의의**: BGP 공격에 특화된 Guard 선택 방어. Astoria와 직교하는 접근.

### 5. Tempest — Wails et al. (2018)

**"Tempest: Temporal Dynamics in Anonymity Systems"**, PETS 2018

- **핵심**: 시간 경과에 따른 **BGP churn(경로 변동)이 관찰 범위를 축적**한다.
- **발견**: 연간 48% edge 변동 → 장기간 관찰 시 익명성 점진적 약화
- **의의**: 정적 분석으로는 파악할 수 없는 시간적 위협을 정량화.

### 6. SICO — Barton et al. (2019)

**"Towards Measuring Interdomain Routing Attacks on Tor"**, HotPETs 2019

- **핵심**: BGP community 속성을 이용한 **정밀 interception** 공격.
- **의의**: 기존 hijack/interception보다 더 은밀하고 정밀한 공격 가능성 제시.

### 7. DeNASA — Barton & Wright (2016)

**"DeNASA: Destination-Naive AS-Awareness in Anonymous Communications"**, PoPETs 2016

- **핵심**: 목적지를 모르는 상태에서도 AS-aware 선택이 가능한 **destination-naive** 방어.
- **의의**: Astoria가 목적지 정보를 필요로 하는 한계를 보완.

---

## Tor 역공학 요약

본 시뮬레이터에 적용한 핵심 파라미터는 Tor 소스 코드(C)의 역공학 분석에서 도출했다.

### 클라이언트 파라미터 (출처: `reverse-engineer/00_final_report.md`)

| 카테고리 | 파라미터 | 값 |
|----------|----------|-----|
| 노드 선택 | 가중치 행렬 | Wgg=0.5869, Wgm=1.0, Wee, Weg, Wmg, Wme, Wmd |
| Guard 관리 | 샘플 크기 | 60~200 |
| Guard 관리 | 수명 | 30~60일 |
| Guard 관리 | Primary Guard 수 | 3개 |
| 타이밍 | CBT (Circuit Build Timeout) | Pareto 분포 (α=1.8, Xm=1.8s) |
| 타이밍 | MaxCircuitDirtiness | 10분 |
| 실패 처리 | 재시도 횟수 | 설정 기반 |

### Hidden Service 파라미터 (출처: `reverse-engineer/18_hs_final_report.md`)

| 카테고리 | 파라미터 | 값 |
|----------|----------|-----|
| Introduction Point | IP 수 | 3~20개 |
| HSDir | HSDir 노드 수 | 6개 |
| HS 주기 | Descriptor 갱신 | 24시간 |
| 동기화 | SRV (Shared Random Value) | 합의 기반 |

---

## 구 시뮬레이터 (onion-simulate)

프로젝트 초기에 `onion-simulate`라는 Go 기반 시뮬레이터를 개발했다. 이 시뮬레이터는 goroutine 기반 메시지 전달 모델로 Tor 프로토콜을 모방했으나, 다음과 같은 한계가 있었다:

- **AS-level 모델링 부족**: 패킷 전달 수준에서 동작하여 AS-level 관찰 판정이 어려웠음
- **역공학 파라미터 미적용**: Guard 수명, 가중치 행렬 등 실제 Tor 파라미터가 반영되지 않음
- **시뮬레이션 시간 불명확**: 이벤트 기반이 아닌 goroutine 기반이라 시간 경과 제어가 불안정

이러한 한계를 극복하기 위해 `next-simulate`를 AS-level 이벤트 드리븐 아키텍처로 재설계했다. `onion-simulate`는 참조용으로 유지하되 더 이상 개발하지 않는다.
