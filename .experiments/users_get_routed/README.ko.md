# "Users Get Routed" 논문 재현 실험

**논문**: Johnson et al., "Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries",
ACM CCS 2013.

**실험 일자**: 2025-02-20 ~ 2025-02-22
**실험 ID**: `users-get-routed-v1`
**상태**: 완료 (2개 실험 세트: 네트워크 적대자 + 릴레이 적대자)

---

## 개요

Johnson et al.의 핵심 발견을 AS-level Tor 시뮬레이터로 재현한 실험이다.
이 논문은 네트워크 계층(BGP 라우팅)에서 entry와 exit 세그먼트를 관찰하여
Tor 트래픽을 상관시킬 수 있는 현실적 AS-level 적대자 개념을 도입했다.
또한 악의적 guard와 exit 릴레이를 운영하는 릴레이 수준 적대자 모델도 포함한다.

### 실험 세트

| 세트 | 설명 | 시나리오 | 논문 참조 |
|------|------|---------|----------|
| **A** | 네트워크 적대자 (AS 수준) | 4개 방어 전략 | Figures 2a, 3 |
| **B** | 릴레이 적대자 (악의적 릴레이) | 1개 기준선 | Figures 2a-c, 3 |

### 방어 전략 (세트 A)

| 시나리오 | 방어 | 논문 참조 |
|----------|------|----------|
| Vanilla | 방어 없음 (기준선) | 원본 논문 모델 |
| Counter-RAPTOR | AS 복원력 기반 guard 가중치 재조정 | Sun et al. 2015 |
| Astoria | entry/exit transit AS 중복 회피 | Nithyanand et al. 2016 |
| Combined | Counter-RAPTOR + Astoria | 새로운 조합 |

## 문서 링크

| 문서 | 설명 |
|------|------|
| [PROTOCOL.ko.md](PROTOCOL.ko.md) | 정확한 재현 프로토콜 (명령어, 파라미터, 소요 시간) |
| [RESULTS.ko.md](RESULTS.ko.md) | 상세 수치 결과 및 논문 비교 |
| [ENVIRONMENT.ko.md](ENVIRONMENT.ko.md) | 하드웨어, 소프트웨어, 데이터 출처 |
| [configs/](configs/) | 5개 YAML 시뮬레이션 설정 (사본) |
| [results/](results/) | JSON 보고서 (네트워크 + 릴레이 적대자) |
| [plots/](plots/) | 11개 논문 수준 시각화 |

## 핵심 결과 요약

### 세트 A: 네트워크 적대자

| 시나리오 | 클라이언트 침해 | 스트림 침해 | 감소율 |
|----------|---------------|-----------|--------|
| Vanilla | 34/50 (68.0%) | 1.93% | 기준선 |
| Counter-RAPTOR | 34/50 (68.0%) | 1.84% | -4.6% 스트림 |
| Astoria | 9/50 (18.0%) | 0.001% | -73.5% 클라이언트 |
| Combined | 5/50 (10.0%) | 0.0003% | -85.3% 클라이언트 |

### 세트 B: 릴레이 적대자

| 지표 | 값 |
|------|-----|
| 침해된 클라이언트 | 200/200 (100%) |
| 최초 침해 | Day 57.1 |
| 50% 침해 | Day 59.7 |
| 100% 침해 | Day 60.0 |
| Guard 수명과의 상관 | 정확히 일치 (30-60일 범위) |

## 디렉토리 구조

```
.experiments/users_get_routed/
├── README.md / README.ko.md            # 실험 개요
├── PROTOCOL.md / PROTOCOL.ko.md        # 단계별 재현 프로토콜
├── RESULTS.md / RESULTS.ko.md          # 상세 수치 결과
├── ENVIRONMENT.md / ENVIRONMENT.ko.md  # 환경 정보
├── configs/                            # 시뮬레이션 설정 사본
│   ├── bgp_attack.yaml
│   ├── counter_raptor_defense.yaml
│   ├── astoria_defense.yaml
│   ├── combined_defense.yaml
│   └── relay_adversary.yaml
├── results/
│   ├── network_defense_comparison_report.json
│   └── relay_adversary_report.json
└── plots/
    ├── network/                        # 세트 A 시각화 (8개)
    └── relay_adversary/                # 세트 B 시각화 (3개)
```

## 인용

```bibtex
@inproceedings{johnson2013users,
  title={Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries},
  author={Johnson, Aaron and Wacek, Chris and Jansen, Rob and
          Sherr, Micah and Syverson, Paul},
  booktitle={ACM Conference on Computer and Communications Security (CCS)},
  pages={337--348},
  year={2013}
}
```
