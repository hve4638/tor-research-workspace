# Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries

**요약 작성일**: 2026-02-21
**원문**: Johnson, Wacek, Jansen, Sherr, Syverson (CCS 2013)
**소속**: U.S. Naval Research Laboratory / Georgetown University
**DOI**: 10.1145/2508859.2516651

---

## 1. 핵심 기여 (One-line)

현실적 적대자(릴레이 운영자, AS, IXP, IXP 조직)를 모델링하여 Tor 사용자의 트래픽 상관 공격에 대한 취약성을 **시간 경과에 따라 정량적으로** 최초 측정한 논문.

---

## 2. 연구 동기

- Tor는 entry/exit 양쪽 트래픽을 관찰할 수 있는 적대자에게 취약 (트래픽 상관 공격)
- 기존 연구의 한계:
  - 엔트로피 기반 정적 메트릭만 사용 → 사용자별 보안 수준을 알 수 없음
  - 단일 AS 또는 단일 IXP만 고려 → 실제로는 한 조직이 여러 AS/IXP를 통제
  - 시간에 따른 위험 누적을 고려하지 않음

---

## 3. 적대자 모델 (Adversary Model)

### 3.1 릴레이 적대자 (Relay Adversary)
- 악의적 Guard 릴레이 + Exit 릴레이를 운영
- 총 **100 MiB/s** 대역폭 보유 (당시 상위 family 수준)
- 최적 배분: **Guard:Exit = 5:1** (83.3 MiB/s : 16.7 MiB/s)
  - Exit-only 릴레이는 exit 가중치가 높아 적은 대역폭으로도 exit 선택 확률이 높음
  - Guard 선택이 deanonymization의 병목 → Guard에 더 많이 투자

### 3.2 네트워크 적대자 (Network Adversary)
| 유형 | 설명 |
|------|------|
| **AS** | 하나 이상의 자율 시스템을 통제, 통과하는 모든 트래픽 관찰 |
| **IXP** | 인터넷 교환점, 여러 AS 간 트래픽이 한 지점을 경유 |
| **IXP 조직** | 한 조직이 다수의 IXP를 운영 (예: Equinix 19개 IXP) |

- 수동적(passive) end-to-end 상관 적대자로 제한
- client→guard 경로와 exit→destination 경로 양쪽에 존재하면 상관 성공

---

## 4. 보안 메트릭

기존의 엔트로피/정적 메트릭 대신 **사용자 관점**의 두 가지 메트릭 제안:

1. **첫 번째 경로 침해까지의 시간 분포** (Time to first path compromise)
2. **주어진 기간 내 경로 침해 횟수의 확률 분포** (Number of path compromises)

→ "내가 이렇게 사용하면 얼마나 안전한가?"에 답할 수 있는 메트릭

---

## 5. 방법론

### 5.1 TorPS (Tor Path Simulator)
- Tor Metrics의 과거 네트워크 상태(consensus, descriptor)를 사용하여 경로 선택을 재현
- 몬테카를로 시뮬레이션 (n = 50,000 ~ 100,000 샘플)
- Dvoretzky-Kiefer-Wolfowitz 부등식으로 CDF 오차 < 0.01 보장

### 5.2 사용자 모델 (5종)

| 모델 | 활동 | 스트림/주 | 포트 |
|------|------|----------|------|
| **Typical** | Gmail, Facebook, 웹 검색 | 2,632 | 80, 443 |
| **IRC** | IRC 채팅 (평일 8am-5pm) | 135 | 6697 |
| **BitTorrent** | 파일 다운로드 (주말 0am-6am) | 6,768 | 118종 |
| **WorstPort** | Typical과 동일, 포트만 6523 (Gobby) | 2,632 | 6523 |
| **BestPort** | Typical과 동일, 포트만 443 | 2,632 | 443 |

### 5.3 인터넷 맵
- BGP 경로 (RouteViews 8개 라우터, 2013.3) + CAIDA traceroute 데이터
- **44,605 AS, 305,381 링크**
- AS 관계 추론: Gao 알고리즘 → CAIDA AS Relationships 덮어쓰기 → RIPE WHOIS 형제 관계 보정
- AS 경로 추론: Qiu 알고리즘 (BGP 테이블 기반 shortest-path 변형)
- IXP 맵: IXP Mapping Project, 199개 IXP, 58,524 AS 피어링

---

## 6. 주요 결과

### 6.1 릴레이 적대자 결과 (100 MiB/s, Guard:Exit = 5:1)

| 메트릭 | 결과 |
|--------|------|
| 6개월 내 deanonymization 확률 | **모든 사용자 모델에서 >80%** |
| 중앙값 첫 침해 시간 | **< 70일** |
| 악의적 Guard 선택 중앙값 | 50~60일 |
| 악의적 Exit 선택 중앙값 | **< 2.5일** |
| 전체 스트림 침해율 중앙값 | 0.25% ~ 1.5% |

- **Guard 선택이 병목**: Guard 선택 확률이 전체 침해 시간을 지배
- **BitTorrent이 가장 취약**: Exit 침해 중앙값 < 6시간, 침해율 중앙값 > 12%
  - 기본 exit 정책에서 거부되는 포트 사용 → 악의적 exit의 상대적 비중 증가
- **대역폭 효과**: 200 MiB/s이면 30일 내 50% 확률로 침해, 10 MiB/s이면 < 10%

### 6.2 네트워크 적대자 결과 (3개월 시뮬레이션)

**AS 적대자** (최상위 AS: Level 3, TeliaNet, Hurricane Electric):
- **최악 위치**: 1일 내 45.9%(Typical), 64.9%(IRC), 76.4%(BitTorrent) 침해
- 3개월 내 **>98%** 샘플이 최소 1회 침해
- **최선 위치**: IRC 사용자도 44일 중앙값으로 침해

**IXP/IXP 조직 적대자**:
- 최악은 AS와 유사
- 최선은 3개월 내 <20% 침해 (네트워크 링크의 80%가 IXP를 거치지 않음)
- IXP 조직 > 개별 IXP: 30일 내 침해 3.7% → 12.4%

**적대자 AS 수 증가 효과**:
- 1개 → 2개 AS: 30일 내 침해 156%(BT), 65.8%(IRC), 122%(Typical) 증가
- 첫 침해까지 시간이 **수개월 → 1일**로 단축 (Typical 웹 사용자)

### 6.3 핵심 발견

| 적대자 유형 | 위험 증가 요인 | 위험 감소 요인 |
|------------|--------------|--------------|
| 릴레이 | 많은 스트림, 소수 exit만 허용하는 포트 | 대중적 포트(443), 적은 활동 |
| 네트워크 | **낮은 목적지 다양성** (IRC처럼 단일 목적지) | **높은 목적지 다양성** (BitTorrent) |

→ 릴레이 적대자와 네트워크 적대자의 위험 패턴이 **정반대**: 네트워크 적대자에게는 목적지가 다양할수록 안전

---

## 7. Congestion-Aware Tor (CAT) 분석

- Wang et al. (2012)의 혼잡 인식 경로 선택 알고리즘 평가
- Shadow를 사용한 가상 Tor 네트워크로 릴레이별 혼잡 프로파일 생성
- **결과**:
  - 첫 침해 시간: Tor와 비슷 (Guard 선택에 영향 없으므로)
  - **스트림 침해율 증가**: 혼잡 낮은 악의적 릴레이가 우선 선택됨
- **새로운 공격 벡터**: 적대자가 자신이 침해한 회로의 응답 시간을 낮추고, 침해하지 않은 회로의 응답 시간을 높여 사용자를 유도 (선택적 DoS와 유사하나 탐지가 더 어려움)

---

## 8. 방어 제안

| 제안 | 효과 |
|------|------|
| Guard 수 줄이기 (3개 → 1개) | 악의적 Guard 선택 확률 비례 감소 |
| Guard 만료 시간 연장 (30일 → 60일+) | 첫 침해까지 시간 증가 (실제로 Tor 0.2.4.12-alpha에서 60일로 변경) |
| AS/IXP 인식 경로 선택 | 네트워크 적대자 방어 (Edman & Syverson, Juen 제안) |
| 사용자별 신뢰 기반 릴레이 선택 | Johnson et al. (2011) 제안 |
| 수동 EntryNodes/ExitNodes 설정 | 개인 방어 가능하나 클라이언트 균일성 훼손 |

---

## 9. 프로젝트 연관성

이 논문은 본 프로젝트(project-tor)의 **핵심 선행 연구**:

| 논문 개념 | 프로젝트 구현 |
|----------|-------------|
| AS-level 적대자 모델 | `next-simulate/internal/asgraph/` — AS 그래프 + 관계 모델링 |
| BGP 경로 추론 (Qiu 알고리즘) | `next-simulate/internal/asgraph/path.go` — AS 경로 추론 |
| Guard/Exit 대역폭 가중치 선택 | `next-simulate/internal/circuit/` — 3-hop 회로 생성 |
| IXP 위협 | 현재 미구현 (AS만 고려) |
| 시간 경과에 따른 침해 확률 | `tor-anal/analysis/` — 상관율 계산, 공격 전/중/후 분석 |
| 릴레이 vs 네트워크 적대자 | `configs/bgp_attack.yaml` — 4종 적대자 모델 |
| Counter-RAPTOR/Astoria 방어 | M6에서 구현 완료 |

### 본 논문이 RAPTOR (Sun et al. 2015)와 다른 점
- RAPTOR는 **BGP 공격(hijack/interception)**을 통한 능동적 경로 조작을 다룸
- 본 논문은 **기존 네트워크 위치**에서의 수동적 관찰에 집중
- 프로젝트는 두 논문의 위협 모델을 모두 구현 (M5: BGP 공격, 네트워크 적대자 관찰)

---

## 10. 한계 및 후속 연구

- 회로 혼잡, 지연시간, 웹사이트 핑거프린팅 등 다른 공격은 미고려
- Hidden Service / Bridge 미고려
- 비대칭 라우팅 미고려 (A→B ≠ B→A) → RAPTOR 논문에서 다룸
- 동적/반응적 전략적 적대자 미고려
- 사용자 모델이 제한적 (5종, 20분 트레이스 기반)
- 2013년 네트워크 데이터 기반 → 현재 Tor 네트워크와 차이 존재

---

## 참고 수치 요약

```
릴레이 적대자 (100 MiB/s, 5:1 배분):
  - 6개월 내 deanonymization: >80% (전 사용자 모델)
  - 첫 침해 중앙값: <70일
  - Exit 침해 중앙값: <2.5일

네트워크 적대자 (단일 AS, 최악 위치):
  - 1일 내 침해: 45.9% (Typical) ~ 76.4% (BitTorrent)
  - 3개월 내 침해: >98%

네트워크 적대자 (2개 AS):
  - Typical 웹 사용자: 첫 침해 수개월 → 1일
  - BitTorrent: 수개월 → ~1개월

인터넷 맵: 44,605 AS, 305,381 링크, 199 IXP
```
