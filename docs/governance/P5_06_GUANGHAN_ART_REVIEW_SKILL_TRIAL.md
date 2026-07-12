# P5-06 Guanghan Art Review Skill Trial

Date: 2026-07-13
Owner: Claude Code
Skill: `skills/guanghan/guanghan-art-review-and-godot-handoff/SKILL.md`
Maturity after trial: `TRIAL`

## Scope

P5-06 created the second project-specific Guanghan art Skill (review-side):

```text
skills/guanghan/guanghan-art-review-and-godot-handoff/SKILL.md
```

No images, production assets, scenes, code, resources, JSON, real saves, or `project.godot` were modified. This is a reasoning-only dry run of the review workflow.

## Dry Run Input

```text
Review task:
VISUAL_ACCEPTANCE + TARGET_VS_SCREENSHOT

Scene or asset name:
Training Base - Spacesuit Preparation Room

Approved target:
P5-05 spacesuit preparation room concept reference (marked NOT_FOR_DIRECT_GAME_IMPORT)
plus the P5-05 modular asset breakdown.

Approved visual requirements:
- indoor 2D pixel art, modular, industrial lunar training base
- suit rack + suit status terminal as primary focus
- clear player path from training-hub door to inner airlock door
- orange warning stripes only near the airlock
- no solar panels indoors
- no full-scene image used as the interactive map

Current game screenshot:
(described) Room built by importing the full-room concept image as one
background sprite; the suit rack, terminal, and doors are baked into that
single image. A separately placed equipment prop sits in front of the
hub-to-airlock walking lane. The suit status terminal is present but tiny
and its text/indicator is unreadable at gameplay zoom.

Before screenshot: (this is first review, no before)
After screenshot: (n/a this round)

Asset specification:
P5-05 asset list (floor, wall, hub door, airlock door, suit rack, stowed
suit, status terminal, alignment marks, storage, warning stripe, status
light, cable module, decals, accessory bin).

Gameplay purpose:
first training room; player approaches suit, wears it, checks the panel,
then the airlock door opens.

Expected player path:
hub door (west) -> center approach lane -> suit rack -> airlock door (east)

Expected visual states:
normal / warning / locked / suit_worn (visible states only)

Known engineering limitations:
none reported

Implementation report:
none provided

Review scope:
visual acceptance of the landed room against the approved target and specs

Out-of-scope items:
code correctness, save/state-machine/signal/collision correctness,
performance, gameplay numbers

Required output:
comparison, classified findings, structured tickets, verdict

Reviewer:
ChatGPT (primary visual reviewer)

Implementation recipient:
Codex or Claude Code
```

## Comparison Matrix (target vs implementation)

| Dimension | Target | Observed | Result |
|---|---|---|---|
| Style | 2D pixel art, modular | pixel look present but baked | deviation |
| Modularity | separable assets | full-room image as one sprite | FAIL-level |
| Scale | readable suit rack focus | acceptable in image, unverifiable per-asset | partial |
| Palette | cool gray + limited warning | broadly consistent | pass |
| Layout | clear central path | prop blocks hub->airlock lane | FAIL-level |
| Readability | terminal identifiable | terminal tiny/unreadable | issue |
| Layering/Occlusion | player path unobstructed | equipment occludes the path | P0/P1 |
| State feedback | terminal states visible | cannot confirm (baked/unreadable) | insufficient |
| Environment | industrial training base | mood ok in the reference image | pass |

## Findings

1. The full concept reference image was imported directly as one background sprite → `REFERENCE_ONLY_MISUSE`. The reference was explicitly marked `NOT_FOR_DIRECT_GAME_IMPORT` in P5-05.
2. A baked/placed equipment prop occludes the hub-to-airlock walking lane → `OCCLUSION_ERROR` / player path blocked.
3. The suit status terminal is too small to read at gameplay zoom → `READABILITY_ISSUE`.
4. Because the scene is a single baked image, per-asset modularity and terminal state variants cannot be confirmed from the screenshot → `INSUFFICIENT_EVIDENCE` (needs an engineering scene-tree report).

## Structured Tickets

## ART-001 — Full concept image imported as the interactive room
- Priority: P0
- Category: `REFERENCE_ONLY_MISUSE`
- Scene/asset: Training Base - Spacesuit Preparation Room
- Evidence: P5-05 concept reference (marked `NOT_FOR_DIRECT_GAME_IMPORT`) vs current screenshot showing one baked background sprite.
- Target requirement: build the room from modular tiles, door sprites, prop sprites, and overlays; the concept image is reference only.
- Actual result: the entire concept image is used as a single background sprite with rack, terminal, and doors baked in.
- Impact: no modular assets, no separable state variants, no per-object interaction/layering; violates the approved production rule.
- Reproduction/viewpoint: open the preparation room scene at default gameplay zoom.
- Required change: rebuild the room from the P5-05 modular asset list; place suit rack, suit terminal, hub door, and airlock door as separate nodes over floor/wall tiles.
- Must preserve: overall composition, mood, cool-gray palette, primary focus on the suit rack.
- Forbidden shortcut: do not keep the full-room PNG as the interactive scene; do not paint interactive objects into the background.
- Expected verification: new screenshot plus an engineering scene-tree report showing separate nodes for rack, terminal, and both doors.
- Implementation owner: Codex or Claude Code
- Reviewer: ChatGPT
- Status: `OPEN`

## ART-002 — Equipment prop occludes the hub-to-airlock player path
- Priority: P1
- Category: `OCCLUSION_ERROR`
- Scene/asset: central approach lane
- Evidence: current screenshot shows a prop in front of the walking lane; target requires a clear central path.
- Target requirement: keep a clear player path from the hub door (west) through the center to the airlock door (east).
- Actual result: a baked/placed equipment prop sits in the walking lane and blocks the approach.
- Impact: player route to the suit rack and airlock is visually obstructed; readability of the intended flow drops.
- Reproduction/viewpoint: default gameplay zoom, player entry position.
- Required change: move the prop off the central lane (toward the storage/maintenance zone) or reduce its footprint so the path reads clearly.
- Must preserve: industrial storage/maintenance feel; do not delete the prop, relocate it.
- Forbidden shortcut: do not solve this by zooming the camera to hide the prop.
- Expected verification: new screenshot from the same view and zoom showing an unobstructed central path.
- Implementation owner: Codex or Claude Code
- Reviewer: ChatGPT
- Status: `OPEN`

## ART-003 — Suit status terminal is unreadable at gameplay zoom
- Priority: P1
- Category: `READABILITY_ISSUE`
- Scene/asset: suit status terminal
- Evidence: current screenshot shows a very small terminal whose indicator/text cannot be read at gameplay zoom.
- Target requirement: interactive objects, including the suit status terminal, must be identifiable at a glance.
- Actual result: the terminal is too small; its state indicator is not readable.
- Impact: the player cannot tell the suit-check state; a core interaction point loses readability.
- Reproduction/viewpoint: default gameplay zoom near the suit rack.
- Required change: enlarge the terminal to the P5-05 prop scale and give it a clearly readable state indicator (blue/ready, yellow/warning, offline).
- Must preserve: the terminal's position beside the suit rack and its industrial style.
- Forbidden shortcut: do not rely on external UI text alone to convey the terminal state.
- Expected verification: new screenshot showing a readable terminal and a distinguishable indicator state.
- Implementation owner: Codex or Claude Code
- Reviewer: ChatGPT
- Status: `OPEN`

## Possible Engineering Issues

- None asserted. The scene being a single baked image is an art/asset-usage problem, not a claimed code defect. Whether the terminal has functioning state logic cannot be judged from a screenshot; that requires an engineering scene-tree/state report and is recorded as `INSUFFICIENT_EVIDENCE`, not as a code-cause claim.

## Items Not Verifiable From Screenshot

- Per-asset modularity of rack/terminal/doors.
- Terminal state-variant switching.
- Collision alignment with visible assets.

Each requires an engineering report or additional state screenshots.

## Code-Correctness Disclaimer

This review judges visual acceptance only. A passing engineering test suite would not constitute a visual PASS, and this visual review makes no claim about the correctness of the underlying state machine, saves, signals, Manager code, or collision logic.

## Verdict

```text
FAIL
```

Rationale: ART-001 (`REFERENCE_ONLY_MISUSE`, P0) alone is blocking, and ART-002 (path occlusion) is an additional high-priority defect. The scene must be rebuilt from modular assets and re-screenshotted before it can pass. This dry run therefore correctly concludes `FAIL` (not `PASS`), routes three or more structured tickets to engineering, keeps the concept image as reference only, and makes no code-correctness judgement.

## Result

P5-06 dry run passes as a Skill exercise (the Skill produced the required non-`PASS` verdict, `REFERENCE_ONLY_MISUSE` classification, occlusion/readability tickets, and code-correctness disclaimer).

The Skill remains:

```text
TRIAL
```

Remaining maturity limitation:

- reasoning-only dry run; no real screenshot was analyzed;
- no before/after re-review cycle has yet been exercised on live art;
- needs at least two real visual-acceptance tasks with an executed re-review before `VALIDATED`.

Recommended next task:

```text
P5-07 (do not start automatically)
```
