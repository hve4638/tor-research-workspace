# 03. 원본 논문 데이터 구성 비교

> RAPTOR와 UGR이 사용한 데이터 소스 및 구성 방법과 우리 구현의 차이

---

## 1. RAPTOR (Sun et al., 2015)

### 토폴로지 데이터

| 항목 | RAPTOR | 우리 |
|------|--------|------|
| AS 그래프 소스 | CAIDA AS-relationships | CAIDA AS-relationships (동일) |
| 노드 수 | ~48,000 AS (전체) | 727 AS (Tor 릴레이만) |
| 관계 유형 | peer, provider-customer, sibling | peer, provider-customer |
| 그래프 용도 | 경로 계산의 기반 | 경로 계산의 기반 (동일 목적) |

### 라우팅 데이터

| 항목 | RAPTOR | 우리 |
|------|--------|------|
| 순방향 경로 | **iPlane traceroute** (매일 갱신) | BFS 최단 경로 |
| 역방향 경로 | **별도 계산** (비대칭 모델) | BFS (대칭과 동일) |
| BGP 정책 | LOCAL_PREF, valley-free 적용 | 없음 (BFS만) |
| 동적 변화 | **BGP Updates** (15분 간격) | CAIDA 스냅샷 (30일 간격) |

### 경로 계산 방법

**RAPTOR의 3단계 경로 모델**:
1. **정적 기반**: CAIDA 전체 AS 그래프에서 valley-free 경로 계산
2. **실측 보정**: iPlane traceroute로 실제 경로 관측 → 정적 모델 보정
3. **비대칭 처리**: forward/reverse를 독립적으로 계산 (A→B ≠ B→A)

**우리의 경로 모델**:
1. 727 AS 그래프에서 BFS 최단 경로 계산
2. forward = reverse (대칭 가정)
3. 비대칭 모드에서도 경로가 짧아 실질적 차이 없음

---

## 2. Users Get Routed (Johnson et al., 2013)

### 토폴로지 데이터

| 항목 | UGR | 우리 |
|------|-----|------|
| AS 그래프 소스 | CAIDA + RouteViews RIB | CAIDA (RIB은 IP→ASN만) |
| 노드 수 | ~39,000 AS | 727 AS |
| 경로 계산 | **BGP RIB의 AS_PATH** | BFS |
| 동적 변화 | Tor consensus 매 시간 | CAIDA 스냅샷 30일 간격 |

### 경로 계산 방법

**UGR의 경로 모델**:
1. RouteViews RIB 덤프에서 **AS_PATH 직접 추출** (실제 BGP 결정 결과)
2. 각 (source, destination) 쌍에 대해 실제 관측된 AS 경로 사용
3. 경로가 없으면 CAIDA 그래프에서 시뮬레이션

**우리의 경로 모델**:
1. 727 AS 그래프에서 BFS
2. AS_PATH 데이터는 pyasn 변환 시 **버려짐**

---

## 3. 정적 vs 동적 구성 비교

### RAPTOR

```
정적 (고정):
  - CAIDA AS 토폴로지 (~48,000 AS)
  - AS 간 관계 유형 (peer/customer)

동적 (변화):
  - iPlane traceroute → 매일 새 경로 반영
  - BGP Updates → 15분마다 경로 변경 감지
  - Tor consensus → 매 시간 릴레이 목록 갱신

핵심: 토폴로지 위에서 "경로"가 시간에 따라 바뀜
```

### Users Get Routed

```
정적 (고정):
  - CAIDA + RouteViews → AS 그래프 (~39,000 AS)
  - BGP RIB → AS_PATH (경로도 고정)

동적 (변화):
  - Tor consensus → 매 시간 릴레이 목록 갱신
  - Guard 교체 → 수명(30-60일) 만료 시 새 guard 선택

핵심: 네트워크는 고정, Tor 레이어가 시간에 따라 바뀜
```

### 우리

```
정적 (고정):
  - CAIDA → 727 AS 그래프
  - BFS 경로 (그래프 변경 시에만 재계산)

동적 (변화):
  - CAIDA 스냅샷 → 30일 간격 그래프 전환 (노드/edge churn)
  - Tor consensus → CAIDA 주기에 맞춰 릴레이 목록 갱신
  - Guard 교체 → 수명 만료 시 새 guard 선택
  - BGP 공격 → 설정된 시점에 경로 변경

핵심: 토폴로지가 30일 주기로 이산적 변화, 경로는 BFS 고정
```

---

## 4. 데이터 소스별 상세

### RouteViews RIB

- **갱신 주기**: 2시간마다 전체 RIB 덤프
- **내용**: BGP 라우팅 테이블 (prefix → AS_PATH)
- **파일 크기**: ~2GB (bz2 압축)
- **우리의 사용**: `pyasn`으로 변환하여 IP → ASN 매핑만 추출
- **버려지는 것**: **AS_PATH** (실제 BGP 경로 결정 결과)
  - 이 AS_PATH가 UGR 논문의 핵심 데이터

### RouteViews BGP Updates

- **갱신 주기**: 15분마다
- **내용**: BGP 경로 변경 알림 (withdraw, announce)
- **우리의 사용**: 사용하지 않음
- **논문 사용**: RAPTOR R2(시간적 변동)에서 경로 변화 감지

### CAIDA AS-relationships

- **갱신 주기**: 월 1회
- **내용**: ~700,000 AS 관계 (peer, provider-customer)
- **파일 형식**: `AS1|AS2|relationship`
- **우리의 사용**: 727 AS 간 6,191 관계만 필터링 (0.88%)
- **논문 사용**: 전체 관계를 그래프로 구축 (~48,000 AS)

### RIPE RIS (대안 소스)

- **갱신 주기**: RIB 1-8시간, Updates 5분
- **내용**: RouteViews와 유사 (유럽 중심)
- **우리의 사용**: 미사용
- **논문 사용**: RAPTOR가 보조 검증에 활용

---

## 5. 결과에 미치는 영향

### 정확하게 재현된 부분 (토폴로지 무관)

이 실험들은 **릴레이 선택 메커니즘**에 의존하며, 727 AS의 guard/exit 가중치만 정확하면 된다:

- Guard 교체에 의한 침해 (day 57-60 계단 함수)
- Exit-only 관찰 (90.5% — 대역폭 비율과 일치)
- Astoria 방어 효과 (-99.97%)
- Tier-1 관찰 순위 (R3)

### 재현 실패한 부분 (토폴로지 의존)

이 실험들은 **transit 경로**에 의존하며, 전체 인터넷 토폴로지가 필요하다:

- 비대칭 라우팅 (R1): 경로가 2-4홉이면 forward/reverse가 같은 AS를 경유
- BGP Interception (R4): Tier-1이 이미 모든 짧은 경로에 존재하여 공격의 한계 효과 없음
- 절대 상관율 수치: 논문 12-21% vs 우리 2-3% (transit AS 부족으로 관찰 기회 적음)
