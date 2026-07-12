# Active Tasks

This file is the current coordination board for active task ownership, file locks, blockers, and short handoff state.

## Board Status

- **Status**: `IDLE`
- **Active tasks**: `0`
- **Locked files**: `0`
- **Pending handoffs**: `0`
- **Branch**: `main`
- **Board baseline**: `1cb6e78`
- **Last updated**: `2026-07-12`

## Active Tasks

No active tasks.

## File Locks

No active file locks.

## Pending Handoffs

No pending handoffs.

## Recently Closed

### P3-03c - Manager self-save authority downgrade

- Status: `VERIFIED_AFTER_FIX`
- Owner: `Codex`
- Reviewer: `User`
- Base commit: `1cb6e78`
- Result: `full_save.json` remains the formal complete-progress authority; formal core Manager-local `load_state()` paths now skip after Full Restore starts/completes; formal continue no longer calls `TrainingManager.load_progress()`; Manager self-save files/APIs, Training Checkpoint, Full Save schema, and JSON field shapes remain unchanged.
- Downgraded: `TimeManager`, `HealthManager`, `BaseStatusManager`, `PowerSystemManager`, `WaterSystemManager`, `AirSystemManager`, `InventoryManager`, `BackpackManager`, `StorageManager`, `SuitManager`, `SupplyManager`, `RepairManager`, `PlantGrowthManager`.
- Not downgraded: `DoorStateManager` (training/local, formal base not connected), `TrainingTimeManager` (training-local), `AcademicBackgroundManager` (profile/settings), and non-self-save Managers.
- P3-03cV fix: added `FullSaveOrchestrator.reset_formal_restore_session()` and calls it from demo/new-game progress clearing so same-process new game/fallback is not permanently blocked after a Full Restore.
- Verification completed: Godot editor parse EXIT 0; Godot headless smoke EXIT 0; P3-03a 39/39; P3-03b 50/50; P3-03c 33/33; real saves SHA unchanged from pre-test baseline; no `p3_03*` temp files remained.
- Follow-up: P3-03d is ready to schedule; do not start it in this task.
