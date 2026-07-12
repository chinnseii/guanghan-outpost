# Active Tasks

This file is the current coordination board for active task ownership, file locks, blockers, and short handoff state.

## Board Status

- **Status**: `IDLE`
- **Active tasks**: `0`
- **Locked files**: `0`
- **Pending handoffs**: `0`
- **Branch**: `main`
- **Board baseline**: `592b602`
- **Last updated**: `2026-07-12`

## Active Tasks

No active tasks.

## File Locks

No file locks.

## Pending Handoffs

No pending handoffs.

## Recently Closed

### P4-07A - Audit training large scripts and UI extraction candidates

- Status: `DONE`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `592b602`
- Result: read-only audit + characterization of `training_module_scene.gd` (3417) and `training_base_map.gd` (2255) → `docs/governance/P4_07A_TRAINING_LARGE_SCRIPT_AUDIT.md`. **No production code moved.** Both build UI dynamically (`add_child`, no `$` hardcoded paths, no tween) → presenter extraction needs no `.tscn` change; UI is flow-wired (buttons→checkpoint/step); no P0/P1 (training progress canonical in `training_progress.json`, not a scene double-hold). **Unique conclusion: A — EXTRACT_TRAINING_MODULE_UI** (`TrainingModuleScreenPresenter`, ~300-400 line reduction, CHARACTERIZE_FIRST); after P4-07B, close Phase 4 (remaining training bulk is scene-tree/flow-coupled).
- Verification: Godot editor/smoke EXIT 0 (no training/base-scene boot); P4-07A 30/30 (source-analysis); P4-06B 41/41; P4-06A 28/28; P4-05 30/30; P4-04 35/35; P4-03 27/27; P4-02 22/22; P3-03a 40/40; P3-03b 50/50; P3-03c 34/34; P3-03d 25/25; P3-04 33/33; P3-05 37/37; real `user://saves/` SHA-256 unchanged.
- Follow-up: P4-07B `TrainingModuleScreenPresenter` extraction — do not start automatically.

### P4-06B - Extract Sprint06ScheduleEvaluator

- Status: `DONE`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `f5c55fc`
- Result: pure schedule/daily-check predicates + schedule text extracted from `sprint06_base_scene.gd` into stateless `scripts/controllers/sprint06_schedule_evaluator.gd` (66 lines, `class_name`/RefCounted, zero member state) — 8 pure fns over `(day, state)` that never mutate the passed Dictionary. Scene keeps thin delegators (call sites unchanged) + ALL mutation/async/finish/transition/save/input-locks (untouched). Strings byte-equivalent + Dictionary immutability unit-tested. `sprint06_base_scene.gd` 2307 → 2268 (net −39). No scene/`project.godot`/schema change.
- Verification: Godot editor/smoke EXIT 0 (no base-scene boot); P4-06B 41/41; P4-06A 28/28 (migrated); P4-05 30/30; P4-04 35/35; P4-03 27/27; P4-02 22/22; P3-03a 40/40; P3-03b 50/50; P3-03c 34/34; P3-03d 25/25; P3-04 33/33; P3-05 37/37; real `user://saves/` SHA-256 unchanged; no residue.
- Follow-up: audit training_module_scene / training_base_map UI split, or Phase 4 close-out — do not start automatically.

### P4-06A - Audit sprint06 schedule and mission-flow coupling

- Status: `DONE`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `bda3d13`
- Result: read-only audit + characterization of sprint06 schedule/daily-check/mission-phase/transition/async/save coupling → `docs/governance/P4_06A_SPRINT06_FLOW_AUDIT.md`. **No production flow logic moved.** Findings: sprint06 mission progress is scene-local `state` (Full Save scene_state), not TaskManager — no double-holding, no P0/P1; completion/finish sequences are async + time-advance + save + scene-change (KEEP); pure daily predicates + checklist text are safely separable. **Unique conclusion: A — SAFE_EVALUATOR_EXTRACTION** (P4-06B should extract a stateless `Sprint06ScheduleEvaluator`, ~70 lines, no touch to async/finish/transition/save).
- Verification: Godot editor/smoke EXIT 0 (no base-scene boot); P4-06A 26/26 (source-analysis); P4-05 30/30; P4-04 35/35; P4-03 27/27; P4-02 22/22; P3-03a 40/40; P3-03b 50/50; P3-03c 34/34; P3-03d 25/25; P3-04 33/33; P3-05 37/37; real `user://saves/` SHA-256 unchanged.
- Follow-up: P4-06B `Sprint06ScheduleEvaluator` extraction — do not start automatically.

### P4-05 - Extract base navigation controller

- Status: `DONE`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `a3aca62`
- Result: safely-separable navigation **computation** extracted from `sprint06_base_scene.gd` into stateless `scripts/controllers/base_navigation_controller.gd` (49 lines, `class_name`/RefCounted, non-Autoload) — `terrain_type_for`, `is_near`, `compute_current_target`. Scene keeps thin delegators, `current_target` (~40 flow consumers), `_transition_to` (12 flow callers), `_interaction_target_rect` (day/schedule logic), the movement main loop, and Full Save. Behavior unchanged (characterized). `sprint06_base_scene.gd` 2331 → 2308 (net −24). P4-05A interface-prep scope: sprint06 nav is largely flow-coupled, so the safe movable amount is small by design (per §9/§12, not a failure). No scene/`project.godot`/schema change.
- Verification: Godot editor/smoke EXIT 0 (no base-scene boot); P4-05 30/30; P4-04 35/35; P4-03 27/27; P4-02 22/22; P3-03a 40/40; P3-03b 50/50; P3-03c 34/34; P3-03d 25/25; P3-04 33/33; P3-05 37/37; real `user://saves/` SHA-256 unchanged.
- Follow-up: P4-06 sprint06 daily/mission flow controller (audit coupling first) — do not start automatically.

### P4-04 - Extract BaseHudPanelPresenter from sprint06_base_scene.gd

- Status: `DONE`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `549b464`
- Result: HUD/status-panel UI construction + 8 panel toggles + panel refresh extracted from `sprint06_base_scene.gd` into `scripts/controllers/base_hud_panel_presenter.gd` (263 lines, RefCounted, non-Autoload). Scene re-exposes the flow-updated label nodes to its own vars (all HUD/flow update sites unchanged); plant-diagnosis modal (gameplay buttons), save/load, Full Save, navigation, day/task flow stay in the scene. Greenhouse gate injected into the plant toggle. `sprint06_base_scene.gd` 2556 → 2331 (net −225). No scene/`project.godot`/schema change. (Original P4-04 sandbox slot-save aggregation deferred: legacy/dev, 20+ shared fields, low value.)
- Verification: Godot editor/smoke EXIT 0; base scene boots clean; P4-04 35/35; P4-03 27/27; P4-02 22/22; P3-03a 40/40; P3-03b 50/50; P3-03c 34/34; P3-03d 25/25; P3-04 33/33; P3-05 37/37; real `user://saves/` SHA-256 restored to baseline.
- Follow-up: P4-05 sprint06 navigation / daily-flow controller — do not start automatically.



