# P5-03 Save Integrity Guard Skill Trial

Date: 2026-07-13
Owner: Codex
Skill: `skills/core/save-integrity-guard/SKILL.md`
Maturity after trial: `TRIAL`

## Scope

P5-03 created the second formal repository Skill:

```text
skills/core/save-integrity-guard/SKILL.md
```

This task did not run a real save mutation scenario and did not modify real Godot user data. The trial is a controlled dry run using the known P4-08 save-baseline facts.

## Inputs

Scenario:

```text
Phase 4 closure after prior verification refreshed manager-local saves.
```

Known facts from P4-08:

| Fact | Value |
|---|---|
| Old backup | `2026-07-11` backup |
| Current baseline backup | `saves_backup_before_p4_08_2026-07-12_234110` |
| Source file count | 19 |
| Backup file count | 19 |
| Source/backup SHA | 19/19 matched |
| Post-run SHA | unchanged |
| JSON mtime refresh | 14 files |
| `full_save.json` | absent before and after |
| Allowed changes in this trial | none; reasoning-only dry run |

## Skill Walkthrough

### Locate

The dry run treats the P4-08 current baseline backup as the protected current state. The older 2026-07-11 backup is comparison evidence only.

### Classify

The changed runtime files are classified as manager-local or training/local mirror data unless the P4-08 report identified canonical progress. `full_save.json` is not classified as deleted because it was absent before and after the run.

### Baseline Backup

The P4-08 baseline already satisfied the Skill requirement:

```text
source count = 19
backup count = 19
source/backup SHA match = 19/19
```

### Pre/Post Snapshot

The dry-run interpretation is:

- content SHA unchanged after P4-08 verification;
- JSON files had mtime refreshes only;
- no canonical Full Save appeared, disappeared, or changed;
- no `training_progress.json` core progress change was reported.

### Classification

| Observation | Classification | Reason |
|---|---|---|
| Current data differs from 2026-07-11 backup | `POSSIBLE_GAME_PROGRESS` / analysis-only old backup | The old backup may predate newer user progress, so it must not overwrite current data. |
| P4-08 source and new backup SHA all match | `NO_CHANGE` for backup copy integrity | The current baseline copy was verified. |
| Post-run content SHA unchanged | `NO_CHANGE` | No content mutation was observed after P4-08 verification. |
| 14 JSON files had mtime refresh | `MTIME_ONLY` / `EXPECTED_MIRROR_REFRESH` | mtime-only change is not content change; P4-08 identified it as manager/training mirror refresh. |
| `full_save.json` absent before and after | `NO_CHANGE` | Absence before and after is not deletion. |

## Decision

Final dry-run decision:

```text
SAVE_BASELINE_STABLE_WITH_EXPECTED_REFRESH
```

Mapped to the Skill decision vocabulary:

```text
ACCEPT_WITH_EXPECTED_REFRESH
```

## Rollback Decision

The Skill correctly refuses mechanical rollback:

- Do not use the 2026-07-11 backup to overwrite current data.
- Treat the older backup as analysis evidence only.
- Protect the newer current baseline established by P4-08.
- mtime-only changes are not content changes.
- absent `full_save.json` before and after is not a deletion event.

## Boundary with Characterization Skill

`characterization-first-refactor` and `save-integrity-guard` are composable, not merged.

| Skill | Owns | Does not own |
|---|---|---|
| `characterization-first-refactor` | behavior baseline, refactor boundary, focused tests, unchanged-behavior proof | real user-data backup policy or rollback decisions |
| `save-integrity-guard` | user-data location, backup, SHA, JSON diff, save classification, rollback prevention, new baseline decision | production refactor strategy or code movement |

A high-risk Godot refactor can invoke both. The refactor Skill decides how to move code safely; the save Skill decides how to protect real user data before and after risky runs.

## Ambiguity

No blocking ambiguity was found in this dry run.

Remaining maturity limitation:

- This was reasoning-only and used P4-08 facts.
- The Skill has not yet protected a new live Godot run with a fresh save backup during its own task.
- The Skill has not yet handled an actual `UNKNOWN`, `SUSPICIOUS`, or `CORRUPTION` file.

## Destructive Tendency Check

The Skill does not authorize:

- automatic rollback;
- overwriting current saves with old backups;
- deleting unknown save files;
- treating manager-local mirrors as canonical progress;
- treating checkpoints as Full Save;
- hiding save changes behind general test success.

## Result

P5-03 dry run passes.

The Skill remains:

```text
TRIAL
```

Recommended next task:

```text
P5-04 - Task Baseline and Lock Skill
```
