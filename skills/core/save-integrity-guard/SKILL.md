---
name: save-integrity-guard
description: Use before, during, and after tasks that may read, generate, refresh, migrate, restore, or overwrite real Godot user data. Protect current user progress with baseline backup, SHA-256 inventory, structured JSON comparison, save-category classification, and explicit decisions that forbid mechanical rollback over possibly newer progress.
version: 0.1.0
status: trial
scope: general
agents:
  - codex
  - claude-code
project: general
maturity: trial
last_validated: 2026-07-13
---

# Save Integrity Guard

## Purpose

Use this Skill to protect real user data whenever a task could touch Godot `user://` data, save files, checkpoints, manager-local mirrors, legacy saves, or test-generated save artifacts.

The goal is not to prevent every write. The goal is to preserve current user progress, distinguish canonical progress from compatibility mirrors, classify changes with evidence, and avoid overwriting newer or unknown data with an older backup.

The task prompt still provides current scope, owner, allowed files, forbidden files, tests, commit message, and push/tag permission. This Skill provides the save-protection method.

## When to Use

Use when any of these are true:

- the task reads, writes, migrates, restores, or compares `user://` data;
- launching Godot may trigger `_ready() -> load_state()` or `_ready() -> save_state()`;
- tests may create, refresh, or delete JSON files;
- scenes, managers, checkpoints, autosave paths, restore paths, or save schemas are involved;
- the task compares before/after real saves;
- the task proposes using an old backup;
- you must decide whether an mtime, SHA, JSON, or schema change is safe;
- you must verify that canonical progress was not overwritten by a manager-local mirror;
- closing a regression phase requires rebuilding a trustworthy save baseline;
- real user data is more valuable than test convenience.

Typical domains:

- Full Save
- Training Checkpoint
- Manager local saves
- legacy save compatibility
- Godot editor or smoke runs that may refresh local data
- real scene boots
- autosave tests
- data migration
- schema adjustment
- restore/load flow
- save-baseline rebuild
- incident recovery
- release data protection

## Do Not Use When

Do not use for:

- pure documentation edits with no Godot run and no `user://` access;
- pure static code analysis with no runtime command;
- work limited to isolated temporary test directories;
- tasks that only modify repository resources and cannot trigger runtime saves;
- user-provided disposable test saves that are explicitly not real progress.

If a runtime command may trigger real autosave or local mirror refresh, use this Skill even if the task does not modify save code.

## Required Inputs

The task prompt or project context must provide:

- User-data location
- Project/application user-data name
- Canonical save files
- Checkpoint files
- Legacy save files
- Manager-local save files
- Known auto-save triggers
- Existing backups
- Current task
- Allowed save changes
- Forbidden save changes
- Rollback authority
- Owner
- Reviewer

Optional inputs:

- known timestamp fields
- volatile fields
- expected mirror refresh files
- test temporary paths
- schema version
- backup retention rule
- hash algorithm
- JSON diff ignore rules

If a required input is missing and cannot be discovered safely from current docs or code, write `UNRESOLVED` instead of guessing.

## Save Categories

Classify every file before judging it:

| Category | Meaning |
|---|---|
| `CANONICAL_FULL_SAVE` | Formal complete-progress save used by the official continue/restore flow. |
| `CHECKPOINT` | Local training, mission, or module checkpoint that is narrower than the full game. |
| `MANAGER_LOCAL_MIRROR` | Manager self-save, debug mirror, fallback, cache, or compatibility snapshot. |
| `LEGACY_SAVE` | Old sandbox, prototype, or compatibility save not authoritative for formal continue. |
| `TEST_TEMPORARY` | File created by the current test in an isolated temp path. |
| `UNKNOWN` | File whose owner or authority cannot be proven. |

Rules:

- `UNKNOWN` blocks automatic overwrite and automatic delete.
- A manager-local mirror is not canonical progress.
- A checkpoint is not a Full Save.
- A legacy save is not automatically upgraded into the formal restore source.
- A missing canonical file is not a deletion unless it existed in the pre-run snapshot.

## Preconditions

Before a risky run:

- Confirm Git/task baseline and task ownership when the work is in a repository.
- Read current save ownership docs or system registries when available.
- Locate the actual user-data directory instead of assuming the path.
- Create a complete current baseline backup when real data may be touched.
- Record SHA-256, size, mtime, relative path, and parse status for all relevant files.
- Verify the backup matches the source before continuing.
- Prefer temp user-data, mocks, source-analysis tests, or dry runs when they can satisfy the task.

## Procedure

### Phase A - Locate

Find and confirm:

- actual user-data root;
- application/user-data name;
- `saves/` directory and save-like JSON files;
- existing backup directories;
- known test temp locations;
- whether the current command can write to real user data.

Do not rely on a remembered path if the project can provide the current path.

### Phase B - Classify

Classify each file as `CANONICAL_FULL_SAVE`, `CHECKPOINT`, `MANAGER_LOCAL_MIRROR`, `LEGACY_SAVE`, `TEST_TEMPORARY`, or `UNKNOWN`.

Use evidence from:

- save ownership docs;
- system registries;
- manager APIs;
- restore entry points;
- filename/path conventions;
- JSON schema or owner fields;
- code references.

Do not infer authority from a filename alone when the code or docs disagree.

### Phase C - Baseline Backup

Before running a command that may touch real user data:

- copy files, do not move them;
- create a timestamped backup directory;
- never overwrite older backups;
- preserve relative paths;
- record file count, size, mtime, and SHA-256;
- verify every copied file against the source SHA;
- stop if the backup is incomplete.

Do not copy large logs or irrelevant caches unless the task explicitly needs them.

### Phase D - Pre-Run Snapshot

Record:

- relative path;
- save category;
- size;
- mtime;
- SHA-256;
- JSON parse status;
- schema/version fields when present;
- a small canonical-field summary.

Do not print full sensitive save contents. Summarize structure and important counts instead.

### Phase E - Execute Controlled Run

Prefer the safest sufficient run:

- dry run or reasoning-only when no runtime proof is required;
- isolated temp user-data when available;
- source-analysis tests instead of scene boots when valid;
- real Godot/editor/smoke only when required.

Record the actual command. Do not delete, restore, or overwrite saves while a process is running.

### Phase F - Post-Run Snapshot

Compare the post-run state to the pre-run snapshot:

- added files;
- deleted files;
- SHA changes;
- mtime-only changes;
- JSON parse failures;
- structural JSON differences;
- canonical-field differences;
- schema/version differences;
- test temporary residue.

### Phase G - Classify Changes

Classify each difference:

| Result | Meaning |
|---|---|
| `NO_CHANGE` | No size, SHA, mtime, or structural difference. |
| `MTIME_ONLY` | SHA and parsed content unchanged; only mtime differs. |
| `FORMAT_ONLY` | Parsed JSON equivalent; bytes changed due to ordering/indentation/format. |
| `EXPECTED_TIMESTAMP_CHANGE` | Only known volatile timestamp fields changed. |
| `EXPECTED_MIRROR_REFRESH` | Manager-local/debug/fallback mirror refreshed without canonical progress change. |
| `EXPECTED_TEST_TEMPORARY` | Known test temp artifact created in an allowed temp path. |
| `POSSIBLE_GAME_PROGRESS` | Save may contain legitimate newer user progress. |
| `UNKNOWN` | Difference cannot be classified. |
| `SUSPICIOUS` | Change looks inconsistent with the task or expected runtime behavior. |
| `CORRUPTION` | JSON cannot parse, file is truncated, or required canonical structure is damaged. |

### Phase H - Decide

Use one final decision:

| Decision | Use when |
|---|---|
| `ACCEPT_BASELINE_STABLE` | No meaningful changes occurred. |
| `ACCEPT_WITH_EXPECTED_REFRESH` | Only expected mirror/timestamp/mtime/test-temp changes occurred. |
| `RESTORE_TEST_TEMPORARY_ONLY` | Only clear test temporary files should be removed. |
| `ESTABLISH_NEW_BASELINE` | Current data is understood and newer/current progress must be protected. |
| `REQUEST_USER_DECISION` | Data may be user progress or authority is unclear. |
| `HARD_STOP` | Canonical progress changed unexpectedly, corruption appeared, backup failed, or rollback would risk user progress. |

Never mechanically overwrite current saves with an older backup just because the old backup has known SHA values.

### Phase I - Close Out

- Delete only files proven to be `TEST_TEMPORARY` when cleanup is allowed.
- Do not overwrite newer progress.
- Save or report the classification and final decision.
- Restore task board state if used.
- Include backup path, file counts, SHA result, classification, final decision, and unresolved items in the final report.
- Do not push or tag unless the task explicitly says to.

## Decision Points

### SHA Changed but JSON Looks the Same

Check key order, indentation, line endings, float formatting, timestamp fields, and manager-local rewrite behavior. Classify as `FORMAT_ONLY`, `EXPECTED_TIMESTAMP_CHANGE`, or `EXPECTED_MIRROR_REFRESH` only when evidence supports it.

### mtime Changed but SHA Is the Same

Classify as `MTIME_ONLY`. This is not a content change.

### Current Save Is Newer Than an Old Backup

Do not roll back. Treat the old backup as analysis input only. Establish a new current baseline or ask the user.

### `full_save.json` Is Absent

Absence is not automatically a deletion. Compare pre-run and post-run existence. If absent before and after, record it as absent and continue.

### Test-Created Files Exist

Delete only when the file is definitely `TEST_TEMPORARY`, located in an allowed temp path, and cleanup is authorized. Otherwise ask.

### Canonical Progress Changed Unexpectedly

Stop with `HARD_STOP` unless the task explicitly allowed that exact canonical change.

### JSON Parse Fails

Classify as `CORRUPTION` and stop.

### Old Backup Differs Greatly from Current Data

Do not assume the backup is better. Protect current data first, then summarize the difference.

## Canonical Field Comparison

When comparing structured JSON, prefer small summaries:

- schema version;
- save timestamp;
- target scene or route;
- current day/time;
- player position/context;
- completed modules/tasks count;
- inventory/resource totals summary;
- checkpoint current module/step;
- canonical manager state presence;
- count of top-level sections or keys.

Do not output full user save data. Do not guess semantics from names when owner docs or restore code are available.

## Allowed Changes

This Skill itself does not authorize file changes. The task prompt does.

Common allowed save-side actions:

- read and hash real saves;
- copy current saves into a new backup directory;
- record a summarized diff report;
- remove known test temp files when cleanup is authorized;
- establish a new baseline when the current data is understood and should be protected.

## Forbidden Changes

Unless the user explicitly authorizes it, do not:

- overwrite current saves with older backups;
- delete `UNKNOWN`, canonical, checkpoint, manager-local, or legacy save files;
- modify save schema;
- edit real save JSON by hand;
- treat manager-local mirrors as the formal truth source;
- treat checkpoints as Full Save;
- hide save changes behind "tests passed";
- print full sensitive save contents;
- use `git add .` or `git add -A`;
- push, tag, or start the next task.

## Validation Matrix

| Validation | Required when |
|---|---|
| User-data location confirmed | Any real-data risk |
| Category classification | Any save comparison |
| Current backup and SHA verification | Any command may write real user data |
| Structured JSON parse | Any JSON save/checkpoint/mirror comparison |
| Canonical-field summary | Any canonical or checkpoint file exists |
| Old backup comparison | Any rollback or baseline-recovery question |
| Post-run snapshot | Any runtime/test command touched possible saves |
| Temp-file cleanup scan | Any test may create save artifacts |
| Final save decision | Always when this Skill is used |

Report actual file counts and classifications.

## Hard Stop Conditions

Stop and report if:

- current backup cannot be completed or verified;
- a canonical save changes unexpectedly;
- a checkpoint core state changes unexpectedly;
- JSON cannot parse;
- files are deleted unexpectedly;
- a file owner is `UNKNOWN` and action would overwrite or delete it;
- old backup would overwrite possibly newer current progress;
- the task would require production code or schema changes outside allowed scope;
- validation fails and save impact is unclear;
- task-board state cannot be restored when the task uses a board.

## Outputs

A save-integrity report should include:

- task name and owner;
- user-data root used;
- backup path;
- file count;
- SHA match result;
- save categories;
- pre/post differences;
- JSON structural summary;
- classification per changed file;
- final decision;
- unresolved items;
- allowed cleanup performed;
- forbidden cleanup avoided;
- whether rollback was used;
- whether a new baseline was established.

## Handoff Format

Use this when handing save-integrity state to another agent:

```text
### Save Integrity Handoff

- Task:
- Owner:
- User-data root:
- Backup path:
- Snapshot time:
- File count:
- SHA verification:
- Canonical files:
- Checkpoint files:
- Manager-local mirrors:
- Legacy files:
- Test temp files:
- Changes detected:
- Classification:
- Final decision:
- Cleanup performed:
- Unresolved:
- Next action:
```

## Rollback

Rollback is a user-data decision, not a reflex.

- Restore only when the user authorizes it or the task explicitly permits it.
- Prefer restoring only known test temporary artifacts.
- Do not roll back current user progress to an older backup without user decision.
- If current saves may contain newer progress, establish a new baseline and ask before destructive action.
- Keep old backups as evidence until the user decides retention.

## Examples

### Example 1 - Editor Smoke Refreshes Mirrors

Godot editor exits cleanly. Several manager-local JSON files have new mtimes but identical SHA. Classify as `MTIME_ONLY` or `EXPECTED_MIRROR_REFRESH`. Do not roll back.

### Example 2 - Old Backup Is Older Than Current Progress

A previous backup differs from current saves. The current saves may include newer user progress. Use the old backup for comparison only, create a fresh baseline, and avoid overwrite.

### Example 3 - Missing Full Save

`full_save.json` is absent before and after a test run. Record "absent before and after"; do not call it deletion.

### Example 4 - Canonical Save Changed During a Docs Task

A docs-only task triggers runtime and changes `full_save.json`. Stop with `HARD_STOP` unless the task explicitly allowed that canonical change.

## Project-Specific References

For a project using governance docs, read current save ownership and system-boundary references before applying this Skill. Examples may include:

- current project status;
- active task board;
- system registry;
- legacy registry;
- save ownership decision;
- closure reports;
- test reports that list save SHA evidence.

These are project-specific references, not universal requirements. Do not hard-code one repository's paths as the only valid context.

## Version and Maturity

Current version: `0.1.0`
Current maturity: `TRIAL`

This Skill has one controlled dry run only. Do not mark it `VALIDATED` until it has protected real user data on at least one live verification/refactor task and at least one baseline-recovery or save-system task without destructive rollback, unexplained canonical changes, or user-data loss.
