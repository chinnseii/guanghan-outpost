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
- P3-04 Manager responsibility overlap cleanup.

Not started:
- P3-05 legacy isolation.
- P3-06 closure/regression sweep.

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

P3-04 is complete and ready for review. P3-05 legacy isolation is ready to schedule next; do not start it automatically.
