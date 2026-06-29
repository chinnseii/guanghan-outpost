# Sprite Guide

Guanghan Outpost currently uses small transparent PNG sprites with programmatic drawing fallback.

## Folders

- `assets/sprites/facilities/`: interior facilities and module equipment.
- `assets/sprites/robots/`: robot bodies by labor role.
- `assets/sprites/collectables/`: moon resources and supply pods.

## Target Sizes

- Facility fixtures: keep exact in-game footprint when possible.
  - Bed: `48x22`
  - Storage: `30x44`
  - Console: `46x28`
  - Robot charger: `38x48`
  - Airlock door: `52x58`
  - Life support tank: `32x44`
  - Greenhouse bed: `52x48`
  - Solar panel tile: `30x58`
- Robots: `48x48`, centered around feet near the lower third.
- Collectables:
  - Resource nodes: `32x32`
  - Supply pod: `48x40`

## Style Rules

- Transparent background.
- Pixel readable at 100 percent scale.
- Use clear status colors:
  - Green: ready or complete.
  - Blue: charging, oxygen, water, ice.
  - Yellow: interactable, highlighted, mission critical.
  - Red/orange: warning, dust, low battery, cargo.
- Keep a fallback drawing path in scripts when adding new sprites.
