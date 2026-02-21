# 프로젝트 현황 요약 및 조언 (2026.01.05)

## 미팅 노트 (2025.12.26) 핵심 내용

| 구분 | 내용 |
|------|------|
| **연구 주제** | Tor 시뮬레이션을 통한 트래픽 추적 |
| **현재 진행** | Onion Network 시뮬레이터 일부 구현 + 시각화 도구 작성 |

**미팅에서 지적된 보완 사항:**
1. 연구 범위 명확화
2. 가제목 및 키워드 설정
3. 시뮬레이션 단순화 타당성 입증 필요
   - 현실 트래픽과의 비교 대상
   - 시나리오를 현실과 유사하게 측정
   - 추적 방법의 공식화 (관련 논문 참조)

---

## 시뮬레이터 (Go 기반) - 구현 완료

| 기능 | 상태 | 설명 |
|------|------|------|
| 틱 기반 시뮬레이션 | ✅ | min-heap 이벤트 큐, 시간 배율 지원 |
| 지역 기반 노드 시스템 | ✅ | 계층적 지역 구조 (대륙→국가→도시), 레이턴시 계산 |
| 루틴 함수 시스템 | ✅ | `browse_random`, `periodic_check`, `download_file` |
| 글로벌 관찰자 로그 | ✅ | NDJSON 형식 출력 |

---

## 시각화 도구 (React/TypeScript) - Phase 4까지 완료

| Phase | 상태 | 내용 |
|-------|------|------|
| 1. 초기 설정 | ✅ | Vite + React 19 + Fastify + FSD 구조 |
| 2. 백엔드 | ✅ | SQLite, 파일 업로드, 로그 페이지네이션 |
| 3. 기본 UI | ✅ | Cytoscape 그래프, 재생 컨트롤, 로그 사이드바 |
| 4. 재생 시스템 | ✅ | 엣지 색상, 키보드 단축키, 패킷 상세 팝업 |
| 5. 로그 사이드바 개선 | ⬜ | 필터링 기능 |
| 6. 그래프 애니메이션 | ⬜ | 회로별 색상, 패킷 이동 애니메이션 |
| 7. 부가 기능 | ⬜ | 통계 대시보드, 성능 최적화 |

---

## 조언

### 1. 연구 방향성 - 가제목 제안

미팅에서 요청한 가제목과 관련하여 다음과 같은 방향을 고려해볼 수 있습니다:

**가제목 예시:**
- "Traffic Correlation Analysis on Onion Networks: A Simulation-Based Approach"
- "Evaluating Global Adversary Capabilities in Tor-like Networks through Discrete Event Simulation"

**핵심 키워드:**
- Traffic Correlation Attack, Global Adversary, Onion Routing, Network Simulation, Timing Analysis

---

### 2. 시뮬레이션 타당성 확보 전략

미팅에서 가장 강조된 부분입니다. 다음 단계를 권장합니다:

**A. 현실 데이터와의 비교 기준 수립**
```
1. 실제 Tor 네트워크 통계 활용
   - Tor Metrics (https://metrics.torproject.org)
   - 릴레이 수, 대역폭 분포, 지역 분포

2. 시뮬레이션 파라미터 매핑
   - 현재 config.yaml의 regions 설정을 실제 Tor 릴레이 분포와 비교
   - 레이턴시 값의 현실성 검증 (실제 네트워크 측정 데이터 참조)
```

**B. 관련 논문 참조 (추적 방법 공식화)**
- Johnson et al. "Users Get Routed: Traffic Correlation on Tor" (2013) - 트래픽 상관 분석의 기본 모델
- Murdoch & Danezis "Low-Cost Traffic Analysis of Tor" (2005) - 타이밍 분석
- Sun et al. "RAPTOR: Routing Attacks on Privacy in Tor" (2015) - 네트워크 레벨 공격

---

### 3. 즉시 수행 가능한 작업

| 우선순위 | 작업 | 이유 |
|----------|------|------|
| **1** | Tor Metrics에서 실제 릴레이 분포 수집 | 시뮬레이션 시나리오의 현실성 근거 |
| **2** | 추적 성공률 공식 정의 | 연구 기여로 삼을 핵심 지표 |
| **3** | 시각화 도구 필터링 기능 완성 | 분석 결과 검증에 필요 |

---

### 4. 연구 기여(Contribution) 후보

1. **시뮬레이션 프레임워크 자체**: 재현 가능한 Tor-like 네트워크 시뮬레이터
2. **글로벌 관찰자 시점의 추적 성공률 분석**: 네트워크 규모/지역 분포에 따른 변화
3. **방어 전략 효과 측정**: 패딩, 경로 다양화 등의 효과 정량화
