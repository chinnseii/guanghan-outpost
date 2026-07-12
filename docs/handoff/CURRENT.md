# Current Project Status

Updated: 2026-07-12

## Phase

Phase 3 system-boundary cleanup is COMPLETE (pushed + tag `system-boundary-cleanup-complete-2026-07-12`). Phase 4 — Large-script decomposition — is IN PROGRESS: P4-01 audit + P4-02 DevToolsController + P4-03 FormalFlowRouter + P4-04 BaseHudPanelPresenter + P4-05 BaseNavigationController + P4-06A flow audit + P4-06B Sprint06ScheduleEvaluator done. sprint06 has no further low-risk extraction; next is either a training_module_scene/training_base_map UI-builder audit or Phase 4 close-out.

Completed:
- P3-01 system boundary audit.
- P3-02 save ownership decision.
- P3-02R independent review reconciliation.
- P3-03a restore consistency fixes.
- P3-03b Full Save Orchestrator formalization.
- P3-03c Manager self-save authority downgrade and P3-03cV lifecycle verification.
- P3-03d checkpoint scope trimming.
- P3-04 Manager responsibility overlap cleanup.
- P3-05 legacy runtime isolation.
- P3-06 Phase 3 regression sweep + closure (Phase 3 formally closed).
- P4-01 large-script responsibility & decomposition audit (`PHASE_4_LARGE_SCRIPT_AUDIT.md`).
- P4-02 DevToolsController extraction from `main.gd` (5182→4346; `scripts/controllers/dev_tools_controller.gd`).
- P4-03 FormalFlowRouter extraction from `main.gd` (4346→4302; `scripts/controllers/formal_flow_router.gd`).
- P4-04 BaseHudPanelPresenter extraction from `sprint06_base_scene.gd` (2556→2331; `scripts/controllers/base_hud_panel_presenter.gd`).
- P4-05 BaseNavigationController extraction from `sprint06_base_scene.gd` (2331→2308; pure nav computation; P4-05A interface-prep scope — sprint06 nav is largely flow-coupled).
- P4-06A sprint06 schedule/mission-flow coupling audit + characterization (`P4_06A_SPRINT06_FLOW_AUDIT.md`; conclusion: A — SAFE_EVALUATOR_EXTRACTION).
- P4-06B Sprint06ScheduleEvaluator extraction from `sprint06_base_scene.gd` (2307→2268; 8 pure schedule fns; `scripts/controllers/sprint06_schedule_evaluator.gd`).

Not started:
- Next: audit `training_module_scene.gd` (3417) / `training_base_map.gd` (2255) UI-builder split, OR Phase 4 close-out. Do not start automatically.

## P3-05 Summary

Goal: isolate legacy sandbox (`main.gd`) and arrival prototype (`arrival_landing_scene.gd`) runtime paths from formal autoloads, Full Save, and the formal continue flow — without deleting legacy, integrating formal-base Door, or changing schema/gameplay/`project.godot`.

Implemented:
- Renamed the legacy-local manager node names to remove the one real collision (local `TimeManager` vs `/root/TimeManager`): sandbox nodes → `SandboxTimeManager` / `SandboxGameStateManager`; arrival nodes → `ArrivalPrototypeTimeManager` / `ArrivalPrototypeGameStateManager`. Safe because these are accessed only via member variables (zero node-name path lookups); formal autoload access stays on `/root/…`.
- Added scope-clarifying comments marking legacy sandbox/arrival save-load (`slot_N.json` / `arrival_prototype_save.json`) and the last-resort legacy sandbox-slot continue fallback as legacy-only, never touching Full Save or `/root/*Manager`.
- Verified (already structurally true from P3-03b/c/d) that `FullSaveOrchestrator` never reads legacy sandbox/arrival files and rejects legacy sprint06 sources; formal continue depends only on Full Save / Training.
- Adapted the GPT spec: did NOT add a new `is_legacy_runtime` mode framework (isolation already holds structurally); did NOT rewrite `main.gd` logic.
- Resolved prior UNKNOWNs: `ArrivalLandingScene` = DEV_ONLY (`main.gd:3751`); arrival genuinely uses `game_state_manager`.
- Added `tests/p3_05_legacy_runtime_isolation_test.gd` (32/32).

Next: P3-06 Phase 3 regression sweep + closure. Manager self-save files and the multi-source risk are addressed within P3-03 scope; legacy is isolated but retained. Deferred beyond Phase 3: legacy deletion, DoorState formal-base integration, `main.gd` split (Phase 4).

## P3-04 Summary

Goal: clarify canonical owners, public write paths, transfer boundaries, and compatibility mirrors for overlapping Manager domains without changing gameplay values, Full Save schema, checkpoint schema, scenes, or formal base Door integration.

Implemented:
- `BackpackManager.transfer_slot_to_storage()` and `StorageManager.transfer_slot_to_backpack()` now return explicit transfer metadata: `source`, `destination`, `source_slot_index`, `requested_amount`, `returned_to_source`, and `rolled_back`.
- Existing take/add/rollback behavior is preserved. Target-full transfers still restore rejected quantities to the source owner.
- `BaseStatusManager.power` is documented and exposed as a compatibility mirror through `sync_power_mirror_from_power_system()` and `get_power_mirror_percent()`. Existing `set_power_percent()` remains as a compatibility wrapper.
- `PowerSystemManager` now calls the mirror-specific BaseStatus API when present, falling back to the old wrapper for compatibility.
- `PlayerStateManager.is_suit_worn` is documented and exposed as a Suit mirror through `sync_suit_worn_mirror_from_suit_manager()`. Existing `set_suit_worn()` remains as a compatibility wrapper.
- `SuitManager` now pushes suit worn state through the mirror-specific PlayerState API when present, falling back to the old wrapper for compatibility.
- Added `tests/p3_04_manager_responsibility_boundary_test.gd`.

## Final Owners

- `InventoryManager`: quantity-style global goods ledger (`stack_items`, `durable_items`) plus training-only `training_containers`.
- `BackpackManager`: player carried slot ledger.
- `StorageManager`: base storage slot ledger.
- `TimeManager`: formal mission clock.
- `TrainingTimeManager`: training-local clock.
- `PowerSystemManager`: canonical power owner.
- `AirSystemManager`: canonical oxygen/CO2/air-system owner.
- `BaseStatusManager`: pressure and temperature owner; `power` remains a Power compatibility mirror.
- `SuitManager`: canonical suit state owner.
- `PlayerStateManager`: player context registry; `is_suit_worn` remains a Suit compatibility mirror.
- `DoorStateManager`: training Door state owner today. Formal old-base navigation is still not connected.

## Shared Files Touched

Core/shared:
- `scripts/managers/BackpackManager.gd`
- `scripts/managers/StorageManager.gd`
- `scripts/managers/BaseStatusManager.gd`
- `scripts/managers/PowerSystemManager.gd`
- `scripts/managers/PlayerStateManager.gd`
- `scripts/managers/SuitManager.gd`

Tests:
- `tests/p3_04_manager_responsibility_boundary_test.gd`
- `tests/p3_04_manager_responsibility_boundary_test.gd.uid`

Docs:
- `docs/handoff/ACTIVE_TASKS.md`
- `docs/handoff/CURRENT.md`
- `docs/governance/PHASE_3_SYSTEM_BOUNDARY_AUDIT.md`
- `docs/governance/PHASE_3_SAVE_OWNERSHIP_DECISION.md`
- `docs/governance/SYSTEM_REGISTRY.md`
- `docs/governance/CLEANUP_PLAN.md`

## Verification Status

P3-04 passed:
- Godot editor parse EXIT 0.
- Godot headless smoke EXIT 0.
- P3-03a regression: 39/39.
- P3-03b Full Save regression: 50/50.
- P3-03c Manager self-save demotion regression: 33/33.
- P3-03d checkpoint scope focused test: 25/25.
- P3-04 responsibility boundary focused test: 33/33.
- Real `user://saves/` SHA-256 unchanged from the pre-test baseline.

## Known Issues / Risks

- Formal old-base Door navigation is still not connected to `DoorStateManager`; this was intentionally not implemented in P3-04.
- Legacy sandbox/arrival isolation remains for P3-05.
- Full Save schema, Training Checkpoint schema, Manager JSON field shapes, scenes, gameplay values, and `project.godot` were not changed.
- Manager-local `*_state.json` files remain present as fallback/debug mirrors per P3-03c.

## Next Step

Phase 3 is COMPLETE, pushed, and tagged. Phase 4 in progress: P4-01..P4-06B done (`main.gd` 5182→4302; `sprint06_base_scene.gd` 2556→2268; controllers under `scripts/controllers/`: DevTools, FormalFlowRouter, BaseHudPanelPresenter, BaseNavigationController, Sprint06ScheduleEvaluator). sprint06's remaining bulk is async completion/finish/transition/save + equipment interaction (all KEEP_IN_SCENE). **Next: either audit `training_module_scene.gd` (3417) / `training_base_map.gd` (2255) for a UI-builder split (same pattern as P4-04), or Phase 4 close-out.** Do not start automatically.

Deferred beyond Phase 3 (not regressions, tracked): legacy file physical deletion; DoorStateManager formal old-base integration (feature work); `main.gd` / `sprint06_base_scene.gd` large-script split (Phase 4); `interaction_detector` orphan and `BaseInterior_Test` entry (UNKNOWN); product-level Inventory↔Backpack relationship.
