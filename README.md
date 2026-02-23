# tor-research-workspace

Tor 네트워크에 대한 **AS-level 글로벌 관찰자 시뮬레이션** 연구 워크스페이스.

BGP 공격과 라우팅 변동이 Tor 익명성을 얼마나 침해하는지 분석한다.

## 프로젝트 구조

```
tor-research-workspace/
├── next-simulate/        # Go — AS-level 이벤트 드리븐 시뮬레이터
├── tor-anal/             # Python — 데이터 파이프라인 + 분석 (tor-research-pipeline)
├── scripts/              # 시뮬레이션 실행 스크립트
├── .experiments/         # 재현 실험 문서 + 결과
│   ├── raptor/           #   RAPTOR (Sun et al., 2015)
│   └── users_get_routed/ #   Users Get Routed (Johnson et al., 2013)
├── .report/              # 분석 보고서
├── .paper/               # 논문 PDF + 요약
├── .overview/            # 발표 자료
├── .archive/             # 아카이브 (구 코드 + 레퍼런스)
├── CLAUDE.md             # Claude Code 프로젝트 지침
├── LATER.md              # M7 Hidden Service 재개 가이드
└── NEXT_v3.md            # 마일스톤 계획 + 연구 질문
```

### 하위 저장소

| 디렉토리 | GitHub | 설명 |
|----------|--------|------|
| `next-simulate/` | `hve4638/next-simulate` | 3-hop 회로 생성, BGP 공격, 방어 전략, 비대칭 경로 |
| `tor-anal/` | `hve4638/tor-research-pipeline` | Tor 릴레이 수집 → AS 모델 생성 (10단계 파이프라인) + 분석 |

## 최초 세팅

### 1. 워크스페이스 클론

```bash
git clone https://github.com/hve4638/tor-research-workspace.git
cd tor-research-workspace
```

### 2. 하위 저장소 가져오기

```bash
git clone https://github.com/hve4638/next-simulate.git
git clone https://github.com/hve4638/tor-research-pipeline.git tor-anal
```

### 3. Python 환경 (tor-anal)

[uv](https://docs.astral.sh/uv/) 필수. `pip` 사용 금지.

```bash
# uv 설치 (없는 경우)
curl -LsSf https://astral.sh/uv/install.sh | sh

# 의존성 설치
cd tor-anal
uv sync

# 외부 데이터 다운로드 (RouteViews RIB, CAIDA, RIR)
uv run python -m pipeline.download --all
```

### 4. Go 환경 (next-simulate)

Go 1.21 이상 필요.

```bash
cd next-simulate
go build ./...
```

## 실행

### 데이터 파이프라인

```bash
cd tor-anal

# 전체 파이프라인 (Step 01~10): Tor 릴레이 → AS 모델 JSON
uv run python -m pipeline --all

# 특정 단계만
uv run python -m pipeline --step 6 7
```

### 시뮬레이션

```bash
cd next-simulate

# 4개 시나리오
go run ./cmd/next-simulate -config configs/bgp_attack.yaml             # Vanilla
go run ./cmd/next-simulate -config configs/counter_raptor_defense.yaml  # Counter-RAPTOR
go run ./cmd/next-simulate -config configs/astoria_defense.yaml         # Astoria
go run ./cmd/next-simulate -config configs/combined_defense.yaml        # Combined
```

### 분석

```bash
cd tor-anal

uv run python -m analysis.run_analysis \
  --vanilla-obs ../next-simulate/output/observations_bgp.ndjson \
  --vanilla-gt ../next-simulate/output/ground_truth_bgp.ndjson \
  --cr-obs ../next-simulate/output/observations_cr.ndjson \
  --cr-gt ../next-simulate/output/ground_truth_cr.ndjson \
  --astoria-obs ../next-simulate/output/observations_astoria.ndjson \
  --astoria-gt ../next-simulate/output/ground_truth_astoria.ndjson \
  --combined-obs ../next-simulate/output/observations_combined.ndjson \
  --combined-gt ../next-simulate/output/ground_truth_combined.ndjson
```

## 요구사항

| 도구 | 버전 | 용도 |
|------|------|------|
| Go | >= 1.21 | 시뮬레이터 빌드/실행 |
| Python | >= 3.12 | 데이터 파이프라인 + 분석 |
| uv | latest | Python 패키지 관리 |

## 참고 논문

| 논문 | 저자 | 연도 | 재현 상태 |
|------|------|------|----------|
| RAPTOR: Routing Attacks on Privacy in Tor | Sun et al. | 2015 | 4건 중 2건 정성적 재현 |
| Users Get Routed: Traffic Correlation on Tor by Realistic Adversaries | Johnson et al. | 2013 | 7건 중 5건 정량적 재현 |
| Measuring and Mitigating AS-level Adversaries Against Tor | Nithyanand et al. | 2016 | Astoria 방어 검증 완료 |
