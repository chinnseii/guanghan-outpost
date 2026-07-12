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
- P3-03c Manager self-save authority downgrade and P3-03cV lifecycle verification.
- P3-03d checkpoint scope trimming.

Not started:
- P3-04/P3-05/P3-06 follow-up cleanup.

## P3-03d Summary

Goal: restrict Training Checkpoint and legacy mission/scene checkpoint behavior so local checkpoints cannot restore formal global Manager state. `full_save.json` remains the only formal complete-progress restore truth source.

Implemented:
- `TrainingManager.default_data()` no longer declares global mission Manager snapshot fields such as `TimeState`, `HealthState`, `PowerSystemState`, `InventoryState`, `BackpackState`, `StorageState`, `PlantGrowthState`, or `PlayerStateManagerState`.
- `TrainingManager._read_progress_data()` only merges checkpoint-owned training keys into active progress data.
- Legacy global fields found in old `training_progress.json` files are exposed as read-only `LegacyGlobalStateFields` metadata and are not applied to live Managers.
- `TrainingManager.load_progress()` now restores only training-owned checkpoint state:
  - training flow flags and current module,
  - `SuitState` as training temporary equipment state,
  - `TrainingTimeState`,
  - `TrainingInventoryState.training_containers`.
- `TrainingManager.save_progress()` writes only checkpoint-owned fields and strips legacy global snapshot keys.
- `FullSaveOrchestrator.read_bundle()` no longer falls back from missing `full_save.json` to `sprint06_progress.json`.
- Explicit legacy sprint06 reads still work as best-effort conversion, but `FullSaveOrchestrator.restore_full_save()` rejects `legacy_source` bundles as read-only compatibility input.
- P3-03a regression expectations were updated: `TrainingManager.load_progress()` is now scoped training restore, not a global Manager restore path.
- Added `tests/p3_03d_checkpoint_scope_test.gd`.

## Final Scopes

Training Checkpoint final scope:
- Owns training progress flags, current training module, training status/failure reason, assignment/opening flow flags, current scene after training, temporary training Suit state, TrainingTime state, and training-only Inventory containers.
- Does not restore formal mission Time, Health, BaseStatus, Air, Power, Water, Inventory stack/durable items, Backpack, Storage, PlantGrowth, or PlayerState snapshot fields.

Mission/scene checkpoint final scope:
- Formal complete restore is handled by `FullSaveOrchestrator` and `full_save.json`.
- Legacy sprint06 unversioned files can be explicitly read for best-effort inspection/conversion, but they are not accepted as formal restore input.
- `sprint06_base_scene.gd` remains a Full Save scene adapter; no code change was needed there in P3-03d.

## Shared Files Touched

Core/shared:
- `scripts/training/training_manager.gd`
- `scripts/systems/full_save_orchestrator.gd`

Tests:
- `tests/p3_03a_restore_consistency_test.gd`
- `tests/p3_03d_checkpoint_scope_test.gd`
- `tests/p3_03d_checkpoint_scope_test.gd.uid`

Docs:
- `docs/handoff/ACTIVE_TASKS.md`
- `docs/handoff/CURRENT.md`
- `docs/governance/PHASE_3_SYSTEM_BOUNDARY_AUDIT.md`
- `docs/governance/PHASE_3_SAVE_OWNERSHIP_DECISION.md`
- `docs/governance/CLEANUP_PLAN.md`
- `docs/governance/SYSTEM_REGISTRY.md`

## Verification Status

P3-03d passed:
- Godot editor parse EXIT 0.
- Godot headless smoke EXIT 0.
- P3-03a regression: 39/39.
- P3-03b Full Save regression: 50/50.
- P3-03c Manager self-save demotion regression: 33/33.
- P3-03d checkpoint scope focused test: 25/25.
- Real `user://saves/` SHA-256 unchanged from the pre-test baseline.
- No `p3_03d*` temporary save files remained.

## Known Issues / Risks

- `DoorStateManager` remains outside core Full Save until formal base Door integration is implemented.
- Inventory stack/durable items remain formal global state; only `InventoryManager.training_containers` is restored through Training Checkpoint.
- `TrainingTimeManager` still has its own `training_time_state.json` fallback, and P3-03d additionally snapshots TrainingTime into `training_progress.json` as training-scoped state.
- Full Save schema and Manager JSON field shapes were not changed.
- No `*_state.json` files were deleted.

## Next Step

P3-03 can be considered ready to close after review. P3-04 is ready to schedule next; do not start P3-04 from the P3-03d task.
