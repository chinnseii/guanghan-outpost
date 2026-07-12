# Current Project Status

Updated: 2026-07-12

## Phase

Phase 3 system-boundary cleanup is in progress.

Completed:
- P3-01 system boundary audit.
- P3-02 save ownership decision.
- P3-02R independent review reconciliation.
- P3-03a restore consistency fixes.
- P3-03b Full Save Orchestrator formalization.
- P3-03c Manager self-save authority downgrade is verified after the P3-03cV lifecycle fix.

Not started:
- P3-03d checkpoint scope trimming.
- P3-04/P3-05/P3-06 follow-up cleanup.

## P3-03c Summary

Goal: make `user://saves/full_save.json` the formal continue/restore authority while keeping Manager-local `*_state.json` files and `save_state/load_state` APIs as transition fallback/debug mirrors.

Implemented:
- `FullSaveOrchestrator.restore_full_save()` now validates required providers before mutation, marks formal restore in progress, and records restore completion.
- `FullSaveOrchestrator.reset_formal_restore_session()` clears the in-progress/completed guard for new-game/demo-reset flows.
- Formal core progress Managers now skip their local `load_state()` after Full Restore has started/completed:
  - `TimeManager`
  - `HealthManager`
  - `BaseStatusManager`
  - `PowerSystemManager`
  - `WaterSystemManager`
  - `AirSystemManager`
  - `InventoryManager`
  - `BackpackManager`
  - `StorageManager`
  - `SuitManager`
  - `SupplyManager`
  - `RepairManager`
  - `PlantGrowthManager`
- Formal main-menu continue now restores through `FullSaveOrchestrator.restore_full_save()` for existing Full Save progress instead of calling `TrainingManager.load_progress()`.
- `TrainingManager.load_progress()` remains as legacy/restoring API for training/dev compatibility, but it is no longer the formal continue entry.
- Added focused P3-03c test coverage for:
  - guarded Manager-local restore,
  - Full Save wins over live/local-like state,
  - no late overwrite after `load_state()` helpers, a deferred frame, and checkpoint/scene read queries,
  - no fallback guard activation when the temp Full Save is missing.
- Updated P3-03a regression expectation: external callers should no longer call `TrainingManager.load_progress()`.

## Manager Auto-Load Classification

REQUIRED_BOOTSTRAP / formal core fallback before Full Restore:
- `TimeManager`, `HealthManager`, `BaseStatusManager`, `PowerSystemManager`, `WaterSystemManager`, `AirSystemManager`, `InventoryManager`, `BackpackManager`, `StorageManager`, `SuitManager`, `SupplyManager`, `RepairManager`, `PlantGrowthManager`.

LEGACY_FALLBACK / local or training scope:
- `DoorStateManager`: training/base-door local state, still excluded from core Full Save because formal base Door integration is not connected.
- `TrainingTimeManager`: training-local clock fallback.
- `TrainingManager.load_progress()`: legacy/training restoring API, not formal continue.

Settings/profile:
- `AcademicBackgroundManager` / `application_profile.json`.

No Manager-local persistence:
- `PlayerStateManager`, `MovementTimeManager`, `PenaltyManager`, `TaskManager` local-manager self-save path not changed in P3-03c.

## Restore Rule

Formal rule after P3-03c:

1. Boot may use default Manager state or existing Manager-local fallback.
2. If Full Save exists, `FullSaveOrchestrator.restore_full_save()` is the final authority.
3. After Full Restore starts/completes, downgraded Managers return early from local `load_state()` and cannot reload `*_state.json` over formal progress.
4. Manager self-save writes may continue as debug/write-through mirrors after normal gameplay actions; they do not change Full Save authority.

## Known Issues / Risks

- P3-03cV found and fixed one lifecycle gap: a completed Full Restore was previously a permanent static flag with no new-game reset path. The new session reset API is called by demo/new-game progress clearing.
- `DoorStateManager` remains outside core Full Save until formal base Door integration is implemented.
- Training Checkpoint scope is intentionally unchanged; P3-03d owns trimming.
- Full Save schema and Manager JSON field shapes were not changed.
- No `*_state.json` files were deleted.

## Verification Status

P3-03cV passed:
- Godot editor parse EXIT 0.
- Godot headless smoke EXIT 0.
- P3-03a regression: 39/39.
- P3-03b Full Save regression: 50/50.
- P3-03c focused test: 33/33.
- Real saves SHA-256 unchanged from the pre-test baseline.
- No `p3_03*` temporary save files remained.

## Next Step

P3-03d can be scheduled next. Do not start it from the P3-03cV task.
