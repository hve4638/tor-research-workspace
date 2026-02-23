# 실험 환경

## 하드웨어

| 항목 | 사양 |
|------|------|
| 플랫폼 | Linux 5.15.0-164-generic (x86_64) |
| 가용 디스크 | ~400 GB (출력물 ~12 GB 사용) |
| RAM 최대 사용량 | ~2 GB (스트리밍 분석), ~4 GB (Go 시뮬레이션) |

## 소프트웨어 버전

| 도구 | 버전 | 용도 |
|------|------|------|
| Go | 1.23+ | 시뮬레이션 엔진 (`next-simulate`) |
| Python | 3.12+ (`uv` 경유) | 분석 파이프라인 (`tor-anal`) |
| uv | 최신 | Python 패키지 관리 |
| matplotlib | 3.x | 시각화 (Agg 백엔드) |
| pandas | 2.x | DataFrame 연산 |

## 데이터 출처

### AS 토폴로지

| 항목 | 상세 |
|------|------|
| 제공자 | CAIDA AS-Relationships |
| 형식 | `.as-rel2.txt` (peer/provider-customer) |
| 사용 스냅샷 | 2025-01-01, 2025-02-01, 2025-03-01 |
| 초기 그래프 | 727 노드, 6,191 엣지 |
| 노드 범위 | Tor 관련 AS만 |

### Tor 릴레이 데이터

| 항목 | 상세 |
|------|------|
| 제공자 | Tor Project Onionoo API |
| 수집일 | 2025-01 (파이프라인 Step 01) |
| 릴레이 수 | 727개 고유 AS로 집계 |
| Guard AS | 704개 |
| Exit AS | 220개 |

### 대역폭 가중치 (Tor 디렉토리 합의)

```yaml
weights:
  wgg: 0.5869    # Guard → Guard 위치
  wgm: 1.0       # Guard → Middle 위치
  wgd: 0.5869    # Guard → Guard+Exit 위치
  wee: 0.5869    # Exit → Exit 위치
  wem: 0.0       # Exit → Middle 위치
  weg: 0.4131    # Exit → Guard 위치
  wed: 0.5869    # Exit → Guard+Exit 위치
  wmg: 0.4131    # Middle → Guard 위치
  wme: 0.4131    # Middle → Exit 위치
  wmm: 1.0       # Middle → Middle 위치
  wmd: 0.4131    # Middle → Guard+Exit 위치
```

## 시뮬레이션 엔진 설정

### 공통 파라미터

| 파라미터 | 값 | 비고 |
|----------|-----|------|
| `seed` | 42 | 결정적 PRNG |
| `tick_interval_ms` | 60,000 | 1분 틱 |
| `time_scale` | 0 | 고속 실행 (실시간 페이싱 없음) |
| `mode` | "longitudinal" | 전체 시간 시뮬레이션 |
| `observer.mode` | "passive" | 능동 탐색 없음 |
| `observer.scope` | "global" | AS 수준 글로벌 관찰자 |

### 클라이언트 설정

| 파라미터 | 세트 A (네트워크) | 세트 B (릴레이) |
|----------|-----------------|----------------|
| `count` | 50 | 200 |
| `distribution` | "uniform" | "uniform" |
| `guard.init_mode` | "fresh_start" | "fresh_start" |
| `guard.max_sample_size` | 60 | 60 |
| `guard.lifetime_days_min` | 30 | 30 |
| `guard.lifetime_days_max` | 60 | 60 |
| `guard.n_primary_guards` | 3 | 3 |
| `circuit.max_dirtiness_sec` | 600 | 600 |
| `circuit.circuits_per_client` | 3 | 3 |

### 세트 A: BGP 공격 일정

4개 네트워크 방어 시나리오 모두 동일한 공격 일정 공유:

| 공격 | 유형 | 공격자 | 대상 | 시작일 | 기간 | 적대자 |
|------|------|--------|------|--------|------|--------|
| 0 | 탈취 | AS174 (Cogent) | AS24940 (Hetzner) | 15일 | 6시간 | single |
| 1 | 가로채기 | AS3356 (Level3) | AS60729 | 45일 | 12시간 | tier1 |
| 2 | 탈취 | AS3320 (DTAG) | AS6939 (HE) | 60일 | 24시간 | state (DE) |

### 세트 A: 방어 설정

| 시나리오 | Counter-RAPTOR | Astoria |
|----------|---------------|---------|
| Vanilla | 비활성화 | 비활성화 |
| Counter-RAPTOR | 활성화 (weight_factor=1.0, max_cap=100.0) | 비활성화 |
| Astoria | 비활성화 | 활성화 (max_retries=5) |
| Combined | 활성화 | 활성화 |

Counter-RAPTOR는 `tor-anal/output/as_path_probabilities.json`의 AS 경로 확률 데이터를 사용.

### 세트 B: 릴레이 적대자 설정

| 파라미터 | 값 | 비고 |
|----------|-----|------|
| `bandwidth_kb` | 102,400 | 총 100 MiB/s |
| `guard_exit_ratio` | 5.0 | Guard 83.3%, Exit 16.7% |
| `asymmetric_routing` | true | 방향별 BFS |
| `duration` | 180일 | 6개월 |
| `temporal` | 비활성화 | 단일 스냅샷 |
| `bgp` | 비활성화 | BGP 공격 없음 |

## 랜덤 시드 재현성

모든 실험에서 `seed: 42` 사용. Go의 결정적 PRNG가 동일 config로
재실행 시 동일한 결과를 보장한다. 검증: 재실행 후 `wc -l` 비교.

## 시뮬레이션 출력 크기

### 세트 A: 네트워크 적대자

| 파일 | 크기 |
|------|------|
| `observations_bgp.ndjson` | 586 MB |
| `ground_truth_bgp.ndjson` | 432 MB |
| `observations_cr.ndjson` | 586 MB |
| `ground_truth_cr.ndjson` | 432 MB |
| `observations_astoria.ndjson` | 574 MB |
| `ground_truth_astoria.ndjson` | 432 MB |
| `observations_combined.ndjson` | 566 MB |
| `ground_truth_combined.ndjson` | 432 MB |
| **소계** | **~4.0 GB** |

### 세트 B: 릴레이 적대자

| 파일 | 크기 |
|------|------|
| `observations_relay_adv.ndjson` | 6.2 GB |
| `ground_truth_relay_adv.ndjson` | 3.5 GB |
| **소계** | **~9.7 GB** |
