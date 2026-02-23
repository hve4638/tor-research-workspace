# 실험 환경

## 하드웨어

| 항목 | 사양 |
|------|------|
| 플랫폼 | Linux 5.15.0-164-generic (x86_64) |
| 가용 디스크 | ~400 GB (출력물 ~42 GB 사용) |
| RAM 최대 사용량 | ~2 GB (스트리밍 분석), ~4 GB (Go 시뮬레이션) |

## 소프트웨어 버전

| 도구 | 버전 | 용도 |
|------|------|------|
| Go | 1.23+ | 시뮬레이션 엔진 (`next-simulate`) |
| Python | 3.12+ (`uv` 경유) | 분석 파이프라인 (`tor-anal`) |
| uv | 최신 | Python 패키지 관리 |
| matplotlib | 3.x | 시각화 (Agg 백엔드) |
| pandas | 2.x | DataFrame 연산 (entity threat 분석용) |

## 데이터 출처

### AS 토폴로지

| 항목 | 상세 |
|------|------|
| 제공자 | CAIDA AS-Relationships |
| 형식 | `.as-rel2.txt` (peer/provider-customer) |
| 사용 스냅샷 | 2025-01 ~ 2025-07 (월별 7개) |
| 초기 그래프 | 727 노드, 6,191 엣지 (2025-01-01) |
| 노드 범위 | Tor 관련 AS만 (guard/middle/exit 릴레이 호스팅) |

### Tor 릴레이 데이터

| 항목 | 상세 |
|------|------|
| 제공자 | Tor Project Onionoo API |
| 수집일 | 2025-01 (파이프라인 Step 01) |
| 릴레이 수 | 727개 고유 AS로 집계 |
| Guard AS | 704개 |
| Exit AS | 220개 |

### 스냅샷 변동 이력

| 일자 | 노드 | 엣지 | 이전 대비 변동 |
|------|------|------|---------------|
| 2025-01-01 | 727 | 6,191 | - (기준) |
| 2025-02-01 | 727 | 6,287 | +205/-109 (5.0%) |
| 2025-03-01 | 727 | 6,212 | +265/-340 (9.6%) |
| 2025-04-01 | 727 | 변동 | ~20.4% |
| 2025-05-01 | 727 | 변동 | ~5.9% |
| 2025-06-01 | 727 | 변동 | ~8.5% |
| 2025-07-01 | 727 | 변동 | ~10.2% |

### 대역폭 가중치 (Tor 디렉토리 합의)

모든 시뮬레이션에서 동일한 Tor 합의 기반 가중치 사용:

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

### 공통 파라미터 (전 실험)

| 파라미터 | 값 | 비고 |
|----------|-----|------|
| `seed` | 42 | 결정적 PRNG (재현 가능) |
| `tick_interval_ms` | 60,000 | 1분 시뮬레이션 틱 |
| `time_scale` | 0 | 실시간 페이싱 없음 (고속 실행) |
| `mode` | "longitudinal" | 전체 시간 시뮬레이션 |
| `observer.mode` | "passive" | 능동 탐색 없음 |
| `observer.scope` | "global" | AS 수준 글로벌 관찰자 |

### 클라이언트 설정 (전 실험)

| 파라미터 | 값 | 비고 |
|----------|-----|------|
| `distribution` | "uniform" | 균일 분포 |
| `guard.init_mode` | "fresh_start" | t=0에서 새 guard 선택 |
| `guard.max_sample_size` | 60 | Guard 후보 풀 크기 |
| `guard.lifetime_days_min` | 30 | Guard 최소 유지 기간 |
| `guard.lifetime_days_max` | 60 | Guard 최대 유지 기간 |
| `guard.n_primary_guards` | 3 | 클라이언트당 주 guard 수 |
| `circuit.max_dirtiness_sec` | 600 | 회로 교체 주기 (10분) |
| `circuit.circuits_per_client` | 3 | 클라이언트당 동시 회로 수 |

## 랜덤 시드 재현성

모든 실험에서 `seed: 42` 사용. Go의 결정적 PRNG가 보장하는 사항:
- 동일 config로 재실행 시 동일한 guard 선택
- 동일한 회로 경로 선택
- 동일한 클라이언트 분포

재현성 검증: 동일 config로 재실행 후 출력 파일의 `wc -l` 비교.
행 수가 정확히 일치해야 한다.

## 파일 무결성

시뮬레이션 출력은 git에 커밋하지 않음 (용량 초과). 재현 후 데이터 무결성 검증을 위해
아래 행 수를 비교:

| 파일 | 예상 행 수 |
|------|-----------|
| `obs_sym.ndjson` | ~17.6M |
| `gt_sym.ndjson` | ~7.8M |
| `obs_asym.ndjson` | ~17.9M |
| `gt_asym.ndjson` | ~7.8M |
| `obs_entity.ndjson` | ~43.5M |
| `gt_entity.ndjson` | ~19.4M |
| `obs_temporal_sym.ndjson` | ~36.3M |
| `gt_temporal_sym.ndjson` | ~15.6M |
| `obs_temporal_asym.ndjson` | ~37.0M |
| `gt_temporal_asym.ndjson` | ~15.6M |
| `obs_intercept.ndjson` | ~17.9M |
| `gt_intercept.ndjson` | ~7.8M |
