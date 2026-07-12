---
name: characterization-first-refactor
description: Use for high-risk Godot or GDScript refactors where existing behavior must be preserved, especially large-script decomposition, Controller/Presenter/Evaluator extraction, save/restore or checkpoint boundary work, Manager responsibility cleanup, legacy isolation, route migration, dependency-injection changes, or UI/gameplay-flow separation. Establish characterization evidence before moving code, perform the smallest responsibility-focused refactor, and prove unchanged behavior with focused tests, historical regressions, Godot editor/smoke, save/data guards, and diff-scope checks.
version: 0.1.0
status: trial
scope: godot
agents:
  - codex
  - claude-code
project: general
maturity: trial
last_validated: 2026-07-13
---

# Characterization-First Refactor

## Purpose

Use this Skill to refactor high-risk Godot code only after recording the current behavior. Build a characterization baseline first, move one responsibility at a time, and prove that player-visible behavior, save semantics, Manager ownership, scene flow, and public call contracts did not change unless the task explicitly asks for behavior change.

This Skill guides method. The task prompt still provides current scope, owner, allowed files, forbidden files, tests, commit message, and push/tag permission.

## When to Use

Use when any of these are true:

- a target file has multiple responsibilities;
- behavior depends on execution order, `_process()`, async steps, signals, SceneTree state, or callbacks;
- existing behavior lacks focused test protection;
- methods will move between files or responsibility layers;
- extracting a Controller, Presenter, Evaluator, helper, or dependency-injected service;
- migrating static assertions after moving code;
- touching save/restore, checkpoint, Manager, scene-state, or formal-route boundaries;
- separating UI construction from gameplay flow;
- the refactor promises unchanged behavior but regression risk is higher than a small edit.

## Do Not Use When

Do not use for:

- documentation-only edits;
- explicit new feature development;
- gameplay-rule or numeric-balance redesign;
- UI redesign where behavior is intended to change;
- tiny spelling/text fixes;
- mechanical renames already covered by strong tests;
- tasks where the user explicitly requests behavior change;
- work that needs an unresolved architecture/product decision first;
- dirty worktrees or unclear ownership;
- simultaneous multi-agent edits to the same file.

Do not disguise a feature request as a behavior-preserving refactor.

## Required Inputs

The task prompt must provide:

- Base commit
- Target files
- Task objective
- Behavior that must remain unchanged
- Allowed files
- Forbidden files
- Required tests
- Save/data protection requirements
- Commit message
- Push/tag permission
- Owner
- Reviewer

Optional inputs:

- Expected line reduction
- Known high-risk fields
- Existing test files
- Related Managers
- Scene paths
- User-data path
- Rollback point

If a required input is missing and cannot be discovered safely from current project docs, stop and report `UNRESOLVED` instead of guessing.

## Preconditions

Before editing production files:

- Confirm Git baseline, ahead/behind, clean worktree, and empty staged area.
- Register the task in the active task board or equivalent coordination document.
- Confirm a single implementation owner.
- Read current project status and relevant registries/docs.
- Identify existing test entry points.
- Protect real saves or user data when scene boot, Manager load, or Godot tests may write to them.
- Confirm no unresolved parallel edits affect the same files.
- Confirm the user approved the task objective.

This Skill never assigns itself ownership and never replaces task registration.

## Procedure

### Phase A - Baseline

Record current HEAD, origin/base reference, ahead/behind, worktree status, active task board state, target file line counts and major functions, existing tests and warnings, and real-save or user-data SHA when the task may write outside the repository.

### Phase B - Responsibility and Coupling Audit

Map responsibility blocks, fields read/written by each block, external callers, public methods, Manager dependencies, SceneTree dependencies, signals, async flow, save/checkpoint boundaries, and route dependencies.

Classify candidates as `MOVE`, `KEEP`, `PARTIAL`, `CHARACTERIZE_ONLY`, `INTERFACE_PREPARATION`, `BLOCKED`, or `HARD_STOP`.

### Phase C - Characterization First

Before the refactor, add or identify focused characterization tests. Lock behavior without overfitting unrelated implementation details, ignore comments when doing static source assertions, avoid booting autosaving scenes when source-analysis tests can cover the boundary, and run characterization tests on the unchanged baseline.

If characterization cannot be established, stop or convert the task to audit-only.

### Phase D - Minimal Refactor

Refactor only after Phase C passes. Move exactly one responsibility at a time, keep call sites and player behavior stable, retain thin wrappers when they reduce call-site churn, avoid copying canonical state into a second owner, avoid adding Autoloads, avoid scene-resource edits unless approved, and avoid slipping in gameplay, UI, text, or balance changes.

### Phase E - Test Migration

After moving code, migrate static assertions to the new responsibility owner, replace rather than delete important assertions, keep historical boundary tests meaningful, and adjust tests for path/class movement only when behavior is unchanged.

### Phase F - Validation

Run validation scaled to risk: focused tests, relevant historical regressions, full regression when touching shared systems, Godot editor parse for `.gd` changes, Godot smoke for runtime changes, save/user-data SHA checks when applicable, forbidden-file scans, diff-scope scans, `git diff --check`, final clean worktree, and active task board restored before close.

### Phase G - Close-Out

Update only required docs, restore the task board to IDLE, stage exact files, commit once, and report the evidence. Do not push or tag unless the task explicitly authorizes it.

## Decision Points

### Safe Movement Is Too Small

If moving code requires many shared fields, implicit `_process()` order, multiple Manager writes, scene-resource edits, schema edits, or fragile async state, choose `CHARACTERIZE_ONLY`, `INTERFACE_PREPARATION`, `KEEP_IN_SCENE`, or `HARD_STOP`. Do not force an extraction to reduce line count.

### UI and Gameplay Are Mixed

Move UI construction or display-only presentation only when gameplay mutation, correctness checks, task completion, checkpoint writes, and scene transitions stay in the original owner or behind explicit intent callbacks.

### Static Tests Fail for the Wrong Reason

If a source scan matches comments or documentation strings, refine the scan or strip comments. Do not change production code to satisfy a brittle test.

### Real Saves Change

If tests or Godot runs touch real saves, classify the source, compare structured JSON and SHA when possible, never overwrite newer user progress with an older backup, establish a new baseline only when the change is understood and accepted, and stop on unexplained canonical progress changes.

### Audit Findings Contradict the Task

You may reduce scope based on evidence, but must document why. Do not expand scope without user approval.

## Allowed Changes

The task prompt defines the allowed files. By default, a characterization-first refactor may modify target production files, one new extracted component, focused tests, existing tests whose assertions need path/owner migration, and necessary governance/current-status docs.

## Forbidden Changes

Unless explicitly allowed by the task prompt, do not:

- add new features;
- fix unrelated bugs;
- change gameplay rules, numbers, text, or UI design;
- change save schema or checkpoint format;
- create a second truth source for state;
- create a broad host object that owns too much;
- use vague SceneTree lookups when explicit references or injection are safer;
- add an Autoload;
- delete old assertions without migrating them;
- use `git add .` or `git add -A`;
- push, tag, or start the next task;
- skip task-board registration;
- let two agents edit the same file concurrently.

## Validation Matrix

| Validation | Required when |
|---|---|
| Focused characterization | Always |
| Focused refactor test | Always for production refactors |
| Related historical regression | Always |
| Full regression | High-risk shared behavior |
| Godot editor parse | Any `.gd` change |
| Godot smoke | Any runtime change |
| Save SHA guard | Save, Manager, checkpoint, scene boot, or user-data risk |
| Forbidden-file scan | Always |
| Diff check | Always |
| Working tree clean | Before final report |
| Task board IDLE | Before final commit or close |

Report actual check counts and exit codes. Do not replace evidence with "tests passed." Classify warnings and restore or baseline any test side effects.

## Hard Stop Conditions

Stop and report if baseline does not match the task, the worktree is dirty before starting, ownership is unclear, characterization cannot be created, current behavior is unknown, required changes exceed allowed files, schema/gameplay/player behavior/Autoload changes become necessary without approval, regressions fail, editor/smoke fails, real-save changes cannot be explained, a P0/P1 architecture gap appears, another agent is changing the same file, or the task board cannot be restored to IDLE.

## Outputs

Final reports should include baseline state, responsibility and coupling audit, characterization evidence, actual change scope, unchanged-behavior evidence, new component boundary, logic left in the original file, test counts, Godot editor/smoke results, save/data state, modified files, commit, final Git status, next task readiness, and push/tag status.

## Handoff Format

Use this when ownership transfers:

```text
### Owner Transfer

- Task:
- Previous owner:
- New owner:
- Reason:
- Base commit:
- Current working-tree state:
- Completed work:
- Remaining work:
- Files already modified:
- Tests already run:
- Known risks:
- Push/tag status:
```

Owner transfer continues the same task. The new owner must reconfirm baseline before working. Reviewers do not become implementation owners unless the task explicitly says so.

## Rollback

- Keep each refactor to one commit when possible.
- Prefer `git revert <commit>` for rollback.
- Do not rely on manual code reconstruction.
- Copy real saves for backup; do not move them.
- Do not overwrite newer user progress with older backups.
- Do not mark half-finished work as DONE.
- Use a distinct commit message for characterization-only or audit-only outcomes.

## Examples

### Example 1 - Controller Extraction

Move a dev-only or route-only controller out of a large scene after characterization proves the old buttons, route priority, and debug action effects. Keep formal gameplay paths independent of dev controllers.

### Example 2 - Presenter Extraction

Move display-only UI construction into a presenter. Keep gameplay mutation, answer correctness, task advancement, checkpoint writes, and scene changes in the scene, exposed through one-way intent callbacks.

### Example 3 - Safe Non-Extraction

If navigation, task flow, and scene state are deeply coupled, extract only pure target calculation or stop at characterization/interface preparation. A small safe reduction is better than a risky line-count win.

## Project-Specific References

For a project using governance docs, read the relevant current references before applying this Skill. Examples may include current project status, active task board, system registry, scene registry, save ownership decision, closure reports, and existing regression test suites.

These are project-specific references, not universal requirements. Do not hard-code one repository's paths as the Skill's only valid context.

## Version and Maturity

Current version: `0.1.0`
Current maturity: `TRIAL`

Do not mark this Skill `VALIDATED` until it has guided at least two different real refactor tasks, including at least one Controller extraction and at least one Presenter, Evaluator, or `CHARACTERIZE_ONLY` task, with no serious scope expansion and with user acceptance.
