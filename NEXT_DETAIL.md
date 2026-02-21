# NEXT.md - 다음 목표

## 최종 목적

Tor 시뮬레이션을 통한 AS-level 글로벌 관찰자 연구 완수

---

## 연구 질문 (Research Questions)

**RQ1: AS-level 글로벌 관찰자가 Tor 트래픽을 얼마나 상관(correlate)할 수 있는가?**
- Guard AS와 Exit AS를 동시에 관측할 때의 추적 성공률
- 관측 AS 수에 따른 커버리지 변화

**RQ2: 특정 AS 위치 (예: IXP)가 추적 성공률에 얼마나 영향을 주는가?**
- IXP 위치 AS vs 일반 AS의 관측 효율성 비교
- 지리적 위치(국가, 대륙)에 따른 영향

**RQ3: Hidden Service 트래픽은 일반 트래픽 대비 얼마나 더 추적 가능한가?**
- HSDir, Introduction Point 관측의 영향
- 6홉 경로의 추적 난이도 분석

---

## 단기 목표

**Tor 시뮬레이션 재작성: `next-simulate`**

Tor의 내부 로직을 모방해 현실성을 높이며 AS-level 단위 관측을 추가

---

## 기존 onion-simulate 구현의 문제

- 현실을 얼마나 잘 나타내는지 불완전 (시뮬레이션된 시간 등)
- 패킷 전달 등 불완전함
- AS-level을 잘 나타내지 않음
- 역공학 파라미터가 적용되지 않음

---

## 기술적 목표

### Tor 핵심 로직 모방

- **Directory/HSDir 서버**: 합의 문서, 디스크립터 제공
- **클라이언트 노드 선택**: 대역폭 가중치 기반 확률적 선택 (Wgg, Wgm, Wee)
- **Guard 관리**: 샘플링, 수명, Primary/Confirmed 계층
- **회로 생성**: CREATE/EXTEND 프로토콜, 타이밍 (CBT Pareto 분포)
- **Hidden Service**: v3 프로토콜 (Introduction Point, Rendezvous, 24시간 주기)
- **패킷 특성**: 512 bytes 셀 구조, 타이밍 시그니처

### 단순화 범위

| 요소 | 실제 Tor | next-simulate |
|------|----------|---------------|
| 암호화 | AES-CTR + ntor | 생략 (plaintext) |
| 패킷 크기 | 고정 512 bytes | size 필드만 유지 |
| 네트워크 전송 | TCP/TLS | 이벤트 기반 메시지 전달 |
| 디렉토리 합의 | 1시간마다 갱신 | 정적 또는 설정 기반 |

### 유지해야 할 핵심

| 요소 | 이유 |
|------|------|
| 패킷 셀 구조 (512 bytes) | 트래픽 핑거프린팅 시그니처 |
| 타이밍 분포 (CBT, 지연) | 상관 분석의 핵심 |
| 3홉 경로 구조 | Tor 기본 아키텍처 |
| Guard 선택 확률 | 관측 확률에 직접 영향 |

### 클라이언트/서버 유연성

- 각 클라이언트, 서버의 동작은 유연하게 설정 가능해야 함
- 시나리오 기반 행동 패턴 정의 (루틴 시스템 재사용)

### AS-level 네트워크 모델링

**노드 세부 정보 Configuration:**
- AS 번호 및 AS 유형 (Transit, Stub, IXP)
- AS 간 물리적 관계 (Provider-Customer, Peer-to-Peer)
- 노드가 속한 AS/IXP 위치
- 지역 정보 (국가, 대륙)

**AS-level 관측 정의:**
- **관측 지점**: Guard AS, Exit AS, IXP, 중간 경로 AS
- **관측 데이터**: 타이밍(timestamp), 패킷 방향, 패킷 크기, 회로 ID(암호화되어 직접 확인 불가)
- **관측 모델**: 
  - Passive observer (패킷 메타데이터만)
  - Active observer (패킷 주입/수정 가능)

---

## 적용할 역공학 파라미터

**출처: ref-tor/reverse-engineer/**

| 카테고리 | 파라미터 |
|----------|----------|
| 노드 선택 | 가중치 매트릭스 (Wgg, Wgm, Wee, Weg, Wmg, Wme, Wmd) |
| Guard 관리 | 샘플 크기 (60-200), 수명 (30-60일), 승격 조건 |
| 타이밍 | CBT Pareto 분포 (α=1.8, Xm=1.8s), MaxCircuitDirtiness (10분) |
| Hidden Service | IP 3-20개, HSDir 6개, 24시간 주기, SRV 동기화 |
| 실패 처리 | 재시도 횟수, 백오프 전략, 경로 바이어스 임계값 |

참조 문서:
- `ref-tor/reverse-engineer/00_final_report.md` (클라이언트)
- `ref-tor/reverse-engineer/18_hs_final_report.md` (Hidden Service)

---

## 현실성 검증 기준 (Validation Criteria)

- [ ] **Tor Metrics 통계와의 비교**: 릴레이 수, 대역폭 분포, 지역 분포
- [ ] **실제 트래픽 패턴 비교**: 회로 생성 빈도, 수명, 실패율
- [ ] **관련 논문 결과 재현**: Johnson et al. 2013, Murdoch & Danezis 2005 등

---

## 예상 산출물

### 1. 시뮬레이션 엔진 (next-simulate)
- **언어**: Go (성능) 또는 Rust (안전성)
- **입력**: YAML 설정 파일 (시나리오, AS 모델, 노드 배치)
- **실행**: 이벤트 기반 시뮬레이션

### 2. 로그 출력
- **AS-level 관측 로그**: Observer가 볼 수 있는 메타데이터만
- **그라운드 트루스 로그**: 실제 회로 매핑, 분석 및 검증용

### 3. 분석 도구
- **추적 성공률 계산기**: AS 관측 조합별 상관 성공률
- **시나리오별 비교 리포트**: RQ1, RQ2, RQ3에 대한 정량 분석

---

## 기존 자산 활용

| 자산 | 활용 방법 |
|------|-----------|
| onion-simulate | 이벤트 큐, 지역 시스템, 루틴 시스템 참조 |
| ref-tor/reverse-engineer | 파라미터 + 알고리즘 직접 적용 |
| ref-tor/pipeline | AS 데이터 (as_sets.json, as_roles.json, as_model.json) |
| onion-simulate-visualize | 로그 형식 호환성 유지 → 시각화 도구 재사용 |

---

## 마일스톤

| 단계 | 목표 | 예상 기간 | 산출물 |
|------|------|-----------|--------|
| M1 | 아키텍처 설계 + 핵심 타입 정의 | 1주 | ARCHITECTURE.md, 타입 정의 |
| M2 | Directory/Guard 선택 구현 | 2주 | 노드 선택 로직, Guard 관리 |
| M3 | 회로 생성 + 패킷 전달 | 2주 | CREATE/EXTEND, 릴레이 메커니즘 |
| M4 | Hidden Service 지원 | 2주 | HSDir, IP, Rendezvous |
| M5 | AS-level 관측 로직 | 1주 | Observer 모델, 로그 생성 |
| M6 | 검증 + 분석 | 2주 | 추적 성공률 계산, 논문 재현 |

**총 예상 기간: 10주**

---

## 다음 즉시 작업

1. **ARCHITECTURE.md 작성**: next-simulate 설계 문서
   - 모듈 구조
   - 데이터 흐름
   - AS-level 네트워크 모델
   
2. **우선순위 결정**: 어떤 RQ를 먼저 구현할 것인가?
   - 제안: RQ1 → RQ2 → RQ3 순서

3. **프로토타입 시작**: M1 단계 착수
   - 핵심 타입 정의 (Circuit, Node, AS, Event)
   - 이벤트 큐 설계
