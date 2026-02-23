# RAPTOR 재현 프로토콜

4가지 RAPTOR 하위 실험을 재현하기 위한 정확한 단계별 프로토콜.
모든 명령어, 파라미터, 예상 출력을 기록한다.

---

## 사전 요구사항

1. **Go 시뮬레이션 엔진** 빌드 및 테스트 완료:
   ```bash
   cd /playground/00_active/project-tor/next-simulate
   go build ./...
   go test ./...
   ```

2. **Python 분석 환경** 준비:
   ```bash
   cd /playground/00_active/project-tor/tor-anal
   uv sync
   ```

3. **CAIDA 스냅샷** 준비 (월별 7개):
   ```bash
   ls tor-anal/output/snapshots/as_model_simplified_2025*.json
   # 필요: 20250101, 20250201, ..., 20250701 (최소)
   ls tor-anal/data/model_edges_2025*.json
   # 동일 날짜
   ```

4. **디스크 공간**: ~50 GB 여유 (시뮬레이션 출력 총 ~42 GB)

---

## Phase A: R1 + R3 시뮬레이션 (병렬, 총 ~25분)

### A1. R1 대칭 라우팅 기준선

```bash
cd /playground/00_active/project-tor/next-simulate
go run ./cmd/next-simulate -config configs/raptor_baseline_sym.yaml
```

| 파라미터 | 값 |
|----------|-----|
| Config | `configs/raptor_baseline_sym.yaml` |
| 기간 | 90일 (129,600 틱) |
| 클라이언트 | 200 |
| 비대칭 라우팅 | **false** |
| 시간 스냅샷 | 3개 (2025-01, 02, 03) |
| BGP 공격 | 없음 |
| 출력 obs | `output/raptor/obs_sym.ndjson` (~2.5 GB) |
| 출력 gt | `output/raptor/gt_sym.ndjson` (~1.7 GB) |
| 실행 시간 | ~10분 |
| 총 회로 수 | 7,776,600 |

**검증**:
```bash
wc -l output/raptor/obs_sym.ndjson output/raptor/gt_sym.ndjson
# obs: ~17.6M 행, gt: ~7.8M 행
head -1 output/raptor/obs_sym.ndjson | python3 -m json.tool
# 포함 필드: circuit_id, asn, is_entry, is_exit, tick
```

### A2. R1 비대칭 라우팅 비교

```bash
go run ./cmd/next-simulate -config configs/raptor_baseline_asym.yaml
```

| 파라미터 | 값 |
|----------|-----|
| Config | `configs/raptor_baseline_asym.yaml` |
| 기간 | 90일 |
| 클라이언트 | 200 |
| 비대칭 라우팅 | **true** |
| 출력 obs | `output/raptor/obs_asym.ndjson` (~2.6 GB) |
| 출력 gt | `output/raptor/gt_asym.ndjson` (~1.7 GB) |
| 실행 시간 | ~15분 |
| 총 회로 수 | 7,776,600 |

### A3. R3 개체별 위협 분석

```bash
go run ./cmd/next-simulate -config configs/raptor_entity_threat.yaml
```

| 파라미터 | 값 |
|----------|-----|
| Config | `configs/raptor_entity_threat.yaml` |
| 기간 | 90일 |
| 클라이언트 | **500** (통계적 유의성을 위해 확대) |
| 비대칭 라우팅 | true |
| 시간 스냅샷 | 비활성화 |
| 출력 obs | `output/raptor/obs_entity.ndjson` (~7.7 GB) |
| 출력 gt | `output/raptor/gt_entity.ndjson` (~4.3 GB) |
| 실행 시간 | ~25분 |
| 총 회로 수 | 19,441,500 |

**참고**: 500 클라이언트(200 대비)로 더 많은 회로를 생성하여 AS별 위협 점수의 신뢰도를 높인다.

---

## Phase B: R2 시간적 시뮬레이션 (병렬, 총 ~35분)

Phase A 검증 후 실행.

### B1. R2 대칭 + 장기 변동

```bash
go run ./cmd/next-simulate -config configs/raptor_temporal_sym.yaml
```

| 파라미터 | 값 |
|----------|-----|
| Config | `configs/raptor_temporal_sym.yaml` |
| 기간 | **180일** (259,200 틱) |
| 클라이언트 | 200 |
| 비대칭 라우팅 | false |
| 시간 스냅샷 | **7개** (2025-01 ~ 2025-07) |
| 출력 obs | `output/raptor/obs_temporal_sym.ndjson` (~5.3 GB) |
| 출력 gt | `output/raptor/gt_temporal_sym.ndjson` (~3.4 GB) |
| 실행 시간 | ~25분 |
| 총 회로 수 | ~15.5M |

### B2. R2 비대칭 + 장기 변동

```bash
go run ./cmd/next-simulate -config configs/raptor_temporal_asym.yaml
```

| 파라미터 | 값 |
|----------|-----|
| Config | `configs/raptor_temporal_asym.yaml` |
| 기간 | 180일 |
| 클라이언트 | 200 |
| 비대칭 라우팅 | **true** |
| 시간 스냅샷 | 7개 |
| 출력 obs | `output/raptor/obs_temporal_asym.ndjson` (~5.4 GB) |
| 출력 gt | `output/raptor/gt_temporal_asym.ndjson` (~3.4 GB) |
| 실행 시간 | ~35분 |
| 총 회로 수 | ~15.5M |

---

## Phase C: R4 가로채기 시뮬레이션 (~20분)

Phase A 이후 실행 (R1 비대칭 기준선과 비교 필요).

### C1. R4 BGP 가로채기

```bash
go run ./cmd/next-simulate -config configs/raptor_interception.yaml
```

| 파라미터 | 값 |
|----------|-----|
| Config | `configs/raptor_interception.yaml` |
| 기간 | 90일 |
| 클라이언트 | 200 |
| 비대칭 라우팅 | true |
| 시간 스냅샷 | 3개 |
| BGP 공격 | **3회 가로채기 공격** |
| 출력 obs | `output/raptor/obs_intercept.ndjson` (~2.6 GB) |
| 출력 gt | `output/raptor/gt_intercept.ndjson` (~1.7 GB) |
| 실행 시간 | ~20분 |

**BGP 공격 일정**:

| 공격 | 공격자 | 대상 | 시작일 | 기간 | 적대자 유형 |
|------|--------|------|--------|------|------------|
| 0 | AS174 (Cogent) | AS24940 (Hetzner) | Day 10 | 7일 | single |
| 1 | AS3356 (Level3/Lumen) | AS60729 | Day 30 | 7일 | tier1 |
| 2 | AS6939 (Hurricane Electric) | AS16276 (OVH) | Day 50 | 7일 | single |

공격 대상 선정 근거: RAPTOR 논문과 R3 실험에서 최상위 Tier-1 위협으로 식별된 AS들.
대상은 상당한 Tor 릴레이(guard/exit)를 보유한 주요 호스팅 제공자.

---

## Phase D: Python 분석 (~10분)

### D1. 스트리밍 분석 실행

```bash
cd /playground/00_active/project-tor/tor-anal

uv run python -m analysis.run_raptor_analysis \
  --sym-obs ../next-simulate/output/raptor/obs_sym.ndjson \
  --sym-gt ../next-simulate/output/raptor/gt_sym.ndjson \
  --asym-obs ../next-simulate/output/raptor/obs_asym.ndjson \
  --asym-gt ../next-simulate/output/raptor/gt_asym.ndjson \
  --temporal-sym-obs ../next-simulate/output/raptor/obs_temporal_sym.ndjson \
  --temporal-sym-gt ../next-simulate/output/raptor/gt_temporal_sym.ndjson \
  --temporal-asym-obs ../next-simulate/output/raptor/obs_temporal_asym.ndjson \
  --temporal-asym-gt ../next-simulate/output/raptor/gt_temporal_asym.ndjson \
  --entity-obs ../next-simulate/output/raptor/obs_entity.ndjson \
  --entity-gt ../next-simulate/output/raptor/gt_entity.ndjson \
  --intercept-obs ../next-simulate/output/raptor/obs_intercept.ndjson \
  --intercept-gt ../next-simulate/output/raptor/gt_intercept.ndjson \
  --output-dir output/raptor_analysis
```

**처리 상세**:
- 스트리밍 NDJSON 처리 사용 (`analysis/raptor_streaming.py`)
- 정수 인코딩 `(circuit_id, asn)` 쌍: `circuit_id * 1_000_000 + asn_int`
- 최대 RAM: ~2 GB (DataFrame 적재 시 ~20 GB 대비)
- 전 실험에서 ~55M 관찰 레코드 처리
- JSON 보고서 + 4개 PNG 시각화 생성

**예상 출력**:
```
output/raptor_analysis/
├── raptor_reproduction_report.json    # 9.6 KB
└── plots/
    ├── asymmetric_comparison.png      # 61 KB
    ├── temporal_churn_curves.png      # 73 KB
    ├── entity_threat_comparison.png   # 97 KB
    └── interception_impact.png        # 59 KB
```

### D2. 결과 검증

```bash
# 보고서 존재 및 유효한 JSON 확인
python3 -c "import json; d=json.load(open('output/raptor_analysis/raptor_reproduction_report.json')); print(list(d.keys()))"
# 예상: ['R1_asymmetric_routing', 'R2_temporal_churn', 'R3_entity_threat', 'R4_interception']

# 모든 플롯 생성 확인
ls -la output/raptor_analysis/plots/
# 예상: 4개 PNG 파일
```

---

## 소요 시간 요약

| Phase | 시뮬레이션 | 실행 시간 | 병렬화 가능 |
|-------|----------|----------|------------|
| A | R1-sym, R1-asym, R3-entity | ~25분 | 예 (3개 병렬) |
| B | R2-temporal-sym, R2-temporal-asym | ~35분 | 예 (2개 병렬) |
| C | R4-interception | ~20분 | 아니오 (A에 의존) |
| D | Python 분석 | ~10분 | 아니오 (R1-R4 순차) |
| **합계** | 6개 시뮬레이션 + 분석 | **~90분** | |

**실제 실행 (2025-02-22)**:
- Phase A 시작: 02:40 UTC → 완료: 02:57 UTC (17분)
- Phase B 시작: 02:57 UTC → 완료: 03:10 UTC (13분)
- Phase C 시작: 03:10 UTC → 완료: 03:23 UTC (13분)
- Phase D 시작: 03:23 UTC → 완료: 03:47 UTC (24분, OOM 재시도 포함)
- **총 실행 시간: ~67분**

---

## 문제 해결

### 분석 시 OOM (종료 코드 137)

초기 분석에서 전체 NDJSON 파일을 pandas DataFrame으로 적재하여 ~20 GB RAM을
사용하며 OOM 발생. 해결: `raptor_streaming.py`가 정수 인코딩 컴팩트 집합을 사용하여
최대 RAM을 ~2 GB로 감소.

여전히 OOM 발생 시 클라이언트 수를 줄이거나, `--skip-viz`로 R3 entity threat
시각화에 필요한 pandas import를 회피.

### 스냅샷 누락

시간적 시뮬레이션이 "snapshot not found"로 실패 시 확인:
```bash
ls tor-anal/output/snapshots/as_model_simplified_*.json
ls tor-anal/data/model_edges_*.json
```

누락 스냅샷 생성:
```bash
cd tor-anal
uv run python -m pipeline --step 7 --snapshot YYYYMMDD
```

### 상관율 0%

상관율이 0.0%인 경우 확인 사항:
1. 관찰 파일에 `is_entry: true`와 `is_exit: true` 레코드가 모두 존재하는지
2. 동일 ASN이 최소 하나의 회로에서 entry와 exit 모두로 나타나는지
3. Ground truth 파일에 일치하는 circuit ID가 있는지

```bash
# 빠른 확인
grep '"is_entry":true' output/raptor/obs_sym.ndjson | head -1
grep '"is_exit":true' output/raptor/obs_sym.ndjson | head -1
```
