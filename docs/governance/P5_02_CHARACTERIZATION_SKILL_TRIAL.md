# P5-02 Characterization Skill Trial

Date: 2026-07-13
Owner: Codex
Skill under trial: `skills/godot/characterization-first-refactor/SKILL.md`
Skill maturity after trial: `TRIAL`

## 1. Scope

This is a controlled dry run of the first formal repository Skill. It does not modify production code, tests, scenes, assets, `project.godot`, JSON, or real saves.

## 2. Simulated Task Invocation

```text
Use skill: characterization-first-refactor

Task-specific context:
- Target: scripts/training/training_base_map.gd
- Objective: Evaluate whether room-switching logic can be extracted
- Behavior that must remain unchanged: room creation, door registration, checkpoint state
- Allowed changes: none; audit-only dry run
- Forbidden changes: scripts, scenes, project.godot
- Required output: responsibility map, coupling classification, hard-stop decision
```

## 3. Input Sufficiency Check

The Skill correctly requires the missing implementation-task inputs before a real refactor:

- Base commit: present from P5-02 task context, not embedded in the Skill.
- Owner/reviewer: present from ACTIVE_TASKS.
- Allowed/forbidden files: present and narrow.
- Required tests: not needed for audit-only dry run; a real refactor would need focused characterization first.
- Save/data protection: no scene boot or production edit in this dry run, so no real-save SHA baseline is required.

Conclusion: sufficient for audit-only dry run. Insufficient for production refactor.

## 4. Read-Only Evidence Sample

This dry run sampled coupling evidence, not a full 2255-line audit.

Relevant code points:

- `scripts/training/training_base_map.gd::_ready()` initializes input actions, builds `areas`, routes initial area, registers training doors, builds screen UI, loads the current area, updates HUD, and syncs overlays.
- `_build_all_areas()` creates per-room configs and derives unlock/completion state from `TrainingManagerScript.read_progress()`.
- `_register_training_doors()` registers all door targets with `DoorStateManager` using generated door/spawn IDs and current lock state.
- `_load_area()` changes `current_area_id`, swaps `module_data`, restores `step_index`, rebuilds the room SceneTree, moves the player, syncs controller position, pushes PlayerState area, and refreshes HUD.
- `_switch_room()` persists current room step/state into `areas[current_area_id]` before calling `_load_area()`.
- `_try_pass_training_door()` coordinates local target gating, `DoorStateManager.try_pass_door()`, spawn resolution, `_try_enter_area()`, and optional door closing.
- `_complete_step()` mutates `module_data["state"]`, advances time, increments `step_index`, writes back into `areas`, hides diagnosis UI, and dispatches `_on_area_task_complete()`.
- `_on_area_task_complete()` writes TrainingManager progress, unlocks future rooms, registers/syncs doors, sometimes switches rooms, and sometimes changes scene.
- `_build_training_area()` clears and rebuilds the live `training_area` SceneTree for the current room, adding floor, target visuals, player, and prompt label.

## 5. Responsibility Map

| Responsibility | Evidence | Classification |
|---|---|---|
| Room config construction | `_hub_area_config()`, `_suit_prep_area_config()`, `_airlock_chamber_area_config()`, `_power_distribution_area_config()`, `_air_system_area_config()`, `_greenhouse_area_config()` | `PARTIAL` |
| Initial routing | `_route_initial_area()`, TrainingManager progress flags | `KEEP` |
| Door registration/state | `_register_training_doors()`, `_sync_training_door_locks()`, `_try_pass_training_door()` | `KEEP` |
| Room switching | `_switch_room()`, `_load_area()`, `areas/current_area_id/module_data/step_index` | `KEEP_IN_SCENE` |
| SceneTree rebuild | `_build_training_area()`, `_clear_container()`, `training_area.add_child()` | `KEEP_IN_SCENE` |
| Step/task progression | `_complete_step()`, `_on_area_task_complete()` | `KEEP_IN_SCENE` |
| Pure geometry helpers | `_is_near()`, `_is_inside_target_area()`, room coordinate helpers | `INTERFACE_PREPARATION` candidate only |
| Static labels/config data | area config dictionaries and HUD text | `CHARACTERIZE_ONLY` before any extraction |

## 6. Coupling Classification

The Skill would not recommend extracting room switching as a production refactor in this dry run.

Reasons:

- Room switching persists and restores live scene-local state across `areas`, `module_data`, `step_index`, `completed`, player position, controller sync, and HUD.
- Door traversal depends on `DoorStateManager` but still leaves actual movement and room loading in the scene.
- Room completion writes TrainingManager checkpoint/progress, unlocks rooms, re-registers doors, and may call `change_scene_to_file()`.
- `_build_training_area()` rebuilds live SceneTree content and is called both on `_ready()`/room load and resize.
- The behavior that must remain unchanged includes room creation, door registration, and checkpoint state, which are exactly the coupled areas.

Dry-run decision:

```text
KEEP_IN_SCENE for room switching
CHARACTERIZE_ONLY for any future room-flow work
INTERFACE_PREPARATION only for small pure helpers or room-config tables
```

## 7. Skill Usability Result

Clear sections:

- Required Inputs
- Preconditions
- Procedure
- Decision Points
- Forbidden Changes
- Validation Matrix
- Hard Stop Conditions

The Skill correctly prevents:

- turning the dry run into a production refactor;
- extracting room switching just for line reduction;
- moving checkpoint/door/SceneTree behavior without characterization;
- replacing the task prompt or ACTIVE_TASKS.

Refinement made during creation:

- Added a trigger-rich `description` field to the front matter so the Skill can be discovered while still preserving the Phase 5 metadata fields.
- Kept examples abstract instead of copying Phase 4 task prompts.
- Kept project paths in the Project-Specific References section as examples only.

## 8. Maturity Decision

The Skill remains `TRIAL`.

Reason:

- This was one controlled audit-only dry run.
- No real production refactor has used the Skill yet.
- Upgrade to `VALIDATED` requires at least two different real refactor tasks, including at least one Controller extraction and at least one Presenter, Evaluator, or `CHARACTERIZE_ONLY` task, with user acceptance.

## 9. Next Recommendation

P5-03 should build the next Wave 1 Skill:

```text
P5-03 - Save Integrity Guard Skill
```

No P5-02R is needed from this dry run.
