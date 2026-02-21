# TOAR: Toward Resisting AS-Level Adversary Correlation Attacks Optimal Anonymous Routing

**요약 작성일**: 2026-02-21
**원문**: Zhao, H.; Song, X. (Mathematics 2024)
**소속**: School of Computer Science and Communication Engineering, Jiangsu University, China
**DOI**: 10.3390/math12233640

---

## 1. 핵심 기여 (One-line)

SDN(Software Defined Network) 환경에서 Bayesian optimization 기반 2단계 라우팅 메커니즘을 제안하여, AS-level 적대자의 트래픽 상관 공격에 대한 Tor 익명성 저하와 라우팅 우회로 인한 고지연 문제를 **네트워크 계층(underlay)**에서 해결하는 최적 익명 라우팅 기법.

---

## 2. 연구 동기

- Tor는 저지연 익명 통신을 위해 트래픽 난독화를 사용하지 않으므로 **트래픽 상관 공격(correlation attack)**에 취약
- AS-level 적대자는 하부 라우팅을 조작하여 Tor 회로의 entry/exit 양쪽 경로에 자신을 배치, 상관 공격 성공률을 높일 수 있음
- **기존 AS-aware 경로 선택 방식의 한계**:
  - Counter-RAPTOR, LASTor, Astoria 등은 **오버레이(application layer)** 수준에서 릴레이 선택 알고리즘을 수정
  - 이 방식은 수동적 추론 기법(passive inference)에 의존하여 **라우팅 추론이 부정확**하고 **지연 시간을 증가**시킴
  - 예: Counter-RAPTOR는 다운로드 시간을 상당히 증가시킴
- Tor 라우팅 우회(detour)로 인해 **90% 이상의 연결에서 직접 연결 대비 5배 이상의 지연** 발생
- 인터넷 라우팅의 **비대칭성(asymmetry)**: client→entry와 entry→client 경로가 다를 수 있어, 하나의 AS가 4개 경로 세그먼트를 관찰할 수 있는 기회 증가

---

## 3. 알고리즘/최적 라우팅 모델

### 3.1 시스템 모델

글로벌 네트워크를 방향 그래프 G = (V, E)로 모델링. 각 정점은 AS 도메인, 각 간선은 AS 간 세션을 나타냄.

**핵심 정의**:
- **Overlay Circuit**: 릴레이 시퀀스 AC = [R1, R2, ..., Rl] (3-hop인 경우 l=3)
- **Inter-domain Routing**: 4개의 라우팅 세그먼트 (비대칭 경로 고려)
  - r^f_1: S → Entry (forward)
  - r^f_{l+1}: Exit → D (forward)
  - r^b_1: D → Exit (backward)
  - r^b_{l+1}: Entry → S (backward)
- **Exit Policy** e(r): 각 AS 노드의 라우팅 광고 정책 준수 여부 (0 또는 1)
- **Price Strategy** c(r): 경로의 통신 비용
- **Security Policy** d(p, k, m, n): 경로가 침해될 확률

### 3.2 보안 정책 함수

```
d(p, k, m, n) = 1 + (1-p)^(m+n-k) - (1-p)^m - (1-p)^n
```

- p: 글로벌 네트워크에서 각 노드가 공격받을 확률
- k: entry측 경로(r^f_1, r^b_{l+1})와 exit측 경로(r^f_{l+1}, r^b_1)에서 **공유(중복) AS 노드 수**
- m: entry측 경로 세그먼트의 AS 노드 수
- n: exit측 경로 세그먼트의 AS 노드 수
- d 값이 클수록 상관 공격 위험이 높음 (k가 클수록 d 증가)

### 3.3 AS-level 적대자 모델

단일 AS가 다음 4가지 조합 중 하나에 동시 존재하면 상관 공격 성공 (d=1):
1. r^f_1 (S→Entry)과 r^f_{l+1} (Exit→D)
2. r^f_1과 r^b_1 (D→Exit)
3. r^f_{l+1}과 r^b_{l+1} (Entry→S)
4. r^b_1과 r^b_{l+1}

### 3.4 최적화 문제 정의

목적 함수: f(r) = e(r) / (|r| * d(r) * c(r)) 를 최대화

제약 조건:
- 출발/도착 AS 일치
- Exit policy 준수: e(r) = 1
- 보안 정책 임계치: d(r) <= D_max
- 비용 임계치: c(r) <= B_max

이 문제는 **NP-hard**임을 3-CNF-SAT 환원을 통해 증명.

---

## 4. 방법론

### 4.1 1단계: 간소화된 보안 정책 기반 경로 탐색 (Algorithm 1 - SKCR)

보안 정책 함수를 간소화하여 공유 노드 수 k만 고려:
```
d ≈ 1 - (1-p)^k
```

**절차**:
1. Policy-Compliance Shortest Routing (PCSR) 알고리즘으로 4개 최단 경로 세그먼트 계산
2. 공유 노드 수 k <= k_max이면 조기 반환
3. 아니면, entry측 경로의 노드를 조합적으로 제거하며 exit측에서 새 최단 경로 탐색
4. 반대로 exit측 노드를 제거하며 entry측 새 최단 경로 탐색
5. 결과 집합 RF에서 최적 경로 반환

- 복잡도: O(mC(m-k_max) * T_PCSR + nC(n-k_max) * T_PCSR)
- k_max는 사용자가 설정: 작을수록 강한 보안, 클수록 약한 보안
- RF 집합은 경로 다양성을 위한 대안 경로 풀로도 활용 가능

### 4.2 2단계: 완전 보안 정책 기반 반복 최적화 (Algorithm 2)

1단계 결과를 기반으로 **지역 탐색(local search)** 수행:

1. 1단계의 최적 경로 r*를 기준으로 시작
2. 공유 노드를 점진적으로 제거
3. 제거된 노드 근처에서 새 최적 경로 탐색
4. 단위 보안 향상 비용 C(r, r*) = b * I_path(r,r*) / I_d(r,r*) 계산
5. C*가 C보다 작으면 경로 업데이트, 아니면 다음 공유 노드 시도
6. 모든 공유 노드 처리 또는 반복 횟수 도달 시 종료

- 복잡도: O(k * T_PCSR)
- **2단계를 별도로 두는 이유**: 1단계는 넓은 탐색 공간, 2단계는 좁은 지역 탐색으로 균형

### 4.3 SDN 프로그래머블 인터페이스

- 각 AS에 소프트웨어 정의 프로그래머블 인터페이스 설계
- SDN 컨트롤러가 애플리케이션 정책과 라우팅 프로토콜을 통합
- **경로 협상 과정**: 사용자가 경로상의 AS를 역순으로 쿼리 → 정책 준수 확인 → 최종 확인
  - 쿼리와 확인을 분리하여 미사용 경로에 대한 비용 부담 방지
- **캐싱**: 원격 쿼리 결과를 로컬에 캐시하여 반복 쿼리 비용 절감

---

## 5. 주요 결과

### 5.1 익명성 분석

Reiter-Rubin 익명성 분석 방법 적용:
```
d = (1/n)^2 / ((1-(1-1/n)^(n-1)) * (1-(1-1/n)^n))
```
- TOAR 적용 후 경로상 침해 노드는 최대 1개 (c=1)
- **n=5일 때 d ≈ 0.1**, **n>15일 때 d → 0** (절대 익명성 수준 근접)
- 경로 길이 증가에 따라 익명성이 급격히 강화됨

### 5.2 유효성 분석 (CAIDA 데이터셋)

**실험 데이터**: CAIDA AS relationship dataset — **63,361 노드, 320,978 간선**

**실험 설정**:
- 트래픽 상위 10개 AS를 목적지로 선택
- 각 목적지당 상위 200개 송신 AS 선별 → 2,000개 end-to-end 라우팅 의도 생성
- Tor Metric 릴레이 정보로 매핑 → **1,000개 유효 의도** 필터링

**보안 정책 함수 유효성**:
- p=0.1, k_max: 0→7, max(m,n)<10 조건에서 보안 함수가 **약 100% 증가**
- 공유 노드 수 감소가 시스템 익명성 향상에 직접적 효과

**기대 향상 함수 유효성**:
- 2단계 알고리즘의 ΔC 값이 실험 횟수에 따라 지속 증가 → 반복 최적화 유효

**경로 탐색 성공률**:
- TOAR: **약 60%** 성공률 (정책 준수 경로 발견)
- Naive enumeration: **약 25%** 성공률
- **TOAR가 약 2.5배 높은 성공률**

### 5.3 네트워크 성능 측정

**실험 환경**: Mininet 2.3.0d6, Ubuntu 16.04, Intel i7-9700 @ 3.0GHz, Ryu SDN controller, Open vSwitch, Internode topology (Zoo dataset, **66 노드**)

**처리량(Throughput)**:
- TOAR disabled vs enabled: 데이터 크기 증가에 따라 양쪽 모두 처리량 증가
- TOAR enabled는 경로 샘플링 추가 처리로 약간의 처리량 감소
- **Lightweight TOAR: IP 처리량의 약 70% 달성**

**통신 지연(Latency)**:
- IP < STAR < TOAR < Tor (경로 길이 증가에 따른 지연)
- Tor가 가장 높은 지연, 경로 길이 증가 시 가장 빠르게 증가
- TOAR는 STAR보다 약간 높음 (exit policy 고려로 인해)
- IP가 가장 낮지만 익명성 제공 없음

**처리량 비교 (패킷 크기 128~1500 bytes)**:
- TOAR ≈ STAR 수준의 처리량 성능
- Lightweight TOAR: IP 대비 약 70% 처리량 달성

---

## 6. 프로젝트 연관성

이 논문은 본 프로젝트(project-tor)가 다루는 AS-level 상관 공격 문제에 대한 **대안적 방어 접근법(SDN 기반 underlay routing)**을 제시:

| 논문 개념 | 프로젝트 구현 |
|----------|-------------|
| AS-level 적대자의 상관 공격 모델 | `next-simulate/internal/asgraph/` — AS 그래프 + 관계 모델링 |
| 비대칭 라우팅 (4개 경로 세그먼트) | `next-simulate/internal/asgraph/path.go` — 비대칭 AS 경로 (RAPTOR 논문 기반) |
| 공유 AS 노드에 의한 침해 확률 d(p,k,m,n) | `next-simulate/internal/observer/` — entry/exit transit AS 교집합 검사 |
| Exit policy, Price policy 기반 경로 최적화 | `next-simulate/internal/circuit/` — 대역폭 가중치 기반 회로 생성 (overlay 수준) |
| Counter-RAPTOR 참조 [12] | `next-simulate/internal/defense/counter_raptor.go` — resilience 기반 Guard 재가중치 |
| LASTor, Astoria 등 AS-aware 경로 선택 | `next-simulate/internal/defense/astoria.go` — entry/exit transit AS 교집합 검사 |
| BGP hijack/interception 위협 | `next-simulate/internal/bgp/` — M5에서 구현된 BGP 공격 시뮬레이션 |
| CAIDA AS 토폴로지 데이터 | `tor-anal/data/model_edges.json` — 6,325 AS 간 연결, `configs/*.yaml` |
| 4종 시나리오 비교 (방어 전략 포함) | `configs/bgp_attack.yaml`, `counter_raptor_defense.yaml`, `astoria_defense.yaml`, `combined_defense.yaml` |
| 상관율 분석 | `tor-anal/analysis/` — 상관율 계산, 공격 전/중/후 분석, 6종 시각화 |

### 본 논문이 프로젝트와 다른 점

- **TOAR는 SDN 기반 underlay 라우팅 제어** → 프로젝트는 **overlay 릴레이 선택 + BGP 공격 시뮬레이션**에 집중
- TOAR는 네트워크 계층에서 AS를 회피하는 최적 경로를 직접 선택 → 프로젝트의 Counter-RAPTOR/Astoria는 릴레이 선택 알고리즘 수정으로 간접 회피
- TOAR는 NP-hard 문제를 Bayesian optimization으로 근사 → 프로젝트는 확률적 가중치 기반 릴레이 선택
- TOAR의 보안 정책 함수 d(p,k,m,n)는 **프로젝트의 상관율 계산에 이론적 근거** 제공 가능

### 프로젝트에 줄 수 있는 시사점

1. **공유 AS 노드 수(k)를 상관율의 핵심 변수로 활용**: 현재 프로젝트의 observer가 entry/exit 경로 교집합을 검사하는데, TOAR의 d(p,k,m,n) 수식을 적용하면 보다 정량적인 침해 확률 모델링 가능
2. **비대칭 경로의 4가지 관찰 시나리오**: 프로젝트가 이미 구현한 비대칭 경로 모델의 이론적 타당성 확인
3. **SDN 기반 방어는 현재 프로젝트 범위 밖**: 하지만 향후 방어 전략 비교 시 "underlay vs overlay" 차원 추가 가능

---

## 7. 한계 및 후속 연구

- **SDN 배포 전제**: 현실적으로 모든 AS가 SDN을 채택해야 하므로 **대규모 배포에 제약**
- **동적 라우팅 프로토콜 미배포**: 경로 발견 과정이 코드 시뮬레이션만으로 검증, 실제 BGP가 SDN 테스트 환경에 배포되지 않음
- **보안 정책이 특정 목표에만 집중**: 일반적 비교/논의 부족
- **실험 규모 제한**: Mininet 기반 66 노드 토폴로지로, 실제 인터넷 규모(63,361+ AS)와 격차
- **비용 모델의 현실성**: 각 AS의 가격 정책(price policy)이 실제 인터넷 과금과 얼마나 일치하는지 불명확
- **NP-hard 문제의 근사 보장 부재**: Bayesian optimization이 최적에 얼마나 근접하는지 이론적 보장 없음
- **공모(colluding) 적대자 미고려**: 다수 AS가 공모하는 시나리오 미분석
- **향후 연구**:
  - 다중 SDN 컨트롤러 환경에서 익명 라우팅 배포
  - 일관된 공격 모델/익명성 목표/모델 추상화를 포함하는 **일반적 익명 라우팅 프레임워크** 구축
  - BGP speakers에 프로그래머블 인터페이스와 segment routing 확장

---

## 8. 참고 수치 요약

```
CAIDA 토폴로지: 63,361 AS 노드, 320,978 간선
실험 데이터: 1,000개 유효 end-to-end 라우팅 의도 (2,000개 중 필터)

익명성 분석:
  - n=5: d ≈ 0.1 (상관 공격 성공 확률)
  - n>15: d → 0 (절대 익명성 수준 근접)

경로 탐색 성공률:
  - TOAR: ~60%
  - Naive enumeration: ~25%
  - 향상: 약 2.5배

보안 정책 함수 (p=0.1, max(m,n)<10):
  - k: 0→7 일 때 d 약 100% 증가
  - 공유 노드 감소 → 직접적 익명성 향상

네트워크 성능 (Mininet, 66 노드):
  - Lightweight TOAR 처리량: IP의 약 70%
  - TOAR ≈ STAR 수준 처리량
  - 지연: IP < STAR < TOAR < Tor

비교 대상 기법:
  - Counter-RAPTOR (overlay, Guard 재가중치)
  - LASTor (overlay, AS-aware 경로 선택)
  - STAR (SDN segment routing 기반 익명 통신)
  - HORNET, LAP, PHI (네트워크 계층 익명 시스템)
```
