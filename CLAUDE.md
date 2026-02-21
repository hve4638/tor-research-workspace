# CLAUDE.md

## 프로젝트 개요

Tor 네트워크에 대한 **AS-level 글로벌 관찰자 시뮬레이션**. BGP 공격과 라우팅 변동이 Tor 익명성을 얼마나 침해하는지 분석한다.

## 현재 단계

**M6 완료 — 연구 분석 단계 진입**

M1~M6 시뮬레이션 엔진이 완성되었으며, 이를 기반으로 연구 질문에 답하는 분석을 진행한다. M7(Hidden Service v3)은 추후 별도 진행 예정.

### 마일스톤 상태

| 마일스톤 | 상태 | 내용 |
|----------|------|------|
| M1 | 완료 | 아키텍처, 타입, 엔진, AS 그래프 |
| M2 | 완료 | 디렉토리 서비스, Guard 선택 |
| M3 | 완료 | 3-hop 회로 생성 + AS-path 관찰 |
| M4 | 완료 | 시간적 그래프 변동 (CAIDA 스냅샷 기반) |
| M5 | 완료 | BGP 공격 시뮬레이션 (hijack/interception) |
| M6 | 완료 | 방어 전략 (Counter-RAPTOR, Astoria) + Python 분석 |
| M7 | 보류 | Hidden Service v3 (배경 문서 작성 완료, 결정 대기 → LATER.md 참조) |

### 현재 답할 수 있는 연구 질문

- **RQ1**: AS-level 글로벌 관찰자가 Tor 트래픽을 얼마나 상관(correlate)할 수 있는가?
- **RQ2**: 특정 AS 위치(IXP, Tier-1)가 추적 성공률에 얼마나 영향을 주는가?
- **RQ3**: Hidden Service 트래픽의 추적 가능성 → M7 필요 (보류)

## 디렉토리 구조

```
project-tor/
├── next-simulate/        # AS-level 이벤트 드리븐 시뮬레이터 (Go) ← 핵심
│   ├── internal/         # 패키지별 구현 (asgraph, bgp, circuit, config, defense, ...)
│   ├── cmd/              # main.go 진입점
│   ├── configs/          # YAML 설정 파일 (4개 시나리오)
│   ├── output/           # NDJSON 시뮬레이션 출력
│   └── .docs/            # 마일스톤 보고서 + M7 배경 문서
├── tor-anal/             # Python 데이터 파이프라인 + 분석
│   ├── pipeline/         # Step 01~10: Tor 릴레이 → AS 모델 JSON
│   ├── analysis/         # M6: NDJSON 파싱, 상관율 계산, 방어 비교, 시각화
│   ├── data/             # 외부 데이터 (CAIDA edges 등)
│   ├── output/           # 파이프라인 산출물 (AS 모델, 확률 등)
│   └── reference/        # Tor 소스 참조 (읽기 전용, 대용량)
├── onion-simulate/       # 구 시뮬레이터 (Go) — 더 이상 개발하지 않음
├── onion-simulate-visualize/  # 로그 시각화 도구
├── LATER.md              # M7 재개 가이드 (전체 컨텍스트 보존)
├── NEXT.md / NEXT_DETAIL.md  # 연구 목표 및 기술적 목표
└── DOCS_INVENTORY.md     # 전체 문서 인덱스
```

## 시뮬레이션 실행

### Go 시뮬레이션 (next-simulate)

```bash
cd next-simulate

# 빌드/테스트
go build ./...
go test ./...

# 4개 시나리오 실행
go run ./cmd/next-simulate -config configs/bgp_attack.yaml              # Vanilla
go run ./cmd/next-simulate -config configs/counter_raptor_defense.yaml   # Counter-RAPTOR
go run ./cmd/next-simulate -config configs/astoria_defense.yaml          # Astoria
go run ./cmd/next-simulate -config configs/combined_defense.yaml         # CR + Astoria
```

### Python 분석 (tor-anal)

**모든 Python 작업은 `uv` 사용 필수. `pip` 금지.**

```bash
cd tor-anal

# 분석 실행 (4개 시나리오 비교)
uv run python -m analysis.run_analysis \
  --vanilla-obs ../next-simulate/output/observations_bgp.ndjson \
  --vanilla-gt ../next-simulate/output/ground_truth_bgp.ndjson \
  --cr-obs ../next-simulate/output/observations_cr.ndjson \
  --cr-gt ../next-simulate/output/ground_truth_cr.ndjson \
  --astoria-obs ../next-simulate/output/observations_astoria.ndjson \
  --astoria-gt ../next-simulate/output/ground_truth_astoria.ndjson \
  --combined-obs ../next-simulate/output/observations_combined.ndjson \
  --combined-gt ../next-simulate/output/ground_truth_combined.ndjson

# 파이프라인 (데이터 갱신 시)
uv run python -m pipeline --all
```

## 시뮬레이션 능력 요약

| 기능 | 설명 |
|------|------|
| 3-hop 회로 생성 | Guard/Middle/Exit 대역폭 가중치 기반 확률적 선택 |
| 동적 AS 토폴로지 | CAIDA 스냅샷 기반 30일 주기 전환, 노드 churn |
| BGP Hijack | prefix 탈취 — 모든 트래픽을 공격자가 흡수 |
| BGP Interception | 경로 삽입 — 기존 provider 유지, 일부 트래픽 경유 |
| 4종 적대자 모델 | SingleAS, Colluding, StateLevel(국가), Tier1 |
| 비대칭 경로 | A→B ≠ B→A (RAPTOR 논문 핵심) |
| Counter-RAPTOR 방어 | resilience 기반 Guard 재가중치 |
| Astoria 방어 | entry/exit transit AS 교집합 검사 |
| Python 분석 | 상관율 계산, 방어 비교, 공격 전/중/후 분석, 6종 시각화 |

## 핵심 데이터 파일

| 파일 | 내용 |
|------|------|
| `tor-anal/output/as_model_simplified.json` | 727 AS 노드 + guard/exit 가중치 |
| `tor-anal/data/model_edges.json` | 6325 AS 간 연결 (peer/provider-customer) |
| `tor-anal/output/as_path_probabilities.json` | AS별 p_entry/p_exit |
| `tor-anal/output/as_geo_map.json` | 727 ASN → 국가 코드 |

## 핵심 참조 문서

| 파일 | 내용 |
|------|------|
| `next-simulate/.docs/M5_report.md` | BGP 공격 구현 보고서 |
| `next-simulate/.docs/M6_report.md` | 방어 전략 + Python 분석 보고서 |
| `next-simulate/.docs/NEXT_v4.md` | 전체 마일스톤 계획 (M1~M7) |
| `LATER.md` | M7 재개 가이드 (배경 문서 4개 + Vanguards 결정 사항) |

## 유저 선호

- **언어**: 문서와 대화는 한국어, 코드와 주석은 영어
- **Python 환경**: `uv` 필수, `pip` 금지
- **커밋**: 유저가 명시적으로 요청할 때만
- **보고서 스타일**: `.docs/M5_report.md`, `.docs/M6_report.md` 형식 참조
