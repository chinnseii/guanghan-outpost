# Active Tasks

This file is the current coordination board for active task ownership, file locks, blockers, and short handoff state.

## Board Status

- **Status**: `IDLE`
- **Active tasks**: `0`
- **Locked files**: `0`
- **Pending handoffs**: `0`
- **Branch**: `main`
- **Board baseline**: `1f53659`
- **Last updated**: `2026-07-12`

## Active Tasks

No active tasks.

## File Locks

No file locks.

## Pending Handoffs

No pending handoffs.

## Recently Closed

### P4-01 - Large-script responsibility and decomposition audit

- Status: `DONE`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `1f53659`
- Result: oversized-script responsibilities, dependencies, shared-state hotspots, extraction candidates, and the Phase 4 decomposition sequence audited (`PHASE_4_LARGE_SCRIPT_AUDIT.md`). Sizes: P0 `main.gd` 5182; P1 `training_module_scene.gd` 3417 / `sprint06_base_scene.gd` 2556 / `training_base_map.gd` 2255. **Sole P4-02 recommendation: extract `DevToolsController` from `main.gd`** (dev-only, ~840 lines, zero formal-gameplay/save/restore impact).
- Verification: documentation-only (Markdown); Godot editor/smoke EXIT 0; scripts/tests/scenes untouched.
- Follow-up: P4-02 (DevToolsController) — do not start automatically.

### P3-06 - Phase 3 regression and closure

- Status: `DONE`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `d1b0802`
- Result: Phase 3 fully regressed, documented, and CLOSED; Phase 4 baseline established (`PHASE_3_CLOSURE_REPORT.md`). One minimal regression fix — a residual legacy node-name collision in `arrival_cinematic_scene.gd` (missed by P3-05) renamed to `ArrivalCinematic…`; repo-wide `name = "TimeManager"/"GameStateManager"` now 0; P3-05 test extended to cover it.
- Verification: P3-03a 39/39; P3-03b 50/50; P3-03c 33/33; P3-03d 25/25; P3-04 33/33; P3-05 36/36 (216 total); Godot editor/smoke EXIT 0; real `user://saves/` SHA-256 identical before/after; no residue.
- Follow-up: Phase 4 — Large-script decomposition (not started).

### P3-05 - Legacy runtime isolation

- Status: `COMPLETED`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `0a1c1af`
- Result: sandbox (`main.gd`) and arrival prototype (`arrival_landing_scene.gd`) runtime paths isolated from formal autoloads / Full Save / formal continue. Local manager node names renamed `Sandbox…` / `ArrivalPrototype…` (only true collision was local `TimeManager` vs `/root/TimeManager`; safe — member-var access only). Legacy save namespaces (`slot_N.json` / `arrival_prototype_save.json`) confirmed separate from `full_save.json`; `FullSaveOrchestrator` rejects legacy and never reads legacy files. Adapted GPT spec: no new mode-framework/guards, no `main.gd` logic rewrite, no legacy deletion, no schema/`project.godot` change.
- Verification: Godot editor/smoke EXIT 0; P3-05 32/32; P3-03a 39/39; P3-03b 50/50; P3-03c 33/33; P3-03d 25/25; P3-04 33/33; real saves SHA-256 identical before/after.
- Follow-up: P3-06 Phase 3 regression sweep + closure.

### P3-04 - Manager responsibility overlap cleanup

- Status: `COMPLETED`
- Owner: `Claude Code`
- Previous owner: `Codex`
- Transfer reason: Codex usage limit reached before it could write `.git/index` (commit); ownership transferred to Claude Code to complete takeover review and Git close-out. Same task, not a re-implementation.
- Reviewer: `User`
- Base commit: `be363f2`
- Result: canonical owners and compatibility mirror directions are clarified for Inventory/Backpack/Storage, Time/TrainingTime, BaseStatus/Power/Air, Suit/PlayerState, and DoorState. Codex completed the implementation and tests; Claude completed takeover review and the commit.
- Code changes: transfer APIs now return explicit source/destination/rollback metadata; BaseStatus and PlayerState now expose mirror-specific sync APIs (`sync_power_mirror_from_power_system`, `sync_suit_worn_mirror_from_suit_manager`) while keeping compatibility wrappers; Power and Suit push through those mirror-specific APIs.
- Boundaries preserved: no Full Save schema change, no Training Checkpoint format change, no gameplay value change, no scene resource change, no `project.godot` change, no formal-base Door integration.
- Verification (Codex, pre-transfer): Godot editor parse EXIT 0; Godot headless smoke EXIT 0; P3-03a 39/39; P3-03b 50/50; P3-03c 33/33; P3-03d 25/25; P3-04 33/33; real saves SHA unchanged.
- Verification (Claude, post-transfer re-run): Godot editor parse EXIT 0; Godot headless smoke EXIT 0; P3-04 33/33; P3-03a 39/39; P3-03b 50/50; P3-03c 33/33; P3-03d 25/25; real `user://saves/` SHA-256 identical before/after (test suites self-restore, no corruption).
- Follow-up: P3-05 legacy isolation is ready to schedule next.

### P3-03d - Checkpoint scope trimming

- Status: `COMPLETED`
- Owner: `Codex`
- Reviewer: `User`
- Base commit: `8429f6a`
- Result: Training Checkpoint is restricted to training progress, temporary Suit state, TrainingTime state, and training-only Inventory containers; legacy global Manager fields are readable as metadata only and are not applied; `save_progress()` strips legacy global snapshot keys.
- Full Save boundary: missing `full_save.json` no longer falls back to `sprint06_progress.json`; explicit legacy sprint06 reads remain available, but formal `restore_full_save()` rejects legacy sources as read-only compatibility input.
- Verification completed: Godot editor parse EXIT 0; Godot headless smoke EXIT 0; P3-03a 39/39; P3-03b 50/50; P3-03c 33/33; P3-03d 25/25; real saves SHA unchanged from pre-test baseline; no `p3_03d*` temp files remained.
