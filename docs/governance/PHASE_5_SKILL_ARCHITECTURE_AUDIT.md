# Phase 5 Skill Architecture Audit

Date: 2026-07-13
Owner: Codex
Base commit: `219cc8d`
Scope: P5-01 audit only. No production code, tests, scenes, assets, `project.godot`, formal Skill directory, or `SKILL.md` was added.

## 1. Scope

This audit designs the repository-level Skill architecture for Guanghan Outpost after Phase 3 system-boundary cleanup and Phase 4 large-script decomposition were verified and closed.

The output is a plan, not an implementation. Phase 5 starts here, but P5-02 is not executed in this task.

## 2. Why Skills Are Needed

The project now has repeated, validated workflows that are too long to keep retyping in every task prompt:

- baseline and task-board registration before touching files;
- save and restore truth-source protection;
- characterization-first refactors for large Godot scripts;
- source-analysis tests that avoid booting autosaving scenes;
- closure reports that separate fixed risks from deferred risks;
- owner transfer without treating the continuation as a new task;
- art direction and Godot handoff boundaries.

Skills should preserve those repeatable methods while task prompts continue to provide current commit, allowed files, exact tests, and stop conditions.

## 3. Evidence from Phases 1-4

| Workflow | Evidence files | Used in real task | Repeated successfully | Stable enough for Skill | Notes |
|---|---|---|---|---|---|
| Repository hygiene | `DOCUMENT_GOVERNANCE_AUDIT.md`, tags `repository-hygiene-complete-2026-07-11`, `.gitignore` history | Yes | Yes | `VALIDATED`, `GENERALIZABLE` | Good as background, not first Skill. |
| Document governance | `DOCUMENT_GOVERNANCE_AUDIT.md`, `README.md`, `CURRENT.md`, `ACTIVE_TASKS.md` | Yes | Yes | `VALIDATED`, `GENERALIZABLE` | Strong source for task-board and current-state rules. |
| System-boundary audit | `PHASE_3_SYSTEM_BOUNDARY_AUDIT.md`, `SYSTEM_REGISTRY.md`, `LEGACY_REGISTRY.md` | Yes | Yes | `VALIDATED`, `PROJECT_SPECIFIC` | Should become a Skill because it has a repeatable inventory and risk report shape. |
| Save architecture change | `PHASE_3_SAVE_OWNERSHIP_DECISION.md`, `FullSaveOrchestrator`, P3-03b/c/d docs | Yes | Yes | `VALIDATED`, `PROJECT_SPECIFIC` | Best folded into save-integrity guard plus system-boundary audit. |
| Restore consistency | `tests/p3_03a_restore_consistency_test.gd`, P3-03a/c verification notes | Yes | Yes | `VALIDATED`, `PROJECT_SPECIFIC` | Works as validation procedure rather than standalone first Skill. |
| Manager responsibility audit | `PHASE_3_CLOSURE_REPORT.md`, `tests/p3_04_manager_responsibility_boundary_test.gd` | Yes | Yes | `VALIDATED`, `PROJECT_SPECIFIC` | Candidate `system-boundary-audit`. |
| Legacy isolation | `LEGACY_REGISTRY.md`, `tests/p3_05_legacy_runtime_isolation_test.gd` | Yes | Yes | `VALIDATED`, `PROJECT_SPECIFIC` | Keep as project references; Skill should point to registries. |
| Large-script decomposition audit | `PHASE_4_LARGE_SCRIPT_AUDIT.md`, P4-06A/P4-07A audits | Yes | Yes | `VALIDATED`, `GODOT` | Strong candidate for `characterization-first-refactor`. |
| Characterization-first refactor | P4-02 through P4-07B tests and closure report | Yes | Yes | `VALIDATED`, `GODOT` | Best first Skill target. |
| Controller/Presenter extraction | `dev_tools_controller`, `formal_flow_router`, `base_hud_panel_presenter`, `training_module_screen_presenter` tests | Yes | Yes | `VALIDATED`, `GODOT` | Should be child/specialized Skills after the generic refactor Skill. |
| Regression closure | `PHASE_4_CLOSURE_REPORT.md`, P3/P4 regression evidence | Yes | Yes | `VALIDATED`, `GENERALIZABLE` | Good Wave 1 or Wave 2 Skill. |
| Save-baseline protection | P4-08 save baseline table, P3 save SHA checks | Yes | Yes | `VALIDATED`, `PROJECT_SPECIFIC` | Must be a Skill because failures can damage user progress. |
| Owner transfer | P4-07B owner transfer note, `AGENT_WORKFLOW.md` | Yes | Partially | `PARTIALLY_VALIDATED`, `GENERALIZABLE` | Useful, but not first; keep concise. |
| Product/UX acceptance | screenshot folders, sprint acceptance docs, `PROJECT_BRIEF.md` | Yes | Yes | `PARTIALLY_VALIDATED`, `PROJECT_SPECIFIC` | Needs separate GPT-facing acceptance Skill later. |
| Art asset production | `docs/art/**`, `SPRITE_GUIDE.md`, art target readmes | Yes | Partially | `PARTIALLY_VALIDATED`, `PROJECT_SPECIFIC` | Needs split design/production vs review/handoff. |
| Art review and Godot handoff | `ASSET_OLD_BASE_ART_SLICE.md`, art reference integration screenshots | Yes | Partially | `PARTIALLY_VALIDATED`, `PROJECT_SPECIFIC` | Good Wave 2 candidate. |
| Bug ticket formatting | `COLLABORATION_RULES.md` human -> GPT -> ticket flow | Yes | Partially | `DOCUMENTED_ONLY`, `GENERALIZABLE` | Keep as template or small Skill later. |
| Agent implementation report review | `COLLABORATION_RULES.md`, closure reports | Yes | Partially | `PARTIALLY_VALIDATED`, `PROJECT_SPECIFIC` | Better as GPT role rule plus checklist. |

## 4. Skill vs Project Doc vs Role vs Task Prompt

| Layer | Responsibility | Exclusions | Lifecycle | Typical contents |
|---|---|---|---|---|
| Skill | Repeatable method for a task class. Teaches procedure, inputs, outputs, validation, hard stops, and handoff format. | Does not set current scope, owner, commit, allowed files, or approval to push/tag. Does not replace ACTIVE_TASKS. | Versioned, trialed, validated, deprecated. | Method, decision points, forbidden changes, validation, examples, references. |
| Project docs | Current facts and authority: system owners, scene status, product direction, art targets, cleanup status. | Should not contain full step-by-step agent operating scripts for every recurring task. | Updated as project truth changes. | Registries, briefs, closure reports, current status. |
| Agent role | Stable division of labor and behavioral constraints for Codex, Claude Code, GPT, and humans. | Should not hard-code task-specific files or tests. | Slow-changing collaboration policy. | Who usually owns logic, scene/UI, product review, or art direction. |
| Task prompt | Current command: baseline, exact scope, allowed files, tests, commit message, and stop conditions. | Should not restate every long-lived method in full. | One task only. | Base commit, target files, current risk, exact acceptance, commit/push/tag instruction. |

Core answer: Skills should contain repo paths and class names only as references and examples, not as permanent scope authority. Current scope must come from the task prompt and current registries.

## 5. Proposed Skill Layers

Recommended model:

1. Core Governance Skills: cross-project and multi-agent methods such as baseline/lock, owner transfer, regression closure, save protection.
2. Godot Engineering Skills: Godot/GDScript methods such as characterization-first refactor, controller extraction, presenter extraction, source-analysis tests.
3. Guanghan Project Skills: project-specific workflows that rely on Guanghan registries, save model, art direction, or product tone.
4. Agent-specific Operating Guides: not repository Skills. These remain role instructions or collaborator rules for Codex, Claude Code, GPT, and humans.

This avoids mixing method, project facts, and personality/role rules into one brittle document.

## 6. Directory Recommendation

Current directory audit:

| Path | Exists now | Decision |
|---|---|---|
| `skills/` | no | Recommended future formal Skill root. |
| `.skill/` | no | Do not use; nonstandard and less discoverable. |
| `.github/` | no | Do not use for Skills; would imply GitHub workflow ownership. |
| `agents/` | no | Do not create yet; agent roles already live in handoff/governance docs. |
| `docs/skills/` | no | Do not use as formal Skill root; would blur docs vs executable Skill packages. |
| `docs/agents/` | no | Do not create in P5-01. |
| `.codex/` | no | Do not create repo-local agent config in this task. |
| `.claude/` | no | Do not create repo-local agent config in this task. |

Recommended future formal directory scheme:

```text
skills/
  core/<skill-name>/SKILL.md
  godot/<skill-name>/SKILL.md
  guanghan/<skill-name>/SKILL.md
```

Recommended future registry path:

```text
skills/SKILL_REGISTRY.md
```

Rationale: version-controlled, discoverable by all agents, clearly separated from ordinary governance docs, and compatible with a layered catalog. Do not create the registry until the first formal Skill is implemented.

## 7. Skill File Standard

Required sections for future `SKILL.md` files:

- Purpose
- When to Use
- Do Not Use When
- Required Inputs
- Preconditions
- Procedure
- Decision Points
- Allowed Changes
- Forbidden Changes
- Validation
- Hard Stop Conditions
- Outputs
- Handoff Format
- Examples
- Project-specific References
- Version and Maturity

Recommended optional fields:

- Owner
- Compatible Agents
- Tool Requirements
- Expected Artifacts
- Rollback
- Security/Data Protection
- Save Protection
- Token Budget
- Failure Modes

Keep Skills concise. If a Skill needs many pages of project-specific facts, move those facts to project docs and link them.

## 8. Metadata Standard

Minimal future front matter:

```yaml
name: characterization-first-refactor
version: 0.1.0
status: trial
scope: godot
agents: [codex, claude-code]
project: guanghan-outpost
maturity: trial
last_validated: 2026-07-13
```

Allowed values:

- `status` / `maturity`: `draft`, `trial`, `validated`, `deprecated`
- `scope`: `general`, `godot`, `guanghan`
- `agents`: `codex`, `claude-code`, `chatgpt`, `human`

Do not over-design a schema before at least one Skill has been trialed.

## 9. Invocation Pattern

Task prompts should use this header:

```text
Use skill: characterization-first-refactor
Task-specific context:
- Base commit:
- Target file:
- Allowed files:
- Forbidden files:
- Required tests:
- Commit message:
```

Rules:

- The Skill provides the long-term method.
- The task prompt provides the current baseline, scope, allowed files, tests, and commit/push/tag instruction.
- A Skill does not silently expand scope.
- A Skill does not replace user approval, ACTIVE_TASKS registration, or hard stop conditions.
- A Skill does not decide to push, tag, or start the next phase.

## 10. ACTIVE_TASKS Integration

- Every implementation or verification task still registers in `docs/handoff/ACTIVE_TASKS.md`.
- The task prompt sets owner and reviewer. A Skill may explain the registration shape, but never chooses ownership.
- One task may compose one to three Skills. More than three suggests the task is too broad.
- No two agents may own the same file or shared subsystem at the same time.
- Reviewers review by default; they do not become implementation owner unless the task explicitly transfers ownership.
- Owner transfer preserves the same task identity and records source commit, destination owner, modified files, risks, and verification.

## 11. Candidate Skill Catalog

| Skill | Layer | Purpose | Trigger | Inputs | Outputs | Agents | Evidence | Maturity | Overlap | Exclusions | Length | Priority | Recommendation |
|---|---|---|---|---|---|---|---|---|---|---|---:|---|---|
| `task-baseline-and-lock` | Core | Confirm Git/project baseline and register ACTIVE_TASKS before work. | Any nontrivial task. | Base commit, branch, allowed files. | Board entry, baseline report. | Codex, Claude, human | `ACTIVE_TASKS.md`, `AGENT_WORKFLOW.md` | validated | owner-transfer | Does not implement code. | short | Wave 1 | `BUILD` |
| `characterization-first-refactor` | Godot | Audit behavior before extracting code, write characterization tests, then refactor minimally. | Any large-script or tier-1 extraction. | Target file, boundary, forbidden changes, tests. | Audit notes, focused tests, safe refactor plan. | Codex, Claude | P4-02..P4-07B | validated | controller/presenter extraction | Does not pick product scope or push. | medium | Wave 1 / P5-02 | `BUILD` |
| `regression-and-closure` | Core | Close a phase/task with full verification, docs, status, and clean git state. | End of phase or high-risk batch. | Required tests, docs, save policy. | Closure report, CURRENT/ACTIVE updates, commit. | Codex, Claude | P3-06, P4-08 | validated | save-integrity | Does not modify production code unless failure path says so. | medium | Wave 1 | `BUILD` |
| `save-integrity-guard` | Guanghan | Protect real saves, compare SHA/JSON, classify changes. | Any Godot/test run that may touch `user://saves`. | User data path, backup path, allowed changes. | Backup, SHA table, classification. | Codex, Claude | P3/P4 save checks, P4-08 | validated | regression closure | Does not restore old backups automatically. | medium | Wave 1 | `BUILD` |
| `owner-transfer-and-handoff` | Core | Continue an existing task after agent interruption without duplicating ownership. | Quota interruption or handoff. | From/to owner, commits, files, risks. | Handoff note, resumed task status. | Codex, Claude, human | P4-07B, `AGENT_WORKFLOW.md` | trial | task-baseline | Does not use dirty handoff worktrees. | short | Wave 2 | `BUILD` |
| `godot-controller-extraction` | Godot | Extract logic/controller helper with injected dependencies and no Autoload. | Controller-like code block. | Host file, candidate methods, tests. | Controller class, tests, boundaries. | Codex, Claude | DevToolsController, FormalFlowRouter, BaseNavigationController | validated | characterization-first | Child of generic refactor. | medium | Wave 2 | `PARENT_CHILD` |
| `godot-presenter-extraction` | Godot | Extract display-only UI construction/presentation while leaving flow in scene. | HUD/panel/screen UI extraction. | Scene UI block, callbacks, no-flow list. | Presenter class, re-expose pattern, tests. | Codex, Claude | BaseHudPanelPresenter, TrainingModuleScreenPresenter | validated | controller extraction | Child of generic refactor. | medium | Wave 2 | `PARENT_CHILD` |
| `system-boundary-audit` | Guanghan | Inventory autoloads/managers, owners, mirrors, dependencies, direct writes. | Boundary or Manager responsibility task. | Registries, project.godot, manager files. | P0/P1/P2/P3 risk report. | Codex, Claude | P3-01/P3-04 | validated | save architecture | Does not redesign gameplay. | medium | Wave 2 | `BUILD` |
| `art-asset-production` | Guanghan | Produce or specify pixel asset targets matching Guanghan visual direction. | New scene/object art request. | Scene goal, dimensions, existing art refs. | Prompt/spec, asset breakdown, naming. | GPT, human, Claude | `PROJECT_BRIEF.md`, `SPRITE_GUIDE.md`, `docs/art/**` | trial | art-scene-design | Does not edit code. | medium | Wave 2 | `MERGE` into `art-design-and-production` |
| `art-review-and-godot-handoff` | Guanghan | Review produced art and translate it into Godot placement/resource instructions. | Art ready for integration. | Asset image/spec, target scene, constraints. | Review notes, reusable object list, handoff. | GPT, human, Claude | `ASSET_OLD_BASE_ART_SLICE.md`, art integration screenshots | trial | product acceptance | Does not alter gameplay logic. | medium | Wave 2 | `BUILD` |
| `bug-ticket-formatter` | Core | Convert human playtest feedback into structured, implementation-neutral bug tickets. | User reports a gameplay bug. | Symptoms, repro, expected/actual, screenshots. | Bug ticket with scope-neutral wording. | GPT, human | `COLLABORATION_RULES.md` | documented | product acceptance | Does not assign Codex vs Claude. | short | Wave 3 | `SKILL_PLUS_TEMPLATE` |
| `product-experience-acceptance` | Guanghan | Review screenshots/reports against project brief and player experience goals. | Acceptance/review request. | Screenshots, report, brief. | Product-level pass/fail and notes. | GPT, human | `PROJECT_BRIEF.md`, screenshot evidence | trial | art review | Does not judge code ownership. | medium | Wave 3 | `SKILL_PLUS_ROLE_RULE` |

## 12. Overlap and Merge Decisions

| Overlap | Decision | Reason |
|---|---|---|
| baseline vs owner-transfer | `KEEP_SEPARATE` | Baseline is every task; owner transfer is an exceptional lifecycle event. |
| regression-and-closure vs save-integrity | `PARENT_CHILD` | Closure may invoke save guard, but save guard is independently critical before risky Godot runs. |
| controller vs presenter extraction | `PARENT_CHILD` | Both derive from characterization-first refactor; UI-only presenter has different forbidden changes. |
| system-boundary vs save-architecture | `PARENT_CHILD` | Save architecture is one domain inside system boundaries; keep separate only when changing save authority. |
| art-asset-production vs art-scene-design | `MERGE` | Current evidence is not strong enough to maintain two production Skills; design and production share inputs/outputs. |
| art-review-and-handoff vs product-experience-acceptance | `KEEP_SEPARATE` | Art handoff gives Godot placement/resource guidance; product acceptance judges player-facing experience. |

## 13. Art Skill Architecture

Recommendation: **C. two Skills**

1. `guanghan-art-design-and-production`
2. `guanghan-art-review-and-godot-handoff`

Why not one combined Skill: production and review have different triggers and outputs. A single Skill would become too broad and would blur "make/spec art" with "approve and hand off to implementation."

Why not three Skills: current evidence does not yet justify splitting scene design from asset production. Most existing art docs combine mood, composition, required reusable objects, and implementation notes in the same README.

Fixed visual direction belongs in the custom GPT role and project docs:

- 2D pixel style;
- top-down readability and modular/tile structure;
- low-saturation lunar industrial base;
- cool gray metal, small orange warning accents;
- sparse plant green;
- use/wear/repair traces;
- lonely, restrained, hopeful relay-in-extreme-environment life feel.

Layer split:

- Custom GPT instruction: long-term art director role and stable taste.
- Skill: repeatable workflow for art prompt/spec/review/handoff.
- `PROJECT_BRIEF.md`, `SPRITE_GUIDE.md`, `docs/art/**`: factual visual direction and target references.
- Task prompt: scene, size, delivery target, current constraints.

Art Skill exclusions:

- no code modification;
- no gameplay numbers;
- no replacing map building with concept art;
- no directing Codex/Claude file ownership without a task prompt.

## 14. Skill Validation Lifecycle

Lifecycle:

1. `draft`: written but not used on a real task.
2. `trial`: used on one real task, with notes.
3. `validated`: used successfully at least twice or once on a high-value task with strong regression evidence.
4. `deprecated`: replaced or stale; keep for history until safe to remove.

Recommended lightweight tracking:

- future `skills/SKILL_REGISTRY.md`: one row per Skill with status, owner, last validated date, evidence commit.
- each Skill keeps a small Examples section, not a long changelog.
- closure docs record which Skill was used when relevant.

Staleness guard:

- Skills link to registries instead of copying live system lists.
- If a Skill's references are stale, task must stop or mark `UNRESOLVED`.
- Version bump when procedure or required validation changes.

Usability validation:

- A different agent can follow the Skill with only a task-specific header.
- The Skill produces the expected artifact without expanding scope.
- Hard stop conditions are clear enough to prevent guessing.

## 15. Wave Plan

Wave 1, maximum 3:

1. `characterization-first-refactor`
2. `task-baseline-and-lock`
3. `save-integrity-guard`

Wave 2, maximum 4:

1. `regression-and-closure`
2. `system-boundary-audit`
3. `godot-presenter-extraction`
4. `guanghan-art-design-and-production`

Wave 3 deferred:

- `owner-transfer-and-handoff`
- `godot-controller-extraction`
- `guanghan-art-review-and-godot-handoff`
- `bug-ticket-formatter`
- `product-experience-acceptance`

## 16. Unique P5-02 Recommendation

P5-02 should build exactly one Skill:

```text
skills/godot/characterization-first-refactor/SKILL.md
```

Why first:

- It is the strongest validated repeatable method from Phase 4.
- It reduces the highest implementation risk: moving Godot code before locking behavior.
- It is useful for Codex and Claude Code.
- It can reference P4 evidence without being Guanghan-only.
- It will provide a parent method for later controller/presenter extraction Skills.

Why not the others first:

- `task-baseline-and-lock` is important but mostly codifies existing board rules and gives less engineering leverage.
- `save-integrity-guard` is critical but narrower and often invoked as a subroutine.
- `regression-and-closure` is best after at least one Skill has been trialed.
- Art Skills are important for the user's long-term GPT art-director workflow, but starting with art would not validate the engineering Skill layer that Phase 5 is expected to establish.

Expected P5-02 details:

- Agents: Codex, Claude Code.
- Status after creation: `trial`, not `validated`.
- Trial: use it on the next small Godot refactor or audit-derived extraction, with exact task prompt scope.
- Exclusions: no automatic production refactor during P5-02 unless explicitly requested; no push/tag; no expansion into presenter/controller child Skills.

## 17. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Skill replaces current task scope and silently expands files. | P1 | Invocation pattern says task prompt owns scope; Skill forbids expansion. |
| Skill copies stale system facts. | P1 | Link to registries; do not duplicate live owner lists except as examples. |
| Too many Skills created at once. | P2 | Wave plan caps Wave 1 at three and P5-02 at one. |
| Art Skills blur role, facts, and workflow. | P2 | Two-Skill split plus explicit custom GPT / project doc / task prompt boundaries. |
| Save guard becomes optional despite real-save risk. | P2 | Make it Wave 1 and child of closure workflows. |
| Agent-specific behavior leaks into reusable Skill. | P3 | Keep agent roles in collaboration docs; Skill lists compatible agents only. |
| Skills become too long to use. | P3 | Require concise sections and external references for project facts. |

## 18. Acceptance Criteria

P5-01 is accepted if:

- workflow evidence has been inventoried;
- Skill vs project doc vs role vs task prompt boundaries are explicit;
- one directory scheme is recommended;
- file and metadata standards are defined;
- ACTIVE_TASKS integration is clear;
- candidate catalog has priorities and merge decisions;
- art Skill architecture has one recommendation;
- exactly one P5-02 target is selected;
- no production code, tests, scenes, assets, formal Skill directory, or `SKILL.md` was added;
- Godot editor and smoke pass.

## 19. P5-02 Implementation Note

P5-02 completed the first formal repository Skill:

```text
skills/godot/characterization-first-refactor/SKILL.md
```

The formal Skill registry now exists at:

```text
skills/SKILL_REGISTRY.md
```

Current maturity:

```text
characterization-first-refactor = TRIAL
```

The Skill was exercised through a controlled dry run documented in:

```text
docs/governance/P5_02_CHARACTERIZATION_SKILL_TRIAL.md
```

Dry-run result:

- The Skill correctly accepted the audit-only task context.
- The sample target `scripts/training/training_base_map.gd` led to `KEEP_IN_SCENE` / `CHARACTERIZE_ONLY` / `INTERFACE_PREPARATION`, not an unsafe extraction.
- No production code, tests, scenes, assets, JSON, real saves, or `project.godot` were modified.
- The Skill remains `TRIAL`, not `VALIDATED`.

Next recommended task:

```text
P5-03 - Save Integrity Guard Skill
```

## 20. P5-03 Implementation Note

P5-03 completed the second formal repository Skill:

```text
skills/core/save-integrity-guard/SKILL.md
```

Current formal Skill count:

```text
2
```

Current maturity:

```text
characterization-first-refactor = TRIAL
save-integrity-guard = TRIAL
```

The Skill was exercised through a controlled dry run documented in:

```text
docs/governance/P5_03_SAVE_INTEGRITY_SKILL_TRIAL.md
```

Dry-run result:

- The Skill correctly refused mechanical rollback from the 2026-07-11 backup over the newer P4-08 current baseline.
- The Skill classified mtime-only save refresh as non-content change.
- The Skill treated absent `full_save.json` before and after as no deletion event.
- The Skill separated canonical saves, checkpoints, manager-local mirrors, legacy saves, test temp files, and unknown files.
- No production code, tests, scenes, assets, JSON, real saves, or `project.godot` were modified.
- The Skill remains `TRIAL`, not `VALIDATED`.

Skill boundary:

```text
characterization-first-refactor = behavior baseline / minimal refactor / unchanged behavior proof
save-integrity-guard = real user-data backup / SHA / structured JSON comparison / rollback prevention
```

The two Skills are `COMPOSABLE`, not merged. A high-risk Godot refactor may invoke both.

Next recommended task:

```text
P5-04 - Task Baseline and Lock Skill
```
