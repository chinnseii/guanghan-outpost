# Active Tasks

This file is the current coordination board for active task ownership, file locks, blockers, and short handoff state.

## Board Status

- **Status**: `IDLE`
- **Active tasks**: `0`
- **Locked files**: `0`
- **Pending handoffs**: `0`
- **Branch**: `main`
- **Board baseline**: `a3aca62`
- **Last updated**: `2026-07-12`

## Active Tasks

No active tasks.

## File Locks

No file locks.

## Pending Handoffs

No pending handoffs.

## Recently Closed

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

### P4-03 - Extract FormalFlowRouter from main.gd

- Status: `DONE`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `4f2baf7`
- Result: formal new-game/continue/route-selection extracted from `main.gd` into `scripts/controllers/formal_flow_router.gd` (133 lines, `class_name`/RefCounted, non-Autoload). Continue priority preserved exactly (Full Save → Training Checkpoint → legacy sandbox slot → notice); read-only predicates use `read_progress()`, router never calls `load_progress()`. Injected callbacks (no state duplication), 0 wrappers (5 call sites rewired). `main.gd` 4346 → 4302. DevToolsController unaffected. No scene/`project.godot`/schema change.
- Verification: Godot editor/smoke EXIT 0; P4-03 27/27; P4-02 22/22; P3-03a 40/40; P3-03b 50/50; P3-03c 34/34; P3-03d 25/25; P3-04 33/33; P3-05 37/37; real `user://saves/` SHA-256 unchanged. Migrated the "routing in main.gd" assertions in p3_05/p4_02/p3_03c/p3_03a to the router (per §11; extends §14's file list).
- Follow-up: P4-04 sandbox slot-save aggregation — do not start automatically.

### P4-02 - Extract DevToolsController from main.gd

- Status: `DONE`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `27c5fbe`
- Result: dev-only menu + all `_debug_*` actions extracted from `main.gd` into `scripts/controllers/dev_tools_controller.gd` (876 lines, non-Autoload, held by main). `main.gd` **5182 → 4346 (−836 / ~16%)**. Shared `_debug_reset_time` kept in main (formal new-game uses it); thin `_toggle_dev_menu` wrapper retained. Formal continue/new-game/Full Save/training/sandbox/arrival flows unchanged and do not depend on the controller. No scene/`project.godot`/save/gameplay change.
- Verification: Godot editor/smoke EXIT 0; P4-02 22/22; P3-03a 39/39; P3-03b 50/50; P3-03c 33/33; P3-03d 25/25; P3-04 33/33; P3-05 36/36; real `user://saves/` SHA-256 unchanged.
- Follow-up: P4-03 FormalFlowRouter — do not start automatically.

### P4-01 - Large-script responsibility and decomposition audit

- Status: `DONE`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `1f53659`
- Result: oversized-script responsibilities, dependencies, shared-state hotspots, extraction candidates, and the Phase 4 decomposition sequence audited (`PHASE_4_LARGE_SCRIPT_AUDIT.md`). Sizes: P0 `main.gd` 5182; P1 `training_module_scene.gd` 3417 / `sprint06_base_scene.gd` 2556 / `training_base_map.gd` 2255. **Sole P4-02 recommendation: extract `DevToolsController` from `main.gd`** (dev-only, ~840 lines, zero formal-gameplay/save/restore impact).
- Verification: documentation-only (Markdown); Godot editor/smoke EXIT 0; scripts/tests/scenes untouched.
- Follow-up: P4-02 (DevToolsController) — do not start automatically.

