# 07. 향후 계획

## M7: Hidden Service v3

### 개요

M7은 Tor Hidden Service v3 프로토콜의 AS-level 관찰 취약성을 분석하는 확장이다. 일반 3-hop 회로와 달리, Hidden Service는 client 측과 service 측 모두 회로를 구성하여 rendezvous point에서 만나므로, 총 6-hop 경로가 생성된다. 이 추가 경로는 새로운 관찰 표면(attack surface)을 형성한다.

### Hidden Service v3 프로토콜 구조

```
Client ──→ Guard_C ──→ Middle_C ──→ RendPoint ◀── Middle_S ◀── Guard_S ◀── HS
                                         ▲
                                         │
                     IntroPoint ◀── Middle_I ◀── Guard_I ◀── HS
                         │
                 Client ─┘ (Introduction)
```

- **Introduction Point (IP)**: HS가 3~20개의 IP를 선택하여 descriptor를 게시
- **Rendezvous Point (RP)**: Client가 선택하는 중립 릴레이, 양쪽 회로가 만나는 지점
- **HSDir**: 6개 노드에 HS descriptor를 저장

### 관찰 표면 분석

일반 회로(3-hop)에서는 entry/exit 2개 세그먼트만 관찰 대상이지만, HS 회로에서는 최대 4종의 상관 조건이 발생한다:

| 상관 유형 | 관찰 세그먼트 | 위험도 |
|----------|-------------|--------|
| Client entry + Client exit | Client→Guard_C + Middle_C→RP | Client 식별 |
| HS entry + HS exit | HS→Guard_S + Middle_S→RP | HS 식별 |
| Client entry + HS exit | Client→Guard_C + Middle_S→RP | 양쪽 연결 |
| Intro circuit | HS→Guard_I + Middle_I→IP | IP 위치 노출 |

### 배경 문서 (작성 완료)

M7 구현 결정을 위해 4개의 배경 지식 문서를 작성했다:

| 문서 | 결정 질문 |
|------|----------|
| `next-simulate/.docs/BG_M7_scope.md` | 구현 깊이: Full protocol / Core only / Minimal PoC |
| `next-simulate/.docs/BG_M7_perspective.md` | 시뮬레이션 관점: 양쪽 모두(Client+HS) / Service-side only |
| `next-simulate/.docs/BG_M7_defense.md` | M6 방어를 HS 회로에도 적용할 것인가 |
| `next-simulate/.docs/BG_M7_python.md` | Python 분석 파이프라인 HS 확장 여부 |

### 미결정 사항

1. **구현 깊이**: Full protocol(IP 선택, descriptor, rendezvous) vs Core only(회로 구조만)
2. **Vanguards 포함 여부**: Tor의 실제 HS 방어 메커니즘(prop-292). L2/L3 고정 릴레이로 Guard discovery를 방지하는 메커니즘으로, Counter-RAPTOR/Astoria와는 직교하는 접근 (~200줄 추가 예상)
3. **양쪽 모델링**: Client와 HS 양쪽 모두 모델링할지, Service-side만 할지
4. **Python 분석 확장**: 6-hop 4종 상관 조건을 분석 파이프라인에 추가할지

### 예상 규모

| 구성 | 예상 규모 |
|------|----------|
| Go 코드 (HS 회로 + 이벤트) | ~500줄 |
| Vanguards (선택적) | ~200줄 |
| Python 분석 확장 (선택적) | ~300줄 |
| YAML 설정 + 테스트 | ~200줄 |

---

## 추가 실험 가능성

### 파라미터 변경 실험

현재 시뮬레이션은 고정 조건(50 클라이언트, 90일, seed=42)에서 수행했다. 다음 변경으로 추가 통찰을 얻을 수 있다:

- **클라이언트 수 증가** (100, 500, 1000명): 규모 확장 시 상관율 변화 측정
- **시뮬레이션 기간 연장** (180일, 365일): 장기 시간 추세 분석, Tempest 재현 시도
- **다른 seed**: 결과의 통계적 안정성 검증 (seed=1~10으로 10회 반복)
- **weight_factor 변경**: Counter-RAPTOR의 가중치 지수를 0.5, 1.0, 2.0으로 변경하여 최적값 탐색

### 다른 공격 시나리오

- **다중 동시 공격**: 3건의 공격을 동시에 실행
- **다른 target AS**: AS6939 외에 AS24875(NovoServe, 8.6%), AS50629(LWLcom, 6.8%) 등 hijack
- **SICO 스타일 공격**: BGP community 속성을 이용한 정밀 interception (현재 미구현)
- **장기 interception**: 24시간 이상 지속되는 interception의 누적 효과

### 다른 적대자 모델

- **다른 국가**: US, RU, CN 국가 수준 적대자 — 각 국가의 AS 수와 위치에 따른 차이
- **IXP 적대자**: 대형 IXP를 제어하는 적대자 (현재 IXP는 명시적으로 모델링하지 않음)
- **복합 적대자**: 국가 + Tier-1 결합 (StateLevel + Tier1)

---

## 연구 확장 방향

### RQ3 답변 (M7 완료 시)

M7이 완료되면 RQ3("Hidden Service 트래픽은 일반 트래픽 대비 얼마나 더 추적 가능한가?")에 답할 수 있다:

- 6-hop 경로의 추가 관찰 표면이 상관율을 얼마나 증가시키는가
- Introduction Point/Rendezvous Point 선택이 HS 식별에 미치는 영향
- Astoria 방어가 HS 회로에도 효과적인가

### 실제 Tor Metrics 대비 검증

현재 시뮬레이션 결과를 실제 Tor 네트워크 통계와 비교하여 현실성을 검증할 수 있다:

- **릴레이 수/대역폭 분포**: Tor Metrics의 실제 분포와 시뮬레이션 입력 비교
- **Guard 선택 분포**: 실제 Tor 클라이언트의 Guard 선택 패턴과 비교
- **회로 수명**: 실측 회로 수명과 시뮬레이션의 10분 교체 주기 비교

### 논문 수치 재현

| 논문 | 기준값 | 현재 결과 | 비고 |
|------|--------|----------|------|
| Johnson et al. 2013 | 40% 취약 | 1.93% 상관율 | 모델 범위 차이 (727 AS vs 전체 인터넷) |
| Counter-RAPTOR 2017 | 최대 36% 개선 | 4.6% 개선 | weight_factor 조정으로 개선 가능 |
| Astoria 2016 | 취약률 40%→2% | 1.93%→~0% | 유사한 효과 확인 |
| Tempest 2018 | 시간적 상관 증가 | slope +0.0031 | 증가 추세 확인 |
| RAPTOR 2015 | 비대칭 경로 시 50% 증가 | 1.84x (공격 #2) | 국가 수준에서 유사 |

---

## 로드맵 요약

```
현재 (M6 완료)
  │
  ├── 추가 실험: 파라미터 변경, 다른 공격 시나리오  ← 즉시 가능
  │
  ├── M7 Hidden Service v3  ← 배경 문서 완료, 결정 대기
  │   ├── 구현 결정 (4가지)
  │   ├── 구현 (~800~1,200줄)
  │   └── RQ3 답변
  │
  └── 연구 확장
      ├── Tor Metrics 검증
      ├── 논문 수치 재현 심화
      └── 추가 방어 전략 (DeNASA, Vanguards)
```
