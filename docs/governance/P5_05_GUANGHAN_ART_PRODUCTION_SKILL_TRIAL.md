# P5-05 Guanghan Art Production Skill Trial

Date: 2026-07-13
Owner: Codex
Skill: `skills/guanghan/guanghan-art-design-and-production/SKILL.md`
Maturity after trial: `TRIAL`

## Scope

P5-05 created the first project-specific Guanghan art Skill:

```text
skills/guanghan/guanghan-art-design-and-production/SKILL.md
```

No images, production assets, scenes, code, resources, JSON, real saves, or `project.godot` were modified.

## Dry Run Input

```text
Task type:
SCENE_CONCEPT + ASSET_BREAKDOWN + GENERATION_PROMPT

Scene:
Training Base - Spacesuit Preparation Room

Gameplay purpose:
- first room after the player enters the training base
- player moves near the spacesuit
- player interacts to wear the spacesuit
- player opens the suit panel to confirm status
- after closing the panel, the main door opens toward airlock training

Visual requirements:
- indoor
- 2D pixel art
- modular
- industrial lunar training base
- solar panels must not appear indoors
- central training hub connection should remain readable
- no full-scene image for direct import

Allowed changes:
- reasoning and documentation only
```

## Scene Blueprint Summary

Scene mood:

```text
quiet training readiness; not heroic, not luxurious; a practical room where the player learns that leaving a pressurized interior requires preparation.
```

Layout:

```text
North wall:
  status strip lights, cable run, small maintenance labels

West side:
  entry from training hub / central connection, readable door frame

Center:
  player clear path, no dense props, suit interaction approach lane

East side:
  airlock inner door, stronger warning stripes, suit-check terminal nearby

South wall:
  storage cabinets, maintenance bench, spare boot/glove bins

Primary focus:
  spacesuit rack and suit status terminal

Secondary focus:
  airlock direction and hub return route
```

Visual zones:

| Zone | Purpose | Visual cue |
|---|---|---|
| Entry zone | connect to training hub | neutral blue-gray door frame |
| Suit prep zone | wear and confirm suit | suit rack, status panel, floor alignment marks |
| Airlock queue zone | lead to next training step | orange warning stripes, sealed door frame |
| Storage zone | background support | cabinets, labels, maintenance bins |
| Maintenance zone | lived-in engineering feel | cables, tool tray, repair marks |

## Asset List Summary

| Asset ID | Asset | Type | Size | Variant | Interactive | Reusable | Priority |
|---|---|---|---|---|---|---|---|
| `tile_training_floor_metal_worn_01` | worn metal floor tile | tile | `TBD` | normal/worn | no | yes | P0 |
| `tile_training_wall_panel_01` | modular wall panel | tile | `TBD` | normal | no | yes | P0 |
| `door_training_hub_left_closed` | hub-side door frame | sprite/door | `TBD` | closed/open | yes | yes | P0 |
| `door_training_airlock_inner_closed` | airlock inner door | sprite/door | `TBD` | closed/open/locked | yes | yes | P0 |
| `prop_training_suit_rack_empty` | spacesuit rack | prop | `TBD` | empty/occupied | yes | yes | P0 |
| `sprite_training_spacesuit_stowed` | stowed suit | sprite | `TBD` | stowed/worn-missing | yes | yes | P0 |
| `prop_training_suit_status_terminal` | suit status terminal | prop | `TBD` | offline/ready/warning | yes | yes | P0 |
| `overlay_training_floor_alignment_marks` | approach lane marks | overlay | `TBD` | normal | no | yes | P1 |
| `prop_training_storage_cabinet` | storage cabinet | prop | `TBD` | closed | no | yes | P1 |
| `prop_training_maintenance_bench` | small bench/tool tray | prop | `TBD` | normal | no | yes | P2 |
| `decal_training_warning_stripe_airlock` | airlock warning stripe | decal | `TBD` | normal/worn | no | yes | P1 |
| `light_training_wall_status_blue` | wall status light | lighting/prop | `TBD` | blue/yellow/red | no | yes | P1 |
| `prop_training_cable_conduit_module` | cable / pipe run module | prop/overlay | `TBD` | normal/worn | no | yes | P2 |
| `decal_training_scuff_marks_01` | floor scuffs | decal | `TBD` | worn | no | yes | P2 |
| `prop_training_glove_boot_bin` | suit accessory bin | prop | `TBD` | normal | no | yes | P2 |

Solar panels are intentionally absent because this is an indoor preparation room.

## State Logic

Visible states only:

- `normal`: cool blue-gray room, rack occupied, terminal blue/ready.
- `warning`: terminal yellow, airlock stripe emphasis, rack still readable.
- `locked`: airlock door red/amber indicator, no gameplay rule specified.
- `suit_worn`: rack empty or suit silhouette missing, terminal ready indicator remains.

Gameplay logic is not defined by this dry run.

## Production Priority

- P0: floor/walls, hub door, airlock door, suit rack, stowed suit, status terminal.
- P1: approach marks, warning stripe, status light variants, storage cabinet.
- P2: maintenance bench, glove/boot bin, scuff decals.
- P3: additional small labels, dust, tiny maintenance notes.

## Generation Prompt - Room Concept Reference

Positive prompt:

```text
Guanghan Outpost training base spacesuit preparation room, 2D modern narrative pixel art, top-down or near top-down readable game scene concept, modular lunar industrial interior, cool gray and blue-gray metal panels, worn metal floor tiles, practical spacesuit rack as the main focus, suit status terminal beside it, clear player path from training hub door to inner airlock door, orange warning stripes only near the airlock, storage cabinets and maintenance tools along the lower wall, restrained warm indicator lights, used but clean engineering training environment, no solar panels indoors, readable separate doors and props, designed as reference for modular asset breakdown, low saturation, crisp pixels
```

Negative prompt:

```text
no text, no watermark, no photorealism, no 3D render, no perspective distortion, no blurry pixels, no mixed pixel scale, no casino neon, no fantasy, no horror, no full-scene image for direct game import, no solar panels indoors, no outdoor lunar surface, no UI mockup, no baked inseparable interactive objects
```

Reference marker:

```text
NOT_FOR_DIRECT_GAME_IMPORT
```

## Generation Prompt - Spacesuit Rack Asset

Positive prompt:

```text
single reusable spacesuit rack asset for Guanghan Outpost, 2D modern pixel art, orthographic front/top readable prop, transparent background, lunar industrial training base equipment, white and pale gray EVA suit hanging in a compact metal rack, blue-gray frame, small blue status light, subtle worn edges, practical hooks and boot clamps, low saturation, crisp pixels, no text labels, sized for a top-down Godot room prop, separate asset not a room background
```

Negative prompt:

```text
no text, no watermark, no photorealism, no 3D render, no perspective distortion, no blurry pixels, no mixed pixel scale, no complete scene background when producing an asset, no character posing, no glossy showroom, no weapon rack, no solar panel, no fantasy armor
```

## Godot-ready Breakdown

Implementation recipient:

```text
Codex or Claude Code implementation agent
```

Usage notes:

- Build the room from tiles, door sprites, prop sprites, and overlays.
- Treat the room concept as reference only.
- Keep suit rack, suit terminal, hub door, and airlock door separate from floor/wall art.
- Use separate state variants or overlays for terminal and door indicators.
- Keep player path clear through the center.
- Use collision/interaction nodes in implementation, not in this art Skill.
- Do not import one complete room PNG as the interactive scene.

## Dry Run Conclusions

The Skill passed the dry run:

- It did not put solar panels indoors.
- It did not treat a complete scene image as a final game asset.
- It produced a clear player path.
- It separated walls, floor, doors, suit rack, terminal, storage, lights, warning signs, and decals.
- It distinguished concept reference from game-ready assets.
- It avoided gameplay-logic design.
- It did not write code.
- It did not generate images.
- It did not modify scenes or assets.

No blocking revision was found.

Remaining maturity limitation:

- This was a reasoning-only dry run.
- No image was generated.
- No actual asset was sliced or imported into Godot.
- The future review/handoff Skill still needs to judge screenshots and implementation results.

## Result

P5-05 dry run passes.

The Skill remains:

```text
TRIAL
```

Recommended next task:

```text
P5-06 - Guanghan Art Review and Godot Handoff Skill
```
