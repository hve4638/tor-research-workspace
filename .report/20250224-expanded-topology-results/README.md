# 20250224 — Expanded Topology Results

> 토폴로지 확장(727→3,727 AS) 후 RAPTOR R1/R4 재실행 결과 및 근본 원인 재진단

## 배경

[20250223-topology-gap-analysis](../20250223-topology-gap-analysis/)에서 식별된 토폴로지 규모 문제를
해결하기 위해 Step 06b(2-hop BFS Transit 확장)를 구현하고, R1/R4를 재실행했다.

결과적으로 토폴로지 확장만으로는 R1/R4를 재현할 수 없으며, **라우팅 모델의 경로 선호도(LOCAL_PREF) 미구현**이
진짜 병목임을 확인했다.

## 문서 구조

| 파일 | 내용 |
|------|------|
| `01_changes.md` | 구현 변경 사항 (Step 06b, Go 버그 fix, config 변경) |
| `02_results.md` | R1/R4 재실행 결과 (확장 전후 비교) |
| `03_diagnosis.md` | 근본 원인 재진단: valley-free는 이미 구현, LOCAL_PREF가 핵심 |
| `04_next-steps.md` | LOCAL_PREF 기반 경로 선택 개선 방안 |

## 핵심 수치

```
확장 전:    727 AS,    6,191 edges,  경로 2-4홉
확장 후:  3,727 AS,  303,731 edges,  경로 4-7홉
RAPTOR:  ~48,000 AS, ~140,000 edges, 경로 5-8홉
```

## 결과 요약

| 실험 | 확장 전 | 확장 후 | 논문 목표 | 판정 |
|------|--------|--------|----------|------|
| R1 비대칭 라우팅 | 1.003x | **1.02x** | 1.66x | 미재현 |
| R4 BGP Interception | -1.4% | **-4.2%** | ~90% 증가 | 미재현 |

## 핵심 발견

1. 토폴로지 49배 확장(엣지 기준)에도 R1/R4 개선 미미
2. **Valley-free 라우팅은 이미 `pathfinder.go`에 구현되어 있었음**
3. 진짜 병목: BFS가 최단 valley-free 경로만 선택 → 실제 BGP의 LOCAL_PREF 선호도 미반영
4. Interception 모델이 `AddProviderEdge`만 수행 → 경로 광고 전파 효과 부재
