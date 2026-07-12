---
name: guanghan-art-design-and-production
description: Use for Guanghan Outpost visual scene design and modular pixel-art production planning: scene concepts, asset breakdowns, tileset/prop/sprite/UI illustration specs, state variants, generation prompts, naming, dimensions, and Godot-ready art handoff briefs. Use when turning a scene goal, concept image, room, equipment, character, plant state, or visual target into reusable production assets; not for code changes, gameplay design, final screenshot review, or Godot integration fixes.
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

# Guanghan Art Design and Production

## Purpose

Use this Skill to translate the visual direction of Guanghan Outpost into executable scene design, modular pixel-art asset lists, generation prompts, asset specifications, and implementation-ready art briefs.

The result should be usable by art generation or pixel-art production and understandable by Godot implementation agents. It must not stop at one complete concept image, and it must not treat a full concept image as a shipped interactive map.

This Skill owns visual design and asset production planning. It does not own code, `.tscn` changes, gameplay rules, system architecture, final screenshot acceptance, or asset import debugging.

## Fixed Visual Direction

Use these long-term project facts, derived from `docs/PROJECT_BRIEF.md`, `docs/SPRITE_GUIDE.md`, and `docs/art/**` target notes:

- Style: 2D modern narrative pixel art.
- View: top-down or near top-down readability.
- Structure: modular tiles and reusable parts.
- Not: realistic 3D, direct full-illustration maps, or over-detailed concept art that cannot be implemented.
- Palette: low-saturation lunar industrial base; cool gray, dark gray, metal white; sparse orange/yellow warning accents; rare but meaningful plant green.
- Texture: use wear, repair marks, labels, cable runs, hatches, seams, dust, maintenance areas, and practical modifications.
- Mood: lonely, restrained, hopeful, relay-like, life persisting in an extreme place.
- Core line: let life grow where life has never existed.
- Readability: doors, airlocks, terminals, repair points, storage, safe/danger states, and player path must be readable without relying on text labels.

Do not drift into:

- cheerful cartoon playground;
- saturated candy colors;
- casino or cyberpunk neon;
- luxury sci-fi palace;
- realistic military base;
- pure horror;
- clean unused NASA showroom.

## When to Use

Use for:

- new scene visual design;
- room or module art planning;
- old-scene visual redesign;
- tileset requirements;
- prop sets;
- equipment appearance;
- astronaut sprite planning;
- plant state assets;
- Critical/Stable/Damaged/Offline/Repairing variants;
- turning a target image into reusable assets;
- generation prompts;
- asset dimensions and naming;
- art-production notes for Codex or Claude Code.

## Do Not Use When

Do not use for:

- product logic;
- system or gameplay numbers;
- bug fixes;
- code refactors;
- save governance;
- pure UX interaction flow;
- final screenshot acceptance;
- code correctness review;
- asset import troubleshooting;
- identifying an existing image only;
- technical import of already-finished assets;
- plain documentation text edits.

Future `guanghan-art-review-and-godot-handoff` should handle screenshot comparison, target-vs-implementation review, visual landing acceptance, stretching/scale/layer problems, and final revision tickets. Do not create or merge that Skill here.

## Required Inputs

Request these inputs:

- Task type
- Scene or asset name
- Gameplay purpose
- Player actions in this space
- Required visual state
- Camera/view
- Target resolution
- Tile size
- Character scale
- Required assets
- Required state variants
- Animation needs
- Collision/readability needs
- Existing references
- Forbidden visual directions
- Target output
- Implementation recipient

Optional:

- Existing screenshot
- Existing concept art
- Current scene layout
- Room dimensions
- Door positions
- Lighting state
- Critical/Stable variants
- Damage level
- Export format
- Asset path
- Naming prefix
- Deadline/priority

If inputs are missing, make only limited assumptions from the fixed project direction and mark them clearly. Do not guess gameplay rules, dimensions, or technical limits. Missing inputs that affect asset specs should trigger `TBD` or a request for confirmation.

## Task Types

Support these task types:

- `SCENE_CONCEPT`: visual structure and narrative for a scene; not a final shipped full map.
- `ASSET_BREAKDOWN`: split the target into tiles, walls, doors, equipment, props, decals, lighting, overlays, characters, plants, and states.
- `GENERATION_PROMPT`: write image-generation prompts.
- `SPRITE_SPEC`: define size, frames, directions, anchor, transparent background, animation states, and names.
- `TILESET_SPEC`: define tile size, floors, walls, corners, edges, door frames, shadows, damage variants, and stitching rules.
- `PROP_SET`: define reusable equipment and environmental objects.
- `STATE_VARIANTS`: define visual states such as critical, damaged, offline, repairing, stable, operational, overheated, low oxygen, and low power.
- `ART_TO_IMPLEMENTATION_BRIEF`: explain how to build and combine art without editing code.

## Procedure

### Phase A - Read Project Context

Read relevant current references:

- `docs/PROJECT_BRIEF.md`
- `docs/SPRITE_GUIDE.md`
- `docs/art/**` notes for comparable targets
- current scene or system registry when the scene function matters
- task screenshot or target image when provided
- current asset directory conventions

If a referenced art-direction document is missing, record the gap and use confirmed project direction. Do not invent nonexistent files.

### Phase B - Clarify Gameplay Function

Clarify why the player enters the space, what they must see, what they can interact with, how they know the next step, and which states must be readable at a glance.

Translate known gameplay into visual needs. Do not design new gameplay.

### Phase C - Define Visual Hierarchy

Define:

- primary visual focus;
- secondary visual focus;
- player path;
- functional zones;
- interaction points;
- danger points;
- background layer;
- foreground layer;
- non-interactive decoration;
- state feedback.

### Phase D - Build Scene Blueprint

Describe layout in text or ASCII:

- room shape;
- north/east/south/west orientation;
- entrances and exits;
- main equipment;
- cable paths;
- maintenance corridors;
- storage zones;
- visible UI/prompt-safe areas;
- player movement clearance;
- occlusion risks;
- narrative props.

### Phase E - Break Down Assets

Split the scene into the smallest useful reusable units. For each asset record:

- asset ID;
- name;
- type;
- count;
- size or `TBD`;
- state variants;
- animated or static;
- collidable or not;
- interactive or not;
- reusable or scene-specific;
- transparent background requirement;
- Godot usage note.

### Phase F - Define Production Specs

Define or mark `TBD`:

- pixel dimensions;
- tile grid;
- character scale;
- facing direction;
- outline thickness;
- palette notes;
- light direction;
- shadow rules;
- transparent padding;
- pivot/anchor;
- spritesheet layout;
- export format;
- filename.

Use existing specs from `docs/SPRITE_GUIDE.md` when applicable. Do not invent official tile or sprite dimensions when the repo has not confirmed them.

### Phase G - Write Generation Prompts

Each prompt should include:

- subject;
- viewpoint;
- pixel-art style;
- size/use;
- project palette;
- materials;
- wear and state;
- background rule;
- forbidden items;
- single asset or sheet;
- transparent background if needed;
- orthographic/no perspective when needed;
- no text unless explicitly requested.

Provide a positive prompt and a negative prompt.

### Phase H - Write Implementation Brief

Explain for implementation:

- where assets are likely to live;
- which are tiles;
- which are standalone sprites;
- which are reusable;
- which need state switching;
- which need animation;
- which are reference-only;
- which must not be imported as a full map;
- which need collision or interaction nodes.

Do not prescribe code implementation.

### Phase I - Self-Check

Check:

- still 2D pixel art;
- modular and reusable;
- clear dimensions or `TBD`;
- clear state variants;
- supports player path;
- does not depend on one baked full-scene image;
- within current implementation ability;
- matches project mood;
- concept images marked reference-only.

## Scene Design Output Standard

Every scene design should include:

- Scene Summary: name, function, mood, player goal, visual narrative.
- Layout: north/east/south/west, entrances, exits, center area, equipment, path, obstacles, interaction points.
- Visual Zones: entry, operations, maintenance, storage, emergency, observation, or task-specific zones.
- Asset List: table with `Asset ID`, `Asset`, `Type`, `Size`, `Variant`, `Interactive`, `Reusable`.
- State Logic: visible states only; do not define gameplay logic.
- Production Priority: `P0` required, `P1` important, `P2` narrative/environment, `P3` later decoration.

## Asset Breakdown Rules

Always split:

- floors;
- walls;
- doors;
- large equipment;
- small equipment;
- cables;
- lights;
- warning signs;
- storage;
- work tables;
- plants;
- glass panels;
- damage overlays;
- shadows;
- stains;
- repair patches.

Avoid splitting:

- tiny non-reusable noise;
- lighting that only works in a full concept image;
- background-fused details;
- excessive decoration.

Forbid:

- one complete room PNG as the interactive map body;
- baking doors, equipment, walls, and floors into one inseparable image;
- making interactive objects impossible to separate;
- requiring full-scene regeneration for state switching;
- mixing incompatible pixel densities.

## Pixel Art Specification

Require or recommend:

- tile size;
- base character height;
- prop scale;
- wall height;
- outline thickness;
- palette size;
- light direction;
- nearest-neighbor scaling;
- transparent padding;
- pivot point;
- animation frame dimensions.

If the repo does not confirm a formal number, use `TBD` and require calibration from existing character or tileset assets. Do not invent official `16x16`, `32x32`, or `64x64` standards.

Known current examples from `docs/SPRITE_GUIDE.md` may be used as references, not universal law:

- astronaut walk frame: `40x56`;
- robot single body: around `48x48`;
- airlock door: around `52x58`;
- storage cabinet: around `30x44`;
- console: around `46x28`;
- greenhouse bed: around `52x48`;
- solar panel single piece: around `30x58`.

## Naming Convention

Suggest names in this shape unless the repo already has a stronger convention:

```text
<category>_<location>_<asset>_<state>_<variant>
```

Examples:

- `prop_greenhouse_nutrient_tank_critical_a`
- `tile_base_floor_metal_worn_01`
- `door_airlock_inner_closed`
- `plant_crop_leaf_low_water`
- `overlay_solar_panel_damage_02`

Rules:

- lowercase;
- `snake_case`;
- no spaces;
- no Chinese filenames;
- consistent state suffixes;
- consistent animation-frame naming;
- do not treat temporary numbers as final semantics;
- map concept IDs to real asset names.

Do not force renaming of existing approved assets.

## Generation Prompt Standard

Each generation prompt should include:

- asset type;
- project name and style;
- viewpoint;
- pixel-art requirement;
- material;
- color;
- state;
- wear;
- outline;
- lighting;
- background;
- size/use;
- forbidden items.

Negative prompt should include:

```text
no text, no watermark, no photorealism, no 3D render, no perspective distortion, no blurry pixels, no mixed pixel scale, no complete scene background when producing an asset, no UI mockup unless requested
```

## State Variant Standard

Consider whether assets need:

- `normal`;
- `warning`;
- `critical`;
- `damaged`;
- `repairing`;
- `repaired`;
- `offline`;
- `active`;
- `low_power`;
- `low_oxygen`;
- `low_water`;
- `overheated`;
- `frozen`;
- `stable`.

Express state through light color, screen state, cracks, stains, sparks, vapor, leaf posture, overlays, animation, and indicator bars. Do not rely only on text labels.

Prefer base sprite plus overlays or state indicators when many states share the same structure.

## Godot-ready Handoff Boundary

This Skill may output:

- filename suggestions;
- asset path suggestions;
- Sprite2D/AnimatedSprite2D/TileMap usage notes;
- layer order;
- collision/interaction needs;
- state-to-asset mapping;
- animation frame notes;
- slicing notes;
- reference-only markers.

This Skill must not:

- write GDScript;
- create `.tscn`;
- change import settings;
- judge node-script logic;
- guarantee collision correctness;
- guarantee state synchronization;
- replace engineering review.

## Decision Points

- Beautiful but inseparable target image: mark `REFERENCE_ONLY` and produce a modular asset breakdown.
- Visual design conflicts with player path: preserve gameplay path and adjust decoration, equipment, and occlusion.
- Too many assets: phase by `P0` interactive, `P1` functional readability, `P2` narrative environment, `P3` later decoration.
- Pixel spec unknown: mark `TBD` and require calibration from existing assets.
- One asset carries many states: prefer base sprite plus overlays, emissive/state indicators, and reusable damage layers.
- Generation result drifts: constrain viewpoint, pixel density, palette, light direction, size, and single-asset output.
- User asks for full scene image: allow concept reference, target image, or mood board only; mark `NOT_FOR_DIRECT_GAME_IMPORT` and then produce the breakdown plan.

## Allowed Changes

By default this Skill may produce:

- art design documents;
- asset lists;
- generation prompts;
- production specs;
- naming suggestions;
- reference-image notes;
- target-image breakdowns;
- Godot implementation briefs.

By default it must not:

- modify code;
- modify scenes;
- modify resources;
- modify gameplay;
- modify saves;
- modify project config;
- create formal asset image files;
- import assets;
- push or tag.

## Hard Stop Conditions

Stop if:

- gameplay purpose is unknown;
- camera/view is unknown and affects asset specs;
- current pixel scale conflicts severely and no standard can be confirmed;
- the user requires a full image to be used directly as an interactive map;
- assets cannot be separated from background;
- target visual direction conflicts with `docs/PROJECT_BRIEF.md`;
- the design requires gameplay changes;
- the task requires writing code;
- critical dimensions are missing and no useful `TBD` output is possible;
- reference images contain conflicting viewpoints;
- the agent starts judging underlying logic;
- the task is actually review/acceptance instead of production;
- a second art Skill would be needed to finish the current task.

## Outputs

Final output should include:

- Task type
- Scene or asset summary
- Gameplay purpose
- Visual direction
- Layout or asset structure
- Asset breakdown
- Pixel/specification requirements
- State variants
- Naming recommendations
- Positive prompt
- Negative prompt
- Godot-ready usage notes
- Reference-only items
- Production priority
- Open questions / `TBD`
- Forbidden implementation shortcuts
- Handoff recipient

## Examples

### Spacesuit Preparation Room

Design a modular indoor preparation room with a suit rack, status terminal, storage cabinet, inner airlock route, training path, clear player clearance, and separate assets for walls, floor, doors, rack, terminal, lights, signs, and state indicators. Do not make one full baked background.

### Solar Panel Repair Set

Break exterior repair art into intact panel, damaged overlay, dusty panel, tilted panel, broken cable, junction box, repair tool, sparks, indicator, lunar dust decal, and repair marker. Use transparent backgrounds for props and overlays.

### Greenhouse Critical and Stable Variants

Use the same base structure for racks, chamber, water-cycle panel, grow lights, and plant position. Express state through lighting, leaf posture, condensation, warning indicators, and overlays rather than regenerating the whole greenhouse for each state.

## Skill Boundaries

`task-baseline-and-lock` owns task baseline, owner, board, locks, scope, and commit/push/tag permission.

`characterization-first-refactor` owns Godot refactor method and regression proof.

`save-integrity-guard` owns user-data protection, backups, SHA, and save change classification.

`guanghan-art-design-and-production` owns scene visual design, asset breakdown, generation prompts, specifications, and production briefs.

Future `guanghan-art-review-and-godot-handoff` should own target-vs-screenshot review, visual landing acceptance, scale/layer/occlusion review, and final revision tickets.

Art production and art review are `SEQUENTIAL_AND_COMPOSABLE`. Do not merge them.

## Agent Responsibilities

### Primary creative agent: ChatGPT

ChatGPT owns:

- scene visual design;
- explaining visual direction;
- asset breakdown;
- generation prompts;
- image generation;
- image revision;
- style consistency;
- asset specifications;
- final art delivery notes.

### Implementation consumers: Codex, Claude Code

Codex and Claude Code own:

- reading approved art specifications;
- checking whether engineering inputs are complete;
- integrating approved assets into the repository;
- slicing, naming, and importing;
- configuring Godot resources;
- assembling scenes;
- configuring layers, animation, collision, and state mapping;
- verifying that assets work in the runtime environment.

Codex and Claude Code do NOT:

- change the visual direction on their own;
- replace ChatGPT as the primary art creator;
- redesign approved assets themselves;
- decide the final art style;
- lower an approved visual standard for engineering convenience.

### Final approval: User

The User owns:

- the final visual-direction decision;
- target-image approval;
- formal-asset approval;
- whether to proceed to engineering integration;
- whether to accept the engineering-landing result.

### Clarification on the `agents` metadata

Codex and Claude Code appear in this Skill's `agents` metadata because they need to **read and consume** this Skill (to integrate approved art), NOT because they are the primary art producers. ChatGPT is the primary creative and image-generation agent. The User retains final approval authority. This Skill is producer-side; the future `guanghan-art-review-and-godot-handoff` Skill is the review-side counterpart, and the two are `SEQUENTIAL_AND_COMPOSABLE`.

## Version and Maturity

Current version: `0.1.0`
Current maturity: `TRIAL`

Do not mark this Skill `VALIDATED` until it has been used on at least two real art tasks: one scene design plus asset breakdown, and one standalone asset or state-variant task. Actual generated results must be separable and usable in Godot, no full-scene direct import should occur, user acceptance must be recorded, and feedback should revise the Skill to at least a later `0.2.x` version.
