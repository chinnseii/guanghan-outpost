---
name: guanghan-art-review-and-godot-handoff
description: Use for Guanghan Outpost visual acceptance review: compare an approved target image / art spec against current in-game screenshots, judge style/scale/pixel-density/palette/layering/occlusion/readability/state-feedback/modular-asset-use/environmental-storytelling, and produce structured, reproducible correction tickets for Codex or Claude Code. Use after art has been implemented and screenshots exist; not for initial art design, image generation, asset breakdown, code review, save/state-machine correctness, or engine bug fixing.
version: 0.1.0
status: trial
scope: guanghan
agents:
  - chatgpt
  - codex
  - claude-code
project: guanghan-outpost
maturity: trial
last_validated: 2026-07-13
---

# Guanghan Art Review and Godot Handoff

## Purpose

Use this Skill to review the visual implementation of Guanghan Outpost against the approved visual direction, target images, and asset specifications, and to turn the differences into engineering-executable, reproducible, re-screenshot-verifiable correction tickets.

This Skill owns:

- visual consistency; style consistency; scene readability; spatial layering; asset scale; pixel density; layering and occlusion; palette; lighting expression; state feedback; modular-asset use; environmental storytelling; target-image-to-game landing deviation; correction tickets; before/after screenshot acceptance.

This Skill does NOT own:

- code review; architecture review; save validation; Manager responsibilities; state-machine correctness; scene-logic correctness; performance analysis; gameplay numbers; automatic engineering changes.

This is the review-side counterpart of `guanghan-art-design-and-production` (the producer-side Skill). The two are `SEQUENTIAL_AND_COMPOSABLE` and must not be merged.

## Agent Responsibilities

### Primary visual reviewer: ChatGPT

ChatGPT owns:

- reading `PROJECT_BRIEF` and the approved art direction;
- comparing the target image, asset specs, and game screenshots;
- judging whether the visual style is consistent;
- checking scale, composition, layering, occlusion, and pixel density;
- checking whether modular assets are used correctly;
- checking whether state expression is clear;
- checking whether environmental storytelling matches the project tone;
- distinguishing visual problems from unknown underlying logic;
- producing structured visual correction tickets;
- giving a PASS / conditional / FAIL verdict.

ChatGPT does NOT:

- read or modify code;
- judge whether the underlying state machine is correct;
- judge whether save, signals, Manager, or collision logic is correct;
- fix engineering directly;
- change approved gameplay on its own;
- replace the User in the final product decision.

### Implementation recipients: Codex, Claude Code

Codex / Claude Code own:

- receiving structured correction tickets;
- reading the target image and specs;
- modifying Godot scenes, resources, or code;
- adjusting layers, scale, nodes, collision, and state mapping;
- providing before/after screenshots;
- providing engineering verification reports;
- cross-checking each other on underlying code correctness.

Codex / Claude Code do NOT:

- change the art direction on their own;
- simplify the target image below the approved standard;
- treat "looks visually correct" as "code is correct";
- expand the change scope without approval.

### Final approval: User

The User owns:

- deciding whether the target image is approved;
- deciding whether a visual change is accepted;
- deciding whether to proceed to engineering fixes;
- deciding whether to merge, push, or tag;
- resolving the final trade-off between art goals and engineering cost.

### Clarification on the `agents` metadata

ChatGPT is the primary visual reviewer. Codex and Claude Code appear in `agents` because they **receive and act on** the tickets this Skill produces, not because they perform the visual acceptance judgement. The User retains final acceptance authority. This Skill is review-side; `guanghan-art-design-and-production` is producer-side.

## Fixed Review Basis (priority order)

Review strictly in this priority; on conflict, do not self-reconcile — mark `USER_DECISION_REQUIRED` and ask the User:

1. the User's latest explicit approved target image or written decision;
2. `docs/PROJECT_BRIEF.md`;
3. the formal art-direction documents;
4. the scene/asset specs produced by the P5-05 producer Skill;
5. the approved asset breakdown;
6. the current game screenshot;
7. the engineering implementation report.

## Core Visual Direction (reused from `guanghan-art-design-and-production`)

- 2D pixel art; top-down or near top-down; modular tiles and standalone assets;
- low-saturation lunar industrial base; cool gray, metal white, dark gray; sparse orange/yellow warnings; rare, emotionally-meaningful plant green;
- use, wear, repair, and assembled marks; lonely, restrained, hopeful, relay-like; a sense of life in an extreme place;
- readable functional zones, player path, doors, terminals, and interaction points.

Reject during review:

- realistic 3D look; high-saturation cartoon; cyberpunk neon; luxury sterile showroom;
- a full concept image used directly as the map; mixed pixel density; large inseparable backgrounds; decoration that blocks gameplay.

## When to Use

- after Codex / Claude Code finish an art integration;
- when the User provides a game screenshot;
- when a target image and a landed screenshot need comparison;
- to judge conformance to `PROJECT_BRIEF`;
- to check visual quality;
- to output revision tickets;
- to check material, scale, color, and layout;
- to judge whether assets are correctly split and reused;
- to accept Critical / Stable / Damaged states;
- to check whether the scene still keeps a readable player path;
- for before/after acceptance;
- to distinguish visual problems from possible engineering problems.

## Do Not Use When

- there is no target image or approval standard yet;
- it is only initial art design;
- it is only image generation;
- it is only asset breakdown;
- it is only code modification;
- it is only import handling;
- it needs GDScript correctness checking;
- it needs save checking;
- it needs Manager/signal checking;
- there is no screenshot or visual evidence;
- the task is only invisible backend logic;
- the User has not approved the target direction.

Those belong to other Skills: art design/production → `guanghan-art-design-and-production`; refactor → `characterization-first-refactor`; saves → `save-integrity-guard`; task governance → `task-baseline-and-lock`.

## Required Inputs

```text
Review task:
Scene or asset name:
Approved target:
Approved visual requirements:
Current game screenshot:
Before screenshot:
After screenshot:
Asset specification:
Gameplay purpose:
Expected player path:
Expected visual states:
Known engineering limitations:
Implementation report:
Review scope:
Out-of-scope items:
Required output:
Reviewer:
Implementation recipient:
```

Optional: multiple resolutions; UI visible/hidden state; Critical/Stable comparison; camera zoom; existing bug ticket; asset filenames; scene path; device/display ratio; lighting state; animation clip.

If key inputs are missing: do not guess the target; limited descriptive observation is allowed; do not give a final PASS verdict; mark `INSUFFICIENT_EVIDENCE`.

## Review Procedure

### Phase A — Confirm Review Contract
Confirm the review subject, target image, current screenshot, review scope, engineering report, which items cannot be judged from a screenshot, and the User-approved standard.

### Phase B — Establish Visual Baseline
Record the target's core features, scene function, player path, primary visual focus, color structure, size ratios, asset states, layering, and readability requirements.

### Phase C — Compare Target and Implementation
Compare per dimension: overall style, composition, spatial layout, scale, pixel density, palette, lighting, material, wear/damage, asset identity, modularity, state variants, readability, interaction visibility, occlusion, player route, environmental storytelling.

### Phase D — Classify Findings
Every finding must be one of: `VISUAL_DEFECT`, `ART_DIRECTION_DEVIATION`, `SCALE_MISMATCH`, `PIXEL_DENSITY_MISMATCH`, `LAYERING_ERROR`, `OCCLUSION_ERROR`, `READABILITY_ISSUE`, `STATE_FEEDBACK_WEAK`, `ASSET_USAGE_ERROR`, `MISSING_ASSET`, `REFERENCE_ONLY_MISUSE`, `POSSIBLE_ENGINEERING_ISSUE`, `INSUFFICIENT_EVIDENCE`, `USER_DECISION_REQUIRED`.

### Phase E — Prioritize
`P0`: blocks understanding, path, interaction, or is a severe target deviation. `P1`: clearly hurts quality or scene identity. `P2`: environmental storytelling and finish. `P3`: micro-tuning and decoration.

### Phase F — Produce Tickets
One independent ticket per finding (see Structured Ticket Format).

### Phase G — Handoff
State who changes it, what to change, what NOT to change, which screenshots are needed, which engineering verifications are needed, and which findings cannot be accepted from a screenshot alone.

### Phase H — Re-review
On new screenshots, compare against the old tickets and mark `FIXED` / `PARTIAL` / `NOT_FIXED` / `REGRESSED`; do not recreate identical tickets; record new problems; output the final acceptance verdict.

## Visual Review Matrix

| Dimension | Review question |
|---|---|
| Style | Still a consistent 2D pixel-art look? |
| Camera | View consistent with existing scenes? |
| Scale | Character, door, equipment, room ratios reasonable? |
| Pixel density | Any mixed pixel scale or blurry scaling? |
| Palette | Matches cool-gray base with limited warning color? |
| Material | Shows industrial metal, wear, and repair marks? |
| Layout | Functional zones and player path clear? |
| Readability | Interactive objects identifiable at a glance? |
| Layering | Foreground/character/equipment/wall order correct? |
| Occlusion | Anything blocking the player or key interactions? |
| Modularity | Built from separable assets rather than one full image? |
| State feedback | Critical/Stable/Offline etc. distinguishable? |
| Environment | Conveys loneliness, hope, and a sense of life? |
| UI relation | Does UI cover key scene content? |
| Consistency | Consistent with other scenes in the project? |

## Screenshot Requirements

Required from engineering: before; after; same camera position; same zoom; same resolution; same game state; consistent UI-visible state; no debug occlusion (unless reviewing debug UI); key states captured separately.

Multi-state tasks (e.g. greenhouse): Critical; Stable; Damaged; Repaired. Multi-region tasks: overall view; player entry; main interaction point; high-risk occlusion spot; state-change close-up. Do not use different-angle screenshots to hide problems.

## Structured Ticket Format

```text
## ART-<ID> — <Issue title>
- Priority:
- Category:
- Scene/asset:
- Evidence:
- Target requirement:
- Actual result:
- Impact:
- Reproduction/viewpoint:
- Required change:
- Must preserve:
- Forbidden shortcut:
- Expected verification:
- Implementation owner:
- Reviewer:
- Status:
```

`Evidence` should cite the target image, current screenshot, before/after screenshots, asset spec, and the User approval record. Tickets must be executable and re-verifiable — never vague ("make it prettier", "more atmosphere", "adjust the ratio a bit", "feels off").

## Art Ticket vs Engineering Bug Boundary

**Art Ticket**: scale; color; assets; visual layering; occlusion; pixel density; state expression; scene readability; environmental storytelling.

**Engineering Bug Ticket**: button not working; state out of sync; broken collision; wrong signal; save error; wrong condition; wrong scene transition; resource not loaded; animation not playing.

From a screenshot ChatGPT may only write `POSSIBLE_ENGINEERING_ISSUE` — never assert a code cause. Output: visible phenomenon; reproduction steps; expected; actual; needs engineering-side verification; do not guess class names or code locations.

## Review Verdicts

- `PASS`: visual target met, no blocking issues.
- `PASS_WITH_MINOR_ISSUES`: core target met, only P2/P3 remain.
- `CONDITIONAL_PASS`: core direction broadly met, but clear P1 remains; re-review after fix.
- `FAIL`: P0, severe direction deviation, or full-image misuse.
- `INSUFFICIENT_EVIDENCE`: screenshot, target, or state insufficient to judge.
- `USER_DECISION_REQUIRED`: target conflict or a visual-direction trade-off.

A passing test suite is NOT a visual PASS.

## Target Image Boundary

The target image is the direction and composition basis, not a pixel-for-pixel requirement. Engineering simplification is allowed, but must not break scene identity, functional readability, or core mood. A full target image must never be used directly as the interactive map. A screenshot "looking like the target image" does not mean the assets are split correctly — check whether it is built from modular assets; when modularity cannot be judged from the screenshot, mark `INSUFFICIENT_EVIDENCE` or require an engineering report.

## Godot Handoff Boundary

This Skill may ask engineering to modify: Sprite2D / AnimatedSprite2D; TileMap or equivalent; z-index; Y-sort; scale; texture filter; region; animation frames; state visibility; light/overlay; collision shape alignment with visible assets; UI-vs-scene layering; asset paths; scene composition.

It must not provide concrete GDScript unless the User approves a separate engineering task. It does not judge: signal connections; Manager correctness; checkpoint correctness; save correctness; state-machine correctness; performance. Engineering must verify those itself.

## Decision Points

1. Screenshot looks correct but engineering report missing → visual may be conditional pass; code correctness unverified; do not write "implementation fully correct".
2. Implementation differs from target but fits gameplay better → mark the difference; judge whether the core visual direction is preserved; if it changes the target, `USER_DECISION_REQUIRED`.
3. Target image cannot land directly → accept engineering simplification; check core visual anchors are preserved; do not require full-image import.
4. A visual problem may be caused by code → mark `POSSIBLE_ENGINEERING_ISSUE`; do not guess the code cause; output an engineering-verification ticket.
5. Image resolution insufficient → `INSUFFICIENT_EVIDENCE`; request original size or a crop.
6. Screenshots taken under different conditions → do not make a direct before/after conclusion; require same view, zoom, and state.
7. Engineering lowers the standard citing performance → require the explicit engineering limit; propose an alternative; the User decides the trade-off.

## Hard Stop Conditions

Stop if: no target image or approval standard; no current screenshot; screenshot conditions not comparable; conflicting User visual requirements; a conclusion requires reading code; the agent starts guessing underlying causes; a direct engineering change is requested; the target image is treated as a full game map; key state screenshots missing; visual vs engineering problems cannot be distinguished; a third art Skill would be needed; maturity would be marked VALIDATED; production files must be changed to finish this round.

## Outputs

Final output must include: review scope; approved target summary; current implementation summary; comparison matrix; findings; priority; category; evidence; structured tickets; possible engineering issues; items not verifiable from screenshots; required follow-up screenshots; implementation recipient; re-review criteria; final visual verdict; user decisions required; and a code-correctness disclaimer.

## Examples

### Example 1 — Greenhouse Critical vs Stable
Check plant state, light color, humidity/condensation, equipment state, and whether Critical vs Stable is distinguishable at a glance (not by text label only). Do not judge growth logic.

### Example 2 — Solar Panel Repair Scene
Check exterior feel, panel scale, damage overlay, repair-point readability, player-vs-equipment occlusion, sparks and warning state. Do not judge repair logic.

### Example 3 — Spacesuit Preparation Room
Check whether the suit rack is the primary visual focus; whether the terminal, doors, and path are clear; whether solar panels are wrongly placed indoors; whether it reads as an industrial training base; and whether it is still built from modular assets.

## Skill Boundaries

`task-baseline-and-lock` owns task governance, owner, scope, and commit/push/tag permission (P5-06 may compose with it, but visual review itself is normally read-only and must not auto-modify the repo).

`characterization-first-refactor` owns Godot refactor method and regression proof, not art acceptance.

`save-integrity-guard` owns user-data protection, not visuals.

`guanghan-art-design-and-production` owns scene visual design, asset breakdown, generation prompts, specs, and production briefs (producer-side).

`guanghan-art-review-and-godot-handoff` owns target-vs-screenshot review, visual acceptance, finding classification, correction tickets, and re-review (review-side).

Art production and art review are `SEQUENTIAL_AND_COMPOSABLE`. Typical flow: producer Skill → User approves target → ChatGPT produces art → Codex/Claude Code implement → this review Skill reviews screenshots → engineering ticket → new screenshots → re-review. Do not merge the two Skills.

## Version and Maturity

Current version: `0.1.0`
Current maturity: `TRIAL`

Do not mark this Skill `VALIDATED` until it has been used on at least two real visual-acceptance tasks (one full scene acceptance and one asset/state-variant acceptance), with at least one before/after re-review, tickets correctly executed by engineering, no case of a visual pass being mistaken for code correctness, User acceptance recorded, and feedback revising the Skill to at least a later `0.2.x` version.
