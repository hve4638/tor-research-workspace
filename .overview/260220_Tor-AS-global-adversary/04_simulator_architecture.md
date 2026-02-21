# 04. 시뮬레이터 설계 (next-simulate)

## 설계 원칙

1. **이벤트 드리븐**: 모든 동작(회로 생성, 토폴로지 전환, BGP 공격)이 이벤트로 표현되며, TickManager가 시간 순서대로 실행한다. 이를 통해 시뮬레이션 시간을 정밀하게 제어한다.

2. **Valley-free Routing**: AS 간 경로는 실제 인터넷의 routing policy를 반영한 valley-free BFS로 계산한다. customer→provider(uphill), peer(최대 1번), provider→customer(downhill) 규칙을 따른다.

3. **실제 Tor 파라미터 적용**: Guard 수명(30~60일), 가중치 행렬(Wgg, Wgm 등), MaxCircuitDirtiness(10분), Proposal 271 Guard 선택 등 역공학으로 도출한 파라미터를 적용한다.

4. **비대칭 경로**: RAPTOR 논문의 핵심 통찰을 반영하여 A→B와 B→A 경로를 독립적으로 계산한다.

5. **재현 가능성**: 시드 기반 난수 생성으로 동일 설정에서 동일 결과를 보장한다.

---

## 패키지 구조

`next-simulate/internal/` 아래 13개 패키지로 구성된다 (~8,300줄 Go 코드, 55개 파일):

```
internal/
├── types/        타입 정의 (ASN, Circuit, Client, Guard, Observer 등)
├── config/       YAML 설정 파싱 + Tor 프로토콜 기본값
├── loader/       JSON 데이터 로더 (AS 모델, edge, geo, 확률)
│
├── asgraph/      AS 그래프 + valley-free BFS + 경로 캐시
│                 ├── graph.go       — ASGraph 구조, Clone/AddEdge/RemoveEdge
│                 ├── pathfinder.go  — FindPath, FindDirectionalPath, BFS
│                 └── cache.go       — PathCache, DirectionalPathCache
│
├── engine/       이벤트 엔진 (TickManager + Scheduler + Events)
├── sim/          시드 기반 난수 생성 (WeightedChoice)
│
├── directory/    가중치 기반 Guard/Exit/Middle AS 선택
├── guard/        Proposal 271 Guard 샘플링/선택/수명 관리
├── circuit/      3-hop 회로 생성 + Astoria 안전성 검사
│
├── observer/     AS-level 관찰 판정 + NDJSON 로깅
├── temporal/     동적 토폴로지 (CAIDA 스냅샷 전환)
│
├── bgp/          BGP Hijack/Interception + 적대자 모델
└── defense/      Counter-RAPTOR resilience 점수
```

### 의존 관계

```
config ──→ loader ──→ asgraph
                        │
              ┌─────────┼──────────┐
              ▼         ▼          ▼
          directory   guard     temporal
              │         │
              ▼         ▼
            circuit ◀──┘
              │
              ▼
           observer
              │
     ┌────────┼────────┐
     ▼        ▼        ▼
   bgp    defense    engine (이벤트 통합)
                       │
                       ▼
                    cmd/main.go
```

---

## 마일스톤별 구현 내용

### M1: 타입 시스템, AS 그래프, 이벤트 엔진

**목표**: 시뮬레이터의 기반 인프라를 구축한다.

- **타입 시스템** (`types/`): ASN, NodeID, Circuit, Client, Guard, Observer 등 핵심 타입 정의. 모든 패키지가 공유하는 도메인 모델.
- **AS 그래프** (`asgraph/`): 727개 AS 노드와 6,325개 edge를 로드하여 그래프를 구성. Valley-free BFS로 임의의 두 AS 간 경로를 계산. `PrecomputeAll()`로 ~530K 쌍의 경로를 사전 계산하고 캐시.
- **이벤트 엔진** (`engine/`): TickManager가 시간 단위(tick)로 이벤트를 실행. Scheduler가 미래 이벤트를 시간 순으로 관리. PrioritySystem으로 동일 tick 이벤트의 실행 순서를 제어.

### M2: 디렉토리 서비스, Guard 선택

**목표**: Tor의 노드 선택 메커니즘을 재현한다.

- **DirectoryService** (`directory/`): AS 모델에서 Guard/Exit/Middle 후보 목록을 구성하고, 대역폭 가중치 행렬(Wgg, Wgm 등)에 따라 확률적으로 선택.
- **GuardSelector** (`guard/`): Proposal 271에 따른 Guard 샘플링. 최대 60개 후보에서 Primary Guard 3개를 선택. 30~60일 수명 관리. Confirmed/Sampled 계층 구분.

### M3: 3-hop 회로 생성 + AS-path 관찰

**목표**: 회로를 생성하고, 어떤 AS가 관찰하는지 판정하여 로그를 출력한다.

- **CircuitManager** (`circuit/`): Guard + Middle + Exit를 조합하여 3-hop 회로를 생성. 모두 서로 다른 AS여야 하는 제약 조건 적용.
- **ObservationAnalyzer** (`observer/`): 회로의 각 세그먼트(Client→Guard, Guard→Middle, Middle→Exit) AS 경로를 계산하고, 각 AS가 어느 세그먼트를 관찰하는지 판정. entry(세그먼트 1)와 exit(세그먼트 3)를 동시에 관찰하는 AS가 있으면 상관(correlation) 가능으로 기록.
- **NDJSON 로거** (`observer/`): 두 종류의 로그를 파일로 출력:
  - `observations_*.ndjson`: 관찰자가 볼 수 있는 메타데이터 (어떤 AS가 어느 세그먼트를 관찰했는가)
  - `ground_truth_*.ndjson`: 실제 회로 매핑 (분석/검증용 정답 데이터)

### M4: 동적 토폴로지 (CAIDA 스냅샷 기반)

**목표**: 시간 경과에 따른 AS 토폴로지 변동을 시뮬레이션한다.

- **SnapshotTimeline** (`temporal/`): CAIDA 월별 스냅샷을 시간축에 배치. 설정에 따라 30일마다 다음 스냅샷으로 전환.
- **SnapshotTransitionEvent** (`engine/`): 전환 시점에 새 스냅샷의 edge를 로드하고, 기존 그래프와의 diff를 계산하여 적용. 영향받는 경로 캐시만 선택적으로 무효화. 활성 회로의 transit AS도 재계산.
- **Guard 수명 추적**: 토폴로지 변경에도 Guard는 유지. 수명 만료 시에만 교체하여 장기 추적 시나리오를 재현.

### M5: BGP 공격 시뮬레이션

**목표**: 능동적 BGP 공격이 관찰률에 미치는 영향을 측정한다. (~1,290줄)

- **비대칭 경로** (`asgraph/pathfinder.go`): `FindDirectionalPath(g, src, dst)` 추가. src에서 uphill BFS 후 각 apex에서 downhill BFS로 dst를 탐색. A→B ≠ B→A를 모델링.
- **그래프 변경** (`asgraph/graph.go`): `Clone()` — 깊은 복사로 원본 보존. `AddProviderEdge()` / `RemoveProviderEdge()` — 공격 시 edge 조작.
- **BGP Hijack** (`bgp/attack.go`): victim의 모든 provider edge를 제거하고 공격자를 유일한 provider로 삽입. 모든 트래픽이 공격자를 경유.
- **BGP Interception** (`bgp/attack.go`): 공격자를 target의 추가 provider로 삽입. 기존 provider 유지. 일부 트래픽만 경유 (은밀).
- **4종 적대자 모델** (`bgp/adversary.go`):

| 모델 | 제어 AS | 설명 |
|------|---------|------|
| SingleAS | 1개 | 단일 AS가 독자적으로 공격 |
| Colluding | N개 | 명시된 AS 그룹이 공모 |
| StateLevel | 국가 전체 | 특정 국가의 모든 AS (geo_map 기반) |
| Tier1 | AS + 직접 고객 | 대형 AS가 고객 AS까지 동원 |

- **PATH RECOMPUTATION**: BGP 공격 시 모든 활성 회로의 transit AS를 즉시 재계산. IP 라우팅은 per-packet이므로 BGP 변경이 기존 TCP 연결(Tor 회로)에도 즉시 반영.
- **캐시 무효화**: `InvalidateInvolving(asn)` — 공격 관련 ASN의 캐시만 선택적 무효화.

### M6: 방어 전략 (Counter-RAPTOR, Astoria)

**목표**: 두 가지 방어를 구현하고, Python 분석으로 효과를 비교한다. (~1,420줄)

- **Counter-RAPTOR** (`defense/resilience.go`):
  - `ResilienceScorer` 인터페이스 — 다른 방법으로 교체 가능
  - `PEntryInverseScorer` — `Score(asn) = min(1/p_entry, maxCap)`
  - `ApplyResilienceWeights()` — Guard 가중치에 곱셈 적용: `weight *= pow(score, factor)`
  - 효과: p_entry가 높은(관찰 위험이 큰) Guard의 선택 확률을 낮춤

- **Astoria** (`circuit/manager.go`):
  - `BuildCircuitSafe()` — Astoria 활성 시 transit 교집합 검사
  - `checkTransitOverlap()` — client→guard / middle→exit transit AS 교집합 검사
  - 교집합 없음 → SAFE, 있음 → 재시도 (최대 5회), 모두 실패 → fallback
  - 효과: 동일 AS가 entry와 exit를 동시 관찰하는 회로를 제거

- **Python 분석** (`tor-anal/analysis/`, 6개 모듈):
  - NDJSON 파싱, 상관율 계산, 시나리오 비교, 공격 기간별 분석, 시각화 6종

---

## 핵심 알고리즘

### Valley-Free BFS

```
입력: AS 그래프 G, 출발 AS src, 도착 AS dst
출력: valley-free 규칙을 만족하는 최단 AS 경로

1. bfsUphill(G, src) — src에서 provider/peer 링크를 따라 상향 탐색
2. bfsUphill(G, dst) — dst에서 상향 탐색
3. 양쪽 도달 집합의 교차점(meeting point) 탐색
4. 최단 경로 선택: src → ... → meeting → ... → dst
```

### 비대칭 경로 계산 (FindDirectionalPath)

```
입력: AS 그래프 G, 출발 AS src, 도착 AS dst
출력: src → dst 방향의 경로 (B→A는 별도 호출)

1. bfsUphill(G, src) — src에서 도달 가능한 모든 AS
2. dst가 직접 도달? → 반환
3. 각 apex에서 bfsDownhill(G, apex) — customer 링크만 따라 하향
4. dst 도달한 최단 경로 선택
```

### 그래프 Clone/Revert (BGP 공격용)

```
공격 시작:
  1. original = 현재 그래프
  2. modified = original.Clone()  (깊은 복사)
  3. modified에 edge 추가/제거  (hijack 또는 interception)
  4. modified로 전환, 캐시 재빌드
  5. 모든 활성 회로의 transit AS 재계산

공격 종료:
  1. original로 복원
  2. 캐시 재빌드, transit 재계산
```

---

## 테스트 현황

14개 패키지, 115+ 테스트:

```
$ cd next-simulate && go test ./...
ok   internal/asgraph      (8 + 8 = 16 tests)
ok   internal/bgp          (3 + 3 + 2 = 8 tests)
ok   internal/circuit       (6 tests)
ok   internal/config        (tests)
ok   internal/defense       (6 tests)
ok   internal/directory     (tests)
ok   internal/engine        (tests)
ok   internal/guard         (tests)
ok   internal/loader        (4 tests)
ok   internal/observer      (tests)
ok   internal/sim           (tests)
ok   internal/temporal      (tests)
ok   internal/types         (tests)
ok   cmd/next-simulate      (tests)
```

---

## 코드 규모

| 구성 | 파일 수 | 줄 수 |
|------|---------|-------|
| Go 소스 (*.go, 테스트 제외) | 35 | ~5,600 |
| Go 테스트 (*_test.go) | 20 | ~2,700 |
| **Go 합계** | **55** | **~8,300** |
| Python 분석 (analysis/) | 7 | ~700 |
| Python 파이프라인 (pipeline/) | 18 | ~4,700 |
| **Python 합계** | **25** | **~5,400** |
| **전체 합계** | **80** | **~13,700** |
