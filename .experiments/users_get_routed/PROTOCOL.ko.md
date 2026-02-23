# "Users Get Routed" 재현 프로토콜

두 실험 세트를 재현하기 위한 정확한 단계별 프로토콜.

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

3. **CAIDA 스냅샷** 준비 (월별 3개):
   ```bash
   ls tor-anal/output/snapshots/as_model_simplified_202501*.json
   ls tor-anal/data/model_edges_202501*.json
   # 필요: 20250101, 20250201, 20250301
   ```

4. **AS 경로 확률** (Counter-RAPTOR용):
   ```bash
   ls tor-anal/output/as_path_probabilities.json
   ```

5. **디스크 공간**: ~15 GB 여유

---

## 세트 A: 네트워크 적대자 (4개 방어 시나리오)

### Phase A1: 시뮬레이션 (병렬, 총 ~15분)

4개 시나리오를 별도 터미널에서 병렬 실행 가능.

#### A1-1. Vanilla (방어 없음)

```bash
cd /playground/00_active/project-tor/next-simulate
go run ./cmd/next-simulate -config configs/bgp_attack.yaml
```

| 파라미터 | 값 |
|----------|-----|
| Config | `configs/bgp_attack.yaml` |
| 기간 | 90일 (129,600 틱) |
| 클라이언트 | 50 |
| 방어 | 없음 |
| BGP 공격 | 3회 (탈취 + 가로채기 + 국가 수준) |
| 시간적 | 3개 스냅샷 (2025-01, 02, 03) |
| 출력 obs | `output/observations_bgp.ndjson` (~586 MB) |
| 출력 gt | `output/ground_truth_bgp.ndjson` (~432 MB) |
| 총 회로 수 | 1,944,150 |
| 실행 시간 | ~5분 |

#### A1-2. Counter-RAPTOR 방어

```bash
go run ./cmd/next-simulate -config configs/counter_raptor_defense.yaml
```

| 파라미터 | 값 |
|----------|-----|
| Config | `configs/counter_raptor_defense.yaml` |
| 방어 | Counter-RAPTOR (weight_factor=1.0, max_cap=100.0) |
| 출력 obs | `output/observations_cr.ndjson` (~586 MB) |
| 출력 gt | `output/ground_truth_cr.ndjson` (~432 MB) |
| 실행 시간 | ~5분 |

Vanilla와 동일한 BGP 공격, 시간적, 클라이언트 설정.

#### A1-3. Astoria 방어

```bash
go run ./cmd/next-simulate -config configs/astoria_defense.yaml
```

| 파라미터 | 값 |
|----------|-----|
| Config | `configs/astoria_defense.yaml` |
| 방어 | Astoria (max_retries=5) |
| 출력 obs | `output/observations_astoria.ndjson` (~574 MB) |
| 출력 gt | `output/ground_truth_astoria.ndjson` (~432 MB) |
| 실행 시간 | ~5분 |

#### A1-4. Combined 방어 (Counter-RAPTOR + Astoria)

```bash
go run ./cmd/next-simulate -config configs/combined_defense.yaml
```

| 파라미터 | 값 |
|----------|-----|
| Config | `configs/combined_defense.yaml` |
| 방어 | Counter-RAPTOR + Astoria |
| 출력 obs | `output/observations_combined.ndjson` (~566 MB) |
| 출력 gt | `output/ground_truth_combined.ndjson` (~432 MB) |
| 실행 시간 | ~5분 |

### Phase A2: 네트워크 분석 (~3분)

```bash
cd /playground/00_active/project-tor/tor-anal

uv run python -m analysis.run_analysis \
  --vanilla-obs ../next-simulate/output/observations_bgp.ndjson \
  --vanilla-gt ../next-simulate/output/ground_truth_bgp.ndjson \
  --cr-obs ../next-simulate/output/observations_cr.ndjson \
  --cr-gt ../next-simulate/output/ground_truth_cr.ndjson \
  --astoria-obs ../next-simulate/output/observations_astoria.ndjson \
  --astoria-gt ../next-simulate/output/ground_truth_astoria.ndjson \
  --combined-obs ../next-simulate/output/observations_combined.ndjson \
  --combined-gt ../next-simulate/output/ground_truth_combined.ndjson \
  --cdf --tick-interval-ms 60000 \
  --output-dir output/analysis_m6_cdf
```

**예상 출력**:
```
output/analysis_m6_cdf/
├── defense_comparison_report.json         # 전체 메트릭 + CDF 데이터
└── plots/
    ├── time_to_first_compromise_cdf.png   # Figure 2a 대응
    ├── stream_compromise_over_time.png    # Figure 3 대응
    ├── correlation_comparison.png         # 방어별 비교 막대 차트
    ├── temporal_curves.png                # 기간별 상관율 추세
    ├── cumulative_compromise.png          # 누적 침해 곡선
    ├── attack_impact.png                  # BGP 공격 전/중/후
    ├── as_risk_heatmap.png               # AS별 위험도 히트맵
    └── guard_distribution_shift.png       # Guard 선택 분포 변화
```

**검증**:
```bash
python3 -c "
import json
d = json.load(open('output/analysis_m6_cdf/defense_comparison_report.json'))
for s in d['overall']:
    print(f\"{s['scenario']:>15}: {s['correlation_rate']*100:.4f}% ({s['correlated_circuits']}/{s['total_circuits']})  감소={s['reduction_pct']:.1f}%\")
"
```

---

## 세트 B: 릴레이 적대자

### Phase B1: 시뮬레이션 (~20분)

```bash
cd /playground/00_active/project-tor/next-simulate
go run ./cmd/next-simulate -config configs/relay_adversary.yaml
```

| 파라미터 | 값 |
|----------|-----|
| Config | `configs/relay_adversary.yaml` |
| 기간 | **180일** (259,200 틱) |
| 클라이언트 | **200** |
| 적대자 대역폭 | 100 MiB/s (102,400 KB) |
| Guard:Exit 비율 | 5:1 (Guard 83.3%, Exit 16.7%) |
| 비대칭 라우팅 | true |
| BGP 공격 | 없음 |
| 시간적 | 비활성화 |
| 출력 obs | `output/observations_relay_adv.ndjson` (~6.2 GB) |
| 출력 gt | `output/ground_truth_relay_adv.ndjson` (~3.5 GB) |
| 총 회로 수 | 15,552,600 |
| 실행 시간 | ~20분 |

**릴레이 적대자 동작 방식**:
- 합성 guard ASN(`_ADV_GUARD`)과 exit ASN(`_ADV_EXIT`)을 디렉토리 서비스에 주입
- Guard가 100 MiB/s 대역폭의 83.3%, Exit이 16.7% 수신
- 회로의 guard와 exit이 모두 적대자 소유일 때 침해로 판정
- `relay_compromise` 마커가 관찰 로그에 기록됨

### Phase B2: 릴레이 적대자 분석 (~5분)

대용량 출력 파일에 대해 스트리밍 CDF 분석 사용:

```bash
cd /playground/00_active/project-tor/tor-anal

uv run python -m analysis.streaming_cdf \
  --obs ../next-simulate/output/observations_relay_adv.ndjson \
  --gt ../next-simulate/output/ground_truth_relay_adv.ndjson \
  --tick-interval-ms 60000 \
  --output-dir output/analysis_relay_adv
```

**예상 출력**:
```
output/analysis_relay_adv/
├── defense_comparison_report.json         # 릴레이 침해 메트릭 + CDF
└── plots/
    ├── relay_compromise_cdf.png           # Figure 2a 대응
    ├── stream_compromise_over_time.png    # Figure 3 대응
    └── time_to_first_compromise_cdf.png   # 네트워크 수준 CDF 오버레이
```

---

## 소요 시간 요약

| Phase | 내용 | 실행 시간 | 병렬화 가능 |
|-------|------|----------|------------|
| A1 | 4개 네트워크 시뮬레이션 | ~15분 | 예 (4개 모두 병렬) |
| A2 | 네트워크 분석 + CDF | ~3분 | 아니오 |
| B1 | 릴레이 적대자 시뮬레이션 | ~20분 | 예 (A1과 병렬 가능) |
| B2 | 릴레이 적대자 분석 | ~5분 | 아니오 |
| **합계** | 5개 시뮬레이션 + 2개 분석 | **~25분** (병렬화 시) | |

**실제 실행 (2025-02-20 ~ 2025-02-22)**:
- 세트 A 시뮬레이션: ~15분 (4개 병렬 Go 프로세스)
- 세트 A 분석: ~3분
- 세트 B 시뮬레이션: ~20분
- 세트 B 분석: ~5분 (6.2 GB obs 스트리밍 처리)
- **총 실행 시간: ~25분** (병렬화 시)

---

## 문제 해결

### 릴레이 적대자 분석 시 OOM

릴레이 적대자가 ~6.2 GB의 관찰 데이터(43.5M 행)를 생성한다. 전체 DataFrame을
로드하는 표준 `analysis.run_analysis` 대신 스트리밍 CDF 분석 모듈
(`analysis.streaming_cdf`)을 사용할 것.

### AS 경로 확률 누락

Counter-RAPTOR에는 `tor-anal/output/as_path_probabilities.json`이 필요하다.
생성 방법:
```bash
cd tor-anal
uv run python -m pipeline --step 5
```

### 방어 효과 없음 (동일한 상관율)

Counter-RAPTOR는 guard 선택만 재가중치한다. 침해하는 AS가 이미 지배적 transit
제공자라면, 재가중치가 도움이 되지 않는다 (이는 예상된 결과 — 상세 분석은
RESULTS.ko.md 참조). Astoria가 극적인 감소를 보여야 한다.

### 릴레이 적대자: 57일간 0% 침해

이는 예상된 동작이다. Guard 수명이 30-60일이므로, 초기 guard가 만료되어
재선택될 때까지 적대자의 guard 릴레이가 선택될 수 없다. Day 57-60에
guard 교체가 발생하면 침해가 급속히 이루어진다.
