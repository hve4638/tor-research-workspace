# Tor AS-Level Global Adversary Simulation — 문서 목차

> 작성일: 2026-02-20
> 프로젝트: AS-level 글로벌 관찰자가 Tor 익명성을 침해하는 정도를 시뮬레이션하고 분석하는 연구

---

## 문서 목록

| # | 문서 | 내용 |
|---|------|------|
| 01 | [연구 개요](./01_research_overview.md) | 연구 동기, 연구 질문, 전체 흐름, 핵심 발견 요약 |
| 02 | [연구 배경](./02_background.md) | Tor 프로토콜, AS-level 위협 모델, 관련 논문 7편, 역공학 요약 |
| 03 | [데이터 파이프라인](./03_data_pipeline.md) | 외부 데이터 소스, 10단계 파이프라인, 핵심 산출물 설명 |
| 04 | [시뮬레이터 설계](./04_simulator_architecture.md) | 이벤트 드리븐 엔진, 13개 패키지, M1~M6 구현 내용 |
| 05 | [시나리오와 방어 전략](./05_scenarios_and_defense.md) | 4개 시나리오, BGP 공격 3건, Counter-RAPTOR/Astoria 방어 |
| 06 | [분석 결과](./06_results.md) | 상관율 비교, 공격 영향, 시각화 해석, RQ 답변 |
| 07 | [향후 계획](./07_future_work.md) | M7 Hidden Service v3, 추가 실험, 연구 확장 |

## 추천 읽기 순서

1. **01 → 02**: 연구 동기와 배경 이해
2. **03**: 시뮬레이션에 입력되는 데이터가 어디서 오는지 파악
3. **04**: 시뮬레이터가 어떻게 동작하는지 이해
4. **05 → 06**: 실험 설계와 결과 확인
5. **07**: 향후 방향 확인

## 프로젝트 디렉토리 구조

```
project-tor/
├── next-simulate/           # Go 시뮬레이터 (핵심, ~8,300줄)
│   ├── internal/            # 13개 패키지 (asgraph, bgp, circuit, ...)
│   ├── cmd/                 # main.go 진입점
│   ├── configs/             # YAML 설정 (4개 시나리오)
│   └── output/              # NDJSON 시뮬레이션 출력
├── tor-anal/                # Python 파이프라인 + 분석 (~5,400줄)
│   ├── pipeline/            # Step 01~10: Tor 릴레이 → AS 모델
│   ├── analysis/            # M6 분석: 상관율, 방어 비교, 시각화
│   └── output/              # 파이프라인 산출물 + 분석 결과
├── .overview/               # ← 현재 문서
├── .report/                 # 시뮬레이션 시나리오·결과 요약
├── onion-simulate/          # 구 시뮬레이터 (참조용)
└── LATER.md                 # M7 재개 가이드
```
