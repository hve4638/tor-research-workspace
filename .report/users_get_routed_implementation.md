# "Users Get Routed" 논문 재현 구현 보고서

> Johnson et al. (CCS 2013) 핵심 결과 재현을 위한 시뮬레이터 확장 구현 완료 보고서
>
> 작성일: 2026-02-21

---

## 1. 개요

기존 AS-level 글로벌 관찰자 시뮬레이터(M1~M6)를 확장하여, Johnson et al.의 "Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries" 논문의 핵심 결과를 재현할 수 있는 기반을 구축하였다.

### 구현 범위

| Phase | 내용 | 상태 |
|-------|------|------|
| Phase 1 | CDF 메트릭 (Python) | 완료 |
| Phase 2 | 비대칭 라우팅 (Go) | 완료 |
| Phase 3 | 릴레이 적대자 모델 (Go + Python) | 완료 |
| Phase 4 | 사용자 모델 + Exit 정책 (Go + Python) | 완료 |
| Phase 5 | 스케일 확장 + Per-entity 위협 분석 | 완료 |

### 의존 관계

```
Phase 1 (CDF 메트릭)           ← Python만, 독립
Phase 2 (비대칭 라우팅)         ← Go만, 독립
Phase 3 (릴레이 적대자)         ← Phase 2 이후
Phase 4 (사용자 모델+Exit 정책) ← Phase 3과 병렬
Phase 5 (스케일 확장)           ← Phase 2 이후
```

---

## 2. Phase 1: CDF 메트릭

### 목적

논문의 핵심 메트릭인 **첫 침해까지 시간 CDF**(Figure 2a)와 **스트림 침해율**(Figure 3)을 기존 NDJSON 출력에서 계산한다.

### 새 파일

#### `tor-anal/analysis/cdf_analysis.py`

4개 함수 구현:

| 함수 | 기능 |
|------|------|
| `compute_time_to_first_compromise()` | 클라이언트별 첫 침해 tick → CDF 생성. entry/exit 관찰 join → correlated circuit_ids → gt_df에서 client_id별 min(tick) 추출 |
| `compute_stream_compromise_fraction()` | 전체 회로 중 침해 비율 + 일별 비율 DataFrame |
| `compute_relay_compromise_cdf()` | relay_compromise 마커 기반 CDF (guard+exit 동시, guard만, exit만) |
| `compute_cdf_with_confidence()` | 다중 시드 결과에서 DKW 신뢰 구간 계산: ε = √(ln(2/α) / 2n) |

**핵심 알고리즘** (`compute_time_to_first_compromise`):

```
1. entry_obs와 exit_obs를 (circuit_id, asn)으로 join → correlated circuits
2. correlated circuit_ids를 gt_df와 join → client_id, tick 획득
3. client_id별 min(tick) = first_compromise_tick
4. 정렬 후 CDF 생성: x=days, y=cumulative fraction
```

tick → day 변환: `day = tick * tick_interval_ms / (1000 * 86400)`

#### `tor-anal/analysis/cdf_visualize.py`

4개 플롯 함수:

| 함수 | 출력 |
|------|------|
| `plot_time_to_first_compromise_cdf()` | CDF step plot (x=days, y=fraction compromised) |
| `plot_stream_compromise_over_time()` | 일별 회로 침해율 라인 플롯 |
| `plot_cdf_with_confidence_bands()` | DKW 신뢰 구간 포함 CDF |
| `plot_relay_compromise_cdf()` | 릴레이 적대자용 CDF |

시각화 스타일: 기존 `visualize.py` 준수 (Agg 백엔드, DPI=150, tight_layout, 시나리오별 고정 색상)

#### `tor-anal/analysis/relay_adversary_analysis.py`

| 함수 | 기능 |
|------|------|
| `extract_relay_compromises()` | relay_compromise 마커 파싱 → clean DataFrame |
| `compute_relay_stats()` | guard/exit/full 침해 건수 및 비율 |
| `compute_relay_cdf()` | 침해 유형별 CDF (full, guard_only, exit_only) |

#### `scripts/multi_seed_run.sh`

N개 시드로 시뮬레이션 반복 실행 스크립트:
- sed로 seed와 output 경로를 교체한 임시 config 생성
- 각 시드별 `output/multi_seed/seed_N/` 디렉토리에 결과 저장

#### `tor-anal/analysis/run_analysis.py` 수정

기존 CLI에 3개 인자 추가:

| 인자 | 기본값 | 설명 |
|------|--------|------|
| `--cdf` | false | CDF 분석 활성화 |
| `--tick-interval-ms` | 60000 | tick 간격 (ms) |
| `--multi-seed-dirs` | - | 다중 시드 디렉토리 목록 |

기존 분석 흐름 이후 "6b. CDF analysis" 섹션 추가:
1. 시나리오별 network-level CDF 계산
2. Stream compromise fraction 계산
3. Relay adversary CDF 계산 (마커 존재 시)
4. JSON 보고서에 cdf/stream_compromise/relay_cdf 섹션 추가
5. CDF 시각화 생성

---

## 3. Phase 2: 비대칭 라우팅

### 목적

`TransitASes()`의 경로 계산을 대칭 BFS에서 비대칭 BFS로 전환.
RAPTOR 논문의 핵심 가정: A→B ≠ B→A (인터넷 라우팅 정책의 비대칭성).

### 변경 내역

#### `internal/config/config.go`

`SimulationConfig` 구조체에 2개 필드 추가:

```go
AsymmetricRouting bool `yaml:"asymmetric_routing"` // default: false
PrecomputePaths   bool `yaml:"precompute_paths"`   // Phase 5 lazy caching
```

#### `internal/circuit/manager.go`

| 변경 | 내용 |
|------|------|
| 구조체 | `dirPathCache *asgraph.DirectionalPathCache` 필드 추가 |
| `NewCircuitManager()` | `dirPathCache` 파라미터 추가 (nil 허용 = 대칭 모드) |
| `TransitASes()` | `dirPathCache != nil`이면 `FindDirectionalPathCached` 사용, 아니면 기존 `FindPathCached` |
| `UpdateTopology()` | `dirPathCache` 파라미터 추가 |

**TransitASes 분기 로직:**

```go
var path *types.ASPath
if cm.dirPathCache != nil {
    path = asgraph.FindDirectionalPathCached(cm.graph, cm.dirPathCache, seg.src, seg.dst)
} else {
    path = asgraph.FindPathCached(cm.graph, cm.pathCache, seg.src, seg.dst)
}
```

#### `cmd/next-simulate/main.go`

`asymmetric_routing: true` 시 `DirectionalPathCache` 생성 후 `NewCircuitManager`에 전달.

#### `internal/engine/events.go`

`UpdateTopology` 호출부 3곳 업데이트 (dirPathCache=nil 전달):
- `SnapshotTransitionEvent.Execute` (line ~228)
- `BGPAttackStartEvent.Execute` (line ~325)
- `BGPAttackEndEvent.Execute` (line ~402)

### 호환성

기존 4개 config에 `asymmetric_routing` 미지정 → `false` → **동작 무변경**.
`FindDirectionalPath`(pathfinder.go:132)와 `DirectionalPathCache`(cache.go:60)는 이미 구현되어 있었으나 production에서 미사용이었음. 이번 변경으로 config 설정을 통해 활성화 가능.

---

## 4. Phase 3: 릴레이 적대자 모델

### 목적

악의적 Guard+Exit 릴레이를 DirectoryService에 주입하여, 회로의 Guard와 Exit이 모두 적대자 소유일 때 침해로 판정. 논문의 **relay-level adversary** 모델 재현.

### 새 파일

#### `internal/relay/adversary.go`

```go
type RelayAdversary struct {
    GuardASN  types.ASN  // "_ADV_GUARD" (합성 ASN)
    ExitASN   types.ASN  // "_ADV_EXIT" (합성 ASN)
    GuardBWKB int64
    ExitBWKB  int64
}
```

| 메서드 | 기능 |
|--------|------|
| `NewRelayAdversary(cfg)` | 대역폭을 GuardExitRatio로 분배 (5:1 → Guard 83.3%, Exit 16.7%) |
| `InjectIntoDirectory(dirSvc)` | 합성 Guard/Exit ASNode 주입 → 가중치 배열 재구축 |
| `IsCompromised(circ)` | Guard AND Exit 모두 적대자 → true |
| `IsGuardCompromised(circ)` | Guard만 적대자 |
| `IsExitCompromised(circ)` | Exit만 적대자 |

### 변경 파일

#### `internal/config/config.go`

```go
type RelayAdversaryConfig struct {
    Enabled        bool    `yaml:"enabled"`
    BandwidthKB    int64   `yaml:"bandwidth_kb"`     // 총 대역폭
    GuardExitRatio float64 `yaml:"guard_exit_ratio"` // Guard:Exit 비율
}
```

`SimConfig`에 `RelayAdversary RelayAdversaryConfig` 필드 추가.
`applyDefaults`: `GuardExitRatio` 기본값 5.0.
`Validate`: `BandwidthKB > 0`, `GuardExitRatio > 0` 검증.

#### `internal/directory/service.go`

| 추가 | 내용 |
|------|------|
| `InjectNodes(nodes []ASNode)` | 노드 추가 후 `rebuildWeights()` 호출 |
| `rebuildWeights()` | guard/exit/middle 가중치 배열 전체 재구축 |

#### `internal/observer/logger.go`

```go
func (ol *ObservationLogger) LogRelayCompromise(
    tick int64, circID CircuitID, clientID NodeID,
    clientASN ASN, guardCompromised, exitCompromised bool,
)
```

NDJSON 마커 형식:
```json
{"type":"relay_compromise","tick":1000,"circuit_id":"C42","client_id":"N1",
 "client_asn":"AS100","guard_compromised":true,"exit_compromised":true}
```

#### `internal/engine/events.go`

| 변경 | 내용 |
|------|------|
| `CircuitBuildEvent` | `RelayAdv *relay.RelayAdversary` 필드 추가 |
| `CircuitRotateEvent` | `RelayAdv *relay.RelayAdversary` 필드 추가 |
| `CircuitBuildEvent.Execute()` | 회로 생성 후 침해 판정 → `LogRelayCompromise` |
| `CircuitRotateEvent.Execute()` | 회로 교체 후 침해 판정 → `LogRelayCompromise` |

Guard만/Exit만 침해도 별도 로깅 (논문 Figure 2b, 2c 재현용).

#### `cmd/next-simulate/main.go`

방어 전략 설정 이후:
```go
if cfg.RelayAdversary.Enabled {
    relayAdv = relay.NewRelayAdversary(cfg.RelayAdversary)
    relayAdv.InjectIntoDirectory(dirSvc)
}
```
이벤트 스케줄링 시 `RelayAdv` 전달.

### 시나리오 config

**`configs/relay_adversary.yaml`**: 6개월 longitudinal, 200 클라이언트, 100 MiB/s 적대자 대역폭, 비대칭 라우팅 활성화, BGP/temporal 비활성화.

---

## 5. Phase 4: 사용자 모델 + Exit 정책

### 목적

포트 기반 Exit 필터링과 사용자 모델(Typical, IRC, BitTorrent)을 구현하여 논문의 "사용자 행동에 따른 보안 차이" 분석 재현.

### 사용자 모델 정의

| 모델 | 포트 | 논문 참조 |
|------|------|-----------|
| Typical | 80, 443 | 일반 웹 브라우징 |
| IRC | 6667, 6697 | IRC 채팅 (소수 exit만 허용) |
| BitTorrent | 6881-6999 | P2P 파일 공유 (대부분 exit 차단) |
| Uniform | (없음) | 포트 필터링 없음 (기본) |

**핵심 가설**: IRC/BitTorrent는 해당 포트를 허용하는 exit AS가 적으므로, 적대자의 exit 선택 확률이 상대적으로 높아져 침해율이 증가한다.

### 새 파일

#### `internal/usermodel/model.go`

```go
var Typical    = []int{80, 443}
var IRC        = []int{6667, 6697}
var BitTorrent = []int{6881, 6882, ..., 6999}  // 119개 포트

func PortsFromConfig(cfg config.UserModelConfig) []int
```

#### `internal/loader/exit_policies.go`

```go
func LoadExitPolicies(path string) (map[types.ASN][]int, error)
```

JSON 형식: `{"AS1234": [80, 443, ...], "AS5678": [80, 443, 6667, ...]}`

### 변경 파일

#### `internal/types/node.go`

```go
type Client struct {
    ...
    DestPorts []int  // nil = 포트 필터링 없음
}
```

#### `internal/config/config.go`

```go
type UserModelConfig struct {
    Type      string `yaml:"type"`       // "typical"|"irc"|"bittorrent"|"uniform"
    DestPorts []int  `yaml:"dest_ports"` // 직접 지정 시
}
```

`ClientsConfig`에 `UserModel UserModelConfig` 필드 추가.
`NetworkConfig`에 `ExitPolicies string` 필드 추가.

#### `internal/directory/service.go`

| 추가 | 내용 |
|------|------|
| `exitPolicies map[ASN]map[int]bool` | AS별 허용 포트 집합 |
| `LoadExitPolicies(policies)` | JSON 데이터를 내부 맵으로 변환 |
| `SelectExitASForPorts(rng, exclude, ports)` | 요구 포트 미허용 AS를 exclude에 추가 후 `SelectExitAS` 호출 |

#### `internal/circuit/manager.go`

`BuildCircuit`에서 포트 기반 exit 선택:
```go
if len(client.DestPorts) > 0 {
    exitASN = cm.dir.SelectExitASForPorts(cm.rng, excludeExit, client.DestPorts)
} else {
    exitASN = cm.dir.SelectExitAS(cm.rng, excludeExit)
}
```

### 시나리오 configs

| 파일 | user_model.type |
|------|-----------------|
| `configs/relay_adv_typical.yaml` | "typical" |
| `configs/relay_adv_irc.yaml` | "irc" |
| `configs/relay_adv_bittorrent.yaml` | "bittorrent" |

모두 relay_adversary + asymmetric_routing + exit_policies 활성화.

---

## 6. Phase 5: 스케일 확장

### Lazy Path Caching

`config.go`에 `PrecomputePaths bool` 필드 추가. `main.go`에서:

```go
if !cfg.Simulation.PrecomputePaths {
    // PrecomputeAll 스킵 → FindPathCached가 cache miss 시 on-demand 계산
} else {
    asgraph.PrecomputeAll(graph, pathCache)
}
```

727 AS에서 확장된 그래프(~5,000-10,000 AS)로 확대 시 O(n²) 사전 계산 회피.
`FindPathCached`와 `FindDirectionalPathCached`는 이미 cache miss 시 자동 계산하므로 추가 코드 불필요.

### Per-Entity 위협 분석

#### `tor-anal/analysis/entity_threat.py`

| 함수 | 기능 |
|------|------|
| `compute_per_entity_threat(obs_df, gt_df)` | AS별 entry+exit 관찰 빈도 → 위협 점수 순위 |
| `top_threats_per_client_location(obs_df, gt_df, top_n)` | 클라이언트 위치별 상위 N개 위협 AS |

위협 점수 = `both_count / total_circuits` (해당 AS가 entry와 exit을 동시에 관찰한 회로 수 / 전체 회로 수).

---

## 7. 파일 변경 요약

### 새 파일 (12개)

| 파일 | Phase | 설명 |
|------|-------|------|
| `next-simulate/internal/relay/adversary.go` | 3 | 릴레이 적대자 모델 |
| `next-simulate/internal/usermodel/model.go` | 4 | 사용자 모델 정의 |
| `next-simulate/internal/loader/exit_policies.go` | 4 | Exit 정책 JSON 로더 |
| `next-simulate/configs/relay_adversary.yaml` | 3 | 릴레이 적대자 시나리오 |
| `next-simulate/configs/relay_adv_typical.yaml` | 4 | Typical 사용자 시나리오 |
| `next-simulate/configs/relay_adv_irc.yaml` | 4 | IRC 사용자 시나리오 |
| `next-simulate/configs/relay_adv_bittorrent.yaml` | 4 | BitTorrent 사용자 시나리오 |
| `tor-anal/analysis/cdf_analysis.py` | 1 | CDF 계산 (4개 함수) |
| `tor-anal/analysis/cdf_visualize.py` | 1 | CDF 시각화 (4개 플롯) |
| `tor-anal/analysis/relay_adversary_analysis.py` | 3 | 릴레이 침해 분석 |
| `tor-anal/analysis/entity_threat.py` | 5 | Per-entity 위협 분석 |
| `scripts/multi_seed_run.sh` | 1 | 다중 시드 실행 스크립트 |

### 수정 파일 (8개)

| 파일 | Phase | 변경 내용 |
|------|-------|----------|
| `next-simulate/internal/config/config.go` | 2,3,4,5 | `AsymmetricRouting`, `PrecomputePaths`, `RelayAdversaryConfig`, `UserModelConfig`, `ExitPolicies` |
| `next-simulate/internal/circuit/manager.go` | 2,4 | `dirPathCache` 필드, `TransitASes` 분기, 포트 기반 exit 선택 |
| `next-simulate/internal/directory/service.go` | 3,4 | `InjectNodes()`, `rebuildWeights()`, `exitPolicies`, `SelectExitASForPorts()` |
| `next-simulate/internal/observer/logger.go` | 3 | `LogRelayCompromise()` |
| `next-simulate/internal/engine/events.go` | 2,3 | `RelayAdv` 필드, `UpdateTopology` 시그니처, 침해 판정 로직 |
| `next-simulate/cmd/next-simulate/main.go` | 2,3,4,5 | `dirPathCache` 초기화, relay adversary, exit 정책, 사용자 모델, lazy caching |
| `next-simulate/internal/types/node.go` | 4 | `Client.DestPorts` 필드 |
| `tor-anal/analysis/run_analysis.py` | 1 | `--cdf`, `--tick-interval-ms`, `--multi-seed-dirs`, CDF 분석/시각화 파이프라인 |

### 테스트 파일 수정 (1개)

| 파일 | 변경 |
|------|------|
| `next-simulate/internal/circuit/manager_test.go` | `NewCircuitManager` 호출에 `nil` (dirPathCache) 추가 |

---

## 8. 호환성 보장

- 모든 새 config 필드의 zero value가 기존 동작 유지:
  - `asymmetric_routing: false` → 대칭 BFS (기존)
  - `precompute_paths: false` (미지정 시) → `PrecomputeAll` 실행 (기존 main.go 로직)
  - `relay_adversary.enabled: false` → 릴레이 적대자 비활성화
  - `user_model.type: ""` → 포트 필터링 없음
  - `exit_policies: ""` → Exit 정책 미적용
- **기존 4개 YAML config는 변경하지 않음**
- **기존 Python 분석 모듈은 수정하지 않고 새 모듈만 추가**
- Go 전체 빌드 성공: `go build ./...` ✓
- Go 전체 테스트 통과: `go test ./...` ✓ (15 패키지)
- Python 전체 import 검증: ✓

---

## 9. 실행 가이드

### 릴레이 적대자 시뮬레이션

```bash
cd next-simulate
go run ./cmd/next-simulate -config configs/relay_adversary.yaml
```

### 사용자 모델별 비교

```bash
go run ./cmd/next-simulate -config configs/relay_adv_typical.yaml
go run ./cmd/next-simulate -config configs/relay_adv_irc.yaml
go run ./cmd/next-simulate -config configs/relay_adv_bittorrent.yaml
```

### CDF 분석

```bash
cd tor-anal
uv run python -m analysis.run_analysis \
  --vanilla-obs ../next-simulate/output/observations_relay_adv.ndjson \
  --vanilla-gt ../next-simulate/output/ground_truth_relay_adv.ndjson \
  --cdf --tick-interval-ms 60000
```

### 사용자 모델 비교 분석

```bash
uv run python -m analysis.run_analysis \
  --vanilla-obs ../next-simulate/output/observations_relay_adv_typical.ndjson \
  --vanilla-gt ../next-simulate/output/ground_truth_relay_adv_typical.ndjson \
  --cr-obs ../next-simulate/output/observations_relay_adv_irc.ndjson \
  --cr-gt ../next-simulate/output/ground_truth_relay_adv_irc.ndjson \
  --cdf
```

### 다중 시드 실행

```bash
cd next-simulate
../scripts/multi_seed_run.sh 10 configs/relay_adversary.yaml
```

---

## 10. 논문 대응표

| 논문 요소 | 구현 위치 | 비고 |
|-----------|----------|------|
| Figure 2a: Time to first compromise CDF | `cdf_analysis.compute_time_to_first_compromise` | network + relay 적대자 |
| Figure 2b: Guard compromise | `relay/adversary.IsGuardCompromised` | 별도 마커 로깅 |
| Figure 2c: Exit compromise | `relay/adversary.IsExitCompromised` | 별도 마커 로깅 |
| Figure 3: Stream compromise fraction | `cdf_analysis.compute_stream_compromise_fraction` | 일별 분해 |
| Table 2: User model comparison | `usermodel/model.go` + `configs/relay_adv_*.yaml` | Typical/IRC/BitTorrent |
| Asymmetric routing | `circuit/manager.TransitASes` + `asgraph.FindDirectionalPath` | A→B ≠ B→A |
| Relay adversary bandwidth | `relay/adversary.NewRelayAdversary` | 설정 가능 대역폭 + 비율 |
| Exit policy filtering | `directory/service.SelectExitASForPorts` | 포트별 exit 제한 |
| Multi-seed confidence | `cdf_analysis.compute_cdf_with_confidence` | DKW 신뢰 구간 |

---

## 11. 향후 과제

1. **Exit 정책 데이터 수집** (`step_11_exit_policies.py`): Onionoo `/details` API에서 `exit_policy_summary` 파싱 → `as_exit_policies.json` 생성
2. **확장 AS 그래프** (`step_12_expanded_topology.py`): Tor AS에서 2-hop 이내 CAIDA AS 포함 (727 → ~5,000-10,000 AS)
3. **실제 시뮬레이션 실행 및 논문 결과 대조**: 위 인프라를 활용하여 6개월 시뮬레이션 수행, 논문 Figure 2/3과 정량적 비교
4. **M7 Hidden Service 통합**: LATER.md 참조, Vanguards 방어와 릴레이 적대자의 상호작용 분석
