# 05. 해결 방안: Step 06b Transit 확장 설계

> 727 AS 모델을 ~8,000 AS로 확장하여 R1/R4 재현을 가능하게 하는 방안

---

## 1. 문제 정의

### 현재 파이프라인

```
Step 06 (727 Tor AS) → Step 07 (727 간 edges 6,191개)
```

### 목표

```
Step 06 (727 Tor AS) → Step 06b (N-hop 확장) → Step 07 (확장 AS 간 edges)
```

---

## 2. Step 06b 알고리즘

### 입력

- `as_model_simplified.json`: 727 Tor AS 노드
- CAIDA `YYYYMMDD.as-rel2.txt`: 전체 AS 관계 (~700,000)

### 처리

```python
# 의사 코드
def expand_topology(tor_asns, caida_graph, n_hops=2):
    # 1. CAIDA 전체 AS 그래프 구축 (인접 리스트)
    full_graph = build_adjacency(caida_graph)  # ~48,000 AS

    # 2. 727 Tor AS를 seed로 N-hop BFS
    expanded = set(tor_asns)
    frontier = set(tor_asns)

    for hop in range(n_hops):
        next_frontier = set()
        for asn in frontier:
            for neighbor in full_graph[asn]:
                if neighbor not in expanded:
                    next_frontier.add(neighbor)
                    expanded.add(neighbor)
        frontier = next_frontier

    # 3. 확장된 AS를 transit 노드로 모델에 추가
    for asn in expanded - tor_asns:
        add_transit_node(asn, guard_weight=0, exit_weight=0, total_relays=0)

    return expanded
```

### 출력

- 확장된 `as_model_simplified.json`: ~8,000 노드 (727 Tor + ~7,300 transit)
- Transit 노드는 `guard_weight=0`, `exit_weight=0` (릴레이 미운영)

---

## 3. 확장 규모 추정

| N-hop | 예상 노드 | 예상 Edges | 경로 길이 | 시뮬 시간 |
|-------|----------|-----------|----------|----------|
| 현재 (0) | 727 | 6,191 | 2-4홉 | ~15분 |
| 1-hop | ~3,000 | ~25,000 | 3-5홉 | ~1시간 |
| **2-hop** | **~8,000** | **~80,000** | **4-7홉** | **~4시간** |
| 3-hop | ~20,000 | ~200,000 | 5-8홉 | ~12시간 |

### 2-hop이 최적인 이유

- RAPTOR 논문의 48K AS에 충분히 근접 (~17%)
- 경로 길이 4-7홉이 실제 인터넷(5-8홉)과 유사
- 시뮬레이션 시간이 합리적 (~4시간)
- 3-hop은 노드가 20K로 급증하여 시뮬 시간 과다

---

## 4. Go 시뮬레이터 변경

### 코드 변경 불필요

`next-simulate`는 `as_model_simplified.json`과 `model_edges.json`을 읽어 그래프를 구성한다.
노드/edges가 증가하면 자동으로 더 긴 경로를 계산한다.

### 성능 최적화 필요

```yaml
# configs/raptor_*.yaml
network:
  precompute_paths: false  # lazy caching 사용
```

- 8,000 AS의 전체 사전 계산 = 64M 쌍 → 메모리 과다
- `precompute_paths: false` → 실제 사용 경로만 온디맨드 캐시
- Tor 릴레이 AS(727)만 경로가 필요하므로 캐시 크기는 관리 가능

---

## 5. 구현 파일

| 파일 | 변경 유형 |
|------|----------|
| `tor-anal/pipeline/steps/step_06b_expand_topology.py` | **신규**: N-hop BFS 확장 |
| `tor-anal/pipeline/steps/step_07_add_edges.py` | 변경 없음 (`model_asns`가 이미 확장됨) |
| `tor-anal/pipeline/main.py` | Step 06b 등록 |
| `next-simulate/configs/raptor_*.yaml` | `precompute_paths: false` 확인 |

### Step 07은 수정 불필요

Step 07의 필터링 로직:
```python
if as1 in model_asns and as2 in model_asns:
```

`model_asns`는 `as_model_simplified.json`에서 추출한다.
Step 06b가 transit 노드를 모델에 추가하면, Step 07이 자동으로 확장된 AS 집합 간의 edges를 추출한다.

---

## 6. 대안 검토

### 대안 A: CAIDA 전체 그래프 직접 사용 (~48,000 AS)

- **장점**: 논문과 동일한 규모
- **단점**: 시뮬 시간 ~24시간+, 메모리 수십 GB
- **판단**: 과도 — 2-hop 확장으로 충분한 효과 기대

### 대안 B: RouteViews AS_PATH 기반 경로 (BFS 대체)

- **장점**: 실제 BGP 경로 사용, 비대칭 자연 발생
- **단점**: 구현 복잡도 높음, Go 시뮬레이터 경로 계산 엔진 변경 필요
- **판단**: Step 06b 적용 후 평가 — 확장만으로 충분할 가능성 높음

### 대안 C: Valley-free BFS (BFS + 관계 유형 반영)

- **장점**: BFS 프레임워크 유지, 정책 부분 반영
- **단점**: Go 코드 수정 필요 (pathfinder.go)
- **판단**: Step 06b 적용 후 2차 개선으로 검토

---

## 7. 검증 계획

확장 토폴로지로 RAPTOR R1, R4만 재실행:

| 실험 | 기대 결과 | 통과 기준 |
|------|----------|----------|
| R1 비대칭 | factor > 1.3x | 경로 길이 증가로 forward/reverse 차이 발생 |
| R4 Interception | during > pre × 1.5 | 공격자의 marginal gain 발생 |
| R2 시간적 (기존) | 유지 | 단조 증가 패턴 보존 |
| R3 Tier-1 (기존) | 유지 | 상위 순위 보존 |

### 추가 검증 지표

- 평균 경로 길이: 4-7홉 범위인지 확인
- Transit AS 다양성: 상위 10 transit AS의 관찰 점유율 합계 < 50%
- Edge 밀도: `edges / (nodes × (nodes-1) / 2)` 가 CAIDA 전체와 유사한지

---

## 8. 실행 순서

```
1. Step 06b 구현 (Python)                     ~2시간
2. 파이프라인 재실행 (Step 06b → 07)           ~10분
3. 확장 모델 통계 확인 (노드, edges, 경로 길이)  ~30분
4. RAPTOR R1 재실행                            ~4시간
5. RAPTOR R4 재실행                            ~4시간
6. 결과 비교 + 보고서 갱신                     ~1시간
```

**예상 총 소요**: ~12시간 (시뮬레이션 병렬 시 ~8시간)
