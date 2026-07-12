# Current Project Status

Updated: 2026-07-12

## Phase

Phase 3 system-boundary cleanup is COMPLETE (pushed + tag `system-boundary-cleanup-complete-2026-07-12`). Phase 4 — Large-script decomposition — is IN PROGRESS through P4-07B.

Completed in Phase 4:
- P4-01 large-script responsibility & decomposition audit (`PHASE_4_LARGE_SCRIPT_AUDIT.md`).
- P4-02 DevToolsController extraction from `main.gd` (5182 -> 4346).
- P4-03 FormalFlowRouter extraction from `main.gd` (4346 -> 4302).
- P4-04 BaseHudPanelPresenter extraction from `sprint06_base_scene.gd` (2556 -> 2331).
- P4-05 BaseNavigationController extraction from `sprint06_base_scene.gd` (2331 -> 2308).
- P4-06A sprint06 schedule/mission-flow coupling audit + characterization.
- P4-06B Sprint06ScheduleEvaluator extraction from `sprint06_base_scene.gd` (2307 -> 2268).
- P4-07A training large-script UI audit + characterization.
- P4-07B TrainingModuleScreenPresenter extraction from `training_module_scene.gd` (3417 -> 3114; net -303).

## P4-07B Summary

Goal: extract display-only training-module screen construction from `training_module_scene.gd` without moving training state, checkpoint ownership, room layout, input locks, or flow-coupled step completion.

Implemented:
- Added non-Autoload `TrainingModuleScreenPresenter` (`scripts/controllers/training_module_screen_presenter.gd`) as a RefCounted display helper.
- Moved dynamic screen chrome, left mission panel labels, footer buttons, minimal HUD, briefing/pause/interaction panels, popup shell ownership, suit-status panel display, entry-blocked briefing UI, overlay visibility, HUD label assignment, and interaction progress display into the presenter.
- `training_module_scene.gd` now creates the presenter, injects UI-intent callbacks, re-exposes only the small set of nodes still needed by scene flow (`hint_label`, `diagnosis_panel`, popup reference, `training_area`, and `prompt_label`).
- Training state remains in the scene: `module_id`, `module_data`, `step_index`, `completed`, `mission_panel_visible`, `briefing_visible`, `pause_visible`, `interaction_running`, `target_nodes`, movement/input handling, `_build_training_area`, `_complete_step`, `_finish_module`, and checkpoint writes.
- Added `tests/p4_07b_training_module_screen_presenter_test.gd` and updated P4-07A characterization to reflect the new presenter boundary.

Instruction adjustment:
- The original generated instruction suggested broad UI extraction. In code, diagnosis/plant/repair option dialogs contain correct-answer checks and call `_complete_step()`, so those gameplay decisions stayed in `training_module_scene.gd`. The presenter owns only the popup container API (`open_popup`, `add_popup_action_control`, body text, close), not training answers or step advancement.
- `training_base_map.gd` remains untouched. Base-map UI extraction is still deferred because its room switching and door navigation are more scene-tree coupled.

Shared/core files touched:
- `scripts/training/training_module_scene.gd` (core training scene; UI delegation only).

New files:
- `scripts/controllers/training_module_screen_presenter.gd`
- `scripts/controllers/training_module_screen_presenter.gd.uid`
- `tests/p4_07b_training_module_screen_presenter_test.gd`
- `tests/p4_07b_training_module_screen_presenter_test.gd.uid`

Tests/docs touched:
- `tests/p4_07a_training_large_script_audit_test.gd`
- `docs/handoff/ACTIVE_TASKS.md`
- `docs/handoff/CURRENT.md`
- `docs/governance/P4_07A_TRAINING_LARGE_SCRIPT_AUDIT.md`
- `docs/governance/PHASE_4_LARGE_SCRIPT_AUDIT.md`
- `docs/governance/CLEANUP_PLAN.md`

## Verification Status

P4-07B passed:
- Godot editor parse EXIT 0.
- Godot headless smoke EXIT 0.
- P4-07B focused test: 20/20.
- P4-07A characterization: 32/32.
- P4-06B: 41/41.
- P4-06A: 28/28.
- P4-05: 30/30.
- P4-04: 35/35.
- P4-03: 27/27.
- P4-02: 22/22.
- P3-03a: 40/40.
- P3-03b: 50/50.
- P3-03c: 34/34.
- P3-03d: 25/25.
- P3-04: 33/33.
- P3-05: 37/37.

Note: initial sandboxed Godot runs crashed before script execution because `user://logs` was not writable. The same commands passed with normal Godot user-data permissions.

## Known Issues / Risks

- `training_module_scene.gd` is still P1-sized at 3114 lines, but the remaining bulk is mostly room layout, target visuals, movement/input locks, step flow, and checkpoint-coupled logic. Further extraction should be justified by a fresh audit, not by line count alone.
- `training_base_map.gd` remains P1-sized and untouched; its UI/navigation coupling was intentionally deferred.
- Diagnosis/repair choice dialogs remain flow-coupled in the scene by design.
- Full Save schema, Training Checkpoint schema, scenes, `project.godot`, gameplay values, and `training_base_map.gd` were not changed.

## Next Step

Recommended next step: Phase 4 close-out / regression closure. Do not start P4-08 automatically. If further training decomposition is requested later, start with a new audit because the safe display-only module-scene extraction is now complete.
