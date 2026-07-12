# Phase 4 Closure Report

Date: 2026-07-12
Owner: Codex
Base commit: `02fd9d3`
Final task: P4-08 — Phase 4 regression, save-baseline recovery, and closure

## 1. Scope

P4-08 closes Phase 4 large-script decomposition. This round did not continue production refactoring and did not start Phase 5. It verified all Phase 3/4 regression suites, protected and re-baselined the current real Godot save files, documented the P4-07B save-refresh side effect, and records why further splitting stops here.

## 2. Baseline

- HEAD at start: `02fd9d3 refactor: extract training module screen presenter`
- Branch: `main`
- Ahead/behind at start: ahead `9`, behind `0`
- Working tree at start: clean
- Staged at start: empty
- ACTIVE_TASKS at start: IDLE
- P4-01 through P4-07B commits present in `git log --oneline --decorate -15`

## 3. Completed Tasks

| Task | New component/document | Source reduction | Responsibility boundary | Test file | Status |
|---|---|---:|---|---|---|
| P4-01 | `PHASE_4_LARGE_SCRIPT_AUDIT.md` | n/a | Read-only decomposition plan | n/a | DONE |
| P4-02 | `scripts/controllers/dev_tools_controller.gd` | `main.gd` 5182 -> 4346 (-836) | Dev menu/debug tools only | `tests/p4_02_dev_tools_controller_test.gd` | DONE |
| P4-03 | `scripts/controllers/formal_flow_router.gd` | `main.gd` 4346 -> 4302 (-44) | Formal continue/new-game routing | `tests/p4_03_formal_flow_router_test.gd` | DONE |
| P4-04 | `scripts/controllers/base_hud_panel_presenter.gd` | `sprint06_base_scene.gd` 2556 -> 2331 (-225) | Base HUD/status panels only | `tests/p4_04_base_hud_panel_presenter_test.gd` | DONE |
| P4-05 | `scripts/controllers/base_navigation_controller.gd` | `sprint06_base_scene.gd` 2331 -> 2308 (-23) | Pure navigation target/terrain computation | `tests/p4_05_base_navigation_controller_test.gd` | DONE |
| P4-06A | `P4_06A_SPRINT06_FLOW_AUDIT.md` | n/a | Read-only sprint06 flow audit | `tests/p4_06a_sprint06_flow_characterization_test.gd` | DONE |
| P4-06B | `scripts/controllers/sprint06_schedule_evaluator.gd` | `sprint06_base_scene.gd` 2307 -> 2268 (-39) | Pure schedule/checklist evaluator | `tests/p4_06b_sprint06_schedule_evaluator_test.gd` | DONE |
| P4-07A | `P4_07A_TRAINING_LARGE_SCRIPT_AUDIT.md` | n/a | Read-only training UI audit | `tests/p4_07a_training_large_script_audit_test.gd` | DONE |
| P4-07B | `scripts/controllers/training_module_screen_presenter.gd` | `training_module_scene.gd` 3417 -> 3114 (-303) | Training module display UI only | `tests/p4_07b_training_module_screen_presenter_test.gd` | DONE |
| P4-08 | `PHASE_4_CLOSURE_REPORT.md` | n/a | Regression, save baseline, closure | all P3/P4 tests | DONE |

## 4. Extracted Components

- `DevToolsController`: Node controller, not Autoload. Dev-only menu/debug actions. Does not own canonical save state and is not required by formal new game or continue.
- `FormalFlowRouter`: RefCounted, not Autoload. Owns route priority only: Full Save -> Training -> legacy fallback -> notice. Uses read-only progress predicates and delegates scene/log/UI effects through callbacks. Does not own save payload.
- `BaseHudPanelPresenter`: RefCounted, not Autoload. Builds and refreshes status/HUD panels. Does not save, change scenes, advance time, or write Managers. Flow-coupled plant diagnosis stays in the scene.
- `BaseNavigationController`: RefCounted, not Autoload. Stateless navigation target/terrain computation. Movement, transitions, and task advancement remain in `sprint06_base_scene.gd`.
- `Sprint06ScheduleEvaluator`: RefCounted, not Autoload. Stateless schedule/checklist predicates and text over `(day, state)`. It never mutates the passed Dictionary and has no Manager/save/scene dependency.
- `TrainingModuleScreenPresenter`: RefCounted, not Autoload. Training module screen presentation only. It does not own `step_index`, `completed`, `module_id`, checkpoint writes, `_complete_step`, `_finish_module`, or diagnosis/plant/repair answer logic.

## 5. Large-Script Size Changes

| File | Phase 4 start lines | Final lines | Net reduction | Remaining dominant responsibilities |
|---|---:|---:|---:|---|
| `scripts/main.gd` | 5182 | 4302 | -880 | Legacy sandbox root, main menu shell, sandbox save slots, sandbox movement/building/UI glue, formal router/controller wiring |
| `scripts/base/sprint06_base_scene.gd` | 2556 | 2268 | -288 | Formal base scene lifecycle, async equipment interactions, finish/transition/save order, scene-local day flags, prop/art setup |
| `scripts/training/training_module_scene.gd` | 3417 | 3114 | -303 | Training room layout/targets, movement/input locks, step state machine, checkpoint writes, flow-coupled diagnosis/repair choices |
| `scripts/training/training_base_map.gd` | 2255 | 2255 | 0 | Training hub room switching, dynamic area/door SceneTree ownership, training door traversal, local room tasks |

Line count reduction is not the only acceptance criterion. The remaining large sections are kept because they are order-dependent, SceneTree-coupled, save/checkpoint-coupled, or gameplay-flow-coupled.

## 6. Responsibility Boundaries

- Dev tools are isolated from formal flow. `DevToolsController` may call training checkpoint APIs only through explicit dev buttons.
- Formal continue remains in `FormalFlowRouter`; it does not write save payloads or mutate training checkpoint state.
- HUD presenters and navigation/evaluator helpers are non-Autoload helpers created by scenes.
- `TrainingModuleScreenPresenter` owns popup shell display but not option correctness, checkpoint, or step advancement.
- `training_base_map.gd` was not modified during P4-07B/P4-08.
- `project.godot` contains no Autoload registration for the extracted controllers.

## 7. Test Evidence

| Suite | Result |
|---|---:|
| P4-07B | 20/20 |
| P4-07A | 32/32 |
| P4-06B | 41/41 |
| P4-06A | 28/28 |
| P4-05 | 30/30 |
| P4-04 | 35/35 |
| P4-03 | 27/27 |
| P4-02 | 22/22 |
| P3-03a | 40/40 |
| P3-03b | 50/50 |
| P3-03c | 34/34 |
| P3-03d | 25/25 |
| P3-04 | 33/33 |
| P3-05 | 37/37 |

Total recorded checks: 454/454.

## 8. Godot Verification

- `godot --headless --editor --quit --path .`: EXIT 0.
- `godot --headless --path . --quit`: EXIT 0.
- No parse error or SCRIPT ERROR observed.
- P4-02 still emits the known test cleanup warning about leaked CanvasItem/ObjectDB instances on exit; this is existing test cleanup noise and not a Phase 4 production regression.

## 9. Save-Baseline Recovery and Integrity

Actual user data directory confirmed:

`C:\Users\csw83\AppData\Roaming\Godot\app_userdata\Guanghan Outpost`

New P4-08 backup:

`C:\Users\csw83\AppData\Roaming\Godot\app_userdata\Guanghan Outpost\saves_backup_before_p4_08_2026-07-12_234110`

Backup scope:
- `saves/`
- root save JSON files: `arrival_prototype_save.json`, `guanghan_outpost_save.json`
- logs/cache directories intentionally excluded.

Backup result: 19 source files, 19 backup files, 0 SHA mismatches.

| Relative path | Size | Modified time | SHA-256 | Backup SHA match |
|---|---:|---|---|---|
| `saves\air_system_state.json` | 194 | 2026-07-12 22:37:39 | `24695ED6E96A58B5326399963354CB67B57C6DFBEACAA4D035769491B74E5B03` | YES |
| `saves\application_profile.json` | 732 | 2026-07-12 03:19:03 | `43D6A9A49CA6AEA8BA5BADFEE2645C56F63771A80BF4B9CCA8B5A8F758EFA44F` | YES |
| `saves\backpack_state.json` | 236 | 2026-07-12 22:37:39 | `FA5317D118650D439F3DD310529EAF127DA3C67091A1C6517836150579C43991` | YES |
| `saves\base_status_state.json` | 180 | 2026-07-12 22:37:39 | `41329D2392DFD35B3A0A28688619BFA3368E3EC2787CD0158C6F1C1EAAC8A535` | YES |
| `saves\door_state.json` | 4920 | 2026-07-09 03:34:22 | `0DFA5EC6105F217BDD92E257B8428FF9D1DF805DEF02B9F9D44D836A2C7F7B0D` | YES |
| `saves\health_state.json` | 105 | 2026-07-12 22:37:39 | `92D1A08FCB20F05520B3724E07BAC74CD60FD4A9E705B469F17E05E32A4EA702` | YES |
| `saves\inventory_state.json` | 113 | 2026-07-12 22:37:39 | `A52F308D99C34770ABFD6498CE8DAE87F92EE25F5E639F5FC777AB3162DB859C` | YES |
| `saves\plant_growth_state.json` | 168 | 2026-07-12 22:37:39 | `2B944AB3FEE13F82D64295A48A23701214F1F48F9A46661FD53F017CE6B06F36` | YES |
| `saves\power_system_state.json` | 259 | 2026-07-12 22:38:22 | `89126DD64BFD9E87101FB4D8EA11CD2974D7F1D0CE553BFD6DA76242C30861A7` | YES |
| `saves\repair_state.json` | 67 | 2026-07-12 03:39:24 | `960A42F28EEA110BB96C2F4C302AF9EDCC801A72672400E3B1608683E73055D3` | YES |
| `saves\storage_state.json` | 618 | 2026-07-12 22:37:39 | `82C3073E7CE6817E18239F9CECEEF151A781B085D6659A2B03A15B871E693DBD` | YES |
| `saves\suit_state.json` | 215 | 2026-07-12 22:37:39 | `07A36E44302E931A350BD8CBEEDE4403350097BA9E223528F5A7B4265B6DC070` | YES |
| `saves\supply_state.json` | 579 | 2026-07-12 22:37:39 | `AA90803AA8432B15B95FE481EEA68A9EB8BB736B998516E270D24E960A8E3AA9` | YES |
| `saves\time_state.json` | 137 | 2026-07-12 22:37:39 | `A9576A442D13F0F2CB8EBB3D69CB57ACFE347408093B1C3169D45A49B99F00A4` | YES |
| `saves\training_progress.json` | 3617 | 2026-07-12 22:37:39 | `D428C48F91FA035C95EDAD36875A306A0A5CC47FB47394682BA1FD63068CFF15` | YES |
| `saves\training_time_state.json` | 163 | 2026-07-12 22:37:39 | `8E515E65F434A47982188245B2CD1956904A847B0177D897E3FE4577820B9F25` | YES |
| `saves\water_system_state.json` | 259 | 2026-07-12 22:37:39 | `FAAE170303D1051DAC37984F08592A4AAA381280C1D3D43C329A039063F8C729` | YES |
| `arrival_prototype_save.json` | 343 | 2026-07-08 02:44:02 | `74A1667D60C080EB27E0EC8D75FA3C469DCFC9F060C7851E94206EF40E3624F7` | YES |
| `guanghan_outpost_save.json` | 2438 | 2026-06-27 23:39:35 | `F7459FD25821B1F6519DA8ABE52CDDDA326CBD625E859DDEB5173A2FA4D218B7` | YES |

P4-07B save-refresh analysis:
- The old `saves_backup_before_p3_03a_2026-07-11` is not a safe rollback source because it predates user/test progress made on 2026-07-12.
- P4-08 did not overwrite current progress with that backup.
- Compared to the 2026-07-11 backup, current saves include later `training_progress.json` and root legacy/dev JSON (`arrival_prototype_save.json`, `guanghan_outpost_save.json`), and several manager-local mirrors differ in expected runtime state values.
- Files with changed structured values since 2026-07-11: `application_profile.json`, `health_state.json`, `power_system_state.json`, `suit_state.json`, `training_time_state.json`.
- Files with identical SHA but newer mtime since 2026-07-11 include multiple manager-local mirrors.
- No `full_save.json` exists in the current save set, so no formal Full Save core progress changed.
- `training_progress.json` exists in current/P4-08 baseline and remained SHA-stable after P4-08 tests.

Post-test comparison against the P4-08 baseline:
- File count remained 19.
- No files added, removed, or structurally changed.
- All SHA-256 values remained identical to the P4-08 backup baseline.
- 14 files had mtime-only refresh after tests: manager-local mirrors plus `training_progress.json`.

Final save conclusion:

`SAVE_BASELINE_STABLE_WITH_EXPECTED_MIRROR_REFRESH`

## 10. Closed Risks

- P4 extracted dev tools, formal flow routing, base HUD presentation, base navigation computation, sprint06 schedule evaluation, and training module screen presentation behind explicit boundaries.
- No controller was registered as an Autoload.
- No Full Save schema, Training Checkpoint schema, scene resource, asset, or gameplay value was changed in Phase 4 closure.
- P4-07B save integrity is no longer unresolved: current user progress is protected by the new P4-08 baseline and tests caused only mtime-only mirror refreshes against that baseline.

## 11. Deferred Risks

DEFER_TO_FEATURE_WORK:
- DoorState formal old-base integration.
- Legacy file physical deletion.
- `interaction_detector` / `BaseInterior_Test` UNKNOWN cleanup.
- Product-level Inventory <-> Backpack relationship decisions.

DEFER_TO_FUTURE_REFACTOR:
- `training_base_map.gd` room/door/dynamic SceneTree ownership.
- `training_module_scene.gd` remaining training state machine and room layout.
- `sprint06_base_scene.gd` async finish/transition/save sequences.
- Legacy sandbox slot-save aggregation.
- `main.gd` remaining legacy sandbox core.

NOT_A_BLOCKER:
- `training_module_scene.gd` and `training_base_map.gd` remain large, but their remaining responsibilities are intentionally scene-tree/flow/checkpoint coupled.
- P4-02 test cleanup warning is not a production regression.

## 12. Why Further Splitting Stops Here

The remaining large-script code is not display-only or pure logic. It coordinates input locks, async interaction timing, scene transitions, checkpoint writes, dynamic room/door SceneTree ownership, or legacy sandbox state. Splitting those areas now would create higher risk than value and would likely require product or architecture decisions outside Phase 4's "one responsibility at a time" rule.

## 13. Phase 5 Entry Criteria

Phase 5 — Skill development is READY because:
- Phase 3 is closed.
- Phase 4 is closed.
- Full P3/P4 regression is green.
- A current real-save baseline exists and is stable.
- Deferred risks are documented and not hidden as solved.

Phase 5 was not started in P4-08.

## 14. Final Repository State

Expected after P4-08 commit:
- Working tree clean.
- `main` ahead `origin/main` by 10.
- Behind `0`.
- ACTIVE_TASKS IDLE.
- Phase 4 COMPLETE.
- Phase 5 READY.
- No push, no tag.
