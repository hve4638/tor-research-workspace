# 05. 시나리오와 방어 전략

## 공통 시뮬레이션 조건

4개 시나리오 모두 동일한 조건에서 **방어 전략만 다르게** 적용하여, 각 방어의 효과를 정량적으로 비교한다.

| 항목 | 값 |
|------|-----|
| 기간 | 90일 |
| 클라이언트 | 50명, 각 3개 회로, 10분(MaxCircuitDirtiness)마다 교체 |
| AS 토폴로지 | 727 AS, 30일마다 CAIDA 스냅샷 전환 (1월 → 2월 → 3월) |
| BGP 공격 | 3건 (아래 상세) |
| 관찰자 | Passive, Global scope |
| 시드 | 42 (재현 가능) |
| 전체 회로 수 | 1,944,150개 |

---

## BGP 공격 3건

3건의 BGP 공격은 서로 다른 공격 유형, 적대자 모델, 대상 AS를 조합하여 다양한 위협 시나리오를 테스트한다.

### 공격 #0: 단일 AS Hijack

| 항목 | 값 |
|------|-----|
| 유형 | Hijack (prefix 탈취) |
| 공격자 | AS174 (Cogent Communications) |
| 적대자 모델 | SingleAS (1개 AS) |
| 대상 | AS24940 (Hetzner) — 대형 Guard 호스팅 |
| 시점 | 15일차 |
| 지속 | 6시간 |

**메커니즘**: AS24940의 모든 provider edge를 제거하고 AS174를 유일한 provider로 삽입. Hetzner로 향하는 모든 트래픽이 Cogent를 경유하게 된다.

**선택 이유**: 단일 Tier-1 AS가 단독으로 수행하는 가장 기본적인 hijack 시나리오.

### 공격 #1: Tier-1 Interception

| 항목 | 값 |
|------|-----|
| 유형 | Interception (경로 삽입) |
| 공격자 | AS3356 (Level3/Lumen) |
| 적대자 모델 | Tier1 (AS3356 + 직접 고객 = 140개 AS) |
| 대상 | AS60729 |
| 시점 | 45일차 |
| 지속 | 12시간 |

**메커니즘**: AS3356을 AS60729의 추가 provider로 삽입. 기존 provider는 유지. 일부 트래픽만 공격자를 경유하며, 기존 연결은 정상 전달되어 은밀하다.

**선택 이유**: Tier-1 AS의 대규모 고객 네트워크를 활용한 은밀한 interception 시나리오.

### 공격 #2: 국가 수준 Hijack

| 항목 | 값 |
|------|-----|
| 유형 | Hijack (prefix 탈취) |
| 공격자 | AS3320 (Deutsche Telekom) |
| 적대자 모델 | StateLevel DE (독일 73개 AS) |
| 대상 | AS6939 (Hurricane Electric) — 전체 transit의 17.7% |
| 시점 | 60일차 |
| 지속 | 24시간 |

**메커니즘**: 독일 국가 적대자가 73개 AS를 동원하여 Hurricane Electric(글로벌 최대 transit AS)을 hijack. 대규모 경로 변경을 유발하여 광범위한 트래픽 관찰.

**선택 이유**: 국가 수준 적대자가 핵심 transit AS를 공격하는 최대 위협 시나리오.

---

## 4개 시나리오

### 1. Vanilla (방어 없음) — 기준선

- **설정**: `configs/bgp_attack.yaml`
- **Guard 선택**: 대역폭 가중치만 사용 (Tor 기본 동작)
- **회로 생성**: 일반 3-hop (안전성 검사 없음)
- **역할**: 다른 시나리오의 비교 기준선(baseline)

### 2. Counter-RAPTOR (Guard 재가중)

- **설정**: `configs/counter_raptor_defense.yaml`
- **방어 지점**: Guard 선택 단계
- **핵심 로직**:

```
기존 Guard 선택 확률:
  P(Guard_j) = bandwidth_weight_j / Σ(bandwidth_weight)

Counter-RAPTOR Guard 선택 확률:
  P(Guard_j) = bandwidth_weight_j × (1/p_entry_j)^weight_factor / Σ(...)
```

| 파라미터 | 값 | 의미 |
|----------|-----|------|
| `weight_factor` | 1.0 | resilience 점수의 지수 (높을수록 효과 강함) |
| `max_cap` | 100.0 | 1/p_entry 상한 (발산 방지) |

- **효과**: p_entry가 높은 AS(= 많은 경로가 지나가는, 관찰 위험이 큰 AS)의 Guard 선택 확률을 낮추고, p_entry가 낮은 AS(= 관찰 위험이 낮은 AS)의 선택 확률을 높인다.
- **한계**: Guard 선택만 변경하므로, Guard 이후의 transit 경로를 통한 관찰은 막지 못한다.

### 3. Astoria (회로 안전성 검사)

- **설정**: `configs/astoria_defense.yaml`
- **방어 지점**: 회로 생성 단계
- **핵심 로직**:

```
1. 후보 회로 생성 (Guard - Middle - Exit)
2. entry transit AS 계산 = Client → Guard 경로의 모든 AS
3. exit transit AS 계산  = Middle → Exit 경로의 모든 AS
4. 교집합 검사: entry_transit ∩ exit_transit
   ├─ 교집합 없음 → SAFE: 동일 AS의 entry+exit 동시 관찰 불가 → 채택
   └─ 교집합 있음 → UNSAFE: 상관 위험 → 폐기, 재시도
5. 최대 5회 재시도 후 모두 실패 → 마지막 회로를 fallback으로 사용
```

| 파라미터 | 값 | 의미 |
|----------|-----|------|
| `max_retries` | 5 | 안전한 회로를 찾기 위한 최대 재시도 횟수 |

- **효과**: 동일 AS가 entry와 exit를 동시 관찰하는 회로를 원천 차단한다.
- **비용**: 회로 생성 시 추가 연산 (재시도). 단, 98.2%가 5회 이내 안전한 회로를 찾음.

### 4. Combined (Counter-RAPTOR + Astoria)

- **설정**: `configs/combined_defense.yaml`
- **동작**: Guard 선택 시 CR 재가중 적용 **+** 회로 생성 시 Astoria 교집합 검사
- **역할**: 두 방어를 동시 적용했을 때 추가적인 상관율 감소가 있는지 검증
- **결과**: Astoria가 이미 상관을 거의 제거하므로 CR의 추가 효과는 미미하나, fallback 회로에서 미세한 추가 감소 (12건 → 5건)

---

## YAML 설정 구조

4개 시나리오는 동일한 YAML 구조를 공유하며, `defense` 블록만 다르다:

```yaml
simulation:
  mode: "longitudinal"
  duration: "90d"
  seed: 42
  tick_interval_ms: 60000           # 1분 = 1 tick

network:
  as_model: "../tor-anal/output/as_model_simplified.json"
  as_edges: "../tor-anal/data/model_edges.json"
  as_geo_map: "../tor-anal/output/as_geo_map.json"
  weights: { wgg: 0.5869, wgm: 1.0, ... }

clients:
  count: 50
  circuits_per_client: 3
  rotation_interval_min: 10         # MaxCircuitDirtiness

temporal:
  enabled: true
  snapshots:                        # 30일마다 CAIDA 스냅샷 전환
    - { tick: 0,     edges: "model_edges_20250101.json" }
    - { tick: 43200, edges: "model_edges_20250201.json" }
    - { tick: 86400, edges: "model_edges_20250301.json" }

bgp:
  enabled: true
  attacks:
    - { type: "hijack",       attacker_as: "AS174",  target_as: "AS24940",
        start_day: 15, duration_hours: 6,  adversary_type: "single" }
    - { type: "interception", attacker_as: "AS3356", target_as: "AS60729",
        start_day: 45, duration_hours: 12, adversary_type: "tier1" }
    - { type: "hijack",       attacker_as: "AS3320", target_as: "AS6939",
        start_day: 60, duration_hours: 24, adversary_type: "state", country: "DE" }

# ↓ 시나리오별로 이 블록만 다름
defense:
  counter_raptor:
    enabled: false                  # Vanilla: false, CR/Combined: true
    as_path_prob_path: "../tor-anal/output/as_path_probabilities.json"
    weight_factor: 1.0
    max_cap: 100.0
  astoria:
    enabled: false                  # Vanilla: false, Astoria/Combined: true
    max_retries: 5

observer:
  mode: "passive"
  scope: "global"

output:
  observation_log: "output/observations_bgp.ndjson"
  ground_truth_log: "output/ground_truth_bgp.ndjson"
```

---

## 실행 명령

```bash
cd next-simulate

# 1. Vanilla (기준선)
go run ./cmd/next-simulate -config configs/bgp_attack.yaml

# 2. Counter-RAPTOR
go run ./cmd/next-simulate -config configs/counter_raptor_defense.yaml

# 3. Astoria
go run ./cmd/next-simulate -config configs/astoria_defense.yaml

# 4. Combined
go run ./cmd/next-simulate -config configs/combined_defense.yaml
```

각 시나리오는 2개의 NDJSON 파일을 생성한다:
- `observations_*.ndjson`: AS-level 관찰 로그
- `ground_truth_*.ndjson`: 실제 회로 매핑 (검증용)

4개 시나리오 × 2개 파일 = **총 8개 NDJSON** 파일이 모이면 Python 분석 단계로 진행한다.
