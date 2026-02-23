# 01. 구현 변경 사항

## 1. Step 06b — Transit AS 확장 (Python)

**신규 파일**: `tor-anal/pipeline/steps/step_06b_expand_topology.py`

### 알고리즘

1. CAIDA 전체 AS 관계 파일 로드 (~70만 관계)
2. 전체 AS 인접 리스트(adjacency list) 구축
3. 727 Tor 릴레이 AS를 seed로 **2-hop BFS** 실행
4. 발견된 transit AS를 `as_model_simplified.json`의 nodes에 추가 (max 3,000개 cap)
5. Transit 노드는 zero-weight (guard/exit 가중치 없음, significant=false)

### 파이프라인 통합

- `step_06_build_model.py`의 `run()` 끝에서 자동 호출
- `__init__.py`에 step_06b 등록

### Step 06 버그 수정 (부수적)

Step 06b 작업 중 발견된 기존 버그 3건 수정:

| 버그 | 원인 | 수정 |
|------|------|------|
| `probabilities`가 list인데 dict로 접근 | `as_path_probabilities.json` 형식 불일치 | list→dict 변환 추가 |
| guard/exit weight가 모두 0 | `as_roles.json`에 bandwidth만 있고 weight 없음 | bandwidth에서 weight 계산 |
| `observation_probability` 항상 0 | 키 이름 `combined_probability` vs `p_both` | fallback 키 추가 |

## 2. Go Temporal PrecomputeAll 버그 수정

**파일**: `next-simulate/internal/engine/events.go`

### 문제

`SnapshotTransitionEvent`, `BGPAttackStartEvent`, `BGPAttackEndEvent`의 `Execute()`가
config의 `precompute_paths` 설정을 무시하고 항상 `PrecomputeAll()`을 호출.

3,727 노드에서 PrecomputeAll = ~13.9M 쌍 계산 → 메모리 폭발 + 수 시간 소요.

### 수정

```go
// 수정 전
pathCache := asgraph.NewPathCache()
asgraph.PrecomputeAll(graph, pathCache)

// 수정 후
pathCache := asgraph.NewPathCache()
if e.PrecomputePaths {
    asgraph.PrecomputeAll(graph, pathCache)
}
```

3개 이벤트 구조체에 `PrecomputePaths bool` 필드 추가.
`main.go`에서 config 값을 이벤트 생성 시 전달.

## 3. RAPTOR Config 변경

**파일**: 3개 YAML config

```yaml
# 추가된 설정
simulation:
  precompute_paths: false
```

- `raptor_baseline_sym.yaml`
- `raptor_baseline_asym.yaml`
- `raptor_interception.yaml`

## 4. 수정 파일 목록

| 파일 | 변경 유형 |
|------|----------|
| `tor-anal/pipeline/steps/step_06b_expand_topology.py` | **신규** |
| `tor-anal/pipeline/steps/__init__.py` | 수정 (step_06b 등록) |
| `tor-anal/pipeline/steps/step_06_build_model.py` | 수정 (버그 3건 + 06b 호출) |
| `next-simulate/internal/engine/events.go` | 수정 (PrecomputeAll 조건부) |
| `next-simulate/cmd/next-simulate/main.go` | 수정 (PrecomputePaths 전달) |
| `next-simulate/configs/raptor_baseline_sym.yaml` | 수정 |
| `next-simulate/configs/raptor_baseline_asym.yaml` | 수정 |
| `next-simulate/configs/raptor_interception.yaml` | 수정 |
