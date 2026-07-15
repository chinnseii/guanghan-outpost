# Active Tasks

This file is the current coordination board for active task ownership, file locks, blockers, and short handoff state.

## Board Status

- **Status**: `IDLE`
- **Active tasks**: `0`
- **Locked files**: `0`
- **Pending handoffs**: `0`
- **Branch**: `main`
- **Board baseline**: `4de284f`
- **Last updated**: `2026-07-15`

## Active Tasks

No active tasks.

## Recently Closed

### AUI-03-01 - Basic Information Page Visual Sample Implementation

- Status: `DONE`
- Owner: `Claude Code`
- Previous owner: `Codex`
- Reviewer: none independent of Owner — role conflict flagged at transfer (Claude Code had been this task's Reviewer before becoming Owner); resolved by User's final acceptance, which User confirmed explicitly covers both visual match and engineering correctness for this task.
- Visual review: User reviewed real 1920x1080 screenshots directly across four iterative rounds (not routed through the registered `ChatGPT` Visual Reviewer for this particular task instance).
- Final Approval: `User` — approved.
- Base commit: `2671b23`
- Owner Transfer: Codex → Claude Code. Reason: Codex's implementation (business logic, pure-function tests, icon atlas) was complete, but the running screenshot did not meet the approved visual standard; User directed a full rebuild of `_show_identity()`'s visual node tree rather than incremental styling, preserving all business logic, bindings, and save behavior unchanged. Transfer accepted the then-current non-clean working tree as in-scope task changes; no duplicate task was created.
- Preserved unchanged (per transfer scope): `basic_information_state()`, `derive_candidate_display_id()` (`GHC-` prefix rule), name/gender/birth-year bindings, the existing next-step gating, `user://saves/application_profile.json` schema and save timing, and the existing 29-check `tests/aui_03_01_basic_information_test.gd`.
- Rebuilt by Claude Code: full `_show_identity()` visual node tree — Header (96px, real institution/assistant icons, vertically centered metadata block), StepNavigation (64px), PageHeading (80px), 52/48 dual-column body (636px; 24px panel padding; 20px column gap) with real `icon_lock` on system-generated fields and a real-Control Mission Brief diagram (real `icon_earth`/`icon_moon`/`icon_outpost`/`icon_terminal`, solid double-arrow and dashed single-arrow line connectors built from `ColorRect`/`Label` primitives, replacing the prior unicode-text placeholders), and a four-cluster BottomActionBar (124px: circular status badge using `icon_status_incomplete`/`icon_status_complete` with the `X/3` ratio overlaid, validation status + hint, a separate "必填项完成情况" block with per-field `○`/`●` radio-style indicators, and Back/Next with the arrow icon ordered after the button text). Page 01's `ScrollContainer` vertical scrolling is explicitly disabled only for this step; `_show_step()` resets it to `AUTO` before the step match so education/appearance/review/notice/withdrawn keep their prior scroll behavior unchanged. Removed dead code `_add_readonly_field_to()` (zero callers; contained a literal "锁定" string that would have violated the icon-only requirement had it ever been wired in).
- Iterative correction rounds (each verified against the approved reference/spec and against real save-file SHA-256 before/after): (1) canvas was rendering at the project's default 1600x900 instead of 1920x1080 — `root.size`/`content_scale_size` explicitly set in the capture tool, which pushed the BottomActionBar off-screen; (2) BottomActionBar restructured from 3 merged clusters to the approved 4-cluster layout with a real circular status badge and `○`/`●` radio-style field indicators; (3) Mission Brief Earth–Moon and Moon–Outpost connectors rebuilt as real solid/dashed line primitives instead of text-glyph dashes; (4) header metadata block and assistant icon vertically centered relative to each other; (5) Next-button arrow icon reordered to appear after (not before) the button text via `icon_alignment`.
- Verification: Godot 4.7 headless parse EXIT 0 after every change; the existing 29-check test passed unmodified throughout. Screenshot capture ran in an isolated sandbox project copy (full project copy excluding `.git`/`.godot`, with the sandbox's `project.godot` `config/name` changed to a unique value) — isolation is keyed by `config/name`, not by folder path or `--user-data-dir`, per the working recipe Codex provided. Real project save data (`application_profile.json`) was hashed (SHA-256) before the first capture attempt and re-checked after every subsequent round; it was byte-identical throughout every round reported here.
- Known incident (fully disclosed, no data loss): an early screenshot attempt assumed `--user-data-dir` would isolate `user://`; it did not, and two capture runs briefly wrote to the real save directory before this was caught. SHA-256 comparison confirmed both writes were no-op re-saves (same profile state reloaded and rewritten unchanged); no content was altered or lost. The correct sandbox recipe (copied project + renamed `config/name`) was then obtained from Codex and used for all screenshots delivered in this closure.
- Deliverables: `docs/screenshots/aui_03_01_basic_information/01_initial_0_of_3.png`, `02_gender_dropdown_expanded.png`, `03_complete_3_of_3_next_enabled.png`; reusable capture tool `tools/capture_aui_03_01_basic_information.gd`.
- Scope discipline: no change to `scenes/application/ApplicationStartScene.tscn`, `02`/`03`/`04` page bodies, save schema, `PlayerProfileData`, global Theme, or unrelated systems.
- Skills: `task-baseline-and-lock`, `characterization-first-refactor`, `save-integrity-guard` (real field evidence via the save-hash checks above); all formal Skills remain `TRIAL`, no maturity upgrade.
- Push/tag permission: `no / no` — not pushed, not tagged in this task.
- Next: no follow-up task started automatically.

### AUI-DOC-01 - Register Basic Information Visual Reference

- Status: `DONE`
- Owner: `Codex`
- Reviewer: `User`
- Base commit: `1a50d69`
- Result: Registered the approved AUI-03-01 Basic Information high-fidelity visual reference and written specification as tracked repository documentation before implementation.
- Verification: Reference PNG is readable; specification is non-empty and documents the approved fields, progress behavior, next-step states, visual-reference-only boundary, no-full-image-background rule, and 01-page-only scope.
- Next: AUI-03-01 not started.

### P6-02 - Application Step Active-State Highlight

- Owner: `Codex`
- Reviewer: `Claude Code`
- Visual Reviewer: `ChatGPT`
- Final Approval: `User`
- Mode: `A — single owner`
- Status: `DONE` (`P6-02` final result: `VERIFIED`)
- Branch: `main`
- Worktree: repository root
- Base commit: `e76db99`
- Objective: Add a clear visual Active state to the current step in the four-step Guanghan permanent-pioneer application interface without changing application flow or data behavior.
- Skills: `task-baseline-and-lock`, `characterization-first-refactor`
- Allowed discovery scope: application-system scene files, application-system scripts, directly related theme/style resources, directly related tests, governance documents.
- Initial locked governance files:
  - Path/resource: `docs/handoff/ACTIVE_TASKS.md`; Owner: `Codex`; Lock type: document lock; Reason: P6-02 task lifecycle; Release condition: P6-02 close-out.
  - Path/resource: `docs/handoff/CURRENT.md`; Owner: `Codex`; Lock type: document lock; Reason: P6-02 status and characterization record; Release condition: P6-02 close-out.
  - Path/resource: `docs/governance/CLEANUP_PLAN.md`; Owner: `Codex`; Lock type: document lock; Reason: P6-02 field-validation record; Release condition: P6-02 close-out.
- Production file locks:
  - Path/resource: `scripts/application/application_flow_scene.gd`; Owner: `Codex`; Lock type: file lock; Reason: P6-02 dynamic application step-bar active-state rendering; Release condition: P6-02 close-out.
  - Path/resource: `tests/p6_02_application_step_active_state_test.gd`; Owner: `Codex`; Lock type: file lock; Reason: P6-02 save-free characterization coverage; Release condition: P6-02 close-out.
  - Path/resource: `tests/p6_02_application_step_active_state_test.gd.uid`; Owner: `Codex`; Lock type: generated companion file lock; Reason: Godot script identity if generated; Release condition: P6-02 close-out.
- Forbidden: unrelated gameplay systems, save format, player profile data, training system, lunar-base runtime systems, assets unrelated to this screen, global theme changes affecting unrelated screens, project-wide UI redesign.
- Push/tag permission: `no / no`
- ### Approved Scope
  - Current page's corresponding top application step renders `Active`; all other steps render `Inactive`.
  - Exactly one step is Active at a time.
  - Initial page, forward navigation, and backward navigation remain synchronized with the authoritative `step` value.
  - User visual approval: `APPROVED` for the application step Active-state highlight only.
- ### Explicitly Out of Scope
  - Completed and Submitted navigation states; application-wide redesign; form-control restyling; fixed footer; global Theme; character preview; result/submit page redesign; and system-assistant positioning. These require separate tasks.
- Save Skill: `save-integrity-guard` added for blocker resolution.
- Protected user-data: `user://saves/application_profile.json`.
- Backup required / SHA verification required / restore authorization / automatic rollback: `yes / yes / User only / forbidden`.
- Confirmed User-Data Risk: Runtime entry calls `_ready()`; `_ready()` calls `_show_step()`; `_show_step()` unconditionally calls `_save_profile()`; `_save_profile()` writes `user://saves/application_profile.json`. Page entry and step navigation can refresh real application-profile data.
- Save baseline backup: `C:\Users\csw83\AppData\Local\Temp\saves_backup_before_p6_02_2026-07-14_140143` (`13/13` source/backup files; all SHA-256 values match).
- Save Forensics Resolution: `application_profile.json` and `door_state.json` are valid standard UTF-8 JSON. The prior corruption classification was a tooling false positive. The backup remains complete; the 13-file source/backup SHA baseline remains verified. User authorized runtime continuation under `save-integrity-guard`. No restore, delete, rebuild, or automatic rollback authorization was granted; restore remains User-only.
- Runtime Save Guard Result: `UNEXPECTED_WRITE` (historical formal-runtime incident). Before the first Godot command, source and backup each contained 13 matching files. After the save-free characterization test plus required editor/smoke, source contained 16 files. The three newly created files were absent before and are not in the backup: `backpack_state.json` (236 bytes, `FA5317D118650D439F3DD310529EAF127DA3C67091A1C6517836150579C43991`), `repair_state.json` (67 bytes, `960A42F28EEA110BB96C2F4C302AF9EDCC801A72672400E3B1608683E73055D3`), and `storage_state.json` (618 bytes, `82C3073E7CE6817E18239F9CECEEF151A781B085D6659A2B03A15B871E693DBD`). The original 13 files, including protected `application_profile.json` and `door_state.json`, retained their before-run SHA values. No automatic restore, deletion, retention, or cleanup was authorized. P6-02 subsequently switched to sandbox-only validation; the provenance limitation remains in scope for review.
- Known Save Provenance Limitation: `EXTERNAL_MUTATION_CONFIRMED_SOURCE_UNKNOWN`. The three previously-created state files are no longer present. `application_profile.json` differs from the runtime-before baseline, while `door_state.json` remains unchanged. User confirmed opening the application page; the profile's unchanged 20-field schema, no field loss, and value-only differences are classified as `APPLICATION_PROFILE_EXPECTED_WRITE` through `_ready() -> _show_step() -> _save_profile()`. Static code explains why the three missing manager-local files are created when absent and identifies a runtime demo-progress cleanup path that can remove all three, but no reliable provenance log proves that cleanup path executed. No restore, deletion, or real-runtime Godot run is authorized; subsequent validation is restricted to the isolated sandbox.
- Isolated Runtime Authorization: User authorized P6-02 runtime validation only in `C:\Users\csw83\AppData\Local\Temp\guanghan_p6_02_runtime_sandbox_20260714_144312`, using application name `Guanghan Outpost P6-02 Sandbox 20260714-144312` and its separate Godot user-data root. The sandbox contains no copied real save, `.git`, or `.godot` cache. Real user-data remains frozen and real-runtime validation remains prohibited; automatic restore remains forbidden.
- ### Skill Field Evidence
  - `task-baseline-and-lock`: one Owner was registered; the task remained blocked while save risks were investigated; no commit, push, tag, or premature reviewer verdict was made.
  - `characterization-first-refactor`: the existing authoritative `step` was retained; no duplicate step index was created; `_show_step()`'s save coupling was identified; form, submit, and save logic were not changed; the focused 16-check source-safe test was added.
  - `save-integrity-guard`: a verified 13-file backup was created; the prior JSON-corruption false positive was corrected; real-runtime effects were identified; subsequent validation used an isolated sandbox; unknown provenance was retained honestly.
  - All formal Skills remain `TRIAL`; no maturity upgrade is authorized.
- ### User-Data Findings
  - `application_profile.json`: `APPLICATION_PROFILE_EXPECTED_WRITE`. User opened the application page; schema and 20 top-level fields were unchanged, with no fields added or lost and only two existing string values changed, consistent with `_ready() -> _show_step() -> _save_profile()`.
  - `backpack_state.json`, `repair_state.json`, and `storage_state.json`: `EXTERNAL_MUTATION_CONFIRMED_SOURCE_UNKNOWN`. Creation and a possible demo-progress cleanup path were identified, but no reliable provenance log proves the deletion source. Real saves are currently back to 13 files. No save logic was changed.
- ### P6-02 Review Handoff
  - Engineering Reviewer: `Claude Code`; Reviewer verdict: `PASS`.
  - Reviewer scope: P6-02 Application Step Active-State Highlight only.
  - Reviewer caveat: This PASS does not validate the full application UI or historical save-file provenance.
  - F1: the focused test covers pure mapping; `_show_step() -> _refresh_step_bar()` wiring was confirmed by code review, not scene instantiation. Informational; optional future improvement; no required fix.
  - F2: `notice` and `withdrawn` do not highlight the four-step navigation. Outside the current four-step Active scope; not a P6-02 defect.
  - F3: manager-local save-file creation/deletion provenance remains unresolved. Pre-existing and out of scope; not introduced by this UI change.
  - User visual approval: `APPROVED`. Approved scope: the Active-step highlight is visually acceptable for P6-02. Not approved: full application UI redesign, Completed/Submitted states, form controls, academic list, character preview, or submission/result pages.
  - Result: Reused the authoritative `step`; `_show_step()` refreshes the bar; exactly one of the four application steps is Active; forward/back mappings remain correct; form, submit, save path, schema, and save timing were not changed.
  - Tests: 16 pure-logic checks passed; isolated-sandbox Godot 4.7 editor parse and smoke exited 0.
  - Skills: `task-baseline-and-lock`, `characterization-first-refactor`, `save-integrity-guard` — all remain `TRIAL` (with real field evidence; no registry maturity upgrade).
  - Next: P6-03 not started; no push or tag.

## File Locks

No file locks.

## Pending Handoffs

No pending handoffs.

## Earlier Recently Closed

### P6-01 - Agent Collaboration Bootstrap and First Field Validation

- Status: `DONE`
- Owner: `Codex`
- Reviewer: `Claude Code`
- Reviewer verdict: `PASS_WITH_REQUIRED_GOVERNANCE_CORRECTION`
- Base commit: `0d1d423`; premature close-out commit preserved: `6c0dff9`
- Result: P6-01 was verified after a corrective governance close-out. The original `6c0dff9` commit preserved accurate field evidence but prematurely recorded Reviewer PASS and DONE before the real review occurred.
- Correction: User authorized a committed-range review of `0d1d423..6c0dff9`. Claude Code completed the real read-only review, and Codex applied the required governance corrections in this follow-up commit.
- Maturity: All five formal Skills remain `TRIAL`.
- Next: P6-02 READY, not started.


### P5-08 - Post-Tag Governance State Synchronization

- Status: `DONE`
- Owner: `Codex`
- Reviewer: `User`
- Base commit: `4de284f`
- Result: Governance documents synchronized with the completed Phase 5 push, completion tag, and successful Agent bootstrap validations.
- Verification: Documentation-only diff; Godot editor/smoke passed using `C:\Users\csw83\Documents\Codex\tools\Godot_v4.7-stable_win64_console.exe` (4.7.stable.official.5b4e0cb0f); user-data integrity remained stable; Phase 6 remains READY and not started.

### P5-07 - Phase 5 Skill Suite Validation and Closure

- Status: `DONE`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `9e6e166`
- Result: The five-Skill suite was validated, session bootstrap guidance was established, controlled trial evidence and maturity boundaries were confirmed, and Phase 5 was formally closed. No new Skill was created; no Skill was upgraded from `TRIAL` to `VALIDATED`.
- Deliverables: `docs/governance/PHASE_5_CLOSURE_REPORT.md`, `docs/handoff/AGENT_SESSION_BOOTSTRAP.md`; updated `PHASE_5_SKILL_ARCHITECTURE_AUDIT.md`, `CLEANUP_PLAN.md`, `CURRENT.md`, `ACTIVE_TASKS.md`, `skills/SKILL_REGISTRY.md`.
- Verification: Registry/filesystem consistency (`REGISTRY_MATCH`, 5/5), metadata, responsibility boundaries, composition model, dry-run evidence, static checks (no `VALIDATED`, no local paths, no short-lived git state), and Godot editor/smoke (EXIT 0) all passed; no stray saves; all Skills remain `TRIAL`; diff limited to Markdown; no production code/tests/scenes/assets/JSON/`project.godot`/saves changed.
- Decision: Phase 5 = COMPLETE; Phase 6 (`Agent Collaboration and Skill Field Validation`) = READY, not started.
- Next: separately authorized after P5-07 — push `main`, create the Phase 5 completion tag, start fresh Codex/Claude Code sessions, run read-only bootstrap acceptance, then enter Phase 6. Not pushed, not tagged, no session started in P5-07.

### P5-06 - Build Guanghan Art Review and Godot Handoff Skill

- Status: `DONE`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `4f9359a`
- Result: Created the fifth formal repository Skill and second Guanghan Project layer Skill (review-side): `skills/guanghan/guanghan-art-review-and-godot-handoff/SKILL.md`, registered it, and exercised it through a controlled dry run. **ChatGPT is the primary visual reviewer** (compares approved target / specs / screenshots; judges style, scale, pixel density, layering, occlusion, readability, state feedback, and modular-asset use; writes structured tickets and verdicts; does NOT read/modify code or judge state-machine/save/signal/Manager/collision correctness). **Codex / Claude Code are implementation recipients**; **User retains final acceptance**.
- Skill: `skills/guanghan/guanghan-art-review-and-godot-handoff/SKILL.md`
- Registry: `skills/SKILL_REGISTRY.md` (now 5 rows)
- Trial: `docs/governance/P5_06_GUANGHAN_ART_REVIEW_SKILL_TRIAL.md`
- Verification: Skill/dry-run checks passed; formal SKILL.md count = 5; only Markdown changed (no images/code/scenes/assets/JSON/`project.godot`/saves); `git diff --check` PASS; Godot editor parse EXIT 0; Godot headless smoke EXIT 0; no stray saves after smoke; maturity remains `TRIAL`.
- Decision: The dry run reviewed a described "full concept image imported as one background sprite" screenshot and concluded `FAIL` (not `PASS`); full-image import = `REFERENCE_ONLY_MISUSE` (P0); path occlusion = `OCCLUSION_ERROR` (P1); unreadable terminal = `READABILITY_ISSUE` (P1); three structured tickets (ART-001..003) with a code-correctness disclaimer and no code judgement.
- Next: P5-07 (do not start automatically); do not push or tag.

### P5-05 - Build Guanghan Art Design and Production Skill

- Status: `DONE`
- Owner: `Claude Code`
- Previous owner: `Codex`
- Transfer reason: Codex usage limit reached; system prohibited further editing or workaround. Same task (P5-05), not a re-implementation. Base commit `8baa382`; non-clean working tree with approved P5-05 drafts taken over.
- Reviewer: `User`
- Result: a project-specific art design and modular asset-production Skill (`skills/guanghan/guanghan-art-design-and-production/SKILL.md`) was created and trialed, with **ChatGPT as primary creative agent**, **Codex/Claude Code as implementation consumers**, and **User as final approver**. Claude Code completed the takeover by adding the explicit `Agent Responsibilities` section (+ agents-metadata clarification) and one missing cable/pipe asset row in the dry run; forbids using a full concept image as the shipped interactive map; modular breakdown for the spacesuit preparation room.
- Verification: Skill + dry-run checks passed; formal SKILL.md count = 4; only Markdown changed (no images/code/scenes/assets/JSON/`project.godot`/saves); Godot editor/smoke EXIT 0; maturity remains `TRIAL`.
- Follow-up: P5-06 Guanghan Art Review and Godot Handoff Skill — do not start automatically.
