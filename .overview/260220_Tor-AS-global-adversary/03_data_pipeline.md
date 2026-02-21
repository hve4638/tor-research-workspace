# 03. 데이터 파이프라인

## 개요

시뮬레이터(`next-simulate`)가 동작하려면 현실적인 AS 토폴로지 데이터가 필요하다. `tor-anal/pipeline/`은 4개의 외부 데이터 소스에서 원시 데이터를 수집하고, 10단계 처리를 거쳐 시뮬레이션 입력 JSON을 생성한다.

---

## 외부 데이터 소스

| 소스 | 데이터 | 용도 | 갱신 주기 |
|------|--------|------|----------|
| **Onionoo** (Tor Project API) | 현재 활성 Tor 릴레이 목록 (IP, 대역폭, 플래그) | Step 01: 릴레이 수집 | 실시간 |
| **RouteViews RIB** | BGP Routing Information Base (IP prefix → ASN 매핑) | Step 02: IP→ASN 변환 | 2시간 |
| **CAIDA AS-relationships** | AS 간 관계 (peer, provider-customer) | Step 07: AS 토폴로지 edge | 월별 |
| **RIR delegated** (RIPE, ARIN 등) | ASN → 국가 코드 매핑 | Step 08: 지리 정보 | 일별 |

---

## 10단계 파이프라인

```
[Onionoo API]        [RouteViews RIB]       [CAIDA edges]      [RIR delegated]
     │                     │                      │                   │
     ▼                     ▼                      │                   │
  Step 01              Step 02                    │                   │
 릴레이 수집          IP → ASN 매핑               │                   │
     │                     │                      │                   │
     ▼                     ▼                      │                   │
  Step 03              Step 04                    │                   │
 AS 집합 분류        AS 역할 분석                  │                   │
 (guard/exit)        (transit/stub)               │                   │
     │                     │                      │                   │
     └──────┬──────────────┘                      │                   │
            ▼                                     │                   │
         Step 05                                  │                   │
        관찰 확률 계산                              │                   │
       (p_entry/p_exit)                           │                   │
            │                                     │                   │
            ▼                                     │                   │
         Step 06                                  │                   │
        AS 모델 생성                               │                   │
    (as_model_simplified.json)                    │                   │
            │                                     │                   │
            ▼                                     ▼                   │
         Step 07 ◀──────────────────────── CAIDA 데이터               │
        edge 추가                                                     │
     (model_edges.json)                                               │
            │                                                         │
            ▼                                                         ▼
         Step 08 ◀─────────────────────────────────────────── RIR 데이터
        지리 매핑
     (as_geo_map.json)
            │
            ▼
         Step 09
       국가별 통계
            │
            ▼
         Step 10
       지도 시각화
```

### 단계별 상세

| Step | 기능 | 입력 | 출력 |
|------|------|------|------|
| 01 | Onionoo API에서 활성 릴레이 수집 | Onionoo REST API | `relays_raw_*.json` |
| 02 | 각 릴레이의 IP를 ASN으로 매핑 | 릴레이 IP + RouteViews RIB | `relay_as_map.csv` |
| 03 | AS를 Guard/Exit/Guard+Exit 집합으로 분류 | relay_as_map + 릴레이 플래그 | `as_sets.json` |
| 04 | 각 AS의 역할(transit/stub) 및 대역폭 집계 | as_sets + 릴레이 대역폭 | `as_roles.json` |
| 05 | AS별 entry/exit 관찰 확률 계산 | as_roles + 대역폭 가중치 | `as_path_probabilities.json` |
| 06 | 시뮬레이션용 AS 모델 생성 (가중치 포함) | as_roles + as_sets | `as_model_simplified.json` |
| 07 | CAIDA AS 관계 데이터에서 edge 추가 | CAIDA *.as-rel2.txt | `model_edges.json` |
| 08 | ASN → 국가 코드 매핑 | RIR delegated files | `as_geo_map.json` |
| 09 | 국가별 AS 분포 통계 생성 | as_geo_map + as_model | `country_as_distribution.json` |
| 10 | HTML 지도 시각화 생성 | 모든 산출물 | `as_map_visualization.html` |

---

## 핵심 산출물

### `as_model_simplified.json` — AS 노드 모델

시뮬레이터의 핵심 입력. 727개 Tor 관련 AS의 가중치 정보를 담는다.

- **727개 AS 노드**: Tor 릴레이를 호스팅하는 모든 AS
- **120개 significant AS**: 전체 대역폭의 대부분을 차지하는 주요 AS
- **가중치 분포**: Guard 가중치, Exit 가중치, Middle 가중치 — 대역폭 기반 확률적 선택에 사용

### `model_edges.json` — AS 간 연결

AS 토폴로지의 edge 정보. CAIDA AS-relationships 데이터에서 추출한다.

- **6,325개 edge**: 727개 AS 간의 모든 연결
- **관계 유형**: peer (5,203개), provider-customer (1,122개)
- **용도**: valley-free BFS 경로 계산의 기반

### `as_path_probabilities.json` — 관찰 확률

각 AS가 entry/exit 경로에서 관찰될 확률의 상한값.

| 필드 | 의미 |
|------|------|
| `p_entry` | Client → Guard 경로에서 해당 AS가 transit으로 나타날 확률 |
| `p_exit` | Middle → Exit 경로에서 해당 AS가 transit으로 나타날 확률 |
| `p_both` | entry와 exit 모두에서 관찰될 확률 (상관 위험도) |

- **Counter-RAPTOR 방어에 직접 사용**: `1/p_entry`가 Guard 선택 resilience 점수가 됨
- p_entry가 높은 AS = 많은 entry 경로가 지나감 = 관찰 위험 높음 → Guard로 선택 확률을 낮춰야 함

### `as_geo_map.json` — 지리 매핑

727개 ASN을 69개국에 매핑. 국가 수준 적대자 모델(StateLevel)에서 특정 국가의 모든 AS를 제어하는 시나리오에 사용한다.

---

## CAIDA 스냅샷

동적 토폴로지(M4)를 위해 CAIDA의 월별 AS 관계 데이터를 13개 스냅샷으로 관리한다:

- **기간**: 2025년 1월 ~ 2026년 1월 (13개월)
- **용도**: 30일마다 AS 토폴로지를 전환하여 자연적 BGP churn을 시뮬레이션
- **edge 변동**: 연간 약 48% edge 변동 (Tempest 2018 참조)
- **관리 도구**: `pipeline.snapshot_cli`로 비교·처리

```bash
# 스냅샷 비교 예시
uv run python -m pipeline.snapshot_cli compare 20251201 20260101
# → added_edges: 142, removed_edges: 87, changed: 3.6%
```

---

## 실행 방법

모든 Python 작업은 `uv` 사용 필수 (`pip` 금지):

```bash
cd tor-anal

# 외부 데이터 다운로드 (최초 1회)
uv run python -m pipeline.download --all

# 전체 파이프라인 실행
uv run python -m pipeline --all

# 특정 단계만 실행
uv run python -m pipeline --step 7 --snapshot 20260101

# 산출물 검증
uv run python -m pipeline --validate
```
