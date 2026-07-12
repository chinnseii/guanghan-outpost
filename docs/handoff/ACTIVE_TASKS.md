# Active Tasks

This file is the current coordination board for active task ownership, file locks, blockers, and short handoff state.

## Board Status

- **Status**: `IDLE`
- **Active tasks**: `0`
- **Locked files**: `0`
- **Pending handoffs**: `0`
- **Branch**: `main`
- **Board baseline**: `e33ea48`
- **Last updated**: `2026-07-13`

## Active Tasks

No active tasks.

## File Locks

No file locks.

## Pending Handoffs

No pending handoffs.

## Recently Closed

### P5-03 - Build Save Integrity Guard Skill

- Status: `DONE`
- Owner: `Codex`
- Reviewer: `User`
- Base commit: `e33ea48`
- Result: The second formal repository Skill was created, registered, and exercised through a controlled dry run without production-code or real-save changes.
- Skill: `skills/core/save-integrity-guard/SKILL.md`
- Registry: `skills/SKILL_REGISTRY.md`
- Trial: `docs/governance/P5_03_SAVE_INTEGRITY_SKILL_TRIAL.md`
- Verification: Skill structure and content checks passed; Godot editor/smoke EXIT 0; diff limited to allowed Markdown docs; no production code/tests/scenes/assets/project/JSON/saves changed; maturity remains `TRIAL`.
- Decision: Dry run concluded `SAVE_BASELINE_STABLE_WITH_EXPECTED_REFRESH`; older backups are analysis-only and must not overwrite newer current progress.
- Next: P5-04 - Task Baseline and Lock Skill. P5-04 was not started.

### P5-02 - Build Characterization-First Refactor Skill

- Status: `DONE`
- Owner: `Codex`
- Reviewer: `User`
- Base commit: `8b12ad9`
- Result: The first repository Skill was created, registered, and exercised through a controlled dry run without production-code changes.
- Skill: `skills/godot/characterization-first-refactor/SKILL.md`
- Registry: `skills/SKILL_REGISTRY.md`
- Trial: `docs/governance/P5_02_CHARACTERIZATION_SKILL_TRIAL.md`
- Verification: Skill structure and content checks passed; Godot editor/smoke EXIT 0; diff limited to allowed Markdown docs; no production code/tests/scenes/assets/project/JSON/saves changed; maturity remains `TRIAL`.
- Next: P5-03 - Save Integrity Guard Skill. P5-03 was not started.

### P5-01 - Skill architecture, directory, and boundary audit

- Status: `DONE`
- Owner: `Codex`
- Reviewer: `User`
- Base commit: `219cc8d`
- Result: Phase 5 Skill architecture was audited and documented. Final layers, directory scheme, Skill file standard, metadata standard, invocation pattern, ACTIVE_TASKS integration, candidate catalog, overlap decisions, art Skill architecture, lifecycle, Wave 1/2/3 plan, and the unique P5-02 target were defined.
- Verification: docs-only change; Godot editor parse EXIT 0; Godot headless smoke EXIT 0; diff limited to allowed Markdown docs; no formal Skill directory or `SKILL.md` created.
- Next: P5-02 should build only `skills/godot/characterization-first-refactor/SKILL.md`. P5-02 was not started.

### P4-08 - Phase 4 regression, save-baseline recovery, and closure

- Status: `DONE`
- Owner: `Codex`
- Reviewer: `User`
- Base commit: `02fd9d3`
- Result: Phase 4 fully regressed and closed; a trustworthy current save baseline was established without overwriting newer user progress.
- Verification: P4-07B 20/20; P4-07A 32/32; P4-06B 41/41; P4-06A 28/28; P4-05 30/30; P4-04 35/35; P4-03 27/27; P4-02 22/22; P3-03a 40/40; P3-03b 50/50; P3-03c 34/34; P3-03d 25/25; P3-04 33/33; P3-05 37/37; Godot editor/smoke EXIT 0.
- Save baseline: `saves_backup_before_p4_08_2026-07-12_234110`, 19/19 SHA match; post-test SHA unchanged with expected mtime-only mirror refresh. Final conclusion: `SAVE_BASELINE_STABLE_WITH_EXPECTED_MIRROR_REFRESH`.
- Follow-up: Phase 5 - Skill development is READY.

### P4-07B - Extract TrainingModuleScreenPresenter

- Status: `DONE`
- Owner: `Codex`
- Reviewer: `User`
- Base commit: `b9d1c0a`
- Result: extracted display-only training-module screen chrome from `training_module_scene.gd` into non-Autoload `scripts/controllers/training_module_screen_presenter.gd` (`class_name`, RefCounted). Scene now injects UI-intent callbacks and keeps all gameplay state/step flow/checkpoint writes. `training_module_scene.gd` 3417 -> 3114 (net -303). `training_base_map.gd`, scenes, `project.godot`, schemas, and gameplay values untouched.
- Scope adjustment: flow-coupled diagnosis/plant/repair option decisions stayed in the scene; presenter owns the popup shell API only. This keeps correct-answer logic and `_complete_step()` out of the display layer.
- Verification: Godot editor/smoke EXIT 0; P4-07B 20/20; P4-07A 32/32; P4-06B 41/41; P4-06A 28/28; P4-05 30/30; P4-04 35/35; P4-03 27/27; P4-02 22/22; P3-03a 40/40; P3-03b 50/50; P3-03c 34/34; P3-03d 25/25; P3-04 33/33; P3-05 37/37.
- Follow-up: Superseded by P4-08 closure.
