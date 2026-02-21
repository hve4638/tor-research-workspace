# LATER.md — M7 계획 재개 가이드

> 이 파일은 M7 Hidden Service v3 계획 수립 중 작업을 중단한 시점의 전체 컨텍스트를 담고 있다.
> 이전 대화 내용이 전혀 없어도 이 파일만으로 작업을 재개할 수 있어야 한다.

---

## 1. 프로젝트 개요

Tor 네트워크에 대한 **AS-level 글로벌 관찰자 시뮬레이션**. BGP 공격과 라우팅 변동이 Tor 익명성을 얼마나 침해하는지 분석한다.

```
project-tor/
├── onion-simulate/   # 구 시뮬레이터 (Go, goroutine 기반) — 더 이상 활발히 개발하지 않음
├── tor-anal/         # Python 데이터 파이프라인 (10단계) + M6 분석 코드
│   ├── pipeline/     # Step 01~10: Tor 릴레이 → AS 모델 JSON
│   ├── analysis/     # M6: NDJSON 파싱, 상관율 계산, 방어 비교, 시각화
│   └── CLAUDE.md     # Python 환경(uv) 및 실행 방법
└── next-simulate/    # AS-level 이벤트 드리븐 시뮬레이터 (Go) ← 핵심 코드베이스
    ├── internal/     # 패키지별 구현
    ├── cmd/          # main.go
    ├── configs/      # YAML 설정 파일들
    └── .docs/        # 마일스톤 보고서 + 배경 문서
```

### 마일스톤 진행 상태

| 마일스톤 | 상태 | 요약 |
|----------|------|------|
| M1 | **완료** | 아키텍처, 타입, 엔진, AS 그래프 |
| M2 | **완료** | 디렉토리 서비스, Guard 선택 |
| M3 | **완료** | 3-hop 회로 생성 + AS-path 관찰 |
| M4 | **완료** | 시간적 그래프 변동 (CAIDA 스냅샷 기반) |
| M5 | **완료** | BGP 공격 시뮬레이션 (hijack/interception) |
| M6 | **완료** | 방어 전략 (Counter-RAPTOR, Astoria) + Python 분석 |
| M7 | **계획 중** | Hidden Service v3 ← **현재 여기** |

---

## 2. 현재 상태: M7 계획 — 유저 결정 대기

### 무엇을 했나

M7 계획을 세우기 위해 4개의 **배경 지식 문서**를 작성했다. 각 문서는 하나의 설계 결정에 대한 배경을 설명하고, 마지막에 결정 질문을 포함한다.

### 반드시 읽어야 할 파일 (순서대로)

| 파일 | 내용 | 결정 질문 |
|------|------|----------|
| `next-simulate/.docs/BG_M7_scope.md` | HS v3 프로토콜 개요, AS-level 관찰 표면, 구현 깊이 | Full protocol / Core only / Minimal PoC |
| `next-simulate/.docs/BG_M7_perspective.md` | 시뮬레이션 관점: 누구를 모델링할 것인가 | 양쪽 모두 (Client+HS) / Service-side only |
| `next-simulate/.docs/BG_M7_defense.md` | M6 방어를 HS 회로에도 적용할 것인가 | 적용 / 미적용 |
| `next-simulate/.docs/BG_M7_python.md` | Python 분석 파이프라인 HS 확장 여부 | 확장 / Go만 |

### 유저에게 물어야 할 것

**4개 배경 문서를 이미 작성하여 유저에게 전달한 상태**이다. 유저가 "모두 읽기 전까지 대기하라"고 했고, 아직 결정을 전달받지 못했다. 또한 대화 중 **Vanguards** (prop-292, Tor의 실제 HS 방어 메커니즘)에 대한 추가 논의가 있었다.

**유저에게 확인할 사항:**

1. **4개 배경 문서를 모두 읽었는가?** 각 문서 끝의 결정 질문에 대한 답변 요청
2. **Vanguards 포함 여부**: BG_M7_defense.md의 결정에 추가로, L2/L3 Vanguard 계층을 구현할지 여부
   - Vanguards는 HS Guard 보호를 위한 Tor 실제 방어 (prop-292)
   - Counter-RAPTOR/Astoria와 직교하는 메커니즘 (릴레이 수명 관리)
   - 포함 시 ~200줄 추가
3. 결정을 모두 받으면 → **M7 구현 계획을 확정** (M6 plan처럼 Phase별 상세 계획)

### 유저에게 설명할 Vanguards 맥락

대화 중 유저가 "Vanguard 같은 기능 구현은 고려되어 있나?"라고 물었고, 다음과 같이 답변했다:

- 현재 계획에 **미포함**. BG_M7_defense.md에서 언급만 함
- Vanguards = HS 회로에서 L2/L3 고정 릴레이로 Guard discovery 방지
- Counter-RAPTOR(선택 가중치) / Astoria(경로 검사) / Vanguards(수명 관리)는 각각 독립적
- 방어 결정 시 Vanguards 포함 여부도 함께 답해달라고 요청한 상태

---

## 3. 당장 다음 작업

```
1. 유저에게: "4개 배경 문서를 모두 읽으셨나요? 각 결정 + Vanguards 포함 여부를 알려주세요"
2. 유저 결정 수신
3. plan mode 진입 → M7 구현 계획 작성 (M6 plan과 동일 형식: Phase별 파일/줄수/검증)
4. 유저 승인 → 구현 시작
```

---

## 4. 참조해야 할 핵심 파일

### 아키텍처 이해

| 파일 | 왜 읽어야 하는가 |
|------|-----------------|
| `next-simulate/.docs/NEXT_v4.md` | 전체 마일스톤 계획 (M1~M7) |
| `next-simulate/.docs/M6_report.md` | M6 구현 보고서 — M7이 확장할 코드의 최신 상태 |
| `next-simulate/.docs/M5_report.md` | M5 구현 보고서 — BGP 공격 구현 패턴 참조 |

### Go 코드 — M7이 수정/확장할 패키지

| 파일 | 역할 |
|------|------|
| `next-simulate/internal/circuit/manager.go` | 회로 생성 — HS 회로 추가 필요 |
| `next-simulate/internal/directory/service.go` | AS 선택 — IntroPoint/RendPoint 선택 추가 |
| `next-simulate/internal/guard/selector.go` | Guard 선택 — HS별 Guard + Vanguard 계층 |
| `next-simulate/internal/observer/logger.go` | NDJSON 출력 — HS 회로 관찰 필드 추가 |
| `next-simulate/internal/config/config.go` | YAML 설정 — HS 관련 설정 추가 |
| `next-simulate/internal/engine/events.go` | 이벤트 — HS 회로 이벤트 추가 |
| `next-simulate/internal/defense/resilience.go` | 방어 — HS에 CR 적용 시 재사용 |
| `next-simulate/cmd/next-simulate/main.go` | 진입점 — M7 블록 추가 |

### Python 코드 — HS 분석 확장 시

| 파일 | 역할 |
|------|------|
| `tor-anal/analysis/parse_observations.py` | NDJSON 파싱 — HS 필드 추가 |
| `tor-anal/analysis/correlation_analysis.py` | 상관율 — 6-hop 4종 상관 조건 |
| `tor-anal/analysis/visualize.py` | 시각화 — HS 전용 차트 |
| `tor-anal/analysis/run_analysis.py` | CLI — --hs-* 인자 추가 |

### 데이터 파일

| 파일 | 역할 |
|------|------|
| `tor-anal/output/as_model_simplified.json` | 727 AS 노드 + guard/exit 가중치 |
| `tor-anal/data/model_edges.json` | 6325 AS 간 연결 (peer/provider-customer) |
| `tor-anal/output/as_path_probabilities.json` | AS별 p_entry/p_exit — CR 방어에 사용 |
| `tor-anal/output/as_geo_map.json` | 727 ASN → 국가 코드 |

### 설정 파일 (기존 — M7 참조용)

| 파일 | 내용 |
|------|------|
| `next-simulate/configs/bgp_attack.yaml` | M5 vanilla BGP 공격 설정 |
| `next-simulate/configs/counter_raptor_defense.yaml` | M6 Counter-RAPTOR 설정 |
| `next-simulate/configs/astoria_defense.yaml` | M6 Astoria 설정 |
| `next-simulate/configs/combined_defense.yaml` | M6 CR+Astoria 복합 설정 |

---

## 5. 환경 및 빌드

### Go (next-simulate)
```bash
cd next-simulate
go build ./...    # 빌드
go test ./...     # 전체 테스트 (현재 모두 통과)
go run ./cmd/next-simulate -config configs/bgp_attack.yaml  # 실행
```

### Python (tor-anal)
```bash
cd tor-anal
uv run python -m analysis.run_analysis --help  # 분석 CLI
# pip 사용 금지 — 모든 Python 작업은 uv 경유
# 의존성 추가: uv add <package>
# 실행: uv run python -m <module>
```

---

## 6. 유저 선호/지시사항

- **언어**: 문서와 대화는 **한국어**, 코드와 주석은 영어
- **Python 환경**: `uv` 사용 필수, `pip` 금지
- **보고서 스타일**: `.docs/M5_report.md`, `.docs/M6_report.md` 형식 참조
- **계획 스타일**: Phase별 상세 계획 (파일, 줄수, 검증 기준) — 기존 M6 plan 참조
- **배경 문서**: 유저가 결정을 내리기 전에 배경 지식 문서를 먼저 요청하는 패턴
- **커밋**: 유저가 명시적으로 요청할 때만 수행

---

## 7. 기존 M6 구현 계획 (참조)

M7 계획도 동일한 형식으로 작성해야 한다. 기존 M6 plan은 conversation summary에 포함되어 있었으나, 핵심 구조:

```
Phase 0: 사전 준비 (리네임 등)
Phase 1: 핵심 타입 + 로더 (독립 모듈)
Phase 2: 기존 패키지 수정 (config, directory, circuit)
Phase 3: 이벤트 + 로거 수정
Phase 4: main.go + YAML 설정
Phase 5: Go 테스트
Phase 6: Python 분석
→ 각 Phase에 파일별 줄수 + 함수 시그니처 + 검증 기준
```

M7도 이 패턴을 따른다. 유저 결정에 따라 Phase 수와 내용이 달라진다.
