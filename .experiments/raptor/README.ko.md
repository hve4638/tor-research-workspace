# RAPTOR 논문 재현 실험

**논문**: Sun et al., "Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries",
USENIX Security Symposium, 2015.

**실험 일자**: 2025-02-22
**실험 ID**: `raptor-reproduction-v1`
**상태**: 완료 (4/4 하위 실험)

---

## 개요

RAPTOR 논문의 4가지 핵심 발견을 AS-level Tor 시뮬레이터(`next-simulate`)와
Python 분석 파이프라인(`tor-anal`)을 사용하여 재현한 실험이다.

| ID | 발견 | RAPTOR 참조 | 재현 여부 |
|----|------|------------|----------|
| R1 | 비대칭 라우팅이 트래픽 상관율을 ~2배 증가 | Figure 4 | 정성적 (경향 약함) |
| R2 | BGP 변동이 시간에 따라 상관율을 ~3배 증가 | Figure 5 | 정성적 |
| R3 | Tier-1 AS가 위협 순위를 지배 | Table 2 | 정성적 |
| R4 | BGP 가로채기 공격이 상관율 급증 유발 | Section 5 | 부분적 (구조적 한계) |

## 문서 링크

| 문서 | 설명 |
|------|------|
| [PROTOCOL.ko.md](PROTOCOL.ko.md) | 정확한 재현 프로토콜 (명령어, 파라미터, 소요 시간) |
| [RESULTS.ko.md](RESULTS.ko.md) | 상세 수치 결과 및 논문 비교 |
| [ENVIRONMENT.ko.md](ENVIRONMENT.ko.md) | 하드웨어, 소프트웨어, 데이터 출처 |
| [configs/](configs/) | 6개 YAML 시뮬레이션 설정 (사본) |
| [results/](results/) | JSON 보고서 + 파생 테이블 |
| [plots/](plots/) | 4개 논문 수준 시각화 |

## 원본 논문과의 주요 차이점

| 항목 | RAPTOR (2015) | 본 재현 (2025) |
|------|---------------|----------------|
| AS 토폴로지 | ~48,000 AS (CAIDA 2013) | 727 AS (CAIDA 2025, Tor 관련만) |
| 릴레이 수 | ~5,000 릴레이 | 727개 AS 집계 노드 |
| BGP 라우팅 | 실제 BGP 피드 (RouteViews) | AS 그래프 기반 시뮬레이션 BFS |
| 비대칭 라우팅 | 실제 traceroute 데이터 | 방향별 BFS (정방향 ≠ 역방향) |
| 시뮬레이션 기간 | 과거 데이터 (2013) | 90-180일 (2025-01 ~ 2025-07) |
| 클라이언트 수 | 전체 Tor 사용자 추정 | 200-500 시뮬레이션 클라이언트 |
| 경로 계산 | 실제 BGP RIB 엔트리 | AS-relationship valley-free 라우팅 |

이러한 차이로 **절대 상관율은 상당히 차이**가 난다 (우리: 2-3% vs 논문: 12-21%).
본 실험은 **상대적 추세와 정성적 패턴**을 검증하며, 절대값은 검증 대상이 아니다.

## 디렉토리 구조

```
.experiments/raptor/
├── README.md / README.ko.md       # 실험 개요
├── PROTOCOL.md / PROTOCOL.ko.md   # 단계별 재현 프로토콜
├── RESULTS.md / RESULTS.ko.md     # 상세 수치 결과
├── ENVIRONMENT.md / ENVIRONMENT.ko.md  # 환경 정보
├── configs/                       # 시뮬레이션 설정 사본
│   ├── raptor_baseline_sym.yaml
│   ├── raptor_baseline_asym.yaml
│   ├── raptor_temporal_sym.yaml
│   ├── raptor_temporal_asym.yaml
│   ├── raptor_entity_threat.yaml
│   └── raptor_interception.yaml
├── results/
│   └── raptor_reproduction_report.json
└── plots/
    ├── asymmetric_comparison.png
    ├── temporal_churn_curves.png
    ├── entity_threat_comparison.png
    └── interception_impact.png
```

## 재현 명령어 (단일 실행)

모든 시뮬레이션 완료 후 (PROTOCOL.ko.md 참조):

```bash
cd tor-anal && uv run python -m analysis.run_raptor_analysis \
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

## 인용

```bibtex
@inproceedings{sun2015raptor,
  title={Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries},
  author={Sun, Yixin and Edmundson, Anne and Vanbever, Laurent and Li, Oscar
          and Rexford, Jennifer and Chiang, Mung and Mittal, Prateek},
  booktitle={24th USENIX Security Symposium},
  pages={337--352},
  year={2015}
}
```
