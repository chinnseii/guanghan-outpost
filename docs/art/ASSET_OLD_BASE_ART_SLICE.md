# Old Base Art Slice Asset Notes

Sprint 08.5 establishes the first modular 2D art slice for the old base core room.

These assets are placeholder pixel-art production targets, not final art. They are split into small PNGs so real art can replace them without rebuilding gameplay logic.

## Asset Folders

- `assets/art/old_base/tiles/`
- `assets/art/old_base/props/`
- `assets/art/old_base/lighting/`
- `assets/art/player/`
- `scenes/props/old_base_art/`

## Scene Structure

`scenes/base/OldBaseCore_ArtSlice.tscn`

- `FloorLayer`
- `WallLayer`
- `BackgroundPropLayer`
- `InteractiveObjectLayer`
- `LightingLayer`
- `ObjectiveMarkerLayer`
- `PlayerLayer`
- `UIOverlay` is created by the shared base scene script at runtime.

## Visual Rules

- Do not use a single baked background for the old base room.
- Important gameplay objects should remain separate nodes or sprites.
- Objective highlights belong in `ObjectiveMarkerLayer`.
- The player belongs in `PlayerLayer`.
- HUD remains in `UIOverlay` and must not cover the playable lower-left area.

## Current Placeholder Coverage

Tiles include worn metal floor, wall frame, seams, warning stripe, hatches, cable overlays, and wall/floor boundaries.

Props include central console, old power panel, life support console, storage cabinet, greenhouse door, wall conduit, ceiling light, maintenance note, dust patches, floor cable, and old log marker.

Player placeholders include directional astronaut idle and two walk frames per direction.

Reusable prop scenes exist for the key old-base objects in `scenes/props/old_base_art/`. They currently wrap the placeholder PNGs and are intended as stable replacement points for later pixel-art production.

## Replacement Notes

Future final pixel art should keep similar bounding boxes where possible:

- Consoles: readable from 1600x900 without relying only on labels.
- Greenhouse door: visibly different from a generic training exit.
- Power and life support equipment: visually distinct enough for objective highlights to make sense.
- Player: small but clearly human, compatible with old base and lunar exterior scenes.
