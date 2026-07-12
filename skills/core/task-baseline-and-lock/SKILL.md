---
name: task-baseline-and-lock
description: Use before starting any real repository task that may modify files, require a commit, involve Codex/Claude Code collaboration, need reviewer approval, use parallel branches or worktrees, transfer ownership, lock files, or perform final push/tag checks. Confirms Git baseline, ACTIVE_TASKS registration, unique primary owner, file/resource locks, allowed and forbidden scope, conflict detection, owner transfer, commit discipline, and clean close-out before work proceeds.
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

# Task Baseline and Lock

## Purpose

Use this Skill before any real task begins to confirm repository baseline, task uniqueness, owner, file locks, allowed scope, forbidden scope, and collaboration state.

The goal is to prevent parallel agents from modifying the same files, starting from a drifting baseline, duplicating a task, expanding scope silently, or leaving the task board in an unsafe state.

This Skill owns task lifecycle discipline. It does not decide the technical implementation, product design, test strategy, save policy, push permission, or tag permission.

## When to Use

Use when any of these are true:

- the task will modify repository files;
- the task needs a commit;
- Codex, Claude Code, or another agent may collaborate;
- file overlap or directory overlap is possible;
- ownership transfers from one agent to another;
- reviewer approval is required;
- the worktree is not clearly clean;
- the prompt baseline may not match the actual HEAD;
- parallel worktrees or branches are active;
- the task is a refactor, bug fix, production-code task, test task, governance-doc task, Skill task, scene change, or art/resource landing task;
- a push or tag is about to happen and final freeze checks are needed.

If a read-only audit later creates governance docs or commits a report, use this Skill before writing.

## Do Not Use When

You may skip or abbreviate this Skill for:

- pure question answering;
- analysis that does not touch a repository;
- read-only code review with no file writes and no commit;
- read-only file lookup;
- creative discussion outside the project;
- a dry run that modifies no files.

If the dry run produces a repository artifact, use this Skill.

## Required Inputs

The task prompt or handoff must provide:

- Task ID
- Task title
- Base commit
- Branch
- Worktree
- Owner
- Reviewer
- Mode
- Objective
- Allowed files
- Forbidden files
- Locked files
- Required tests
- Commit message
- Push permission
- Tag permission
- Handoff status

Optional inputs:

- Related Skill
- Expected ahead/behind
- Related task IDs
- Known modified files
- Backup requirements
- User-data risk
- Stop conditions

If a required input is missing and cannot be discovered safely from current project docs, write `UNRESOLVED` and stop instead of guessing.

## Baseline Procedure

Before editing files, run and record:

```text
git rev-parse HEAD
git rev-parse --abbrev-ref HEAD
git status -sb
git status --short
git diff --cached --name-only
git log --oneline --decorate -10
```

When a remote baseline matters, also run:

```text
git rev-parse origin/main
git rev-list --left-right --count origin/main...HEAD
```

Confirm:

- HEAD matches the task baseline;
- branch matches the task;
- worktree/root matches the task;
- staged files are known;
- modified files are known;
- untracked files are known;
- ahead/behind is known;
- old tasks are closed;
- ACTIVE_TASKS state is known;
- no unexpected parallel modifications exist.

If any difference appears, stop and report. Do not clean, stash, reset, checkout, merge, or rebase unless the user explicitly instructs that action.

## Task Registration

Before modifying any file, register one active task:

```text
### <Task ID> - <Task title>

- Owner:
- Reviewer:
- Mode:
- Status: `IN_PROGRESS`
- Branch:
- Worktree:
- Base commit:
- Objective:
- Allowed files:
- Forbidden files:
- Locked files:
- Required tests:
- Commit message:
- Push/tag permission:
```

Rules:

- task ID must be unique;
- do not register the same task twice;
- one task has exactly one primary owner;
- reviewer reviews by default and does not automatically modify;
- no owner means no work;
- no allowed scope means no work;
- if the task prompt and board conflict, stop and report instead of choosing.

## Ownership Model

`PRIMARY_OWNER`:

- is the only default modifier;
- executes the task;
- updates the board;
- stages and commits;
- gives the final report.

`REVIEWER`:

- checks output and risks;
- does not modify by default;
- does not automatically take over;
- must use owner transfer or a new task before fixing.

`USER`:

- decides final scope;
- accepts or rejects results;
- authorizes push or tag;
- decides owner transfer;
- resolves conflicts.

`SECONDARY_AGENT`:

- may perform read-only audit when asked;
- does not modify locked files;
- does not create a duplicate task;
- does not secretly fix issues.

## Lock Model

Support these lock types:

- file lock;
- directory lock;
- document lock;
- user-data write lock;
- push/tag permission lock.

Record each lock as:

```text
Path/resource:
Owner:
Lock type:
Reason:
Release condition:
```

Default rules:

- the same file cannot be modified by two agents at the same time;
- the same user-data directory cannot be written by two agents at the same time;
- reviewer cannot modify the owner's locked files without transfer or a new task;
- unclear lock scope is unauthorized;
- if a new file must be modified, update task scope first or stop and report.

## Allowed and Forbidden Scope

Tasks must list what is allowed:

- files that may be modified;
- files that may be created;
- tests that may be updated;
- governance docs that may be updated;
- whether `.uid` generation is allowed;
- whether scene resources are allowed;
- whether `project.godot` is allowed;
- whether user-data writes are allowed;
- whether commit, push, or tag is allowed.

Tasks must list what is forbidden:

- unlisted production systems;
- unrelated bugs;
- schema changes;
- gameplay changes;
- assets;
- JSON data;
- user saves;
- unapproved Autoloads;
- unapproved scene resources;
- unapproved remote operations.

Do not expand scope because "tests need it." Use `REQUEST_SCOPE_EXPANSION` or `HARD_STOP`.

## Parallel Work Detection

Check:

- working tree modifications;
- staged files;
- ACTIVE_TASKS active owners;
- overlapping locked files;
- branch and worktree identity;
- pending owner transfer;
- pending handoff;
- another agent running commands that can write the same user data.

If a conflict exists, return:

```text
HARD_STOP_PARALLEL_CONFLICT
```

Do not merge, stash, reset, checkout, overwrite, or continue on top of another owner's work.

## Owner Transfer

Use this format:

```text
### Owner Transfer

- Task ID:
- Task title:
- Previous owner:
- New owner:
- Reason:
- Base commit:
- Current branch:
- Current worktree:
- Working-tree state:
- Files already modified:
- Files locked:
- Completed work:
- Remaining work:
- Tests already run:
- Known failures:
- Known risks:
- Commit status:
- Push/tag status:
```

Rules:

- transfer continues the same task;
- do not create a duplicate task;
- new owner reconfirms baseline;
- if the worktree is not clean, new owner must explicitly accept existing changes;
- previous owner stops modifying after transfer;
- update board owner after transfer;
- reviewer does not become owner automatically;
- user confirms the final transfer.

## Decision Points

### HEAD Differs from Task Baseline

Return `HARD_STOP`. Do not rebase, reset, checkout, or reinterpret the task.

### Working Tree Is Not Clean

Classify modifications:

- current task changes;
- other task changes;
- generated noise;
- unknown.

Continue only when the changes clearly belong to the current registered task.

### ACTIVE_TASKS Is Not IDLE

- same task and same owner: continue after confirming scope;
- same task and different owner: require owner transfer;
- different task and no overlap: continue only if user approved parallel mode;
- overlapping files or resources: `HARD_STOP_PARALLEL_CONFLICT`.

### Unauthorized File Is Needed

Choose `REQUEST_SCOPE_EXPANSION` or `HARD_STOP`. Do not edit it silently.

### Owner Runs Out of Capacity

Record owner transfer, keep the same task ID, and let the new owner reconfirm baseline.

### Reviewer Finds a Problem

Reviewer reports it. User decides whether to return it to the owner, transfer ownership, or start a new task.

### Tests Fail at Completion

Do not mark `DONE`. Keep `IN_PROGRESS` or mark `BLOCKED` with reason.

## Task Status Model

Allowed statuses:

- `IDLE`
- `IN_PROGRESS`
- `BLOCKED`
- `READY_FOR_REVIEW`
- `DONE`
- `CANCELLED`

Rules:

- board status must match active task state;
- no active task means board status is `IDLE`;
- `DONE` requires completed validation;
- `BLOCKED` requires a reason;
- `CANCELLED` releases locks;
- `READY_FOR_REVIEW` does not allow reviewer edits by itself.

## Close-Out Procedure

Before closing:

- run required tests;
- check forbidden files;
- check diff and staged diff;
- update required governance docs;
- update current status;
- restore ACTIVE_TASKS to `IDLE`;
- set active tasks to `0`;
- set locked files to `0`;
- set pending handoffs to `0`;
- add a Recently Closed entry;
- stage exact files only;
- make one commit for one task;
- verify working tree clean after commit;
- report ahead/behind;
- do not push or tag unless explicitly authorized.

## Commit Rules

- Prefer one main commit per task.
- Use separate messages for characterization-only and production refactor work.
- Stage exact files.
- Do not use `git add .`.
- Do not use `git add -A`.
- Do not amend an accepted older task unless the user authorizes it.
- Do not force push.
- Do not push automatically.
- Do not tag automatically.
- After commit, verify board state and worktree state again.

## Hard Stop Conditions

Stop when:

- HEAD does not match;
- branch or worktree does not match;
- working tree has unknown modifications;
- ACTIVE_TASKS has a conflicting task;
- owner is unclear;
- file locks overlap;
- reviewer attempts automatic modification;
- scope expansion is needed but not approved;
- another owner is writing the same files or user data;
- staged area contains unrelated files;
- continuing would require reset, stash, or overwrite of another person's work;
- two agents may write the same user-data directory;
- required tests fail;
- board cannot return to `IDLE`;
- push/tag permission cannot be confirmed.

## Outputs

Final output should include:

- Task ID
- Base commit
- Final commit
- Owner
- Reviewer
- Working-tree state
- ahead/behind
- Allowed files
- Actual modified files
- Lock status
- Tests
- Commit
- Board state
- Handoff state
- Push/tag state
- Next task readiness

## Examples

### Example 1 - Clean Single-Owner Task

Baseline matches, worktree is clean, owner is defined, files are locked, and scope is explicit. Register the task, perform the allowed work, run validation, restore the board to `IDLE`, stage exact files, commit, and report final status.

### Example 2 - Owner Transfer

Claude Code runs out of capacity during the same task. Codex receives an owner transfer, keeps the same task ID, reconfirms baseline, accepts recorded modifications, updates board owner, completes remaining work, and does not create a duplicate task.

### Example 3 - Parallel Conflict

Two agents both need the same scene file. Return `HARD_STOP_PARALLEL_CONFLICT`. Do not stash, reset, merge, or overwrite the other owner's work.

### Example 4 - Scope Expansion

A required test reveals an unapproved file must change. Stop with `REQUEST_SCOPE_EXPANSION` or `HARD_STOP`. Do not edit the file silently.

## Skill Boundaries

`task-baseline-and-lock` owns:

- task lifecycle;
- owner and reviewer roles;
- board state;
- locks;
- scope;
- commit/push/tag permission checks.

`characterization-first-refactor` owns:

- refactor method;
- characterization;
- minimal behavior-preserving movement;
- regression proof.

`save-integrity-guard` owns:

- user-data location;
- backup;
- SHA;
- save change classification;
- rollback prevention.

These Skills are `COMPOSABLE`, not merged. A high-risk refactor may use all three, but each keeps its boundary.

## Version and Maturity

Current version: `0.1.0`
Current maturity: `TRIAL`

Do not mark this Skill `VALIDATED` until it has been used on at least two real tasks, including one clean single-owner task and one owner-transfer or parallel-conflict scenario, with no duplicate task, no lock conflict, no board registration gap, user acceptance, and revisions incorporated into at least a later `0.2.x` version.
