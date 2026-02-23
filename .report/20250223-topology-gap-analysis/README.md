# 20250223 — Topology Gap Analysis

> RAPTOR/UGR 재현 실험에서 발견된 토폴로지 규모 불일치 문제의 원인 분석 및 해결 방안

## 배경

RAPTOR(Sun et al., 2015)와 "Users Get Routed"(Johnson et al., 2013) 두 논문의 재현 실험을 완료했다.
7개 실험 중 5개는 재현에 성공했으나, RAPTOR R1(비대칭 라우팅)과 R4(BGP Interception)는 재현에 실패했다.
원인 조사 결과, **파이프라인의 AS 전처리 필터링이 과도하여 토폴로지가 실제 인터넷의 1.5% 수준으로 축소**된 것이 근본 원인으로 밝혀졌다.

## 문서 구조

| 파일 | 내용 |
|------|------|
| `01_gap-summary.md` | 불일치 현황, 원인, 해결 방안 요약 (기존 문서) |
| `02_pipeline-trace.md` | AS 수집/전처리 파이프라인 전체 추적 |
| `03_paper-comparison.md` | 원본 논문의 데이터 구성과 우리 구현의 차이 |
| `04_routing-model.md` | BFS 라우팅 모델 vs 실제 BGP 정책 |
| `05_solution-design.md` | Step 06b Transit 확장 설계 + 대안 |

## 핵심 수치

```
우리 모델:     727 AS,   6,191 edges, 경로 2-4홉
RAPTOR 논문:   ~48,000 AS, ~140,000 edges, 경로 5-8홉
비율:          1.5%       4.4%
```

## 영향받는 실험

| 실험 | 우리 결과 | 논문 결과 | 원인 |
|------|----------|----------|------|
| R1 비대칭 라우팅 | 1.003x (변화 없음) | 1.66x 증가 | 경로 짧아 비대칭 불가 |
| R4 BGP Interception | -1.4% (변화 없음) | ~90% 상관율 | Tier-1이 이미 모든 경로에 존재 |

## 다음 단계

Step 06b (Transit AS 확장) 구현 → 2-hop 확장 모델 생성 → R1/R4 재실행
