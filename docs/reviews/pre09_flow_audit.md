# Pre-09 Flow Audit

Status: Sprint 08.6 review pass

## Flow Audited

The current opening flow is intended to proceed without dev entries:

1. Main Menu
2. Application System
3. Qualification Review
4. National Training
5. Final Assessment
6. Mission Assignment Notice
7. Moon assignment black screen
8. Lunar Arrival / Earth observation
9. Old Base airlock entry
10. Old Base system recovery
11. Last Plant discovery and stabilization
12. Day 02 routine and Earth report
13. Day 03-07 week-one routine
14. First Week End
15. Phase 02 placeholder

## Fixes Applied

- Normal title screen entry is separated from dev-only scene shortcuts.
- A Day 07 report dev test entry was added for regression work only.
- Week One no longer ends at report send. It ends only after the player rests.
- First Week End now includes the full prologue closing text sequence.
- Completed Week One saves now continue to the Phase 02 placeholder instead of looping into week-end rest.
- The Phase 02 placeholder appears without starting Sprint 09 gameplay.
- Narrative black-screen evidence is covered by the Sprint 08.5 and Sprint 08.6 capture scripts.

## Text Continuity Notes

- Last Plant continuity is present at discovery, stabilization, Day 06 recovery signal, and Day 07 weekly report.
- Day 02 and Day 03-07 reports use mission-log language instead of RPG reward language.
- Mission assignment remains formal and procedural.
- Arrival keeps Earth as a distant fixed home, not an Earthrise spectacle.

## Known Non-Blocking Issues

- Some archive/settings buttons remain placeholders.
- The full Phase 02 gameplay is intentionally not implemented.
- Some scene visuals are still modular placeholder art and will need later art passes.
- Existing untracked Godot `.png.import` files are left untouched.

## Review Evidence

Acceptance screenshots are generated to:

`docs/screenshots/sprint08_6_acceptance/`

The screenshot set covers normal path milestones from main menu through Phase 02 placeholder.
