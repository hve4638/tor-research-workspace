# 02. AS 수집/전처리 파이프라인 추적

> 7,000개 Tor 릴레이가 727개 AS 노드로 축소되는 과정

---

## 전체 흐름

```
[Onionoo API]           [RouteViews RIB]           [CAIDA AS-rel]
  ~7,000 릴레이            IP→ASN 매핑 DB            ~700,000 AS 관계
     │                        │                          │
     ▼                        ▼                          │
  Step 01 ──────────────► Step 02                        │
  릴레이 수집              IP → ASN 변환                  │
  ~7,000 relays            ~6,500 매핑 성공               │
                           727 고유 ASN                   │
     │                        │                          │
     ▼                        ▼                          │
  Step 03~04              Step 05                        │
  역할 분류                경로 확률 계산                  │
  guard/exit/middle        p_entry, p_exit               │
                              │                          │
                              ▼                          │
                           Step 06                       │
                           AS 모델 생성                   │
                           727 노드, 0 edges              │
                              │                          │
                              ▼                          ▼
                           Step 07 ◄──── CAIDA 필터링
                           edges 추가
                           727 AS 간 6,191 edges만 추출
                              │
                              ▼
                       [시뮬레이션 입력]
                       727 노드, 6,191 edges
```

---

## Step별 상세

### Step 01: Tor 릴레이 수집

- **소스**: Onionoo Details API (`https://onionoo.torproject.org/details`)
- **출력**: `relays_raw_{timestamp}.json`
- **내용**: ~7,000개 릴레이의 IP, bandwidth, flags, country 등
- **손실 없음**: 전체 릴레이 데이터 보존

**코드**: `tor-anal/pipeline/steps/step_01_fetch_relays.py`

### Step 02: IP → ASN 매핑 (첫 번째 축소)

- **소스**: RouteViews RIB → pyasn 변환 (`ipasn_YYYYMMDD.dat`)
- **방법**: 각 릴레이의 IPv4 주소를 `pyasn.lookup(ip)` → (ASN, prefix)
- **출력**: `relay_as_map.csv`

**축소 과정**:
```
~7,000 릴레이 IP
  → IPv6 제외, 매핑 실패 제외
  → ~6,500 매핑 성공
  → 고유 ASN 집계: 727개
```

**핵심**: 여러 릴레이가 같은 AS에 속함 (예: Hetzner AS24940에 ~500개 릴레이)

**코드**: `step_02_ip_to_asn.py:91-166` — `map_relays_to_asn()` 함수

### Step 03~05: 역할/가중치/확률 (노드 수 변화 없음)

727 AS 내에서의 분석만 수행:
- Step 03: AS별 guard/exit/middle 릴레이 수 집계
- Step 04: AS별 대역폭 가중치 계산 (guard_weight, exit_weight)
- Step 05: AS별 관찰 확률 계산 (p_entry, p_exit, combined)

### Step 06: AS 모델 생성 (두 번째 병목)

- **입력**: `as_roles.json` (727 AS의 역할/가중치)
- **출력**: `as_model_simplified.json` (727 노드, edges 비어있음)

**병목 코드** (`step_06_build_model.py:53`):
```python
for asn, stats in as_roles.items():   # as_roles에는 727 Tor AS만 존재
    node = {
        "asn": asn,
        "guard_weight": stats.get("guard_weight", 0),
        "exit_weight": stats.get("exit_weight", 0),
        ...
    }
    nodes.append(node)
```

`as_roles`는 Step 03~04에서 Tor 릴레이를 호스팅하는 AS만 모았으므로, transit-only AS는 여기에 포함되지 않는다.

### Step 07: CAIDA edges 추가 (세 번째 병목 — 가장 치명적)

- **입력**: CAIDA `YYYYMMDD.as-rel2.txt` (~700,000 관계)
- **필터**: Step 06의 727 AS 집합 (`model_asns`)
- **출력**: `model_edges.json` (6,191 edges)

**병목 코드** (`step_07_add_edges.py:92`):
```python
if as1 in model_asns and as2 in model_asns:  # 양쪽 다 727개 안에 있어야
    edges.append(...)
```

**필터링 결과**:
```
CAIDA 전체:   ~700,000 관계 (peer + provider-customer)
필터 후:      6,191 관계 (0.88%)
손실:         ~693,000 관계 (99.1%)
```

---

## 왜 727개인가?

**7,000개 릴레이 → 727개 AS**로 축소되는 이유:

1. **AS 집중도가 높다**: 소수 호스팅 업체가 다수 릴레이를 운영
   - Hetzner (AS24940): ~500개 릴레이
   - OVH (AS16276): ~300개 릴레이
   - 상위 20개 AS가 전체 릴레이의 ~60% 차지

2. **전체 인터넷 AS 대비 극소수**: 전 세계 AS 수는 ~75,000개
   - Tor 릴레이를 운영하는 AS는 그중 ~1%
   - 대부분의 AS는 ISP, 기업, 대학 등 일반 네트워크

---

## 논문과의 결정적 차이

| 항목 | 우리 파이프라인 | RAPTOR/UGR |
|------|---------------|-----------|
| 그래프의 노드 | Tor 릴레이 AS만 (727) | **전체 인터넷 AS** (~48,000) |
| 그래프의 edges | 727 AS 간 관계만 (6,191) | **전체 AS 관계** (~140,000) |
| Tor AS의 역할 | 노드이자 경로 종단 | 경로 종단 (그래프의 일부) |
| Transit AS | **존재하지 않음** | 경로 중간에 다수 존재 |
| 경로 계산 | 727 노드 BFS (2-4홉) | 48K 노드 위 경로 (5-8홉) |

**비유**: 우리는 "공항만 있는 지도"를 만들었다. 논문은 "전체 도로망 위에 공항을 표시"했다.
공항 간 직항만 있으면 경유지가 없고, 경유지가 없으면 중간 관찰자가 없다.

---

## 데이터 가용성

이 문제는 **데이터 부족이 아니라 전처리 선택**의 문제다:

| 데이터 | 이미 보유 | 현재 사용 |
|--------|----------|----------|
| CAIDA 전체 AS 관계 (~70만) | O | 0.88%만 사용 |
| RouteViews RIB (AS_PATH 포함) | O | IP→ASN만 사용, AS_PATH 버림 |
| Tor 릴레이 가중치 | O | 전부 사용 |

CAIDA 파일에는 이미 ~48,000개 AS 간의 관계가 들어있다. 우리가 Step 07에서 99%를 버린 것이다.
