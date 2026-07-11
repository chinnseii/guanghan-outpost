# Sprint 01 Foundation Review

Date: 2026-06-29

## Completed Systems

- Game state flow: `scripts/game_state_manager.gd`
- Time/day clock: `scripts/time_manager.gd`
- Camera follow, zoom and lock hooks: `scripts/camera_manager.gd`
- UI root/HUD/prompt/dialogue hooks: `scripts/ui_manager.gd`
- One-shot event state and save data: `scripts/event_manager.gd`
- Audio event forwarding: `scripts/audio_manager.gd`, `scripts/audio_feedback.gd`
- Save slot foundation: `scripts/save_manager.gd`
- Asset catalog foundation: `scripts/asset_catalog.gd`
- Interaction placeholders: `scripts/interactable.gd`, `scripts/interaction_detector.gd`
- Data Resources: `scripts/data/item_data.gd`, `scripts/data/life_entity_data.gd`, `scripts/data/structure_data.gd`, `scripts/data/interactable_data.gd`, `scripts/data/dialogue_data.gd`, `scripts/data/scene_event_data.gd`
- Lighting framework first pass: `scripts/lighting_manager.gd`, `scripts/light_zone.gd`

## Runnable Scenes

- Main prototype: `res://scenes/main.tscn`
- Sprint 02 dev prototype: `res://scenes/arrival/ArrivalLandingScene.tscn`
- Base interior transition test: `res://scenes/base/BaseInterior_Test.tscn`

## Controls

- Main prototype: WASD/arrows move, E interact, F5 save, F9 load, F10 new run, Z/X camera zoom, [/ ] UI scale.
- Arrival prototype: WASD/arrows move, E enter airlock, F5 save arrival test state, F9 load arrival test state.

## Launch

- Open `project.godot` in Godot 4.7 and run the main scene.
- From the main menu, use `Dev Entry: Arrival Prototype` to enter the Sprint 02 arrival test.

## Known Issues

- `scripts/main.gd` is still large and should continue moving toward managers and data tables.
- Player movement is not yet fully extracted into a reusable `PlayerController.gd`.
- The generic `Interactable` / `InteractionDetector` path exists, but the older main prototype still uses direct E-key logic in places.
- Arrival save data currently uses a separate development save file: `user://arrival_prototype_save.json`.
- The lighting framework supports global color and registered lights, but art-directed lighting is still placeholder level.

## Sprint 02 Risks

- Arrival must remain a development/test entry until the full New Game flow exists.
- The old survival sandbox and the new directed first-hour experience can conflict if they share scene state too early.
- TS-001 and TS-002 should verify camera, event, UI, time, save/load and lighting foundations without adding full automation, mining, robots or tech trees.
