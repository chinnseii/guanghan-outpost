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
- P3-03c Manager self-save authority downgrade code/docs are implemented in this working copy.

Not started:
- P3-03d checkpoint scope trimming.
- P3-04/P3-05/P3-06 follow-up cleanup.

## P3-03c Summary

Goal: make `user://saves/full_save.json` the formal continue/restore authority while keeping Manager-local `*_state.json` files and `save_state/load_state` APIs as transition fallback/debug mirrors.

Implemented:
- `FullSaveOrchestrator.restore_full_save()` now validates required providers before mutation, marks formal restore in progress, and records restore completion.
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

- Godot editor/headless verification could not be executed in this run because escalation approval was rejected by the environment usage limit. Do not start P3-03d until P3-03c, P3-03a, P3-03b, editor parse, and headless smoke are run successfully.
- `DoorStateManager` remains outside core Full Save until formal base Door integration is implemented.
- Training Checkpoint scope is intentionally unchanged; P3-03d owns trimming.
- Full Save schema and Manager JSON field shapes were not changed.
- No `*_state.json` files were deleted.

## Verification Status

Completed without Godot:
- `git diff --check`: PASS, only existing line-ending warnings for touched CRLF files.
- Static scan confirms `scripts/main.gd` no longer contains `TrainingManagerScript.load_progress()`.
- Static scan confirms all downgraded Managers contain `FullSaveOrchestratorScript.should_skip_manager_local_restore()`.
- Static scan confirms `FullSaveOrchestrator` still does not read `training_progress.json`.

Blocked:
- P3-03c focused Godot test.
- P3-03a 39/39 regression.
- P3-03b 50/50 regression.
- Godot editor parse.
- Godot headless smoke.

## Next Step

Run the blocked Godot verification set. If all pass, P3-03d can be scheduled. Until then, treat P3-03d as not ready.
