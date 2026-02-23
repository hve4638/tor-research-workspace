# 04. 다음 단계: LOCAL_PREF 기반 경로 선택

## 목표

`pathfinder.go`의 BFS를 수정하여, 최단 경로 대신 **LOCAL_PREF를 반영한 경로 선택**을 구현.

## 현재 vs 목표

```
현재: bfsUphill → 모든 valley-free 경로 중 최단 선택
목표: bfsUphill → 모든 valley-free 경로 중 LOCAL_PREF 최우선, 동률 시 최단 선택
```

## LOCAL_PREF 모델

### 경로 선호도

각 AS가 이웃으로부터 받은 경로에 대해:

| 이웃 관계 | LOCAL_PREF | 의미 |
|----------|-----------|------|
| Customer | 150 | 돈을 받으므로 가장 선호 |
| Peer | 100 | 무료 교환, 중간 |
| Provider | 50 | 돈을 내므로 가장 비선호 |

### 경로 선택 순서 (BGP Decision Process 단순화)

```
1. LOCAL_PREF (높을수록 선호)
   → 같은 목적지라도 customer 경로 > peer 경로 > provider 경로

2. AS_PATH 길이 (짧을수록 선호)
   → 같은 LOCAL_PREF 내에서 짧은 경로 선택

3. Tiebreak: 낮은 ASN (결정론적)
```

## 구현 방안

### 방안 A: BFS 가중치 변경 (권장)

`bfsUphill`과 `bfsDownhill`에서 hop count 대신 **비용 함수** 사용:

```go
// 현재: 모든 hop이 동일 비용
cost = depth + 1

// 개선: 관계 타입별 차등 비용 (낮을수록 선호)
cost_customer = depth + 1   // 선호 (LOCAL_PREF 150 → 비용 1)
cost_peer     = depth + 3   // 중간 (LOCAL_PREF 100 → 비용 3)
cost_provider = depth + 5   // 비선호 (LOCAL_PREF 50 → 비용 5)
```

BFS를 **Dijkstra로 변경**하여 최소 비용 경로를 찾음.

**장점**: 기존 valley-free 구조 유지, 비용 함수만 추가
**단점**: BFS → Dijkstra로 약간의 성능 저하 (O(V+E) → O((V+E)logV))

### 방안 B: 다단계 경로 선택

Phase 1에서 도달 가능한 모든 apex를 찾되, 각 apex까지의 경로를 LOCAL_PREF로 점수화.
최종 경로 선택 시 점수 최우선, 길이 차순.

**장점**: BGP 결정 과정에 더 충실
**단점**: 구현 복잡도 높음

### 방안 C: Customer-Cone 기반 (Gao-Rexford)

Gao-Rexford 모델을 완전 구현. 각 AS의 customer cone을 미리 계산하고,
경로 선택 시 export policy까지 반영.

**장점**: 학술적으로 가장 정확
**단점**: 구현 + 사전 계산 비용 높음

### 권장: 방안 A

최소 변경으로 최대 효과. `pathfinder.go`의 BFS를 비용 가중 Dijkstra로 변경하면:

1. Customer 경로 선호 → 비대칭성 증가 (R1 개선 기대)
2. Provider 경로 회피 → 경로가 더 다양해짐
3. Interception 시 공격자 경유 경로의 비용이 기존 경로보다 낮으면 자연스럽게 전환 (R4 개선 기대)

## 수정 대상 파일

| 파일 | 변경 |
|------|------|
| `asgraph/pathfinder.go` | BFS → Dijkstra, 비용 함수 추가 |
| `asgraph/pathfinder_test.go` | LOCAL_PREF 반영 테스트 추가 |
| `asgraph/cache.go` | 변경 없음 (인터페이스 동일) |

## Interception 모델 개선 (선택적)

현재 `AddProviderEdge`만으로는 트래픽 유인 효과가 부족. 추가로:

1. Interception 시 공격자→target 경로의 비용을 customer 수준(1)으로 설정
2. 주변 AS들이 공격자 경로를 자연스럽게 선호하게 됨
3. 이는 실제 BGP interception의 "더 매력적인 경로 광고" 효과를 근사

## 기대 효과

| 실험 | 현재 | 기대 | 근거 |
|------|------|------|------|
| R1 | 1.02x | **1.3-1.5x** | Customer 경로 선호로 양방향 경로 분기 증가 |
| R4 | -4.2% | **+20-50%** | 공격자 경로가 비용 우위로 트래픽 유인 |

보수적 추정. 논문 수준(R1: 1.66x, R4: ~90%)에 도달하려면 방안 C(Gao-Rexford)가
필요할 수 있으나, 방안 A로 먼저 효과를 확인하는 것이 합리적.

## 실행 순서

1. `pathfinder.go` 수정 (BFS → Dijkstra + 비용 함수)
2. 테스트 추가 + 기존 테스트 통과 확인
3. R1 sym/asym + R4 interception 재실행
4. 결과 비교 → 추가 조치 결정
