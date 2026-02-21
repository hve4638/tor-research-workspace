# Draft: Docs Inventory (project-tor)

## Goal

- Inventory existing documentation (Markdown) across this workspace and organize it into a navigable map.

## Repo-Wide Observations

- Docs are primarily Markdown and live next to each subproject rather than a single top-level `docs/`.
- There appear to be 3 major doc “clusters”:
  - `onion-simulate/` (Go simulator)
  - `ref-tor/` (Python pipeline + reverse-engineering notes)
  - `onion-simulate-visualize/` (log visualizer)
- Root-level planning/notes exist (`NEXT*.md`, `FEEDBACK.md`, meeting notes).
- Missing repo-level “standard” files: `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md` (at repo root), `.github/` docs.
- Potential duplication / drift risk:
  - `ref-tor/CLAUDE.old.md`, `ref-tor/AGENTS.old.md` (old variants)
  - Step docs exist both in `ref-tor/docs/` and `ref-tor/memo/` (same topic, different locations).

## Primary Entry Points (start here)

- `onion-simulate/README.md` — build/run/test + architecture overview + links into `onion-simulate/docs/*`.
- `ref-tor/pipeline/README.md` — pipeline CLI usage, step summaries, inputs/outputs, data locations.
- `ref-tor/docs/presentation/README.md` — presentation deck-style index; provides a recommended reading order.
- `onion-simulate-visualize/README.md` — how to run frontend/backend for visualization.

## Documentation Map

### Root-level planning / notes

- `NEXT.md`, `NEXT_v3.md`, `NEXT_DETAIL.md` — research goals + next simulator rewrite notes.
- `FEEDBACK.md` — feedback checklist for `NEXT.md`-style docs.
- `meeting-251226.md` — meeting summary.
- `ai-advice-260105.md` — project status + guidance.
- `COMMENT_GUIDE.md` — comment-writing guidelines.

### `onion-simulate/` (Go simulator)

- Entry
  - `onion-simulate/README.md`
  - `onion-simulate/AGENTS.md` (agent instructions; contains build/run/test + key file map)
  - `onion-simulate/PLAN.md` (runbook-like plan)
  - `onion-simulate/PPT.md` (presentation/material)
  - `onion-simulate/CLAUDE.md` (tooling notes)
- Core docs
  - `onion-simulate/docs/ONBOARDING.md`
  - `onion-simulate/docs/FEATURES.md`
  - `onion-simulate/docs/ONION_SERVICE.md`
  - `onion-simulate/docs/GUIDE.md`
  - `onion-simulate/docs/GUIDE_ROUTINE.md`
  - `onion-simulate/docs/SERVER.md`
  - `onion-simulate/docs/HISTORY.md`
  - `onion-simulate/docs/report-data-handler-module.md`
- Dev reports (historical)
  - `onion-simulate/report/251120/REPORT.md`
  - `onion-simulate/report/251126/*` (WORK_*, PLAN_*, REPORT_* series)
  - `onion-simulate/archive/PLAN.md`, `onion-simulate/archive/REPORT.md`
  - `onion-simulate/COMMENT_RESULTS.md` (commenting/results notes)

### `ref-tor/` (AS analysis pipeline + reverse engineering)

- Entry
  - `ref-tor/pipeline/README.md`
  - `ref-tor/CLAUDE.md` (commands + architecture summary)
  - `ref-tor/PROGRESS.md`, `ref-tor/memo/PROGRESS_STATUS.md` (progress)
- Pipeline docs
  - `ref-tor/pipeline/docs/data-sources.md`
  - `ref-tor/pipeline/docs/snapshots.md`
  - `ref-tor/pipeline/SNAPSHOT_GUIDE.md`
- Step-by-step technical docs
  - `ref-tor/docs/step_flow.md`
  - `ref-tor/docs/execution_plan.md`
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
- Analysis reports
  - `ref-tor/docs/tor_network_analysis_report.md`
  - `ref-tor/docs/snapshot_report_202501_202601.md`
  - `ref-tor/docs/fetch_tor_nodes.md`
- Presentation bundle
  - `ref-tor/docs/presentation/README.md`
  - `ref-tor/docs/presentation/01_overview.md`
  - `ref-tor/docs/presentation/02_pipeline.md`
  - `ref-tor/docs/presentation/03_outputs.md`
  - `ref-tor/docs/presentation/04_snapshots.md`
  - `ref-tor/docs/presentation/05_statistics.md`
- Reverse engineering corpus
  - `ref-tor/REVERSE_ENGINEER.md`
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
- Memo (potential duplicates of step docs)
  - `ref-tor/memo/MEMO.md`
  - `ref-tor/memo/step_01_ip_to_asn_mapping.md` .. `ref-tor/memo/step_10_map_visualization.md`
- Legacy/old
  - `ref-tor/CLAUDE.old.md`
  - `ref-tor/AGENTS.old.md`

### `onion-simulate-visualize/` (log visualizer)

- Entry
  - `onion-simulate-visualize/README.md`
  - `onion-simulate-visualize/CLAUDE.md`
  - `onion-simulate-visualize/PLAN.md`, `onion-simulate-visualize/PLAN_251225.md`
  - `onion-simulate-visualize/LOG_FORMAT.md`
  - `onion-simulate-visualize/SUMMARY_251223.md`, `onion-simulate-visualize/SUMMARY_251224.md`
- Additional docs
  - `onion-simulate-visualize/docs/SOURCE_PROBABILITY.md`

## Suggested Reading Paths

### If your goal is “run the simulator + understand its logs”

1. `onion-simulate/README.md`
2. `onion-simulate/docs/FEATURES.md`
3. `onion-simulate/docs/GUIDE.md`
4. `onion-simulate/docs/GUIDE_ROUTINE.md`
5. `onion-simulate/docs/ONION_SERVICE.md` (if HS topics matter)

### If your goal is “run the AS analysis pipeline”

1. `ref-tor/pipeline/README.md`
2. `ref-tor/docs/step_flow.md`
3. `ref-tor/pipeline/docs/data-sources.md`
4. `ref-tor/pipeline/docs/snapshots.md`
5. `ref-tor/docs/execution_plan.md`

### If your goal is “reverse engineer Tor behaviors for next simulator”

1. `ref-tor/REVERSE_ENGINEER.md`
2. `ref-tor/reverse-engineer/00_final_report.md`
3. `ref-tor/reverse-engineer/18_hs_final_report.md`

### If your goal is “visualize NDJSON logs”

1. `onion-simulate-visualize/README.md`
2. `onion-simulate-visualize/LOG_FORMAT.md`
3. `onion-simulate-visualize/PLAN.md`

## Gaps / Risks

- No single “docs home” at repo root, so discoverability is split by subproject.
- No clear “canonical vs memo” rule for `ref-tor/docs/*` vs `ref-tor/memo/*`.
- No repo-level contribution/security/changelog docs, which makes onboarding and governance harder.

## Full Inventory (paths only)

Note: this is a path list for quick grep/navigation.

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

## Open Questions

- Is the goal only to inventory + recommended reading order, or also to create a unified docs index (and possibly a docs site via MkDocs/Docusaurus)?
