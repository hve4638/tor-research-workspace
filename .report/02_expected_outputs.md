# 예상 산출물

## 1단계: Go 시뮬레이션 출력 (8개 NDJSON 파일)

경로: `next-simulate/output/`

| 파일 | 시나리오 | 상태 |
|------|----------|------|
| `observations_bgp.ndjson` | Vanilla (방어 없음) | 있음 (586MB) |
| `ground_truth_bgp.ndjson` | Vanilla (방어 없음) | 있음 (432MB) |
| `observations_cr.ndjson` | Counter-RAPTOR | 미생성 |
| `ground_truth_cr.ndjson` | Counter-RAPTOR | 미생성 |
| `observations_astoria.ndjson` | Astoria | 미생성 |
| `ground_truth_astoria.ndjson` | Astoria | 미생성 |
| `observations_combined.ndjson` | Combined (CR + Astoria) | 미생성 |
| `ground_truth_combined.ndjson` | Combined (CR + Astoria) | 미생성 |

## 2단계: Python 분석 출력

경로: `tor-anal/output/analysis/`

### JSON 리포트

| 파일 | 내용 |
|------|------|
| `defense_comparison_report.json` | 전체 정량 비교 데이터 |

포함 항목:
- **overall**: 시나리오별 전체 상관율 + Vanilla 대비 감소율(%)
- **client_compromise**: 클라이언트별 침해율
- **attack_impact**: BGP 공격 3건 각각의 pre/during/post 상관율
- **trends**: 시나리오별 시간 추세 분석

### 시각화 PNG (6개)

경로: `tor-anal/output/analysis/plots/`

| 파일 | 차트 유형 | 보여주는 것 |
|------|----------|-----------|
| `correlation_comparison.png` | 바 차트 | 4개 시나리오별 전체 상관율 비교 |
| `temporal_curves.png` | 라인 플롯 | 시간 경과에 따른 상관율 변화 (시나리오별) |
| `cumulative_compromise.png` | 누적 곡선 | 시간이 지남에 따라 누적 상관율 증가 추이 |
| `attack_impact.png` | 그룹 바 차트 | 공격 3건 각각의 전/중/후 상관율 |
| `as_risk_heatmap.png` | 히트맵 | Top 20 transit AS의 entry/exit 관찰 빈도 |
| `guard_distribution_shift.png` | 비교 바 차트 | Vanilla vs Defense의 Guard AS 선택 분포 변화 |

## 전체 흐름

```
시뮬레이션 (Go)          분석 (Python)              산출물
─────────────      →     ──────────────      →     ──────────
8개 NDJSON (~4GB)        상관율 계산                 JSON 리포트 1개
                         방어 비교                   PNG 차트 6개
                         공격 영향 분석
                         시간 추세 분석
```

## 연구 질문과의 매핑

| 산출물 | 답변하는 연구 질문 |
|--------|-------------------|
| `correlation_comparison.png` + overall | RQ1: 글로벌 관찰자의 상관 능력 |
| `as_risk_heatmap.png` | RQ2: AS 위치별 추적 성공률 |
| `attack_impact.png` | BGP 공격이 상관율에 미치는 영향 |
| `guard_distribution_shift.png` | Counter-RAPTOR의 Guard 분포 변화 효과 |
| `temporal_curves.png` | 방어 전략의 시간적 안정성 |
