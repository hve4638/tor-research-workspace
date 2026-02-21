# 프로젝트 문서 인벤토리

## 목적

이 문서는 `project-tor` 워크스페이스의 Markdown 문서를 빠르게 찾고 탐색하기 위한 인덱스입니다.

## 전체 구조 요약

- 문서는 단일 루트 `docs/`가 아니라, 하위 프로젝트별로 분산되어 있습니다.
- 핵심 문서 군은 3개입니다.
  - `onion-simulate/` (Go 시뮬레이터)
  - `ref-tor/` (Python 파이프라인 + Tor 역공학 문서)
  - `onion-simulate-visualize/` (로그 시각화)
- 루트에는 연구/기획 메모(`NEXT*.md`, `FEEDBACK.md`, 회의 노트)가 있습니다.

## 우선 읽기 진입점

1. `onion-simulate/README.md`
2. `ref-tor/pipeline/README.md`
3. `ref-tor/docs/presentation/README.md`
4. `onion-simulate-visualize/README.md`

## 주의 포인트

- `ref-tor/docs/*`와 `ref-tor/memo/*`에 Step 주제 문서가 중복되어 있어 최신/정본 판단 기준이 필요합니다.
- 구형 문서가 남아 있습니다.
  - `ref-tor/CLAUDE.old.md`
  - `ref-tor/AGENTS.old.md`
- 루트 기준 표준 문서(`CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`)는 현재 보이지 않습니다.

---

## 전체 경로 목록 (Markdown)

### Root

- `NEXT.md`
- `NEXT_DETAIL.md`
- `NEXT_v3.md`
- `FEEDBACK.md`
- `COMMENT_GUIDE.md`
- `ai-advice-260105.md`
- `meeting-251226.md`

### onion-simulate

- `onion-simulate/AGENTS.md`
- `onion-simulate/CLAUDE.md`
- `onion-simulate/COMMENT_RESULTS.md`
- `onion-simulate/PLAN.md`
- `onion-simulate/PPT.md`
- `onion-simulate/README.md`
- `onion-simulate/archive/PLAN.md`
- `onion-simulate/archive/REPORT.md`
- `onion-simulate/docs/FEATURES.md`
- `onion-simulate/docs/GUIDE.md`
- `onion-simulate/docs/GUIDE_ROUTINE.md`
- `onion-simulate/docs/HISTORY.md`
- `onion-simulate/docs/ONBOARDING.md`
- `onion-simulate/docs/ONION_SERVICE.md`
- `onion-simulate/docs/SERVER.md`
- `onion-simulate/docs/report-data-handler-module.md`
- `onion-simulate/report/251120/REPORT.md`
- `onion-simulate/report/251126/PLAN_metadata_output.md`
- `onion-simulate/report/251126/PLAN_output_file_formatting.md`
- `onion-simulate/report/251126/REPORT_debug_only_removal.md`
- `onion-simulate/report/251126/REPORT_fixed_interval_routine.md`
- `onion-simulate/report/251126/REPORT_logdebug_fix.md`
- `onion-simulate/report/251126/REPORT_output_file_formatting.md`
- `onion-simulate/report/251126/WORK_1.md`
- `onion-simulate/report/251126/WORK_2.md`

### ref-tor

- `ref-tor/AGENTS.old.md`
- `ref-tor/CLAUDE.md`
- `ref-tor/CLAUDE.old.md`
- `ref-tor/PROGRESS.md`
- `ref-tor/REVERSE_ENGINEER.md`
- `ref-tor/docs/execution_plan.md`
- `ref-tor/docs/fetch_tor_nodes.md`
- `ref-tor/docs/presentation/01_overview.md`
- `ref-tor/docs/presentation/02_pipeline.md`
- `ref-tor/docs/presentation/03_outputs.md`
- `ref-tor/docs/presentation/04_snapshots.md`
- `ref-tor/docs/presentation/05_statistics.md`
- `ref-tor/docs/presentation/README.md`
- `ref-tor/docs/snapshot_report_202501_202601.md`
- `ref-tor/docs/step_01_ip_to_asn_mapping.md`
- `ref-tor/docs/step_02_as_sets.md`
- `ref-tor/docs/step_03_as_roles.md`
- `ref-tor/docs/step_04_as_model.md`
- `ref-tor/docs/step_05_probabilities.md`
- `ref-tor/docs/step_06_simulation_input.md`
- `ref-tor/docs/step_07_as_relationships.md`
- `ref-tor/docs/step_08_as_geo_map.md`
- `ref-tor/docs/step_09_country_as_distribution.md`
- `ref-tor/docs/step_10_map_visualization.md`
- `ref-tor/docs/step_flow.md`
- `ref-tor/docs/tor_network_analysis_report.md`
- `ref-tor/memo/MEMO.md`
- `ref-tor/memo/PROGRESS_STATUS.md`
- `ref-tor/memo/step_01_ip_to_asn_mapping.md`
- `ref-tor/memo/step_02_as_sets.md`
- `ref-tor/memo/step_03_as_roles.md`
- `ref-tor/memo/step_04_as_model.md`
- `ref-tor/memo/step_05_probabilities.md`
- `ref-tor/memo/step_06_simulation_input.md`
- `ref-tor/memo/step_07_as_relationships.md`
- `ref-tor/memo/step_08_as_geo_map.md`
- `ref-tor/memo/step_09_country_as_distribution.md`
- `ref-tor/memo/step_10_map_visualization.md`
- `ref-tor/pipeline/README.md`
- `ref-tor/pipeline/SNAPSHOT_GUIDE.md`
- `ref-tor/pipeline/docs/data-sources.md`
- `ref-tor/pipeline/docs/snapshots.md`
- `ref-tor/reverse-engineer/00_final_report.md`
- `ref-tor/reverse-engineer/01_client_bootstrap.md`
- `ref-tor/reverse-engineer/02_node_selection.md`
- `ref-tor/reverse-engineer/03_circuit_creation.md`
- `ref-tor/reverse-engineer/04_circuit_failure.md`
- `ref-tor/reverse-engineer/05_guard_management.md`
- `ref-tor/reverse-engineer/06_rotation_timing.md`
- `ref-tor/reverse-engineer/07_crypto_key_exchange.md`
- `ref-tor/reverse-engineer/08_timing_probability.md`
- `ref-tor/reverse-engineer/10_hs_architecture.md`
- `ref-tor/reverse-engineer/11_hs_service_lifecycle.md`
- `ref-tor/reverse-engineer/12_hs_intro_point.md`
- `ref-tor/reverse-engineer/13_hs_descriptor.md`
- `ref-tor/reverse-engineer/14_hs_client_flow.md`
- `ref-tor/reverse-engineer/15_hs_introduction.md`
- `ref-tor/reverse-engineer/16_hs_rendezvous.md`
- `ref-tor/reverse-engineer/17_hs_security.md`
- `ref-tor/reverse-engineer/18_hs_final_report.md`
- `ref-tor/reverse-engineer/19_build_artifacts.md`

### onion-simulate-visualize

- `onion-simulate-visualize/README.md`
- `onion-simulate-visualize/CLAUDE.md`
- `onion-simulate-visualize/PLAN.md`
- `onion-simulate-visualize/PLAN_251225.md`
- `onion-simulate-visualize/LOG_FORMAT.md`
- `onion-simulate-visualize/SUMMARY_251223.md`
- `onion-simulate-visualize/SUMMARY_251224.md`
- `onion-simulate-visualize/docs/SOURCE_PROBABILITY.md`

---

## 빠른 읽기 경로

### 1) 시뮬레이터 실행/구조 파악

1. `onion-simulate/README.md`
2. `onion-simulate/docs/FEATURES.md`
3. `onion-simulate/docs/GUIDE.md`
4. `onion-simulate/docs/GUIDE_ROUTINE.md`

### 2) AS 분석 파이프라인 파악

1. `ref-tor/pipeline/README.md`
2. `ref-tor/docs/step_flow.md`
3. `ref-tor/pipeline/docs/data-sources.md`
4. `ref-tor/pipeline/docs/snapshots.md`
5. `ref-tor/docs/execution_plan.md`

### 3) Tor 역공학 결과 파악

1. `ref-tor/REVERSE_ENGINEER.md`
2. `ref-tor/reverse-engineer/00_final_report.md`
3. `ref-tor/reverse-engineer/18_hs_final_report.md`

### 4) 시각화 도구 파악

1. `onion-simulate-visualize/README.md`
2. `onion-simulate-visualize/LOG_FORMAT.md`
3. `onion-simulate-visualize/PLAN.md`
