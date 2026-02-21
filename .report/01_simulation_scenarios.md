# 1단계: 4개 시나리오 시뮬레이션 설명

> 동일한 조건에서 방어 전략만 다르게 적용하여, 각 방어의 효과를 정량적으로 비교한다.

---

## 공통 조건 (4개 시나리오 모두 동일)

| 항목 | 값 |
|------|-----|
| 기간 | 90일 |
| 클라이언트 | 50명, 각 3개 회로, 10분마다 회전 |
| AS 토폴로지 | 727 AS, 30일마다 스냅샷 전환 (1월 → 2월 → 3월) |
| BGP 공격 | 3건 (아래 표 참조) |
| 시드 | 42 (재현 가능) |
| 관찰자 | Passive, Global scope |

### BGP 공격 3건

| # | 유형 | 공격자 | 적대자 모델 | 대상 | 시점 | 지속 |
|---|------|--------|------------|------|------|------|
| 1 | Hijack | AS174 (Cogent) | SingleAS (1개 AS) | AS24940 (Hetzner) | 15일차 | 6시간 |
| 2 | Interception | AS3356 (Level3) | Tier1 (140개 AS) | AS60729 | 45일차 | 12시간 |
| 3 | Hijack | AS3320 (Deutsche Telekom) | StateLevel DE (73개 AS) | AS6939 (Hurricane Electric) | 60일차 | 24시간 |

- **Hijack**: victim의 모든 provider edge를 제거하고 공격자를 유일한 provider로 삽입. 모든 트래픽이 공격자를 경유.
- **Interception**: 공격자를 target의 추가 provider로 삽입. 기존 provider 유지. 일부 트래픽만 경유 (hijack보다 은밀).

---

## 시나리오별 차이

### 1. Vanilla (방어 없음) — 기준선

- **설정**: `configs/bgp_attack.yaml`
- **출력**: `observations_bgp.ndjson` (586MB) — **실행 완료**
- **동작**: Tor 기본 Guard 선택 (대역폭 가중치만) + 일반 회로 생성
- **역할**: 다른 시나리오의 비교 기준선(baseline)

### 2. Counter-RAPTOR (Guard 재가중)

- **설정**: `configs/counter_raptor_defense.yaml`
- **출력**: `observations_cr.ndjson` — **미실행**
- **방어 지점**: Guard 선택 단계
- **핵심 로직**:

```
기존 Guard 선택 확률 = bandwidth_weight
CR Guard 선택 확률   = bandwidth_weight × (1/p_entry)^weight_factor
```

| 파라미터 | 값 | 의미 |
|----------|-----|------|
| `as_path_prob_path` | `as_path_probabilities.json` | AS별 p_entry (관찰 확률) 데이터 |
| `weight_factor` | 1.0 | resilience 점수의 지수 (높을수록 효과 강함) |
| `max_cap` | 100.0 | 1/p_entry 상한 (p_entry=0일 때 발산 방지) |

- **효과**: p_entry가 높은 AS (= 많은 경로가 지나가는 AS, 관찰당할 확률 높음)의 Guard 선택 확률을 낮추고, p_entry가 낮은 AS (= 관찰 확률 낮음)의 선택 확률을 높인다.
- **참조**: Sun et al., "Counter-RAPTOR: Safeguarding Tor Against Active Routing Attacks", IEEE S&P 2017

### 3. Astoria (회로 안전성 검사)

- **설정**: `configs/astoria_defense.yaml`
- **출력**: `observations_astoria.ndjson` — **미실행**
- **방어 지점**: 회로 생성 단계
- **핵심 로직**:

```
1. 회로 생성 (Guard - Middle - Exit)
2. entry transit AS = client → Guard 경로에 있는 모든 AS
3. exit transit AS  = Middle → Exit 경로에 있는 모든 AS
4. 교집합 검사: entry_transit ∩ exit_transit
   - 교집합 없음 → SAFE (동일 AS가 entry+exit 동시 관찰 불가)
   - 교집합 있음 → UNSAFE → 회로 폐기, 재시도
5. 최대 5회 재시도 후 모두 실패 → 마지막 회로를 fallback으로 사용
```

| 파라미터 | 값 | 의미 |
|----------|-----|------|
| `max_retries` | 5 | 안전한 회로를 찾기 위한 최대 재시도 횟수 |

- **효과**: 동일 AS가 entry(client→Guard)와 exit(Middle→Exit) 경로를 동시에 관찰할 수 없는 회로만 선택한다.
- **참조**: Nithyanand et al., "Astoria: AS-Aware Relay Selection for Tor", NDSS 2015

### 4. Combined (Counter-RAPTOR + Astoria)

- **설정**: `configs/combined_defense.yaml`
- **출력**: `observations_combined.ndjson` — **미실행**
- **동작**: Guard 선택 시 CR 재가중 적용 + 회로 생성 시 Astoria 교집합 검사
- **역할**: 두 방어를 동시 적용했을 때 추가적인 상관율 감소가 있는지 검증

---

## 비교 분석 목표

```
같은 90일, 같은 BGP 공격 3건에 대해:

Vanilla:  상관율 X%  ← 기준선
CR:       상관율 Y%  ← Guard 재가중만으로 얼마나 낮아지나?
Astoria:  상관율 Z%  ← 회로 검사만으로 얼마나 낮아지나?
Combined: 상관율 W%  ← 둘 다 적용하면 추가 효과가 있나?
```

추가로 공격 기간별(pre/during/post) 상관율 변화도 비교하여, 각 방어가 BGP 공격 상황에서도 효과적인지 분석한다.

---

## 실행 명령

```bash
cd next-simulate

# Vanilla — 이미 완료
# go run ./cmd/next-simulate -config configs/bgp_attack.yaml

# Counter-RAPTOR
go run ./cmd/next-simulate -config configs/counter_raptor_defense.yaml

# Astoria
go run ./cmd/next-simulate -config configs/astoria_defense.yaml

# Combined
go run ./cmd/next-simulate -config configs/combined_defense.yaml
```

---

## 실행 후 산출물

각 시나리오는 2개의 NDJSON 파일을 생성한다:

| 파일 | 내용 |
|------|------|
| `observations_*.ndjson` | AS-level 관찰 로그 (관찰자가 볼 수 있는 메타데이터) |
| `ground_truth_*.ndjson` | 실제 회로 매핑 (검증/분석용 정답 데이터) |

4개 시나리오 × 2개 파일 = 총 8개 NDJSON 파일이 모이면 Python 분석 단계로 진행한다.
