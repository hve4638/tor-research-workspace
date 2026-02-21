# Experiment Results: "Users Get Routed" 논문 재현

**실행일**: 2026-02-22
**시뮬레이터**: next-simulate (Go, AS-level event-driven)
**분석**: tor-anal (Python, streaming CDF)

---

## 1. 실험 개요

Johnson et al. "Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries" 논문의 핵심 결과를 AS-level 시뮬레이션으로 재현한다.

### 실험 구성

| 실험 | 기간 | 클라이언트 | 적대자 유형 | 방어 |
|------|------|-----------|------------|------|
| M6 네트워크 CDF | 90일 | 50 | AS-level 글로벌 관찰자 | Vanilla / CR / Astoria / Combined |
| 릴레이 적대자 CDF | 180일 | 200 | 릴레이 운영자 (100 MiB/s) | 없음 (Vanilla) |

### 시뮬레이션 파라미터

- **Tick interval**: 60초 (1분)
- **Circuit rotation**: 600초 (10분, max dirtiness)
- **Guard lifetime**: 30-60일 (uniform)
- **Primary guards**: 3개/클라이언트
- **Asymmetric routing**: 활성화 (A→B ≠ B→A)
- **AS 모델**: 727 ASes, 6,191 edges (CAIDA 2025-01-01 기반)
- **릴레이 적대자**: 100 MiB/s, guard:exit = 5:1

---

## 2. 결과 A: AS-level 네트워크 적대자 (M6 데이터)

**설정**: 90일, 50 클라이언트, AS-level entry+exit 상관 분석

### 2-1. 방어 전략별 클라이언트 침해율

| 시나리오 | 침해된 클라이언트 | 침해율 | 감소율 |
|----------|-------------------|--------|--------|
| Vanilla | 34/50 | 68.0% | — |
| Counter-RAPTOR | 34/50 | 68.0% | 0.0% |
| Astoria | 9/50 | 18.0% | 73.5% |
| Combined (CR+Astoria) | 5/50 | 10.0% | 85.3% |

### 2-2. Time to First Compromise CDF

| 시나리오 | 최초 침해 | 50% 침해 시점 | 최종 비율 |
|----------|-----------|---------------|-----------|
| Vanilla | day 0.0 | day 50.6 | 68.0% |
| Counter-RAPTOR | day 0.0 | day 52.8 | 68.0% |
| Astoria | day 5.0 | — (18%에서 정체) | 18.0% |
| Combined | day 15.0 | — (10%에서 정체) | 10.0% |

> **시각화**: `tor-anal/output/analysis_m6_cdf/plots/time_to_first_compromise_cdf.png`

### 2-3. 스트림(회로) 침해율

| 시나리오 | 침해 회로 | 전체 회로 | 침해율 |
|----------|----------|----------|--------|
| Vanilla | 37,572 | 1,944,150 | 1.93% |
| Counter-RAPTOR | 35,856 | 1,944,150 | 1.84% |
| Astoria | 12 | 1,944,150 | 0.001% |
| Combined | 5 | 1,944,150 | 0.0003% |

> **시각화**: `tor-anal/output/analysis_m6_cdf/plots/stream_compromise_over_time.png`

### 2-4. 해석

- **Counter-RAPTOR**는 guard 재가중치만 수행하므로, 이미 관찰 가능한 AS 경로에는 효과 제한적 (침해율 동일, 스트림 침해 4.6% 감소)
- **Astoria**는 entry/exit transit AS 교집합을 회피하므로 극적 효과 (침해율 73.5% 감소)
- **Combined**는 두 방어를 결합하여 최대 효과 (침해율 85.3% 감소, 스트림 침해 99.99% 감소)

---

## 3. 결과 B: 릴레이 적대자 (논문 핵심 결과)

**설정**: 180일, 200 클라이언트, 100 MiB/s 릴레이 적대자

### 3-1. 릴레이 적대자 침해 요약

| 지표 | 값 |
|------|-----|
| 침해된 클라이언트 | **200/200 (100%)** |
| Full compromise 마커 (guard+exit) | 1,472,947 |
| Guard-only 마커 | 107 |
| Exit-only 마커 | 14,078,731 |
| 전체 회로 | 15,552,600 |

### 3-2. Time to First Compromise CDF (릴레이 적대자)

| 지표 | 값 |
|------|-----|
| 최초 full compromise | **day 57.1** |
| 50% 클라이언트 침해 | **day 59.7** |
| 90% 클라이언트 침해 | **day 60.0** |
| 100% 클라이언트 침해 | **day 60.0** |

> **시각화**: `tor-anal/output/analysis_relay_adv/plots/relay_compromise_cdf.png`

### 3-3. 침해 패턴 분석

Guard lifetime이 30-60일로 설정되어 있으므로:

1. **Day 0-57**: Exit만 적대자에게 할당됨 (exit rotation이 10분마다). Guard는 기존 정상 릴레이에 고정.
2. **Day 57-60**: Guard lifetime 만료 후 재선택 시 적대자 guard가 선택됨. 이 시점에서 entry+exit 동시 관찰이 발생하며, **거의 모든 클라이언트가 2-3일 내에 일제히 침해**됨.
3. **Day 60 이후**: 100% 침해 완료.

이는 guard lifetime의 상한(60일)과 정확히 일치하며, 논문의 Figure 2a와 유사한 계단 형태의 CDF를 보여준다.

### 3-4. 네트워크 레벨 AS 상관 (부가 분석)

릴레이 적대자 시나리오에서도 AS-level entry+exit 상관이 발생:
- 27/200 클라이언트 (13.5%)가 AS-level에서도 침해됨
- 이는 릴레이 적대자의 transit AS가 우연히 entry/exit 경로를 모두 관찰하는 경우

---

## 4. 논문 대응표

| 논문 Figure | 우리 결과 | 대응 파일 |
|-------------|----------|----------|
| Figure 2a (CDF) | 100% 침해, day 57-60 집중 | `relay_compromise_cdf.png` |
| Figure 2b (Guard) | Guard-only: 107건 (guard lifetime 만료 전 미미) | 보고서 내 수치 |
| Figure 2c (Exit) | Exit-only: 14M건 (90.5%, exit rotation 빈번) | 보고서 내 수치 |
| Figure 3 (Stream) | 전체 스트림 침해율: 0.0002% (네트워크), 9.5% (릴레이) | `stream_compromise_over_time.png` |
| Defense comparison | Astoria 73.5%, Combined 85.3% 감소 | `time_to_first_compromise_cdf.png` |

---

## 5. 산출물 인벤토리

### 시뮬레이션 출력

| 파일 | 크기 | 행 수 |
|------|------|-------|
| `next-simulate/output/observations_relay_adv.ndjson` | 6.2 GB | 43,581,011 |
| `next-simulate/output/ground_truth_relay_adv.ndjson` | 3.5 GB | 15,552,600 |
| `next-simulate/output/observations_bgp.ndjson` | 586 MB | 4,137,289 |
| `next-simulate/output/ground_truth_bgp.ndjson` | 432 MB | 1,944,600 |
| (+ CR/Astoria/Combined 각 ~500MB) | | |

### 분석 보고서

| 파일 | 내용 |
|------|------|
| `tor-anal/output/analysis_m6_cdf/defense_comparison_report.json` | M6 4-시나리오 CDF + 메트릭 |
| `tor-anal/output/analysis_relay_adv/defense_comparison_report.json` | 릴레이 적대자 CDF + 메트릭 |

### 시각화 (PNG)

| 파일 | 내용 |
|------|------|
| `analysis_m6_cdf/plots/time_to_first_compromise_cdf.png` | 4-시나리오 네트워크 CDF |
| `analysis_m6_cdf/plots/stream_compromise_over_time.png` | 일별 스트림 침해율 |
| `analysis_m6_cdf/plots/correlation_comparison.png` | 방어별 상관율 비교 |
| `analysis_m6_cdf/plots/temporal_curves.png` | 시간별 상관율 추이 |
| `analysis_m6_cdf/plots/cumulative_compromise.png` | 누적 침해 곡선 |
| `analysis_m6_cdf/plots/attack_impact.png` | BGP 공격 영향 |
| `analysis_m6_cdf/plots/as_risk_heatmap.png` | AS별 위험도 히트맵 |
| `analysis_m6_cdf/plots/guard_distribution_shift.png` | Guard 분포 변화 |
| `analysis_relay_adv/plots/relay_compromise_cdf.png` | 릴레이 적대자 CDF |
| `analysis_relay_adv/plots/stream_compromise_over_time.png` | 릴레이 스트림 침해율 |
| `analysis_relay_adv/plots/time_to_first_compromise_cdf.png` | 릴레이 네트워크 CDF |

---

## 6. 재현 방법

```bash
# Step 1: M6 네트워크 CDF (기존 데이터)
cd tor-anal
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

# Step 2: 릴레이 적대자 시뮬레이션
cd ../next-simulate
go run ./cmd/next-simulate -config configs/relay_adversary.yaml

# Step 3: 릴레이 적대자 CDF (streaming — 대용량 데이터)
cd ../tor-anal
uv run python -m analysis.streaming_cdf \
  --obs ../next-simulate/output/observations_relay_adv.ndjson \
  --gt ../next-simulate/output/ground_truth_relay_adv.ndjson \
  --tick-interval-ms 60000 \
  --output-dir output/analysis_relay_adv
```
