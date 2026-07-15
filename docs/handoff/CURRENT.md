# Current Project Status

Updated: 2026-07-15

## Phase

Current Phase: Phase 6 — Agent Collaboration and Skill Field Validation (P6-01 verified after governance correction).
Next Phase: Continue Phase 6 field validation only when User assigns the next task; P6-02 is verified and P6-03 has not started.

Phase 3 system-boundary cleanup is COMPLETE and tagged `system-boundary-cleanup-complete-2026-07-12`.
Phase 4 large-script decomposition is COMPLETE and tagged `large-script-decomposition-complete-2026-07-12`.
Phase 5 Skill suite is COMPLETE, `main` is pushed, and tag `skill-suite-complete-2026-07-13` exists at `4de284f`. Codex and Claude Code new-session bootstrap validations have passed. Phase 6 is IN_PROGRESS; P6-01 is `VERIFIED_AFTER_GOVERNANCE_CORRECTION` and P6-02 is `VERIFIED`.

P6-02 implementation adds only the four-step application Active-state highlight. Claude Code's engineering verdict is `PASS` for that scope only; the PASS does not validate the full application UI or historical save-file provenance. User approved the Active-state visual scope only. `application_profile.json` remains an expected page-entry write, while the earlier temporary-state-file disappearance remains source-unknown. Validation ran only in the dedicated sandbox after real user-data was frozen. P6-03 has not started, and all five formal Skills remain `TRIAL`.

AUI-03-01 (Basic Information page visual sample) is DONE, `VISUAL_PASS_WITH_MINOR_ADJUSTMENTS`, pushed. After the first acceptance, User's real (non-forced-resolution) testing found the BottomActionBar completely off-screen; root cause was a page-level `SCROLL_MODE_DISABLED` override combined with the project's actual default 1600x900 viewport (not 1920x1080) overflowing a zero-slack layout. That was fixed, then superseded by the core fix: a single authoritative per-scene uniform-scale + letterbox/pillarbox scheme (`aui_canvas`, fixed 1920x1080, `scale = min(w/1920, h/1080)`, centered, recomputed on resize and defensively every frame) implemented entirely inside `application_flow_scene.gd` — no `project.godot` stretch-mode change, no effect on other scenes. Verified at 1920x1080, 1600x900 (exact 83.33% scale), and 1440x900 non-16:9 (letterboxed, pixel-measured symmetric margins). A global project-wide stretch-mode change was discussed and explicitly deferred to a separate future task, not started. Formal Skills remain `TRIAL`; no maturity change.

## Recent Completion

AUI-03-01 — Basic Information Page Visual Sample Implementation is DONE (`VISUAL_PASS_WITH_MINOR_ADJUSTMENTS`, pushed).

- Owner: Claude Code (transferred from Codex mid-task; User directed the takeover because the running screenshot did not meet the approved visual standard).
- Reviewer: none independent of Owner — User's final acceptance (relaying ChatGPT's visual review) explicitly covers both visual match and engineering correctness for this task, resolving the Owner/Reviewer role conflict flagged at transfer. User's own message was explicit: a visual PASS does not claim engineering-logic verification.
- Preserved unchanged throughout every round: `basic_information_state()`, `derive_candidate_display_id()` (the `GHC-` prefix rule), the 0/3–3/3 completion and validation-status logic, Next enabled/disabled gating, the existing 29-check `tests/aui_03_01_basic_information_test.gd`, and the application/education/save flow. No save-schema, `PlayerProfileData`, or other-page change.
- Rebuilt: `_show_identity()`'s full visual node tree — Header (96px, real institution/assistant icons, 3 stable zones all vertically centered), StepNavigation (64px), PageHeading (80px, description now anchored next to the title), 52/48 dual-column body (636px, 24px panel padding, 20px gap) with real lock icons (dimmed) on system-generated fields and a real-Control Mission Brief diagram (Earth/Moon/Outpost/Terminal icons, solid double-arrow and dashed single-arrow connector lines built from `ColorRect`/`Label` primitives), and a four-cluster BottomActionBar (124px: circular status badge swapping `icon_status_incomplete`/`icon_status_complete` with the ratio overlaid, validation status + hint, a separate required-field-completion block with `○`/`●` radio indicators, and Back/Next with a ~20%-smaller arrow icon ordered after the button text).
- Core scaling fix (this is the load-bearing part of this closure): the whole page lives on a fixed 1920x1080 `aui_canvas` Control, uniformly scaled (`min(w/1920, h/1080)`) and letterboxed/pillarboxed to fit the real window, recomputed on resize and defensively every frame. The earlier `ScrollContainer`-based fallback (page-level scroll disabled, relying on internal scroll for overflow) was fully replaced by this — no ScrollContainer remains in the identity page's shell. This is implemented entirely inside `application_flow_scene.gd`; no `project.godot` stretch-mode change, no effect on other scenes.
- Root cause of the original "footer disappears" report: `_show_identity()` had disabled the shared `ScrollContainer`'s scrolling, and the project's actual default viewport is 1600x900 (not 1920x1080) — the zero-slack 1920x1080-only layout overflowed and pushed the footer off-screen at that real resolution. A global project-wide stretch-mode change (`canvas_items`, etc.) was discussed with User and explicitly deferred to a separate future task, since it would affect every scene; the per-scene `aui_canvas` scheme was found sufficient for this task's scope.
- Verification: Godot 4.7 headless parse EXIT 0 after every change; the 29-check test passed unmodified throughout. Screenshots captured across 5 rounds in an isolated sandbox project copy (separate `project.godot` `config/name`, per Codex's recipe — isolation is keyed by project name, not folder path or `--user-data-dir`). Real project save data was SHA-256 checked before and after every round; content stayed byte-identical to the state User confirmed was their own manual testing.
- Known limitations (disclosed): (1) an early screenshot attempt mistakenly assumed `--user-data-dir` would isolate `user://`; it did not, and two capture runs briefly re-saved the real profile with no content change (SHA-256 identical) before the correct sandbox recipe was obtained from Codex. (2) the `OptionButton` dropdown popup is a native separate-window layer, not a child of `aui_canvas`, so its own text may not shrink proportionally at non-1.0 scale factors — not addressed this round.
- Final deliverables: `docs/screenshots/aui_03_01_basic_information/` (5 screenshots across 1920x1080 / 1600x900 / a non-16:9 window), `tools/capture_aui_03_01_basic_information.gd` (reusable multi-resolution capture script).
- Formal Skills remain `TRIAL`; no maturity change. User explicitly authorized push for this round ("通过，可以push"); pushed to `origin/main`, not tagged.

P6-01 — Agent Collaboration Bootstrap and First Field Validation is verified after governance correction.

- Owner: Codex.
- Reviewer: Claude Code — read-only committed-range review.
- Reviewer verdict: `PASS_WITH_REQUIRED_GOVERNANCE_CORRECTION`.
- Correction status: Owner corrective close-out completed after the real Reviewer verdict. Commit `6c0dff9` is preserved as the premature close-out commit; the follow-up corrective commit corrects the governance record without rewriting history.
- Scope: validate fresh-session Bootstrap, task ownership, locks, reviewer boundary, blocker continuity, and close-out using real Phase 5-to-Phase 6 evidence.
- Formal Skill count remains 5; all maturity remains `TRIAL`. No Skill upgrade is authorized.
- Verification: documentation/Git scope checks, Godot 4.7 editor parse, and Godot 4.7 smoke passed; committed-range review returned the stated governance-correction verdict; no Skill was upgraded and no P6-02 work occurred.

P5-07 - Phase 5 Skill Suite Validation and Closure.

Result:
- Validated the complete five-Skill suite at the suite level and formally closed Phase 5. No new Skill was created; no Skill was upgraded from `TRIAL` to `VALIDATED`.
- Formal SKILL.md count = 5, consistent with the Registry and filesystem (`REGISTRY_MATCH`).
- Metadata consistent across all five Skills; no `VALIDATED`; `status` and `maturity` agree (all `trial`).
- Short-lived-state / local-path scan: no hardcoded HEAD/commit/ahead-behind, no absolute local paths, no Windows username, no phase-status freezing inside the Skills.
- Permission semantics: all `git add .`/`-A` references are prohibitions; push/tag references are correct governance boundaries.
- All five controlled dry-run reports exist and their decisions match the Skills.
- Created `docs/governance/PHASE_5_CLOSURE_REPORT.md` and `docs/handoff/AGENT_SESSION_BOOTSTRAP.md`.
- Updated `PHASE_5_SKILL_ARCHITECTURE_AUDIT.md`, `CLEANUP_PLAN.md`, `CURRENT.md`, `ACTIVE_TASKS.md`, and `SKILL_REGISTRY.md` (suite-closure note only; no maturity change).
- Did not modify production code, tests, scenes, assets, images, JSON, real saves, or `project.godot`.
- Did not push, tag, start a new session, or start Phase 6.

Current post-Phase-5 remote-frozen baseline:
- HEAD: `4de284f`
- `origin/main`: `4de284f`
- Branch: `main`
- Ahead/behind: ahead `0`, behind `0`
- Completion tag: `skill-suite-complete-2026-07-13`
- Working tree: clean
- ACTIVE_TASKS: IDLE

### Previously completed: P5-06 - Build Guanghan Art Review and Godot Handoff Skill

- Created the fifth formal repository Skill and second Guanghan Project layer Skill (review-side) at `skills/guanghan/guanghan-art-review-and-godot-handoff/SKILL.md`; registry updated (5 rows); dry-run report at `docs/governance/P5_06_GUANGHAN_ART_REVIEW_SKILL_TRIAL.md`.
- Dry run reviewed a "full concept image imported as one background sprite" screenshot and concluded `FAIL`; classified it `REFERENCE_ONLY_MISUSE` (P0), path occlusion `OCCLUSION_ERROR` (P1), tiny terminal `READABILITY_ISSUE` (P1); three tickets (ART-001..003) + code-correctness disclaimer. Maturity remains `TRIAL`. The two-stage Art Skill pair (producer + review) is now complete.

## Skill Status

Formal Skills (Phase 5 suite closed 2026-07-13; all remain `TRIAL`):

| Skill | Layer | Status | Version | Maturity |
|---|---|---|---|---|
| `characterization-first-refactor` | `godot` | `trial` | `0.1.0` | `TRIAL` |
| `save-integrity-guard` | `core` | `trial` | `0.1.0` | `TRIAL` |
| `task-baseline-and-lock` | `core` | `trial` | `0.1.0` | `TRIAL` |
| `guanghan-art-design-and-production` | `guanghan` | `trial` | `0.1.0` | `TRIAL` |
| `guanghan-art-review-and-godot-handoff` | `guanghan` | `trial` | `0.1.0` | `TRIAL` |

`characterization-first-refactor` should not be treated as `VALIDATED` until it has guided at least two different real refactor tasks, including at least one Controller extraction and at least one Presenter, Evaluator, or `CHARACTERIZE_ONLY` task.

`save-integrity-guard` should not be treated as `VALIDATED` until it has protected real user data on at least one live verification/refactor task and at least one baseline-recovery or save-system task without destructive rollback, unexplained canonical changes, or user-data loss.

`task-baseline-and-lock` should not be treated as `VALIDATED` until it has managed at least two real tasks, including one clean single-owner task and one owner-transfer or parallel-conflict scenario, without duplicate tasks, lock conflicts, or board registration gaps.

`guanghan-art-design-and-production` should not be treated as `VALIDATED` until it has guided at least two real art tasks, including one scene design plus asset breakdown and one standalone asset or state-variant task, with separable Godot-usable results and user acceptance.

`guanghan-art-review-and-godot-handoff` should not be treated as `VALIDATED` until it has been used on at least two real visual-acceptance tasks, including one full-scene acceptance and one asset/state-variant acceptance, with at least one before/after re-review, tickets correctly executed by engineering, no case of a visual pass mistaken for code correctness, and user acceptance recorded.

## Suite Validation Summary (P5-07)

Objective:

Validate the complete five-Skill suite (directory, metadata, boundaries, composition, Registry, trial evidence, new-session bootstrap) and formally close Phase 5, without creating a new Skill or upgrading any Skill to `VALIDATED`.

Conclusion:

- Formal SKILL.md count = 5; `REGISTRY_MATCH` (5/5, no phantom/duplicate/candidate rows).
- Metadata consistent; no `VALIDATED`; `status`/`maturity` all `trial`.
- Structure complete for every Skill; both art Skills have Agent Responsibilities, visual direction, Godot boundary, and User approval.
- No short-lived state (HEAD/commit/ahead-behind), no local paths, no username inside the Skills.
- `git add .`/`-A` only appear as prohibitions; push/tag semantics are correct.
- All five dry-run reports exist with decisions matching the Skills.
- Composition: three core/godot Skills are COMPOSABLE; the two art Skills are SEQUENTIAL_AND_COMPOSABLE (not merged); art-review + refactor are SEPARATE_WORKSTREAMS.
- New-session bootstrap guide created; Phase 5 closure report created.
- Phase 5 = COMPLETE; Phase 6 = READY (not started).

## Deferred Risks

Deferred from earlier phases and not closed by P5-02:
- DoorState formal old-base integration.
- Legacy file physical deletion.
- `interaction_detector` / `BaseInterior_Test` UNKNOWN cleanup.
- Product-level Inventory <-> Backpack relationship decisions.
- `training_base_map.gd` room/door/dynamic SceneTree ownership.
- `training_module_scene.gd` remaining training state machine and room layout.
- `sprint06_base_scene.gd` async finish/transition/save sequences.
- Legacy sandbox slot-save aggregation.
- `main.gd` remaining legacy sandbox core.

## Verification

P5-07 is docs-only (plus new closure/bootstrap docs; no Skill business content changed).
- Git diff contains only allowed Markdown docs.
- `git diff --check`: PASS.
- Godot editor parse: EXIT 0.
- Godot headless smoke: EXIT 0.
- Formal Skill count: 5 (all `TRIAL`).
- Production code/tests/scenes/assets/project/JSON/saves: unchanged.

## Next Step

Phase 6 — Agent Collaboration and Skill Field Validation is IN_PROGRESS; P6-01 is `VERIFIED_AFTER_GOVERNANCE_CORRECTION`, P6-02 is `VERIFIED`, and P6-03 has not started.

Phase 5 remote freeze is complete: `main` is pushed, completion tag `skill-suite-complete-2026-07-13` exists, and Codex/Claude Code bootstrap acceptance has passed. P6-01 and P6-02 are verified Phase 6 field validations; do not start P6-03 automatically.
