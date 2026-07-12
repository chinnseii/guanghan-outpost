# P5-04 Task Baseline and Lock Skill Trial

Date: 2026-07-13
Owner: Codex
Skill: `skills/core/task-baseline-and-lock/SKILL.md`
Maturity after trial: `TRIAL`

## Scope

P5-04 created the third formal repository Skill:

```text
skills/core/task-baseline-and-lock/SKILL.md
```

This task did not modify production code, tests, scenes, assets, JSON, real saves, or `project.godot`.

The dry run used simulated task-board states only.

## Dry Run A - Parallel Conflict

Input:

```text
Use skill: task-baseline-and-lock
Task ID: P5-99
Owner requested: Codex
Current ACTIVE_TASKS: another task owned by Claude Code
Both tasks lock: docs/handoff/CURRENT.md
Working tree: uncommitted change to docs/handoff/CURRENT.md
Parallel approval: not granted by user
Expected result: reject task start
```

Skill decision:

```text
HARD_STOP_PARALLEL_CONFLICT
```

Required behavior:

- Do not register a second active task.
- Do not overwrite `docs/handoff/CURRENT.md`.
- Do not stash, reset, checkout, merge, or clean the other owner's work.
- Do not take over Claude Code's task.
- Do not modify any file.
- Request a user decision: wait for the original task to close, approve owner transfer, or explicitly approve non-overlapping parallel work.

Result:

```text
PASS
```

The Skill rejects unsafe start and does not create a duplicate task.

## Dry Run B - Clean Single-Owner Start

Input:

```text
Use skill: task-baseline-and-lock
Task ID: P5-100
Owner requested: Codex
ACTIVE_TASKS: IDLE
Working tree: clean
Staged files: none
Branch/worktree: matches task prompt
Allowed files: explicit governance docs
Forbidden files: production code, tests, scenes, assets, JSON, real saves
Parallel approval: not needed
```

Skill decision:

```text
TASK_START_ALLOWED
```

Required behavior:

- Confirm Git baseline.
- Register exactly one ACTIVE_TASKS entry.
- Record owner, reviewer, mode, branch, worktree, base commit, objective, allowed files, forbidden files, locks, required tests, and push/tag permission.
- Modify only allowed files.
- Restore ACTIVE_TASKS to IDLE before close.

Result:

```text
PASS
```

The Skill allows a safe start only after baseline, owner, scope, and board state are explicit.

## Clarity Check

The Skill clearly distinguishes:

- primary owner from reviewer;
- owner transfer from duplicate task creation;
- clean worktree from unknown modifications;
- allowed scope from scope expansion;
- parallel non-overlap from locked-file conflict;
- commit permission from push/tag permission.

## Overreach Check

The Skill does not allow:

- skipping ACTIVE_TASKS;
- two primary owners;
- reviewer auto-fix;
- automatic stash/reset/checkout;
- automatic push/tag;
- silent scope expansion;
- duplicate task after owner transfer.

## Boundary with Existing Skills

| Skill | Owns | Does not own |
|---|---|---|
| `task-baseline-and-lock` | task lifecycle, owner, board, locks, scope, commit/push/tag permission | refactor mechanics or save diff classification |
| `characterization-first-refactor` | behavior baseline, minimal refactor, regression proof | ACTIVE_TASKS ownership model |
| `save-integrity-guard` | user-data backup, SHA, structured JSON diff, rollback prevention | repository task locking |

The three Skills are `COMPOSABLE`, not merged.

## Revision Need

No blocking revision was found.

Remaining maturity limitation:

- This was a simulated dry run.
- The Skill has not yet managed a live owner transfer.
- The Skill has not yet blocked a real parallel conflict in an active multi-agent worktree.

## Result

P5-04 dry run passes.

The Skill remains:

```text
TRIAL
```

Recommended next task:

```text
P5-05 - Guanghan Art Design and Production Skill
```
