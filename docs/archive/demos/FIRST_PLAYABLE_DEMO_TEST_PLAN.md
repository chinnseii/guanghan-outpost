# First Playable Demo Test Plan

Status: Sprint 08.7 editor-playable demo

## Launch

1. Open the project in Godot.
2. Press Run.
3. Confirm the title screen appears with `v0.5-editor-playtest`.
4. Confirm normal entries are visible:
   - 开始新驻留
   - 继续驻留
   - 开发入口 / Debug
   - 退出

## Clean New Run

1. If progress exists, choose `开始新驻留`.
2. Confirm the warning dialog appears.
3. Choose `清除进度并开始`.
4. Confirm the Application flow begins.

## Continue

1. With no progress, confirm `继续驻留` is disabled.
2. Start any normal-flow progress.
3. Return to the main menu.
4. Confirm `继续驻留` is enabled and routes to the latest normal-flow state.

## Full Normal Flow

Complete the playable chain without Dev / Debug entries:

1. Application
2. Qualification Review
3. Training
4. Final Assessment
5. Mission Assignment
6. Lunar Arrival
7. Old Base Entry
8. Last Plant rescue
9. Day 02 routine
10. Day 03-07 week-one routine
11. First Week End
12. Phase 02 Placeholder
13. Return to Main Menu

## Dev / Debug

1. Press F12 or choose the visually separated Dev / Debug entry.
2. Confirm dev shortcuts are labeled `Dev Only`.
3. Use `Dev Only: Reset Demo Progress` for local testing only.

## Pass Criteria

- The normal path reaches Phase 02 Placeholder.
- Sprint 09 gameplay is not started.
- Continue and reset behavior are safe for local self-testing.
- Known issues remain documented.
