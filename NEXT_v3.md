# NEXT_v3.md - Tor AS-level 글로벌 관찰자 시뮬레이션 계획

## 최종 목적

Tor 시뮬레이션을 통한 AS-level 글로벌 관찰자 연구 완수

**핵심 질문: "이 시뮬레이션이 실제 Tor 네트워크를 잘 대변하는가?"**

---

## 연구 질문 (Research Questions)

### RQ1: AS-level 글로벌 관찰자가 Tor 트래픽을 얼마나 상관(correlate)할 수 있는가?

- Guard AS와 Exit AS를 동시에 관측할 때의 추적 성공률
- 관측 AS 수에 따른 커버리지 변화
- **홉 간 AS 경로**를 통한 관측 가능성 포함

### RQ2: 특정 AS 위치 (예: IXP)가 추적 성공률에 얼마나 영향을 주는가?

- IXP 위치 AS vs 일반 AS의 관측 효율성 비교
- 지리적 위치(국가, 대륙)에 따른 영향
- Transit AS의 전략적 위치 효과

### RQ3: Hidden Service 트래픽은 일반 트래픽 대비 얼마나 더 추적 가능한가?

- HSDir, Introduction Point 관측의 영향
- 6홉 경로의 추적 난이도 분석
- Vanguard 적용 여부에 따른 차이

---

## 단기 목표

**Tor 시뮬레이션 재작성: `next-simulate`**

Tor의 내부 로직을 모방해 현실성을 높이며, AS-level 단위 관측 및 **홉 간 AS 경로 시뮬레이션**을 추가

---

## 기존 onion-simulate 구현의 문제

| 문제 | 설명 | 영향 |
|------|------|------|
| 현실성 불완전 | 시뮬레이션된 시간, 파라미터 미적용 | 결과 신뢰도 저하 |
| 패킷 전달 불완전 | 단순화된 메시지 전달 | 타이밍 분석 부정확 |
| AS-level 미흡 | 릴레이 AS만 고려, 경로 AS 미고려 | RQ1, RQ2 분석 불가 |
| 역공학 파라미터 미적용 | Tor 실제 동작과 괴리 | 현실성 검증 불가 |

---

## 기술적 목표

### 1. Tor 핵심 로직 모방

#### 1.1 노드 선택 (Node Selection)

**핵심 공식:**
```
P(노드 i 선택) = (bandwidth_kb × weight) / Σ(bandwidth_kb × weight)
```

**가중치 매트릭스:**

| 선택 목적 | Wg (Guard) | Wm (Middle) | We (Exit) | Wd (Guard+Exit) |
|-----------|------------|-------------|-----------|-----------------|
| Guard 선택 | Wgg | Wgm | 0 | Wgd |
| Middle 선택 | Wmg | Wmm | Wme | Wmd |
| Exit 선택 | Weg | Wem | Wee | Wed |

**구현 요구사항:**
- 합의 문서에서 가중치 파라미터 로드
- 대역폭 기반 확률적 선택
- 노드 가족(Family) 제외 규칙
- 동일 /16 서브넷 제외 규칙

#### 1.2 Guard 관리 (Guard Management)

**Guard 상태 전이:**
```
┌─────────────────────────────────────────────────────────────────────┐
│                      Guard 상태 머신                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  [Sampled] ──filter──► [Filtered] ──confirm──► [Confirmed]         │
│                              │                       │              │
│                              ▼                       ▼              │
│                        [Usable]              [Primary]              │
│                              │                       │              │
│                              └───────┬───────────────┘              │
│                                      ▼                              │
│                              [Selected for Circuit]                 │
│                                                                     │
│  Reachability: REACHABLE_YES ←→ REACHABLE_MAYBE ←→ REACHABLE_NO    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Guard 파라미터:**

| 파라미터 | 기본값 | 설명 |
|---------|--------|------|
| guard-max-sample-size | 60-200 | 샘플 최대 크기 |
| guard-lifetime-days | 30-60일 | Guard 수명 |
| guard-n-primary-guards | 3 | Primary 목록 크기 |
| guard-n-primary-guards-to-use | 1 | 우선 사용 Primary 수 |

#### 1.3 회로 생성 (Circuit Creation)

**Circuit Build Timeout (CBT) - Pareto 분포:**
```
타임아웃 = Xm / (1 - quantile)^(1/α)

Xm: 10개 최빈 빈의 가중 평균 (밀리초)
α: Pareto alpha (MLE 추정)
quantile: cbtquantile / 100 (기본 80%)
```

**회로 타이밍 상수:**

| 상수 | 값 | 설명 |
|------|-----|------|
| MaxCircuitDirtiness | 10분 | 회로 재사용 최대 시간 |
| 3홉 타임아웃 | CBT | 기본 회로 구축 |
| 4홉 타임아웃 | CBT × (10/6) | Vanguard, HS 등 |

#### 1.4 Hidden Service (v3)

**HS 아키텍처:**
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Tor v3 Onion Service 연결 흐름                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  [Service]                                                     [Client]    │
│     │                                                              │        │
│     │ 1. 키 생성 (identity → blinded → signing)                    │        │
│     │ 2. 소개점 설정 (ESTABLISH_INTRO)                              │        │
│     │ 3. 디스크립터 업로드 → [HSDir]                                │        │
│     │                          │                                   │        │
│     │                          │◄── 4. 디스크립터 페치 ─────────────│        │
│     │                                                              │        │
│     │                          5. 랑데부 회로 설정 (ESTABLISH_REND) │        │
│     │                                                              │        │
│     │◄──────── 6. INTRODUCE1/2 via IP ─────────────────────────────│        │
│     │                                                              │        │
│     │ 7. 랑데부 회로 빌드 → RENDEZVOUS1 ─────────────────────────►│        │
│     │                                                              │        │
│     │◄═══════════════════ e2e 암호화 통신 ═════════════════════════│        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**HS 시간 파라미터:**

| 상수 | 값 | 용도 |
|-----|-----|------|
| HS_TIME_PERIOD_LENGTH | 24시간 | 시간 주기 길이 |
| HS_TIME_PERIOD_ROTATION_OFFSET | 12시간 | UTC 기준 오프셋 |
| INTRO_POINT_LIFETIME_MIN | 18시간 | IP 최소 수명 |
| INTRO_POINT_LIFETIME_MAX | 24시간 | IP 최대 수명 |
| Descriptor lifetime | 180분 | 디스크립터 유효 시간 |

**HS 노드 수량:**

| 상수 | 값 | 용도 |
|-----|-----|------|
| 소개점 최소 | 3개 | 서비스당 |
| 소개점 최대 | 20개 | 서비스당 |
| HSDir 선택 수 | 6개 | 시간 주기당 |
| HSDir 복제본 | 2개 | hs_index 계산용 |

#### 1.5 Vanguard 지원 (선택적)

**Vanguard 계층 구조:**
```
일반 HS 회로:
  Service → Guard → Middle → IP

Vanguard 적용 시:
  Service → Guard → Vanguard-L2 → Vanguard-L3 → Middle → IP
                    ↑              ↑
            중간 레이어 (AS 분산 효과로 추적 방어)
```

**Vanguard 옵션:**
- `vanguard_enabled: bool` - Vanguard 사용 여부
- `vanguard_l2_lifetime: 1-12시간` - L2 Vanguard 수명
- `vanguard_l3_lifetime: 24-48시간` - L3 Vanguard 수명

---

### 2. 단순화 범위

| 요소 | 실제 Tor | next-simulate | 이유 |
|------|----------|---------------|------|
| 암호화 | AES-CTR + ntor | 생략 (plaintext) | 성능, AS 분석에 불필요 |
| 패킷 크기 | 고정 512 bytes | size 필드만 유지 | 시그니처 보존 |
| 네트워크 전송 | TCP/TLS | 이벤트 기반 메시지 전달 | 성능 |
| 디렉토리 합의 | 1시간마다 갱신 | 정적 또는 설정 기반 | 단순화 |
| ntor 핸드셰이크 | 암호학적 연산 | 지연 시간만 모델링 | 타이밍 보존 |

### 3. 유지해야 할 핵심

| 요소 | 이유 | 현실성 영향 |
|------|------|------------|
| 패킷 셀 구조 (512 bytes) | 트래픽 핑거프린팅 시그니처 | Medium |
| 타이밍 분포 (CBT, 지연) | 상관 분석의 핵심 | **Critical** |
| 3홉 경로 구조 | Tor 기본 아키텍처 | **Critical** |
| Guard 선택 확률 및 지속성 | 장기 추적 성공률에 직접 영향 | **Critical** |
| 대역폭 가중치 기반 선택 | AS 관측 확률 결정 | **Critical** |

---

### 4. AS-level 네트워크 모델링

#### 4.1 노드 세부 정보

```yaml
node_configuration:
  as_number: "AS12345"
  as_type: "Transit" | "Stub" | "IXP"
  region:
    country: "US"
    continent: "NA"
  bandwidth_kb: 10000
  flags: ["Guard", "Exit", "Stable", "Fast"]
```

#### 4.2 AS 관계 모델

**데이터 소스:** CAIDA AS-relationships

**관계 유형:**
- `peer`: 동등 피어링 (P2P)
- `provider-customer`: 제공자-고객 관계 (P2C)

**Valley-Free 라우팅 가정:**
```
허용 경로 패턴:
  Customer* → Peer? → Provider*
  
금지 경로 패턴:
  Provider → Customer → Provider (Valley)
```

#### 4.3 홉 간 AS 경로 시뮬레이션 ⭐ (신규)

**문제 인식:**
기존 계획은 릴레이가 위치한 AS만 모델링했으나, 실제 AS-level 상관 공격은 **홉 간 AS 경로**도 관측함.

```
기존 모델 (불완전):
  Client → [Guard AS] → [Middle AS] → [Exit AS] → Dest
              ↑             ↑             ↑
        이 AS들만 관측 모델링

새 모델 (완전):
  Client ──[AS50]──[AS75]──→ Guard ──[AS110]──→ Middle ──[AS250]──→ Exit
                ↑                    ↑                    ↑
        홉 간 AS 경로도 관측 가능 (IXP, Transit AS)
```

**AS 경로 계산:**
```python
def compute_as_path(src_as: str, dst_as: str, as_graph: ASGraph) -> List[str]:
    """
    Valley-free BGP 경로 시뮬레이션
    
    입력:
      - src_as: 출발 AS
      - dst_as: 도착 AS
      - as_graph: CAIDA 기반 AS 관계 그래프
      
    출력:
      - AS 경로 리스트 (src_as 포함, dst_as 포함)
      
    알고리즘:
      1. BFS/Dijkstra로 valley-free 경로 탐색
      2. 다중 경로 존재 시 최단 경로 선택
      3. 경로 없으면 직접 연결 가정 (fallback)
    """
    pass
```

**관측 포인트 확장:**

| 관측 지점 | 기존 | 신규 |
|----------|------|------|
| Guard AS | ✅ | ✅ |
| Middle AS | ✅ | ✅ |
| Exit AS | ✅ | ✅ |
| Client → Guard 경로 AS | ❌ | ✅ |
| Guard → Middle 경로 AS | ❌ | ✅ |
| Middle → Exit 경로 AS | ❌ | ✅ |
| Exit → Destination 경로 AS | ❌ | ✅ |
| IXP 경유 여부 | ❌ | ✅ |

#### 4.4 IXP 모델링 ⭐ (신규)

**데이터 소스:** PeeringDB API 또는 CAIDA IXPs 데이터셋

**IXP 특성:**
- 여러 AS 간 피어링 허브 역할
- 높은 트래픽 관측 가능성
- RQ2 핵심 분석 대상

**모델링 방식:**
```yaml
ixp_node:
  id: "IXP-DECIX"
  type: "IXP"
  location: "Frankfurt, DE"
  member_ases: ["AS3356", "AS1299", "AS6939", ...]
  observation_capability: "all_member_traffic"
```

#### 4.5 AS-level 관측 정의

**관측 데이터:**
- 타이밍 (timestamp)
- 패킷 방향 (ingress/egress)
- 패킷 크기 (512 bytes 셀)
- 소스/목적지 IP (→ AS 매핑)
- 회로 ID는 암호화되어 직접 확인 불가

**관측 모델:**

| 모델 | 설명 | 구현 |
|------|------|------|
| Passive Observer | 패킷 메타데이터만 관측 | 기본 |
| Active Observer | 패킷 주입/수정 가능 | 선택적 |
| Partial Observer | 특정 AS 집합만 제어 | 기본 |
| Global Observer | 모든 AS 관측 가능 | 상한 분석용 |

---

## 시간 모델 정의 ⭐ (신규)

### 1. 시간 해상도 레벨

| 레벨 | 단위 | 용도 | 적용 이벤트 |
|------|------|------|------------|
| **Micro** | 100ms | 패킷/회로 이벤트 | 셀 전송, CBT 측정, 핸드셰이크 |
| **Meso** | 1분 | 회로 수명 | MaxCircuitDirtiness, 회로 재사용 |
| **Macro** | 1시간 | Guard/HS 주기 | Guard 교체, HS Time Period, HSDir 로테이션 |

### 2. 시뮬레이션 모드

| 모드 | 기간 | 해상도 | 용도 | 메모리/성능 |
|------|------|--------|------|------------|
| **snapshot** | 1시간 | Micro+Meso | 단일 시점 AS 관측 확률 측정 | 낮음 |
| **longitudinal** | 30일 | Macro (Meso 집계) | Guard 교체에 따른 추적 확률 변화 | 중간 |
| **hs_lifecycle** | 48시간 | Meso+Macro | HS Time Period 전환 영향 분석 | 중간 |

### 3. 시간 관련 이벤트 매핑

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         시간 이벤트 계층                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Micro (100ms)                                                              │
│  ├── 셀 전송/수신                                                           │
│  ├── CREATE/EXTEND 핸드셰이크                                               │
│  ├── CBT 샘플 수집                                                          │
│  └── 타이밍 상관 분석 데이터                                                 │
│                                                                             │
│  Meso (1분)                                                                 │
│  ├── 회로 dirtiness 체크                                                    │
│  ├── 스트림 할당/종료                                                       │
│  └── IP 재시도 (3초 단위지만 분 집계)                                       │
│                                                                             │
│  Macro (1시간)                                                              │
│  ├── Guard 상태 전이 (reachability)                                         │
│  ├── HS 디스크립터 갱신                                                     │
│  ├── HSDir 로테이션                                                         │
│  ├── IP 수명 만료                                                           │
│  └── SRV 전환 (12시간 오프셋)                                               │
│                                                                             │
│  Ultra-Macro (일 단위)                                                      │
│  ├── Guard 수명 만료 (30-60일)                                              │
│  ├── HS Time Period 전환 (24시간)                                           │
│  └── 장기 추적 확률 분석                                                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4. Guard 상태 초기화

**시뮬레이션 시작 시 옵션:**

| 옵션 | 설명 | 용도 |
|------|------|------|
| `fresh_start` | 모든 클라이언트가 새 Guard 샘플 생성 | 첫 접속 시나리오 |
| `steady_state` | 기존 Guard 분포 로드 (랜덤 수명 할당) | 현실적 스냅샷 |
| `deterministic` | 시드 기반 재현 가능한 Guard 할당 | 검증/디버깅 |

---

## 적용할 역공학 파라미터

**출처:** `ref-tor/reverse-engineer/`

### 클라이언트 파라미터 (00_final_report.md)

| 카테고리 | 파라미터 | 기본값 | 소스 파일 |
|----------|----------|--------|----------|
| 노드 선택 | Wgg, Wgm, Wee, Weg, Wmg, Wme, Wmd | 합의 문서 | node_select.c:604-811 |
| Guard 관리 | guard-max-sample-size | 60-200 | entrynodes.c:376-569 |
| Guard 관리 | guard-lifetime-days | 30-60 | entrynodes.c |
| 타이밍 | CBT quantile | 80% | circuitstats.c:1228-1257 |
| 타이밍 | MaxCircuitDirtiness | 10분 | circuituse.c:508-546 |
| 경로 | DEFAULT_ROUTE_LEN | 3 | - |

### Hidden Service 파라미터 (18_hs_final_report.md)

| 카테고리 | 파라미터 | 기본값 | 소스 파일 |
|----------|----------|--------|----------|
| 시간 주기 | HS_TIME_PERIOD_LENGTH | 24시간 | hs_common.c |
| 시간 주기 | 로테이션 오프셋 | 12시간 | hs_common.c |
| 소개점 | IP 최소 수 | 3개 | hs_service.c |
| 소개점 | IP 최대 수 | 20개 | hs_service.c |
| 소개점 | IP 수명 | 18-24시간 | hs_intropoint.c |
| HSDir | 선택 수 | 6개 | hs_common.c |
| HSDir | 복제본 | 2개 | hs_common.c |
| HSDir | spread_store | 4 | hs_common.c |
| DoS | INTRO2 rate | 25/sec | hs_dos.c |
| DoS | INTRO2 burst | 200 | hs_dos.c |

### 핵심 공식

**노드 선택 확률:**
```
P(i) = (bandwidth_i × weight_i) / Σ(bandwidth_j × weight_j)
```

**CBT Pareto 타임아웃:**
```
timeout = Xm / (1 - quantile)^(1/alpha)
```

**hs_index 계산:**
```
hs_index = SHA3-256("store-at-idx" || blinded_pk || replica || period_len || period_num)
```

**hsdir_index 계산:**
```
hsdir_index = SHA3-256("node-idx" || node_identity || srv || period_len || period_num)
```

---

## 현실성 검증 기준 (Validation Criteria) ⭐ (대폭 보강)

### 3단계 검증 프레임워크

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    3단계 현실성 검증 프레임워크                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Level 1: 분포 검증 (Distribution Validation)                               │
│  └─ 시뮬레이션 출력 분포가 실제 Tor 통계와 유사한가?                          │
│                                                                             │
│  Level 2: 행동 검증 (Behavioral Validation)                                 │
│  └─ 시뮬레이션 동작이 Tor 프로토콜 명세와 일치하는가?                         │
│                                                                             │
│  Level 3: 결과 검증 (Result Validation)                                     │
│  └─ 시뮬레이션 결과가 기존 연구 결과를 재현하는가?                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Level 1: 분포 검증

| 검증 항목 | 비교 대상 | 데이터 소스 | 허용 오차 | 검증 방법 |
|----------|----------|------------|----------|----------|
| Guard AS 분포 | 시뮬 vs 실제 | Onionoo API → AS 매핑 | χ² p > 0.05 | Chi-square 적합도 검정 |
| Exit AS 분포 | 시뮬 vs 실제 | Onionoo API → AS 매핑 | χ² p > 0.05 | Chi-square 적합도 검정 |
| 대역폭 분포 | 시뮬 vs 실제 | Tor Metrics bandwidth | KS p > 0.05 | Kolmogorov-Smirnov 검정 |
| 국가별 릴레이 비율 | 시뮬 vs 실제 | Tor Metrics by country | ±5% | 비율 비교 |
| Guard 선택 확률 | 시뮬 vs 이론 | Wgg×bandwidth 공식 | ±2% | 몬테카를로 샘플링 |

**검증 코드 예시:**
```python
def validate_guard_as_distribution(simulated_circuits, real_onionoo_data):
    """
    시뮬레이션된 회로의 Guard AS 분포가 실제와 유사한지 검증
    """
    from scipy.stats import chisquare
    from collections import Counter
    
    # 시뮬레이션 Guard AS 빈도
    sim_guard_as = Counter(c.guard.as_number for c in simulated_circuits)
    
    # 실제 Guard 가중치 기반 기대 분포
    expected_dist = calculate_expected_guard_distribution(real_onionoo_data)
    
    # Chi-square 검정
    chi2, p_value = chisquare(
        f_obs=list(sim_guard_as.values()),
        f_exp=[expected_dist[as_] * len(simulated_circuits) 
               for as_ in sim_guard_as.keys()]
    )
    
    return {
        "chi2": chi2,
        "p_value": p_value,
        "pass": p_value > 0.05,
        "interpretation": "분포 유사" if p_value > 0.05 else "분포 상이"
    }
```

### Level 2: 행동 검증

| 검증 항목 | 예상 동작 | 검증 방법 | 허용 오차 |
|----------|----------|----------|----------|
| Guard 지속성 | 동일 클라이언트가 30-60일간 같은 Guard 사용 | 클라이언트별 Guard 변경 이벤트 추적 | 범위 내 |
| 회로 재사용 | MaxCircuitDirtiness(10분) 이후 새 회로 | 회로 수명 분포 히스토그램 | ≤10분 |
| 3홉 경로 보장 | 모든 일반 회로가 Guard-Middle-Exit | 경로 길이 == 3 assertion | 100% |
| HS 6홉 경로 | 양측 경로 합 6홉 | HS 회로 경로 길이 검증 | 100% |
| HSDir 선택 | hs_index 기반 6개 HSDir 선택 | 선택된 HSDir과 이론값 비교 | 일치 |
| CBT 적응 | 빌드 타임 학습 후 타임아웃 조정 | 타임아웃 값 변화 추적 | Pareto 분포 일치 |
| Guard 상태 전이 | Primary → Confirmed → Filtered 순서 | 상태 전이 로그 검증 | 명세 일치 |

**검증 코드 예시:**
```python
def validate_guard_persistence(simulation_log, expected_lifetime_days=(30, 60)):
    """
    Guard가 기대 수명만큼 지속되는지 검증
    """
    client_guard_history = defaultdict(list)
    
    for event in simulation_log:
        if event.type == "CIRCUIT_BUILD":
            client_guard_history[event.client_id].append({
                "guard": event.guard_id,
                "timestamp": event.timestamp
            })
    
    guard_lifetimes = []
    for client_id, history in client_guard_history.items():
        changes = find_guard_changes(history)
        for start, end in changes:
            lifetime_days = (end - start).days
            guard_lifetimes.append(lifetime_days)
    
    median_lifetime = np.median(guard_lifetimes)
    min_expected, max_expected = expected_lifetime_days
    
    return {
        "median_guard_lifetime_days": median_lifetime,
        "expected_range": expected_lifetime_days,
        "pass": min_expected <= median_lifetime <= max_expected,
        "distribution": guard_lifetimes
    }
```

### Level 3: 결과 검증 (논문 재현)

#### 3.1 Johnson et al. 2013 재현 (필수)

**논문:** "Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries"

| 논문 결과 | 재현 목표 | 허용 오차 |
|----------|----------|----------|
| 상위 5개 AS가 ~40% 회로 관측 | 시뮬레이션에서 유사 수치 | ±10% |
| 6개월 내 95% 사용자 추적 가능 | longitudinal 시뮬레이션으로 검증 | ±10% |
| IXP 위치가 추적률 증가 | IXP 포함 vs 미포함 비교 | 방향성 일치 |

**재현 시나리오:**
```yaml
johnson_2013_baseline:
  description: "2013년 조건 재현"
  as_model: "2013년 CAIDA 스냅샷 (가능시) 또는 현재 모델"
  relay_count: "~3000개 (2013년 수준) 또는 현재"
  expected_result: "Top-5 AS 관측률 35-45%"
  
johnson_2013_updated:
  description: "현재 네트워크로 업데이트"
  as_model: "최신 CAIDA 스냅샷"
  relay_count: "~7000개 (현재 수준)"
  comparison: "2013년 대비 추적률 변화"
```

#### 3.2 Sun et al. 2015 재현 (권장)

**논문:** "RAPTOR: Routing Attacks on Privacy in Tor"

| 논문 결과 | 재현 목표 |
|----------|----------|
| BGP hijack으로 AS 경로 조작 | AS 경로 시뮬레이션 정확도 검증 |
| Asymmetric 경로 공격 | 양방향 AS 경로 모델링 필요성 확인 |

#### 3.3 Murdoch & Danezis 2005 재현 (선택)

**논문:** "Low-Cost Traffic Analysis of Tor"

| 논문 결과 | 재현 목표 |
|----------|----------|
| 타이밍 공격으로 릴레이 식별 | 타이밍 분포 시뮬레이션 정확도 |

### 검증 결과 리포트 형식

```yaml
validation_report:
  metadata:
    simulation_version: "next-simulate v0.1"
    simulation_date: "2025-XX-XX"
    configuration: "config_baseline.yaml"
    
  level_1_distribution:
    guard_as_distribution:
      chi2: 12.34
      p_value: 0.42
      status: "PASS"
    exit_as_distribution:
      chi2: 18.76
      p_value: 0.11
      status: "PASS"
    bandwidth_distribution:
      ks_statistic: 0.03
      p_value: 0.87
      status: "PASS"
      
  level_2_behavioral:
    guard_persistence:
      median_lifetime_days: 42
      expected_range: [30, 60]
      status: "PASS"
    circuit_reuse:
      max_dirty_observed_minutes: 10.0
      expected_max: 10
      status: "PASS"
    path_length:
      all_circuits_3_hop: true
      status: "PASS"
      
  level_3_result_reproduction:
    johnson_2013:
      top5_as_observation_rate: 0.38
      paper_reported: 0.40
      deviation: "-5%"
      status: "PASS"
    longitudinal_tracking:
      percent_tracked_6months: 0.91
      paper_reported: 0.95
      deviation: "-4%"
      status: "PASS"
      
  overall_verdict: "VALIDATED"
  confidence_level: "HIGH"
  notes:
    - "IXP 모델링 추가 후 johnson_2013 재현율 개선 예상"
```

### 검증 자동화 파이프라인

```bash
# 1. 시뮬레이션 실행
next-simulate --config baseline.yaml --output sim_output/

# 2. 실제 데이터 수집
python -m pipeline --step 1 2 3 4 5

# 3. Level 1 검증
python validate.py --level 1 --sim sim_output/ --real output/

# 4. Level 2 검증
python validate.py --level 2 --sim sim_output/

# 5. Level 3 검증
python validate.py --level 3 --sim sim_output/ --papers johnson2013

# 6. 리포트 생성
python validate.py --report --format yaml --output validation.yaml
```

---

## 예상 산출물

### 1. 시뮬레이션 엔진 (next-simulate)

- **언어:** Go (성능 + onion-simulate 자산 재사용)
- **입력:** YAML 설정 파일 (시나리오, AS 모델, 노드 배치, 클라이언트 분포)
- **실행:** 이벤트 기반 시뮬레이션 (다중 해상도 지원)

### 2. 설정 파일 구조

```yaml
# config.yaml 예시
simulation:
  mode: "snapshot" | "longitudinal" | "hs_lifecycle"
  duration: "1h" | "30d" | "48h"
  seed: 12345  # 재현성

network:
  as_model: "output/as_model_simplified.json"
  ixp_data: "data/ixp_members.json"  # 신규
  relay_count: 7000
  
clients:
  count: 1000
  distribution: "config/client_distribution.yaml"  # 별도 설정
  
hidden_service:
  enabled: true
  vanguard_enabled: false  # 선택적
  service_count: 100

observers:
  mode: "passive" | "active"
  controlled_ases: ["AS3356", "AS1299"]  # 부분 관찰자
```

### 3. 로그 출력

**AS-level 관측 로그 (Observer 시점):**
```json
{
  "timestamp": 1234567890123,
  "observer_as": "AS3356",
  "event": "CELL_OBSERVED",
  "src_as": "AS12345",
  "dst_as": "AS67890",
  "direction": "ingress",
  "size": 512,
  "circuit_id": null  // 암호화되어 확인 불가
}
```

**그라운드 트루스 로그 (검증용):**
```json
{
  "timestamp": 1234567890123,
  "event": "CIRCUIT_BUILD",
  "client_id": "client_001",
  "circuit_id": "circ_12345",
  "path": [
    {"node": "guard_01", "as": "AS100"},
    {"node": "middle_01", "as": "AS200"},
    {"node": "exit_01", "as": "AS300"}
  ],
  "as_paths": {
    "client_to_guard": ["AS50", "AS75", "AS100"],
    "guard_to_middle": ["AS100", "AS110", "AS200"],
    "middle_to_exit": ["AS200", "AS250", "AS300"]
  }
}
```

### 4. 분석 도구

- **추적 성공률 계산기:** AS 관측 조합별 상관 성공률
- **시나리오별 비교 리포트:** RQ1, RQ2, RQ3에 대한 정량 분석
- **검증 파이프라인:** 3단계 현실성 검증 자동화

---

## 기존 자산 활용

| 자산 | 위치 | 활용 방법 | 재사용 수준 |
|------|------|-----------|------------|
| TickManager | onion-simulate/internal/simulation/ | 이벤트 스케줄러 | 높음 (그대로 사용) |
| 이벤트 타입 | onion-simulate/internal/simulation/events.go | PacketEvent 등 | 중간 (확장) |
| Network 레지스트리 | onion-simulate/internal/simulation/network.go | 노드 관리 | 중간 (AS 추가) |
| RegionManager | onion-simulate/internal/region/ | 지역/지연 시간 | 높음 |
| 타입 정의 | onion-simulate/internal/types/ | NodeID, CircuitID 등 | 높음 |
| 역공학 결과 | ref-tor/reverse-engineer/ | 파라미터 + 알고리즘 | 직접 적용 |
| AS 데이터 | ref-tor/pipeline/output/ | as_model, as_roles 등 | 직접 로드 |
| 시각화 도구 | onion-simulate-visualize | 로그 형식 호환 | 높음 |

### 리팩토링 필요 사항

| 모듈 | 현재 상태 | 필요 변경 |
|------|----------|----------|
| 노드 구현 | time.Sleep 사용 | TickManager 스케줄링으로 전환 |
| 회로 상태 | 노드 내부 혼재 | 별도 상태 머신 추출 |
| 경로 선택 | RandomSelector | 가중치 기반 선택기로 교체 |
| AS 모델링 | 없음 | 신규 구현 (AS 경로 포함) |

---

## 마일스톤

| 단계 | 목표 | 예상 기간 | 산출물 | 주요 작업 |
|------|------|-----------|--------|----------|
| **M1** | 아키텍처 설계 + 핵심 타입 정의 | 1주 | ARCHITECTURE.md, 타입 정의 | 시간 모델 정의, AS 타입 설계 |
| **M2** | Directory/Guard 선택 구현 | 2주 | 노드 선택 로직, Guard 관리 | Wgg/Wgm 가중치, Guard 상태 머신 |
| **M3** | 회로 생성 + 패킷 전달 | 2주 | CREATE/EXTEND, 릴레이 메커니즘 | CBT Pareto, 3홉 경로 |
| **M4** | Hidden Service 지원 | 2주 | HSDir, IP, Rendezvous | HS v3, Vanguard 옵션 |
| **M5** | AS-level 관측 + AS 경로 시뮬레이션 | 2주 | Observer 모델, AS 경로 계산 | Valley-free 경로, IXP 모델링 |
| **M6** | 검증 + 분석 | 2주 | 추적 성공률 계산, 논문 재현 | 3단계 검증 프레임워크 |

**총 예상 기간: 11주**

### 마일스톤 상세

#### M1: 아키텍처 설계 (1주)

- [ ] ARCHITECTURE.md 작성
  - 모듈 구조 다이어그램
  - 데이터 흐름
  - 시간 모델 (Micro/Meso/Macro)
- [ ] 핵심 타입 정의
  - `Node`, `Circuit`, `Cell`, `Event`
  - `AS`, `ASPath`, `ASRelation`
  - `Observer`, `ObservationLog`
- [ ] 이벤트 큐 설계 (TickManager 재사용)
- [ ] 설정 파일 스키마 정의

#### M2: Directory/Guard 선택 (2주)

- [ ] 합의 문서 파서 (또는 정적 로드)
- [ ] 대역폭 가중치 기반 노드 선택
  - Wgg, Wgm, Wee 등 적용
  - 가족 제외, /16 제외
- [ ] Guard 상태 머신 구현
  - Sampled → Filtered → Confirmed → Primary
  - Reachability 상태 전이
- [ ] Guard 수명 관리 (30-60일)

#### M3: 회로 생성 + 패킷 전달 (2주)

- [ ] CREATE/EXTEND 프로토콜 (단순화)
- [ ] CBT Pareto 분포 구현
  - Xm 계산, alpha MLE
  - 타임아웃 적용
- [ ] 3홉 경로 구성
- [ ] 셀 전달 (512 bytes 구조)
- [ ] MaxCircuitDirtiness 적용

#### M4: Hidden Service 지원 (2주)

- [ ] HS v3 프로토콜 구현
  - 시간 주기 (24시간)
  - HSDir 선택 (hs_index)
  - 소개점 관리 (3-20개)
- [ ] INTRODUCE/RENDEZVOUS 흐름
- [ ] 6홉 경로 구성
- [ ] Vanguard 옵션 구현 (선택적)

#### M5: AS-level 관측 + AS 경로 시뮬레이션 (2주)

- [ ] AS 모델 로더 (as_model_simplified.json)
- [ ] IXP 데이터 통합 (PeeringDB 또는 CAIDA)
- [ ] AS 경로 시뮬레이션
  - Valley-free 경로 계산
  - 홉 간 AS 경로
- [ ] Observer 모델 구현
  - Passive/Active
  - Partial/Global
- [ ] 관측 로그 생성

#### M6: 검증 + 분석 (2주)

- [ ] Level 1 검증 구현 (분포)
  - Chi-square, KS 검정
- [ ] Level 2 검증 구현 (행동)
  - Guard 지속성, 회로 수명
- [ ] Level 3 검증 구현 (논문 재현)
  - Johnson et al. 2013
- [ ] 분석 도구
  - 추적 성공률 계산기
  - RQ별 리포트 생성
- [ ] 검증 자동화 파이프라인

---

## 클라이언트/목적지 분포 설정

> **참고:** 클라이언트 및 목적지 분포는 시뮬레이션 완성 후 별도 configuration 파일로 구성 예정

### 설정 파일 구조 (예정)

```yaml
# client_distribution.yaml
clients:
  total_count: 1000
  
  # 옵션 1: 국가별 비율 (Tor Metrics 기반)
  distribution_type: "by_country"
  country_weights:
    US: 0.25
    DE: 0.15
    RU: 0.10
    FR: 0.08
    # ...
    
  # 옵션 2: AS별 직접 지정
  # distribution_type: "by_as"
  # as_weights:
  #   AS7922: 0.05  # Comcast
  #   AS3320: 0.04  # Deutsche Telekom
  #   ...

destinations:
  # 옵션 1: 균등 분포
  distribution_type: "uniform"
  
  # 옵션 2: 상위 AS 집중
  # distribution_type: "top_ases"
  # top_n: 100
```

---

## 다음 즉시 작업

1. **ARCHITECTURE.md 작성:** next-simulate 설계 문서
   - 모듈 구조
   - 데이터 흐름
   - 시간 모델 (Micro/Meso/Macro)
   - AS-level 네트워크 모델

2. **TickManager 재사용 검증:** onion-simulate에서 그대로 사용 가능한지 확인

3. **AS 경로 계산 프로토타입:**
   - CAIDA 데이터로 valley-free 경로 계산 테스트
   - 성능 벤치마크

4. **IXP 데이터 수집:**
   - PeeringDB API 연동 또는
   - CAIDA IXPs 데이터셋 다운로드

5. **M1 단계 착수:**
   - 핵심 타입 정의 (Circuit, Node, AS, Event)
   - 이벤트 큐 설계

---

## 부록: RQ별 계획 적합성 평가

| Research Question | 적합성 | 이유 |
|-------------------|--------|------|
| **RQ1:** Guard+Exit AS 상관 | ✅ 양호 | 릴레이 AS + 홉 간 경로 AS 관측 모델링 |
| **RQ2:** IXP 위치 영향 | ✅ 양호 (수정 후) | IXP 모델링 추가됨 |
| **RQ3:** HS vs 일반 트래픽 비교 | ✅ 양호 | 6홉 구조, HSDir, IP, Vanguard 옵션 포함 |

---

## 변경 이력

| 버전 | 날짜 | 주요 변경 |
|------|------|----------|
| v1 | - | 초기 계획 |
| v2 (NEXT_DETAIL.md) | - | 역공학 파라미터, 마일스톤 추가 |
| **v3** | 2025-01 | 홉 간 AS 경로 시뮬레이션 추가, IXP 모델링 추가, Vanguard 옵션 추가, 시간 모델 정의, 3단계 검증 프레임워크 보강 |
