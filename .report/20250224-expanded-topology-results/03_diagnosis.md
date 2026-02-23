# 03. 근본 원인 재진단

## 이전 진단 (20250223)

> "BFS가 비즈니스 관계를 무시하여 경로가 비현실적. Valley-free BGP 라우팅 구현 필요."

**이 진단은 틀렸다.** 코드를 상세 분석한 결과, valley-free 라우팅은 이미 구현되어 있었다.

## 현재 라우팅 모델 분석

### 이미 구현된 것

`next-simulate/internal/asgraph/pathfinder.go`:

| 기능 | 상태 | 위치 |
|------|------|------|
| Valley-free 제약 | **구현됨** | `bfsUphill()` + `bfsDownhill()` |
| Customer/Provider/Peer 분리 저장 | **구현됨** | `graph.go` (3개 adjacency map) |
| 비대칭 경로 (A→B ≠ B→A) | **구현됨** | `FindDirectionalPath()` |
| CAIDA 관계 타입 보존 | **구현됨** | `ASEdge.RawRel` (-1, 0) |

### Valley-Free 경로 구조 (현재 구현)

```
FindPath (대칭):
  1. src에서 위로 BFS (customer→provider + peer)
  2. dst에서 위로 BFS (customer→provider + peer)
  3. 양쪽에서 도달 가능한 AS에서 만남
  4. 최단 경로 선택

FindDirectionalPath (비대칭):
  1. src에서 위로 BFS (customer→provider + peer) → apex 집합
  2. 각 apex에서 아래로 BFS (provider→customer만) → dst 탐색
  3. 최단 경로 선택
```

이 구조는 valley-free를 **완벽하게 보장**한다:
- 올라감(c2p) → 선택적 횡단(p2p) → 내려감(p2c)
- 골짜기(내려갔다 다시 올라감)는 구조적으로 불가능

## 진짜 병목: LOCAL_PREF 미구현

### 실제 BGP 경로 선택 알고리즘

실제 BGP 라우터는 같은 목적지에 대해 여러 경로가 있을 때 다음 순서로 선택:

```
1. LOCAL_PREF (높을수록 선호)
   - Customer 경로: 150 (돈을 받으니까 선호)
   - Peer 경로:     100 (무료 교환)
   - Provider 경로:  50 (돈을 내야 하니까 비선호)

2. AS_PATH 길이 (짧을수록 선호)

3. MED, IGP cost 등 (세부 tiebreak)
```

### 현재 구현의 문제

현재 BFS는 **1단계(LOCAL_PREF)를 건너뛰고 2단계(최단 경로)만 적용**:

```
예시: AS_A에서 AS_D까지

경로 1: A → Provider_B → Tier1_C → D          (3홉, provider 경로)
경로 2: A → Customer_X → Peer_Y → Provider_Z → D  (4홉, customer 경로)

현재 BFS:  경로 1 선택 (짧으니까)
실제 BGP:  경로 2 선택 (customer 경로 = LOCAL_PREF 높음)
```

### 이것이 R1/R4에 미치는 영향

#### R1 (비대칭 라우팅)

LOCAL_PREF가 없으면:
- 양방향 모두 최단 valley-free 경로를 선택
- 최단 경로는 대부분 비슷한 AS를 경유 (선택지가 적음)
- **비대칭성이 억제됨**

LOCAL_PREF가 있으면:
- A→B는 A의 customer 방향을 선호 → 특정 AS 집합 경유
- B→A는 B의 customer 방향을 선호 → 완전히 다른 AS 집합 경유
- **비대칭성이 증폭됨** → RAPTOR이 관찰한 1.66x 효과

#### R4 (BGP Interception)

현재 interception은 `AddProviderEdge(attacker, target)`:
- 공격자가 target의 추가 provider가 됨
- 하지만 BFS는 최단 경로를 선택하므로, 기존에 더 짧은 경로가 있으면 **공격자를 경유하지 않음**

실제 BGP interception:
- 공격자가 target의 prefix를 짧은 AS_PATH로 광고
- 주변 AS들이 공격자 경로를 LOCAL_PREF + 짧은 경로로 인해 선호
- **대규모 트래픽이 공격자를 경유** → 상관율 급증

## 검증: 경로 길이 분포

확장된 토폴로지(3,727 AS)에서도 R1이 1.02x에 그친 것은 경로 길이가 아닌 **경로 다양성**의 문제:

| 지표 | 확장 전 | 확장 후 | 의미 |
|------|--------|--------|------|
| 평균 경로 | 2-4홉 | 4-7홉 | 경로 길어짐 (개선) |
| 절대 상관율 | 2.58% | 1.93% | 길어진 경로로 관찰 기회 감소 |
| 비대칭 배율 | 1.003x | 1.02x | **비대칭성은 거의 변화 없음** |

경로가 길어졌음에도 비대칭 배율이 거의 동일 → **경로 선택 로직이 병목**, 토폴로지 크기가 아님.

## 결론

```
이전 진단: 토폴로지 규모 부족 → transit AS 확장 필요
↓
확장 결과: 49배 엣지 확장에도 개선 미미
↓
수정된 진단: BFS 최단 경로 선택이 실제 BGP의 LOCAL_PREF 기반 선택을 반영하지 못함
↓
다음 조치: pathfinder.go에 LOCAL_PREF 가중 경로 선택 구현
```
