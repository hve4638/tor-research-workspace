# Tor Hidden Services: A Systematic Literature Review

**요약 작성일**: 2026-02-21
**원문**: Diana L. Huete Trujillo, Antonio Ruiz-Martínez (J. Cybersecur. Priv. 2021)
**소속**: University of Murcia, Department of Information and Communications Engineering
**DOI**: 10.3390/jcp1030025

---

## 1. 핵심 기여 (One-line)

Tor Hidden Service(THS)에 대한 **최초의 체계적 문헌 고찰(SLR)**으로, 2006~2019년 57편의 논문을 분석하여 보안, 콘텐츠 분류, 발견/측정, 성능, 설계 변경, 인적 요인의 6개 연구 영역으로 분류하고 주요 발견과 미해결 과제를 종합 정리한 논문.

---

## 2. 연구 동기

- Tor Hidden Service(현재 Onion Service)는 서버 IP를 숨기는 핵심 메커니즘으로, 2004년 도입 이후 **150,000개 이상** 운영
- THS는 검열 우회, 내부고발(WikiLeaks), 언론 자유 보호에 핵심이나, 동시에 다크넷 마켓(Silk Road 등) 등 불법 활동에도 악용
- 기존 Tor 관련 서베이에서 THS는 부분적으로만 다루어짐:
  - Saleh et al. (2018): Tor 전체 분류 중 THS 관련 논문 **9%**에 불과
  - Alidoost Nia & Ruiz-Martínez (2017): 203편 중 THS 관련 9편만 분석
  - Nepal et al. (2015): THS de-anonymization 공격만 다룸 (3가지 방법)
- **THS만을 전면적으로 다루는 체계적 문헌 고찰이 부재** → SLR 수행의 동기

---

## 3. 방법론 (SLR 절차)

### 3.1 연구 질문 (Research Questions)

| RQ | 질문 |
|----|------|
| RQ1 | THS의 주요 연구 영역과 핵심 발견은 무엇인가? |
| RQ2 | 연구의 한계와 연구가 부족한 분야는? |
| RQ3 | 최근 수년간 THS에 의미 있는 진전이 있었는가? |
| RQ4 | THS 영역에서 가장 많이 인용된 논문은? |
| RQ5 | Tor Rendezvous Specification v3 출시와 연구 간 관계는? |
| RQ6 | THS 관련 주요 미래 연구 주제/문제는? |

### 3.2 검색 전략

- **검색 기간**: 2019년 6~7월 수행
- **데이터베이스 3개**: Google Scholar, Web of Science, Scopus
- **검색어**:
  - `+Tor "Onion|Hidden Services|Server"`
  - `Tor "Hidden Services" OR TOR "onion services"`
  - `("Tor" AND "Hidden services") OR ("Tor" AND "onion services")`

| 데이터베이스 | 검색 결과 |
|-------------|----------|
| Google Scholar | 1,770편 |
| Web of Science | 105편 |
| Scopus | 339편 |

### 3.3 선정 기준

**포함 기준**:
- 저널 또는 컨퍼런스에 출판된 논문
- THS에 초점을 맞춘 연구
- 영어로 작성된 문서

**배제 기준**:
- 도서 챕터, 특허, 인용, 기술 보고서
- THS를 일반적으로만 다루는 익명 통신 시스템 연구

**최종 선정**: 2,214편 → **57편**

---

## 4. 주요 발견: 6대 연구 영역 분류

### 4.1 연구 영역 분포

| 연구 영역 | 논문 수 | 비율 |
|-----------|---------|------|
| **보안 (Security)** | **28** | **최다** |
| 콘텐츠 분류 (Content Classification) | 17 | 2위 |
| 발견 및 측정 (Discovery & Measurement) | 12 | 3위 |
| 설계 변경 (Changes in Design) | 6 | |
| 성능 (Performance) | 4 | |
| 인적 요인 (Human Factors) | 3 | |

> 일부 논문은 복수 영역에 걸쳐 분류됨

### 4.2 보안 — 공격 (20편)

보안 영역은 **공격**(20편)과 **방어**(9편)로 나뉘며, 공격이 압도적.

#### De-anonymization 공격 유형

| 공격 유형 | 핵심 메커니즘 | 대표 연구 |
|-----------|-------------|----------|
| **Entry node 제어** | 악의적 OR이 HS의 첫 번째 노드로 선택되면 IP 노출 | Overlier & Syverson (2006) — 최초 공격 문서화 |
| **트래픽 상관 (Traffic Correlation)** | 제어된 entry node에서 트래픽 패턴 매칭 | Zhang et al. (2011), Elices et al. (2013), Ling et al. (2013), Wang et al. (2016) |
| **웹 기반 트래픽 패턴** | 브라우저를 통해 특정 트래픽 생성 → 제어 노드에서 탐지 | Zhang et al. (2011) |
| **핑거프린팅 (Fingerprinting)** | 요청 패턴으로 HS를 식별. 큰 .onion 사이트일수록 취약 | Elices (2012), Kwon (2015), Overdorf et al. (2017), Panchenko et al. (2017) |
| **Clock skew** | CPU 온도 변화 → 클럭 틸트 패턴으로 HS 서버 식별 | Murdoch (2006), Zander & Murdoch (2008) |
| **정보 유출** | HS 설정/콘텐츠의 URL, 이메일, HTTP 인증서에서 위치 추론 | Matic et al. (2015) — CARONTE |
| **워터마킹 (Watermarking)** | TCP/Tor 혼잡 관리 메커니즘 악용, 클라이언트 측 워터마크 삽입 | Iacovazzi et al. (2018) |
| **MITM** | HS 개인키 탈취 (서버 취약점/설정 오류 이용), 경로 외부에서 공격 가능 | Sanatinia & Noubir (2017) |
| **클라이언트 식별** | 악성 HS가 클라이언트의 entry node를 통해 클라이언트 IP 발견 | Ma & Xu (2017) |

> **핵심 결론**: 모든 de-anonymization 공격은 최소 **1개의 악의적 Guard 노드** 제어가 필수. Guard 선택을 강제하지 못하면 공격 실패. (Nepal et al. 2015)

#### DoS 공격 유형

| 공격 유형 | 메커니즘 | 대표 연구 |
|-----------|---------|----------|
| **HSDir 제어** | HS descriptor 접근 통제 → 서비스 모니터링/차단 | Biryukov et al. (2013) |
| **Eclipse 공격** | 가짜 HSDir로 라우팅 테이블 장악 → 모든 incoming 연결 차단 | Tan et al. (2017, 2019) |

> DoS 공격은 **대규모 자원 불필요** — 소수의 악의적 HSDir로도 가능

### 4.3 보안 — 방어 (9편)

| 방어 메커니즘 | 내용 | 대표 연구 |
|-------------|------|----------|
| **Valet Services (Guard 노드)** | entry point에 추가 보호 계층, 사용자로부터 entry point 은닉 | Øverlier & Syverson (2006) |
| **Ring 라우팅 (Ferris Wheel)** | HS를 라우터에 포함, 폐쇄 회로 + 더미 패킷으로 트래픽 분석 방지 | Beitollahi & Deconinck (2012) |
| **다중 경로 라우팅** | 흐름 혼합/병합으로 공격자의 트래픽 패턴 왜곡 | Yang & Li (2015) |
| **Honey Onions (Honions)** | 비공개 .onion 허니팟으로 악의적 HSDir 탐지 | Sanatinia & Noubir (2016) |
| **포렌식 핑거프린팅** | HS에 지속적 핑거프린트 삽입 → 추후 범죄 증거로 활용 | Shebaro et al. (2010), Elices et al. (2011) |
| **Botnet 남용 방지** | 실패한 부분 회로 재사용, HS 회로 격리 | Hopper (2014) |
| **MITM 탐지** | descriptor 비교 기반 MITM 탐지 메커니즘 | Sanatinia & Noubir (2017) |

### 4.4 콘텐츠 분류 (17편)

- 불법/비윤리적 콘텐츠 비율: **38%~45%** (연구에 따라 상이)
  - Guitton (2013): 1,171개 HS 중 **45%** 비윤리적/불법
  - Biryukov et al. (2014): 1,813개 기능 서비스 중 **44%** 불법
  - Faizan & Khan (2019): **38%**만 불법
- 가장 인기 있는 HS: 연구마다 상이 (Goldnet 봇넷, Silk Road, 마약/마약류 등)
- HS 콘텐츠 **~73.28% 영어**, ~2.14% 스페인어
- ~20% 이상의 .onion 도메인이 surface web 리소스를 임포트
- ~90%의 onion 서비스가 상호 연결됨
- 분류 기법: 수동 분류, 텍스트 기반 데이터 마이닝, 이미지 인식 (ATOL, bag of visual words)

### 4.5 발견 및 측정 (12편)

| 핵심 발견 | 출처 |
|-----------|------|
| 다크 네트워크는 광범위하게 상호 연결: 39개 HS에서 **20,499개** 추가 발견 | Betzwieser et al. (2009) |
| 6개월 관찰에서 **~80,000개** HS 발견, **15%만** 6개월간 지속 | Savage & Owen (2016) |
| 다크웹은 생각보다 훨씬 작음 — 대부분의 HS는 **일시적(ephemeral)** | Owenson et al. (2018) |
| 수집 과정에서 전체 공식 HS의 **25%~35%**만 도달 가능 | Bernaschi et al. (2019) |
| 173,667개 .onion 주소 중 실제 온라인은 **4,857개**만 | Li et al. (2016) |

### 4.6 성능 (4편)

- Hidden Service 연결 수립 평균 시간: **24초** (broadband) — Loesing et al. (2008)
- 시간 대부분이 **Introduction Point/Rendezvous Point 연결 수립**에 소요
- 저대역폭 환경: relay descriptor 다운로드와 회로 구축이 병목 — Lenhard et al. (2009)
- HS는 Client→RP + HS→RP로 **6개 OR**을 거침 (일반 회로의 2배)

### 4.7 설계 변경 제안 (6편)

| 제안 | 효과 |
|------|------|
| 관여 노드 수 감소 | 연결 수립 시간 단축 |
| 다중 exit 노드 사용 | 트래픽 분석 저항 유지 |
| Hidden Service DNS (HSDNS) | 보안 통신, anti-scanning, anti-registration 공격, 인증 검증 |
| .onion 주소를 사람이 읽을 수 있는 DNS로 변경 | 사용성 향상 (단, 추적 가능성 증가 우려) |

### 4.8 인적 요인 (3편)

- **Botnet C&C**: HS를 이용한 봇넷 아키텍처 — 높은 은닉성, 단 높은 지연 — Anagnostopoulos et al. (2017)
- **불법 활동 탐지**: 법적 관점에서 불법 활동 분류/탐지 방법 — He et al. (2019)
- **사용성**: 많은 사용자가 surface web과의 차이를 인식하지 못함, HS 발견 방법 제한적, 사용성 문제 — Winter et al. (2018)

---

## 5. 공격 분류 (Attack Taxonomy)

```
THS 공격
├── De-anonymization (서버/클라이언트 IP 노출)
│   ├── Entry Node 제어 기반
│   │   ├── 직접 트래픽 패턴 삽입 (Overlier & Syverson 2006)
│   │   ├── 웹 기반 트래픽 생성 (Zhang et al. 2011)
│   │   ├── 트래픽 상관 공격 (Elices 2013, Ling 2013, Wang 2016)
│   │   ├── 워터마킹 (Iacovazzi et al. 2018)
│   │   └── 클라이언트 측 식별 (Ma & Xu 2017)
│   ├── 핑거프린팅 기반
│   │   ├── 요청 패턴 핑거프린트 (Elices 2012, Kwon 2015)
│   │   ├── 사이트 크기 기반 추적 (Overdorf et al. 2017)
│   │   └── 현실 환경에서는 낮은 인식률 (Panchenko et al. 2017)
│   ├── 사이드 채널
│   │   ├── Clock skew (CPU 온도 변화) (Murdoch 2006, Zander 2008)
│   │   └── 정보 유출 (URL, 인증서, 이메일) (Matic et al. 2015)
│   └── MITM (개인키 탈취) (Sanatinia & Noubir 2017)
│
└── Denial of Service (서비스 차단)
    ├── HSDir 제어 (Biryukov et al. 2013)
    └── Eclipse 공격 (Tan et al. 2017, 2019)
```

**핵심 전제**: 거의 모든 de-anonymization 공격은 **악의적 Guard/Entry 노드 제어**를 필수 조건으로 함.

---

## 6. 방어 분류 (Defense Taxonomy)

```
THS 방어
├── 네트워크 계층
│   ├── Valet Services / Guard 노드 (entry point 은닉)
│   ├── Ring 라우팅 + 더미 패킷 (Ferris Wheel)
│   └── 다중 경로 라우팅 (흐름 혼합/병합)
│
├── 디렉토리 계층
│   └── Honey Onions (악의적 HSDir 탐지)
│
├── 프로토콜 계층
│   ├── HS 회로 격리 (botnet 남용 방지)
│   ├── HSDNS (안전한 도메인 이름 시스템)
│   └── MITM descriptor 비교 탐지
│
├── 포렌식
│   └── 지속적 핑거프린트 삽입 (증거 수집용)
│
└── v3 프로토콜 개선 (2017 DEF CON 25)
    ├── 향상된 암호화
    ├── 고급 클라이언트 인증
    ├── 56자 .onion 주소 (16자 → 56자, 악의적 발견 방지)
    ├── 디렉토리 프로토콜 누출 감소
    └── 오프라인 키 지원
```

---

## 7. 프로젝트 연관성

이 SLR은 프로젝트의 **M7 Hidden Service v3** 구현 계획에 직접적으로 관련된다.

### 7.1 논문 개념 → 프로젝트 매핑

| 논문 개념 | 프로젝트 구현/계획 |
|----------|------------------|
| **6-hop 회로 구조** (Client→RP 3-hop + HS→RP 3-hop) | M7에서 `internal/circuit/manager.go`에 HS 회로 생성 추가 예정 (`LATER.md` 참조) |
| **Introduction Point / Rendezvous Point** | M7에서 `internal/directory/service.go`에 IP/RP 선택 로직 추가 예정 |
| **Entry node 기반 de-anonymization** | 현재 M5에서 BGP hijack/interception으로 모델링. M7에서 HS 회로에 확장 |
| **Guard 노드 선택의 핵심성** | `internal/guard/selector.go` — 현재 3-hop용, M7에서 HS별 Guard 추가 |
| **Valet Services → Vanguards** | `LATER.md`의 Vanguards 결정 — L2/L3 Vanguard 계층 구현 여부 대기 중 |
| **HSDir 기반 공격 (Eclipse)** | 시뮬레이션 범위 외 (AS-level 관찰에 집중) |
| **콘텐츠 분류/발견** | 시뮬레이션 범위 외 (네트워크 레벨 분석) |
| **성능 — 24초 연결 수립** | 시뮬레이터는 성능이 아닌 AS 관찰 확률 측정에 집중 |

### 7.2 M7 설계 결정에 대한 시사점

`LATER.md`의 4개 배경 문서(`BG_M7_*.md`) 결정에 이 SLR이 제공하는 인사이트:

| 결정 항목 | SLR 시사점 |
|----------|-----------|
| **구현 범위** (`BG_M7_scope.md`) | SLR에서 HS 프로토콜의 핵심 취약점은 **entry node 선택**에 집중 → AS-level 시뮬레이션에서는 전체 rendezvous 프로토콜보다 **회로의 AS 경로 관찰 가능성**이 핵심 |
| **시뮬레이션 관점** (`BG_M7_perspective.md`) | 공격은 서버 측(HS IP 노출)과 클라이언트 측 모두 존재 → 양쪽 모델링이 이상적 |
| **방어 적용** (`BG_M7_defense.md`) | SLR에서 Valet Services/Guard 보호가 핵심 방어 → **Vanguards**는 이 논문이 다루는 Guard 보호의 현대적 구현 |
| **Python 분석** (`BG_M7_python.md`) | HS 회로는 6-hop이므로 관찰 조건이 4가지(client-side entry/exit, HS-side entry/exit)로 확장 → 상관율 분석 로직 변경 필요 |

### 7.3 SLR이 다루지 않는 것 (프로젝트 gap)

- **AS-level 경로 분석**: SLR의 공격은 대부분 릴레이 수준 — AS-level 글로벌 관찰자 모델은 프로젝트 고유 기여
- **BGP 공격과 HS의 교차**: BGP hijack/interception이 HS 회로에 미치는 영향은 SLR에서 다루지 않음 → 프로젝트 M7의 핵심 연구 질문
- **동적 토폴로지 변동**: CAIDA 스냅샷 기반 시간적 변동은 SLR 논문들에서 고려하지 않음
- **방어 비교 (Counter-RAPTOR vs Astoria vs Vanguards)**: SLR은 각 방어를 개별적으로 다루나, 프로젝트는 정량적 비교 수행

---

## 8. 한계 및 후속 연구

### 논문의 한계

- 검색 기간이 **2019년 7월까지**로, v3 onion service 관련 연구가 **전무** (v3는 2017년 발표되었으나 연구 반영 지연)
- 데이터베이스 3개에서 **57편만** 선정 — THS의 빠른 발전 속도에 비해 적은 수
- **시뮬레이션 환경 vs 실제 환경**: 대부분의 공격 연구가 시뮬레이션에서만 검증, 실제 Tor 네트워크에서의 성공률 불명
- Panchenko et al. (2017)은 현실 환경에서 **낮은 인식률**을 보고 → 시뮬레이션 결과의 일반화 가능성 의문
- 연구 결과 간 **불일치**: HS 발견 수(20,499 vs ~80,000), 불법 콘텐츠 비율(38%~45%) 등 상이
- HS 발견 방법 간 **비교 연구 부재** — 공식 Tor 메트릭 대비 25%~35%만 도달
- SLR 자체 방법론 한계: 영어 논문만 포함, 기술 보고서/도서 챕터 배제

### 미래 연구 과제 (논문 제안)

1. **v3 Onion Service 보안 분석**: 기존 취약점 제거 여부, 신규 취약점 존재 여부
2. **.onion 주소 발견/수집 메커니즘 개선**: 현재 25%~35%만 발견 가능
3. **성능 향상**: 연결 수립 24초 → 릴레이 수 감소, 회로 최적화
4. **다크웹 생태계의 정확한 규모 측정**: HS의 일시성(ephemeral nature)을 고려한 측정
5. **자동화 콘텐츠 분류 개선**: 수동 분류의 한계 극복 (이미지 인식, NLP)
6. **공격 성공/실패 진화 평가**: Tor 프로젝트의 취약점 수정 후 기존 공격의 유효성 재평가
7. **전체 설계 재검토**: 성능, 보안, 익명성을 종합적으로 고려한 글로벌 설계 개선

---

## 9. 참고 수치 요약

```
SLR 규모:
  - 검색 결과: Google Scholar 1,770 / Web of Science 105 / Scopus 339
  - 최종 선정: 57편 (2006~2019)
  - 연구 영역: 6개 (보안 28, 콘텐츠 분류 17, 발견/측정 12, 설계 변경 6, 성능 4, 인적 요인 3)

보안 (공격 vs 방어):
  - 공격 논문: 20편 / 방어 논문: 9편
  - 최다 인용 논문: Biryukov et al. (2013) 363회, Overlier & Syverson (2006) 270회, Murdoch (2006) 169회
  - 핵심 전제: 모든 de-anonymization에 최소 1개 악의적 Guard 노드 필요

HS 콘텐츠:
  - 불법/비윤리적 콘텐츠: 38%~45% (연구별 상이)
  - 영어 콘텐츠: ~73.28%
  - Surface web 리소스 임포트: >20%
  - HS 상호 연결률: ~90%

HS 규모 및 생존:
  - Tor 공식 기록: >150,000 HS
  - 실제 발견 가능: 25%~35%
  - 6개월 생존율: ~15% (Savage & Owen 2016)
  - Li et al. (2016): 173,667 주소 중 온라인 4,857개 (~2.8%)

성능:
  - HS 연결 수립: 평균 24초 (broadband)
  - 회로 구조: 6 OR (일반 3 OR의 2배)
  - 병목: Introduction Point / Rendezvous Point 연결

프로토콜 버전:
  - v2: .onion 주소 16자, 2004년 도입, 2021년 지원 종료 예정
  - v3: .onion 주소 56자, 2017년 DEF CON 25에서 발표, 향상된 암호화/인증

연구 트렌드:
  - 2015년 이후 연구 관심 급증
  - 2017년 최대 논문 수
  - v3 관련 연구: 0편 (2019년 기준)
```
