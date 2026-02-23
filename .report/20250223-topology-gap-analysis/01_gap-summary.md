# 토폴로지 규모 불일치 분석

> 작성일: 2025-02-23
> 관련 실험: `.experiments/raptor/`, `.experiments/users_get_routed/`

---

## 1. 현재 상황

RAPTOR(Sun et al., 2015)와 "Users Get Routed"(Johnson et al., 2013) 두 논문의 재현 실험이 완료되었다.

### 재현 성공 (5건)

| 실험 | 결과 | 재현 수준 |
|------|------|----------|
| UGR: 릴레이 적대자 100% 침해 | day 57-60 step function | 정량적 |
| UGR: Exit-only 90.5% | 논문과 거의 일치 | 정량적 |
| UGR: Astoria 방어 -99.97% | 극적 감소 확인 | 정량적 |
| RAPTOR R2: 시간적 churn | 단조 증가 (2.04%→3.29%) | 정성적 |
| RAPTOR R3: Tier-1 위협 순위 | 4개 Tier-1 모두 top-6 | 정성적 |

### 재현 실패 (2건)

| 실험 | 논문 | 우리 | 괴리 |
|------|------|------|------|
| RAPTOR R1: 비대칭 라우팅 | 1.66x 증가 | 1.003x (변화 없음) | factor 1.66 vs 1.00 |
| RAPTOR R4: BGP Interception | ~90% 상관율 | 2.55% (변화 없음) | 절대값 35배 차이 |

---

## 2. 문제 원인

### 근본 원인: 토폴로지 규모 (기여도 80%)

현재 AS 그래프는 **Tor 릴레이를 호스팅하는 727개 AS만** 포함한다.

```
실제 인터넷 (RAPTOR):   ~48,000 AS, 경로 5-8홉
우리 그래프:             727 AS, 경로 2-4홉
```

이로 인해:

1. **경로가 짧아 비대칭이 발생하지 않음 (R1)**
   - 2-3홉 경로에서 forward/reverse가 동일한 중간 AS를 경유
   - 비대칭의 여지가 구조적으로 없음

2. **Tier-1이 이미 모든 경로에 존재하여 Interception 효과 없음 (R4)**
   - AS6939(HE)가 경로의 20.7%를 이미 관찰
   - 공격으로 추가 관찰 가능한 경로가 거의 없음 (marginal gain ≈ 0)

3. **절대 상관율이 낮음 (전체)**
   - 논문 12-21% vs 우리 2-3%
   - 짧은 경로 = 중간 transit AS 수 적음 = 관찰 기회 적음

### 파이프라인 병목 위치

| 위치 | 파일 | 문제 |
|------|------|------|
| **Step 06 line 53** | `step_06_build_model.py` | `as_roles`에 Tor 릴레이 AS만 포함 → transit AS 노드 누락 |
| **Step 07 line 92** | `step_07_add_edges.py` | `as1 in model_asns and as2 in model_asns` → 727 AS 간 edges만 추출 |

### 보조 원인: 라우팅 모델 (기여도 20%)

- BFS는 실제 BGP 정책(LOCAL_PREF, MED, hot-potato)을 반영하지 못함
- 소규모 그래프에서 BFS의 한계가 증폭됨
- 대규모 그래프에서는 BFS로도 비대칭 효과 발생 가능

---

## 3. 해결 방안

### 3-1. Transit AS 확장 (핵심)

Step 06과 07 사이에 **Step 06b: Transit AS 확장** 단계를 추가한다.

```
현재:   Step 06 (727 Tor AS) → Step 07 (727간 edges)
수정:   Step 06 (727 Tor AS) → Step 06b (N-hop 확장) → Step 07 (확장 AS간 edges)
```

**Step 06b 알고리즘**:

1. CAIDA 전체 AS 그래프 로드 (~70만 AS)
2. 727 Tor AS를 seed로 N-hop BFS 실행
3. 발견된 transit AS를 모델에 추가 (guard_weight=0, exit_weight=0, total_relays=0)
4. 확장된 AS 집합으로 `model_asns` 갱신

**확장 규모 추정**:

| N-hop | 예상 노드 | 예상 Edges | 경로 길이 | 시뮬 시간 |
|-------|----------|-----------|----------|----------|
| 현재 (0) | 727 | 6,191 | 2-4홉 | ~15분 |
| 1-hop | ~3,000 | ~25,000 | 3-5홉 | ~1시간 |
| **2-hop** | **~8,000** | **~80,000** | **4-7홉** | **~4시간** |

**2-hop 확장이 최적**: RAPTOR 논문의 48K AS에 가장 가까우면서도 시뮬레이션 시간이 합리적.

### 3-2. Go 시뮬레이터 변경

**코드 변경 불필요**. `next-simulate`는 `as_model_simplified.json`과 `model_edges.json`을 읽는다. 노드/edges가 증가하면 자동으로 더 긴 경로를 계산한다.

단, 성능 최적화 필요:
- `precompute_paths: false` (lazy caching) 사용 → 실제 사용 경로만 캐시
- 8,000 AS의 전체 사전 계산 = 64M 쌍 → 메모리 과다 → lazy 필수

### 3-3. 구현 파일

| 파일 | 변경 |
|------|------|
| `tor-anal/pipeline/steps/step_06b_expand_topology.py` | **신규**: N-hop BFS 확장 |
| `tor-anal/pipeline/steps/step_07_add_edges.py` | 변경 없음 (`model_asns` 이미 확장됨) |
| `tor-anal/pipeline/main.py` | Step 06b 등록 |
| `next-simulate/configs/raptor_*.yaml` | `precompute_paths: false` 확인 |

---

## 4. 검증 계획

확장 토폴로지로 RAPTOR R1, R4만 재실행:

| 실험 | 기대 결과 | 통과 기준 |
|------|----------|----------|
| R1 비대칭 | factor > 1.3x | 경로 길이 증가로 forward/reverse 차이 발생 |
| R4 Interception | during > pre × 1.5 | 공격자의 marginal gain 발생 |

기존 R2, R3 결과는 유지되어야 한다 (토폴로지 확대가 단조 증가/Tier-1 순위에 부정적 영향 없음).

---

## 5. 우선순위 판단

| 항목 | 영향 | 노력 | 우선순위 |
|------|------|------|---------|
| Step 06b Transit 확장 | R1, R4 재현 가능 | 중 (1-2일) | **높음** |
| 실제 BGP RIB 경로 | 비대칭 정밀도 향상 | 대 (1주) | 낮음 (확장만으로 충분할 가능성) |
| Customer cone 전파 | R4 정밀도 향상 | 중 (2-3일) | 중 (확장 후 평가) |

**다음 단계**: Step 06b 구현 → 2-hop 확장 모델 생성 → RAPTOR R1/R4 재실행
