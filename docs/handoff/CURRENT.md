# Current Project Status

Updated: 2026-07-12

## Phase

Current Phase: Phase 4 complete.
Next Phase: Phase 5 — Skill development.

Phase 3 system-boundary cleanup is COMPLETE and tagged `system-boundary-cleanup-complete-2026-07-12`. Phase 4 large-script decomposition is COMPLETE through P4-08. Phase 5 is READY but has not been started.

## Recent Completion

P4-08 — Phase 4 regression, save-baseline recovery, and closure.

Result:
- Full P3/P4 regression passed.
- Godot editor parse and default headless smoke passed.
- A new current real-save baseline was created without overwriting newer user progress.
- P4-07B save integrity is resolved as `SAVE_BASELINE_STABLE_WITH_EXPECTED_MIRROR_REFRESH`.
- Phase 4 is formally closed.

Current repository baseline before P4-08 closing commit:
- HEAD: `02fd9d3`
- Branch: `main`
- Ahead/behind before closing commit: ahead `9`, behind `0`
- Working tree at P4-08 start: clean
- P4-08 owner: `Codex`
- P4-07B owner transfer: Claude Code quota exhaustion -> Codex completed the same approved task, not a duplicate task.

## Phase 4 Completed Work

- P4-01 large-script responsibility & decomposition audit.
- P4-02 DevToolsController extraction from `main.gd` (5182 -> 4346).
- P4-03 FormalFlowRouter extraction from `main.gd` (4346 -> 4302).
- P4-04 BaseHudPanelPresenter extraction from `sprint06_base_scene.gd` (2556 -> 2331).
- P4-05 BaseNavigationController extraction from `sprint06_base_scene.gd` (2331 -> 2308).
- P4-06A sprint06 schedule/mission-flow coupling audit.
- P4-06B Sprint06ScheduleEvaluator extraction from `sprint06_base_scene.gd` (2307 -> 2268).
- P4-07A training large-script UI audit.
- P4-07B TrainingModuleScreenPresenter extraction from `training_module_scene.gd` (3417 -> 3114).
- P4-08 regression, save-baseline recovery, and closure.

## Large Script Final State

| File | Phase 4 start lines | Final lines | Net reduction | Remaining reason |
|---|---:|---:|---:|---|
| `scripts/main.gd` | 5182 | 4302 | -880 | legacy sandbox root/menu/save glue remains coupled |
| `scripts/base/sprint06_base_scene.gd` | 2556 | 2268 | -288 | async finish/transition/save and scene task state remain coupled |
| `scripts/training/training_module_scene.gd` | 3417 | 3114 | -303 | room layout, movement, step flow, checkpoint, answer logic remain coupled |
| `scripts/training/training_base_map.gd` | 2255 | 2255 | 0 | dynamic rooms/doors/area switching remain SceneTree-coupled |

## Save Baseline

Actual user data directory:

`C:\Users\csw83\AppData\Roaming\Godot\app_userdata\Guanghan Outpost`

P4-08 backup:

`C:\Users\csw83\AppData\Roaming\Godot\app_userdata\Guanghan Outpost\saves_backup_before_p4_08_2026-07-12_234110`

Backup status:
- 19 source files copied.
- 19 backup files verified.
- 0 SHA mismatches.
- Test-after-baseline comparison: all SHA unchanged; 14 files had mtime-only refresh.
- Final save conclusion: `SAVE_BASELINE_STABLE_WITH_EXPECTED_MIRROR_REFRESH`.

Why no 2026-07-11 rollback:
- The 2026-07-11 backup predates later user/test progress from 2026-07-12.
- It was used for analysis only, not as an overwrite source.

## Verification

- P4-07B: 20/20
- P4-07A: 32/32
- P4-06B: 41/41
- P4-06A: 28/28
- P4-05: 30/30
- P4-04: 35/35
- P4-03: 27/27
- P4-02: 22/22
- P3-03a: 40/40
- P3-03b: 50/50
- P3-03c: 34/34
- P3-03d: 25/25
- P3-04: 33/33
- P3-05: 37/37
- Total: 454/454
- Godot editor parse: EXIT 0
- Godot headless smoke: EXIT 0

## Deferred Risks

DEFER_TO_FEATURE_WORK:
- DoorState formal old-base integration.
- Legacy file physical deletion.
- `interaction_detector` / `BaseInterior_Test` UNKNOWN cleanup.
- Product-level Inventory <-> Backpack relationship.

DEFER_TO_FUTURE_REFACTOR:
- `training_base_map.gd` room/door/dynamic SceneTree ownership.
- `training_module_scene.gd` remaining state machine and room layout.
- `sprint06_base_scene.gd` async finish/transition/save.
- legacy sandbox slot-save aggregation.
- `main.gd` remaining legacy sandbox core.

These are not Phase 4 blockers.

## Next Step

Phase 5 — Skill development. Do not push, tag, or start Phase 5 automatically from P4-08.
