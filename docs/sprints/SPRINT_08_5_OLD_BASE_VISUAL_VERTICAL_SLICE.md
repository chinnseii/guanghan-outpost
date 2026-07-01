# Sprint 08.5: Old Base Visual Vertical Slice

Status: Implemented for review

Sprint 08.5 creates the first art-ready old base core room while preserving the frozen Sprint 08 week-one routine.

## Scope

Included:

- `OldBaseCore_ArtSlice.tscn` as the new old base core visual slice.
- Modular placeholder PNG assets for old base tiles, props, lighting, and player.
- Layered scene hierarchy for future art replacement.
- Objective marker layer that highlights only the current interaction target.
- Week routine flow continues to use the old base gameplay script.
- Narrative black screens hide gameplay HUD.
- Acceptance screenshot capture script.

Not included:

- New survival systems.
- Full farming.
- Inventory.
- Base building.
- New Day 08 content.
- Final pixel art pass.

## Scene Flow

Existing old base transitions now route to:

`res://scenes/base/OldBaseCore_ArtSlice.tscn`

The old greybox scene remains available through the dev menu as:

`Dev Only: Old Base Interior`

The art slice can be opened directly through:

`Dev Only: Old Base Art Slice`

## Acceptance Screenshots

Screenshots are generated into:

`docs/screenshots/sprint08_5_acceptance/`

Expected files:

- `01_old_base_full_room.png`
- `02_player_near_central_console.png`
- `03_player_near_power_panel.png`
- `04_player_near_life_support_console.png`
- `05_player_near_greenhouse_door.png`
- `06_interaction_focus_state.png`
- `07_completed_checklist_state.png`
- `08_day07_report_flow_still_works.png`
- `09_week_end_black_screen_hud_hidden.png`
- `10_asset_overview_contact_sheet.png`

## Notes

This pass is intentionally a visual vertical slice, not a redesign of Sprint 08 gameplay. The goal is to prove that the old base can move away from greybox rectangles into modular, swappable 2D assets while keeping the playable routine stable.
